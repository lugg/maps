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

@implementation GoogleStaticMapProvider {
  GMSMapView *_warmupMapView;
  BOOL _tilesRendered;
  BOOL _swapScheduled;
}

#pragma mark - StaticMapProviderBase

- (MKMapRect)mapRectForSize:(CGSize)size {
  // GMSMapView shows the world 256 * 2^zoom points wide, centered on the
  // camera target - the same web mercator MKMapPoint uses, so overlays
  // project onto the warmed-up tiles exactly
  double zoom = MAX(MIN(self.zoom, (double)kGMSMaxZoomLevel),
                    (double)kGMSMinZoomLevel);
  double mapPointsPerPoint = MKMapSizeWorld.width / (256.0 * pow(2.0, zoom));
  double width = size.width * mapPointsPerPoint;
  double height = size.height * mapPointsPerPoint;
  MKMapPoint center = MKMapPointForCoordinate(self.coordinate);
  return MKMapRectMake(center.x - width / 2, center.y - height / 2, width,
                       height);
}

- (UIView *)newDefaultMarkerOverlayView {
  return [[UIImageView alloc]
      initWithImage:[GMSMarker markerImageWithColor:nil]];
}

- (void)renderBaseMap {
  if (_warmupMapView) {
    // Retry a swap that couldn't run (e.g. view was off-window)
    [self scheduleSwap];
    return;
  }
  [self startWarmup];
}

- (void)cancelBaseRender {
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

  _tilesRendered = NO;

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
  mapView.paddingAdjustmentBehavior =
      kGMSMapViewPaddingAdjustmentBehaviorNever;
  mapView.mapType = LuggGMSMapTypeFromMapType(self.mapType);
  mapView.overrideUserInterfaceStyle = LuggInterfaceStyleFromTheme(self.theme);

  _warmupMapView = mapView;
  [wrapperView insertSubview:mapView atIndex:0];
}

- (void)destroyWarmupMapView {
  if (!_warmupMapView)
    return;
  _warmupMapView.delegate = nil;
  [_warmupMapView removeFromSuperview];
  EnqueueStaticMapView([self poolKey], _warmupMapView);
  _warmupMapView = nil;
}

// Once tiles are fully rendered, swap the live map with its image and
// release the map view. The image render and map teardown are expensive,
// so they run outside scroll tracking; the live map keeps displaying (and
// loading tiles) until then.
- (void)scheduleSwap {
  if (_swapScheduled || !_warmupMapView || !_tilesRendered ||
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
  // and this runloop pass; the next tile callback or resumeAnimations
  // retries
  if (!_warmupMapView || !_tilesRendered || !_warmupMapView.window)
    return;

  UIImageView *imageView = [_warmupMapView lugg_snapshotImageView];
  if (!imageView)
    return;

  [self displayBaseImage:imageView.image fromCache:NO];
  [self destroyWarmupMapView];
}

#pragma mark - GMSMapViewDelegate

- (void)mapViewDidStartTileRendering:(GMSMapView *)mapView {
  _tilesRendered = NO;
}

- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView {
  _tilesRendered = YES;
  // The visible warmup map is fully rendered; show the overlays now
  // instead of waiting for the swap, which is deferred while scrolling
  [self revealOverlays];
  [self scheduleSwap];
}

- (void)mapViewSnapshotReady:(GMSMapView *)mapView {
  // Stable per the SDK: tiles loaded, labels and overlays rendered
  _tilesRendered = YES;
  [self revealOverlays];
  [self scheduleSwap];
}

@end
