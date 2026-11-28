#import "GoogleStaticMapProvider.h"

#import "../extensions/UIView+Snapshot.h"
#import "GoogleMapProvider.h"

// Static maps churn through GMSMapViews as list rows warm up, and both
// creating one and tearing one down are expensive main-thread operations
// (renderer setup/teardown). Detached map views are pooled and reused so a
// warmup usually only costs a camera move plus tile load. Keyed by map ID,
// which is fixed at GMSMapView creation.
static const NSUInteger kStaticMapViewPoolCapacity = 6;

static NSMutableDictionary<NSString *, NSMutableArray<GMSMapView *> *> *
StaticMapViewPool(void) {
  static NSMutableDictionary<NSString *, NSMutableArray<GMSMapView *> *> *pool;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pool = [NSMutableDictionary dictionary];
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *notification) {
                  [pool removeAllObjects];
                }];
  });
  return pool;
}

static GMSMapView *_Nullable DequeueStaticMapView(NSString *mapId) {
  NSMutableArray<GMSMapView *> *views = StaticMapViewPool()[mapId];
  GMSMapView *mapView = views.lastObject;
  [views removeLastObject];
  return mapView;
}

static void EnqueueStaticMapView(NSString *mapId, GMSMapView *mapView) {
  NSMutableDictionary<NSString *, NSMutableArray<GMSMapView *> *> *pool =
      StaticMapViewPool();
  NSMutableArray<GMSMapView *> *views = pool[mapId];
  if (!views) {
    views = [NSMutableArray array];
    pool[mapId] = views;
  }
  if (views.count >= kStaticMapViewPoolCapacity)
    return;
  [views addObject:mapView];
}

// A setting change (or a list mounting) re-renders every static map at
// once. Warmups beyond the limit wait in FIFO order; at the pool capacity
// each finished warmup returns its map view to the pool for the next one.
static const NSUInteger kMaxConcurrentWarmups = kStaticMapViewPoolCapacity;

// A warmup whose tiles failed (e.g. offline) never becomes stable and would
// hold its slot until it leaves the window. After this grace period, a
// waiting map takes its slot; one still loading tiles keeps it.
static const NSTimeInterval kWarmupTimeout = 5.0;
// A successful tile render turns stable shortly after it finishes
static const NSTimeInterval kStableGrace = 1.0;

static NSPointerArray *PendingWarmups(void) {
  static NSPointerArray *pending;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pending = [NSPointerArray weakObjectsPointerArray];
  });
  return pending;
}

// Oldest first
static NSPointerArray *ActiveWarmups(void) {
  static NSPointerArray *active;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    active = [NSPointerArray weakObjectsPointerArray];
  });
  return active;
}

@interface GoogleStaticMapProvider ()
@property(nonatomic, readonly) BOOL needsWarmup;
@property(nonatomic, readonly) BOOL warmupStalled;
- (void)startWarmup;
- (void)destroyWarmupMapView;
@end

static void RemoveWarmup(NSPointerArray *warmups,
                         GoogleStaticMapProvider *provider) {
  for (NSInteger i = (NSInteger)warmups.count - 1; i >= 0; i--) {
    void *pointer = [warmups pointerAtIndex:i];
    // Released providers leave NULL entries behind
    if (!pointer || pointer == (__bridge void *)provider) {
      [warmups removePointerAtIndex:i];
    }
  }
}

// The reclaimed map shows the placeholder and retries when it returns to
// the window or on reload(), not right away: requeueing would cycle failing
// maps through the slots for as long as the list is offline
static BOOL ReclaimStalledWarmup(void) {
  NSPointerArray *active = ActiveWarmups();
  for (NSUInteger i = 0; i < active.count; i++) {
    GoogleStaticMapProvider *provider =
        (__bridge GoogleStaticMapProvider *)[active pointerAtIndex:i];
    if (provider.warmupStalled) {
      [provider abandonBaseRender];
      return YES;
    }
  }
  return NO;
}

// Deferred so a settings change that cancels warmups mid-update doesn't
// start pending maps that are about to get the same change
static void SchedulePendingWarmups(void) {
  static BOOL scheduled = NO;
  if (scheduled)
    return;
  scheduled = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    scheduled = NO;
    NSPointerArray *pending = PendingWarmups();
    while (pending.count > 0) {
      GoogleStaticMapProvider *provider =
          (__bridge GoogleStaticMapProvider *)[pending pointerAtIndex:0];
      // Left the window or rendered from another path while it waited;
      // resumeAnimations queues it again on return
      if (!provider.needsWarmup) {
        [pending removePointerAtIndex:0];
        continue;
      }
      if (ActiveWarmups().count >= kMaxConcurrentWarmups &&
          !ReclaimStalledWarmup())
        break;
      [pending removePointerAtIndex:0];
      [provider startWarmup];
    }
  });
}

@implementation GoogleStaticMapProvider {
  GMSMapView *_warmupMapView;
  BOOL _snapshotReady;
  BOOL _swapScheduled;
  BOOL _indoorEnabled;
  BOOL _tilesRendering;
  CFTimeInterval _tilesFinishedTime;
  BOOL _warmupTimedOut;
  NSUInteger _warmupGeneration;
}

- (instancetype)init {
  if (self = [super init]) {
    _indoorEnabled = YES;
  }
  return self;
}

- (void)setIndoorEnabled:(BOOL)enabled {
  if (_indoorEnabled == enabled)
    return;
  _indoorEnabled = enabled;
  [self rerenderBaseMap];
}

#pragma mark - StaticMapProviderBase

- (MKMapRect)mapRectForSize:(CGSize)size {
  // GMSMapView shows the world 256 * 2^zoom points wide, centered on the
  // camera target - the same web mercator MKMapPoint uses, so overlays
  // project onto the warmed-up tiles exactly
  double zoom =
      MAX(MIN(self.zoom, (double)kGMSMaxZoomLevel), (double)kGMSMinZoomLevel);
  double mapPointsPerPoint = MKMapSizeWorld.width / (256.0 * pow(2.0, zoom));
  double width = size.width * mapPointsPerPoint;
  double height = size.height * mapPointsPerPoint;
  MKMapPoint center = MKMapPointForCoordinate(self.coordinate);
  return MKMapRectMake(center.x - width / 2, center.y - height / 2, width,
                       height);
}

- (UIView *)newDefaultMarkerOverlayView {
  return
      [[UIImageView alloc] initWithImage:[GMSMarker markerImageWithColor:nil]];
}

// Inverse of mapRectForSize
- (double)zoomForMapPointsPerPoint:(double)mapPointsPerPoint {
  double zoom = log2(MKMapSizeWorld.width / (256.0 * mapPointsPerPoint));
  return MAX(MIN(zoom, (double)kGMSMaxZoomLevel), (double)kGMSMinZoomLevel);
}

- (void)renderBaseMap {
  if (_warmupMapView) {
    // Retry a swap that couldn't run (e.g. view was off-window)
    [self scheduleSwap];
    return;
  }
  RemoveWarmup(PendingWarmups(), self);
  [PendingWarmups() addPointer:(__bridge void *)self];
  SchedulePendingWarmups();
}

- (void)cancelBaseRender {
  RemoveWarmup(PendingWarmups(), self);
  [self destroyWarmupMapView];
}

// Frees the warmup slot of a provider dropped without destroy
- (void)dealloc {
  [self destroyWarmupMapView];
}

#pragma mark - Warmup

// "" resolves to the demo map ID (see LuggGMSMapIDFromString), so both
// share a pool bucket
- (NSString *)poolKey {
  return self.mapId.length > 0 ? self.mapId : @"DEMO_MAP_ID";
}

- (void)startWarmup {
  UIView *wrapperView = self.wrapperView;
  if (!wrapperView)
    return;

  _snapshotReady = NO;
  _tilesRendering = NO;
  _tilesFinishedTime = 0;
  _warmupTimedOut = NO;

  GMSMapView *mapView = DequeueStaticMapView([self poolKey]);
  if (mapView) {
    mapView.frame = wrapperView.bounds;
    [mapView moveCamera:[GMSCameraUpdate setTarget:self.coordinate
                                              zoom:(float)self.zoom]];
  } else {
    GMSCameraPosition *camera =
        [GMSCameraPosition cameraWithLatitude:self.coordinate.latitude
                                    longitude:self.coordinate.longitude
                                         zoom:(float)self.zoom];

    GMSMapViewOptions *options = [[GMSMapViewOptions alloc] init];
    options.frame = wrapperView.bounds;
    options.camera = camera;
    options.mapID = LuggGMSMapIDFromString(self.mapId);

    mapView = [[GMSMapView alloc] initWithOptions:options];
  }

  mapView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  mapView.delegate = self;
  mapView.userInteractionEnabled = NO;
  mapView.preferredFrameRate = kGMSFrameRateConservative;
  mapView.paddingAdjustmentBehavior = kGMSMapViewPaddingAdjustmentBehaviorNever;
  // Frames the camera like the inset-shifted projection (and clears stale
  // padding on pooled views)
  mapView.padding = self.edgeInsets;
  mapView.mapType = LuggGMSMapTypeFromMapType(self.mapType);
  mapView.indoorEnabled = _indoorEnabled;
  // The snapshot would bake in a dead floor picker
  mapView.settings.indoorPicker = NO;
  mapView.overrideUserInterfaceStyle = LuggInterfaceStyleFromTheme(self.theme);

  _warmupMapView = mapView;
  [ActiveWarmups() addPointer:(__bridge void *)self];
  [wrapperView insertSubview:mapView atIndex:0];

  NSUInteger generation = ++_warmupGeneration;
  __weak GoogleStaticMapProvider *weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(kWarmupTimeout * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   GoogleStaticMapProvider *strongSelf = weakSelf;
                   if (strongSelf &&
                       strongSelf->_warmupGeneration == generation) {
                     [strongSelf warmupDidTimeOut];
                   }
                 });
}

- (void)warmupDidTimeOut {
  if (!_warmupMapView)
    return;
  _warmupTimedOut = YES;
  SchedulePendingWarmups();
}

- (BOOL)needsWarmup {
  return !_warmupMapView && !self.baseRenderDone && self.wrapperView.window;
}

// Checked whenever a waiting map needs a slot, so a warmup that renders
// again (e.g. tiles invalidated before its swap) can still give way later
- (BOOL)warmupStalled {
  return _warmupMapView && _warmupTimedOut && !_tilesRendering &&
         !_snapshotReady &&
         CACurrentMediaTime() - _tilesFinishedTime >= kStableGrace;
}

- (void)destroyWarmupMapView {
  if (!_warmupMapView)
    return;
  _warmupMapView.delegate = nil;
  [_warmupMapView removeFromSuperview];
  EnqueueStaticMapView([self poolKey], _warmupMapView);
  _warmupMapView = nil;
  RemoveWarmup(ActiveWarmups(), self);
  SchedulePendingWarmups();
}

// Once the map is stable, swap the live map with its image and release the
// map view. The image render and map teardown are expensive, so they run
// outside scroll tracking; the live map keeps displaying (and loading
// tiles) until then.
- (void)scheduleSwap {
  if (_swapScheduled || !_warmupMapView || !_snapshotReady ||
      !_warmupMapView.window)
    return;

  _swapScheduled = YES;
  __weak GoogleStaticMapProvider *weakSelf = self;
  [[NSRunLoop mainRunLoop] performInModes:@[ NSDefaultRunLoopMode ]
                                    block:^{
                                      GoogleStaticMapProvider *strongSelf =
                                          weakSelf;
                                      if (!strongSelf)
                                        return;
                                      strongSelf->_swapScheduled = NO;
                                      [strongSelf performSwap];
                                    }];
}

- (void)performSwap {
  // Tiles can invalidate (or the view leave the window) between scheduling
  // and this runloop pass; the next snapshotReady or resumeAnimations
  // retries
  if (!_warmupMapView || !_snapshotReady || !_warmupMapView.window)
    return;

  UIImageView *imageView = [_warmupMapView lugg_snapshotImageView];
  if (!imageView)
    return;

  [self displayBaseImage:imageView.image fromCache:NO];
  [self destroyWarmupMapView];
}

#pragma mark - GMSMapViewDelegate

- (void)mapViewDidStartTileRendering:(GMSMapView *)mapView {
  _snapshotReady = NO;
  _tilesRendering = YES;
}

// Fires for tiles that failed permanently too, so it can't gate the swap:
// capturing here cached blank tiles under the static key with no way to
// recover. The visible warmup map has rendered what it can; show the
// overlays now instead of waiting for the swap, which is deferred while
// scrolling
- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView {
  _tilesRendering = NO;
  _tilesFinishedTime = CACurrentMediaTime();
  [self revealOverlays];
  // Still not stable after the grace (and past the timeout) means tiles
  // failed; a waiting map can take over
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kStableGrace * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        SchedulePendingWarmups();
      });
}

// Stable per the SDK: tiles loaded, labels and overlays rendered. The only
// signal that the render is complete, so the only one that captures and
// caches. Without it (e.g. offline) the live map stays until the view
// leaves the window or a waiting map takes its slot, and a fresh warmup
// runs on return.
- (void)mapViewSnapshotReady:(GMSMapView *)mapView {
  _snapshotReady = YES;
  [self revealOverlays];
  [self scheduleSwap];
}

@end
