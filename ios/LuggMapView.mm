#import "LuggMapView.h"
#import "LuggCircleView.h"
#import "LuggGroundOverlayView.h"
#import "LuggMapWrapperView.h"
#import "LuggMarkerView.h"
#import "LuggPolygonView.h"
#import "LuggPolylineView.h"
#import "LuggTileOverlayView.h"
#import "core/AppleMapProvider.h"
#import "core/AppleStaticMapProvider.h"
#if LUGG_GOOGLE_MAPS_ENABLED
#import "core/GoogleMapProvider.h"
#import "core/GoogleStaticMapProvider.h"
#endif
#import "core/MapProviderDelegate.h"
#import "events/CameraIdleEvent.h"
#import "events/CameraMoveEvent.h"
#import "events/LongPressEvent.h"
#import "events/PressEvent.h"
#import "events/ReadyEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

// Static snapshots cached across view recycling, keyed by the user-provided
// staticKey plus the map settings that affect appearance. Bounded by bytes
// only: mounted rows hold their images anyway, so the limit has to cover a
// list's mounted maps plus the ones scrolled away (a 407x140pt @3x image is
// ~2 MB, so ~60 of them). NSCache also evicts under memory pressure.
static NSCache<NSString *, UIImage *> *StaticSnapshotCache(void) {
  static NSCache<NSString *, UIImage *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
    cache.totalCostLimit = 128 * 1024 * 1024; // bytes
  });
  return cache;
}

// How long an unfinished static map survives off-window. Transitions (e.g.
// a screen push) move maps out of the window and back in; tearing them down
// right away rebuilt every map mid-render.
static const NSTimeInterval kOffWindowTeardownDelay = 0.5;

@interface LuggMapView () <RCTLuggMapViewViewProtocol, MapProviderDelegate>
@end

@implementation LuggMapView {
  id<MapProvider> _provider;
  LuggMapWrapperView *_mapWrapperView;
  LuggMapViewProvider _providerType;
  NSString *_mapId;
  BOOL _initialized;
  // Cached props to apply after content creation
  BOOL _zoomEnabled;
  BOOL _scrollEnabled;
  BOOL _rotateEnabled;
  BOOL _pitchEnabled;
  BOOL _compassEnabled;
  BOOL _indoorEnabled;
  BOOL _staticMode;
  NSString *_staticKey;
  // Appearance the static map renders for with the 'system' theme
  UIUserInterfaceStyle _staticStyle;
  BOOL _userLocationEnabled;
  LuggMapViewMapType _mapType;
  LuggMapViewTheme _theme;
  LuggMapViewIdleFrameRate _idleFrameRate;
  BOOL _poiEnabled;
  LuggMapViewPoiFilterMode _poiFilterMode;
  NSArray<NSString *> *_poiFilterCategories;
  double _minZoom;
  double _maxZoom;
  UIEdgeInsets _edgeInsets;
  UIEdgeInsets _edgeInsetsProp;
  LuggMapViewInsetAdjustment _insetAdjustment;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<LuggMapViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const LuggMapViewProps>();
    _props = defaultProps;

    _initialized = NO;
    _mapId = @"";
    _providerType = LuggMapViewProvider::Google;
    _zoomEnabled = YES;
    _scrollEnabled = YES;
    _rotateEnabled = YES;
    _pitchEnabled = YES;
    _compassEnabled = YES;
    _indoorEnabled = YES;
    _staticMode = NO;
    _staticKey = @"";
    _userLocationEnabled = NO;
    _poiEnabled = NO;
    _poiFilterMode = LuggMapViewPoiFilterMode::Including;
    _poiFilterCategories = @[];
    _mapType = LuggMapViewMapType::Standard;
    _theme = LuggMapViewTheme::System;
    _idleFrameRate = LuggMapViewIdleFrameRate::Maximum;
    _edgeInsets = UIEdgeInsetsZero;
    _insetAdjustment = LuggMapViewInsetAdjustment::Never;
  }
  return self;
}

#pragma mark - View Lifecycle

- (void)mountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                          index:(NSInteger)index {
  [super mountChildComponentView:childComponentView index:index];

  if ([childComponentView isKindOfClass:[LuggMapWrapperView class]]) {
    _mapWrapperView = (LuggMapWrapperView *)childComponentView;
  } else if ([childComponentView isKindOfClass:[LuggMarkerView class]]) {
    LuggMarkerView *markerView = (LuggMarkerView *)childComponentView;
    if (_provider) {
      [_provider addMarkerView:markerView];
    }
  } else if ([childComponentView isKindOfClass:[LuggPolylineView class]]) {
    LuggPolylineView *polylineView = (LuggPolylineView *)childComponentView;
    if (_provider) {
      [_provider addPolylineView:polylineView];
    }
  } else if ([childComponentView isKindOfClass:[LuggPolygonView class]]) {
    LuggPolygonView *polygonView = (LuggPolygonView *)childComponentView;
    if (_provider) {
      [_provider addPolygonView:polygonView];
    }
  } else if ([childComponentView isKindOfClass:[LuggCircleView class]]) {
    LuggCircleView *circleView = (LuggCircleView *)childComponentView;
    if (_provider) {
      [_provider addCircleView:circleView];
    }
  } else if ([childComponentView isKindOfClass:[LuggGroundOverlayView class]]) {
    LuggGroundOverlayView *groundOverlayView =
        (LuggGroundOverlayView *)childComponentView;
    if (_provider) {
      [_provider addGroundOverlayView:groundOverlayView];
    }
  } else if ([childComponentView isKindOfClass:[LuggTileOverlayView class]]) {
    LuggTileOverlayView *tileOverlayView =
        (LuggTileOverlayView *)childComponentView;
    if (_provider) {
      [_provider addTileOverlayView:tileOverlayView];
    }
  }
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  if ([childComponentView isKindOfClass:[LuggMarkerView class]]) {
    LuggMarkerView *markerView = (LuggMarkerView *)childComponentView;
    if (_provider) {
      [_provider removeMarkerView:markerView];
    }
  } else if ([childComponentView isKindOfClass:[LuggPolylineView class]]) {
    LuggPolylineView *polylineView = (LuggPolylineView *)childComponentView;
    if (_provider) {
      [_provider removePolylineView:polylineView];
    }
  } else if ([childComponentView isKindOfClass:[LuggPolygonView class]]) {
    LuggPolygonView *polygonView = (LuggPolygonView *)childComponentView;
    if (_provider) {
      [_provider removePolygonView:polygonView];
    }
  } else if ([childComponentView isKindOfClass:[LuggCircleView class]]) {
    LuggCircleView *circleView = (LuggCircleView *)childComponentView;
    if (_provider) {
      [_provider removeCircleView:circleView];
    }
  } else if ([childComponentView isKindOfClass:[LuggGroundOverlayView class]]) {
    LuggGroundOverlayView *groundOverlayView =
        (LuggGroundOverlayView *)childComponentView;
    if (_provider) {
      [_provider removeGroundOverlayView:groundOverlayView];
    }
  } else if ([childComponentView isKindOfClass:[LuggTileOverlayView class]]) {
    LuggTileOverlayView *tileOverlayView =
        (LuggTileOverlayView *)childComponentView;
    if (_provider) {
      [_provider removeTileOverlayView:tileOverlayView];
    }
  }

  [super unmountChildComponentView:childComponentView index:index];
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  [NSObject
      cancelPreviousPerformRequestsWithTarget:self
                                     selector:
                                         @selector(
                                             teardownOffWindowStaticContent)
                                       object:nil];
  if (self.window) {
    if (!_provider && _mapWrapperView) {
      if (_staticMode) {
        [self startStaticContent];
      } else {
        [self initializeProvider];
      }
    }
    [self updateStaticAppearance];
    [_provider resumeAnimations];
  } else {
    [_provider pauseAnimations];
    if ([_provider isKindOfClass:[StaticMapProviderBase class]] &&
        !((StaticMapProviderBase *)_provider).baseRenderDone) {
      [self performSelector:@selector(teardownOffWindowStaticContent)
                 withObject:nil
                 afterDelay:kOffWindowTeardownDelay];
    }
  }
}

// A static map mid-warmup may hold an expensive live map view. Destroy it
// once it stays off-window and re-render on return, instead of letting
// paused maps pile up across screen switches and all resume at once
- (void)teardownOffWindowStaticContent {
  if (self.window || ![_provider isKindOfClass:[StaticMapProviderBase class]] ||
      ((StaticMapProviderBase *)_provider).baseRenderDone)
    return;
  [_provider destroy];
  _provider = nil;
  _initialized = NO;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
  [super traitCollectionDidChange:previousTraitCollection];
  if (!_staticMode || self.traitCollection.userInterfaceStyle ==
                          previousTraitCollection.userInterfaceStyle)
    return;

  // App switcher snapshots flip the appearance and restore it in the same
  // pass; only a change that sticks re-renders
  __weak LuggMapView *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf updateStaticAppearance];
  });
}

// A 'system' theme static map shows the appearance it rendered with, so a
// change renders it again (or reuses the snapshot cached for the new one)
- (void)updateStaticAppearance {
  UIUserInterfaceStyle style = self.traitCollection.userInterfaceStyle;
  if (!_staticMode || !self.window || style == _staticStyle)
    return;
  _staticStyle = style;

  if (_theme != LuggMapViewTheme::System ||
      ![_provider isKindOfClass:[StaticMapProviderBase class]])
    return;

  StaticMapProviderBase *staticProvider = (StaticMapProviderBase *)_provider;
  [staticProvider rerenderBaseMap];
  NSString *cacheKey = [self staticSnapshotCacheKey];
  if (cacheKey) {
    staticProvider.cachedBaseImage =
        [StaticSnapshotCache() objectForKey:cacheKey];
  }
}

// Shown while the map warms up, until the live map or snapshot covers it
- (void)applyStaticPlaceholderBackground {
  // Also styles the base render, which the 'system' theme inherits, so it
  // applies with a custom background too
  switch (_theme) {
  case LuggMapViewTheme::Dark:
    _mapWrapperView.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    break;
  case LuggMapViewTheme::Light:
    _mapWrapperView.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    break;
  default:
    _mapWrapperView.overrideUserInterfaceStyle =
        UIUserInterfaceStyleUnspecified;
    break;
  }

  const auto &viewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(_props);
  if (viewProps.backgroundColor) {
    // A user-provided background acts as the placeholder
    return;
  }
  _mapWrapperView.backgroundColor = UIColor.secondarySystemBackgroundColor;
}

- (nullable NSString *)staticSnapshotCacheKey {
  if (_staticKey.length == 0 || !_mapWrapperView)
    return nil;

  CGSize size = _mapWrapperView.bounds.size;
  if (size.width <= 0 || size.height <= 0)
    return nil;

  // 'system' theme snapshots depend on the appearance they render with
  NSInteger style = _theme == LuggMapViewTheme::System ? (NSInteger)_staticStyle
                                                       : -(NSInteger)_theme;

  // Camera is part of the key so a reused staticKey with a different
  // location/zoom can't serve a stale snapshot. The provider's camera (when
  // available) reflects imperative camera changes, so a re-rendered
  // snapshot is keyed on what it actually shows.
  const auto &viewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(_props);
  double latitude = viewProps.initialCoordinate.latitude;
  double longitude = viewProps.initialCoordinate.longitude;
  double zoom = viewProps.initialZoom;
  if ([_provider isKindOfClass:[StaticMapProviderBase class]]) {
    StaticMapProviderBase *staticProvider = (StaticMapProviderBase *)_provider;
    latitude = staticProvider.coordinate.latitude;
    longitude = staticProvider.coordinate.longitude;
    zoom = staticProvider.zoom;
  }

  // Only Google renders indoor maps and only Apple filters POIs; Apple also
  // serves provider="google" when the Google SDK is excluded
  BOOL isApple = [_provider isKindOfClass:[AppleStaticMapProvider class]];
  BOOL indoorEnabled = _indoorEnabled && !isApple;
  NSString *poiFilter = @"";
  if (isApple) {
    poiFilter =
        _poiEnabled
            ? [NSString stringWithFormat:@"%d:%@", (int)_poiFilterMode,
                                         [_poiFilterCategories
                                             componentsJoinedByString:@","]]
            : @"off";
  }

  return [NSString
      stringWithFormat:@"%@|%d|%@|%d|%d|%@|%ld|%.0fx%.0f|%.6f,%.6f,%.2f|%@",
                       _staticKey, (int)_providerType, _mapId, (int)_mapType,
                       (int)indoorEnabled, poiFilter, (long)style, size.width,
                       size.height, latitude, longitude, zoom,
                       NSStringFromUIEdgeInsets(_edgeInsets)];
}

- (void)startStaticContent {
  [self applyStaticPlaceholderBackground];

  // Both static providers render fully async: the placeholder shows until
  // the snapshotter (Apple) or a brief live-map warmup (Google) delivers
  // the base map, which reveals together with the marker/shape overlays
  [self initializeProvider];
}

// staticKey identifies the map's content; when it changes (e.g. a recycled
// list row bound to a new item), any live warmup or displayed snapshot is
// stale and the static lifecycle restarts. Without this, an in-flight
// warmup caches the old item's map under the new key. Insets from the
// setEdgeInsets command belong to the old item, so the prop insets return.
- (void)resetStaticContent {
  _edgeInsets = _edgeInsetsProp;

  if (_provider) {
    [_provider destroy];
    _provider = nil;
    _initialized = NO;
  }

  if (self.window) {
    [self startStaticContent];
  }
}

- (void)prepareForRecycle {
  [super prepareForRecycle];

  _edgeInsets = UIEdgeInsetsZero;
  _edgeInsetsProp = UIEdgeInsetsZero;

  [_provider destroy];
  _provider = nil;
  _mapWrapperView = nil;
  _initialized = NO;
}

#pragma mark - Provider Initialization

- (void)initializeProvider {
  const auto &viewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(_props);
  [self
      initializeProviderWithCoordinate:CLLocationCoordinate2DMake(
                                           viewProps.initialCoordinate.latitude,
                                           viewProps.initialCoordinate
                                               .longitude)
                                  zoom:viewProps.initialZoom];
}

- (void)initializeProviderWithCoordinate:(CLLocationCoordinate2D)coordinate
                                    zoom:(double)zoom {
  if (_provider || !_mapWrapperView)
    return;

  if (_providerType == LuggMapViewProvider::Apple) {
    _provider = _staticMode ? [[AppleStaticMapProvider alloc] init]
                            : [[AppleMapProvider alloc] init];
#if LUGG_GOOGLE_MAPS_ENABLED
  } else if (_staticMode) {
    GoogleStaticMapProvider *google = [[GoogleStaticMapProvider alloc] init];
    google.mapId = _mapId;
    _provider = google;
  } else {
    GoogleMapProvider *google = [[GoogleMapProvider alloc] init];
    google.mapId = _mapId;
    _provider = google;
  }
#else
  } else {
    NSLog(@"[LuggMaps] provider=\"google\" requested but the Google Maps SDK "
          @"is excluded ($LuggMapsGoogleEnabled = false); using Apple Maps");
    _provider = _staticMode ? [[AppleStaticMapProvider alloc] init]
                            : [[AppleMapProvider alloc] init];
  }
#endif

  _provider.delegate = self;
  _provider.staticMode = _staticMode;

  [_provider initializeMapInView:_mapWrapperView
               initialCoordinate:coordinate
                     initialZoom:zoom];

  // Apply cached props after map view is created
  [self applyProps];
  [_provider setEdgeInsets:_edgeInsets oldEdgeInsets:UIEdgeInsetsZero];

  // After initializeMapInView so the cache key reads the provider's camera,
  // and after the props so later setting changes drop the pending image;
  // the base render is async and picks up the cached image
  if (_staticMode) {
    _staticStyle = self.traitCollection.userInterfaceStyle;
    NSString *cacheKey = [self staticSnapshotCacheKey];
    if (cacheKey) {
      ((StaticMapProviderBase *)_provider).cachedBaseImage =
          [StaticSnapshotCache() objectForKey:cacheKey];
    }
  }

  _initialized = YES;

  // Flush any children that were mounted before content was created
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[LuggMarkerView class]]) {
      [_provider addMarkerView:(LuggMarkerView *)subview];
    } else if ([subview isKindOfClass:[LuggPolylineView class]]) {
      [_provider addPolylineView:(LuggPolylineView *)subview];
    } else if ([subview isKindOfClass:[LuggPolygonView class]]) {
      [_provider addPolygonView:(LuggPolygonView *)subview];
    } else if ([subview isKindOfClass:[LuggCircleView class]]) {
      [_provider addCircleView:(LuggCircleView *)subview];
    } else if ([subview isKindOfClass:[LuggGroundOverlayView class]]) {
      [_provider addGroundOverlayView:(LuggGroundOverlayView *)subview];
    } else if ([subview isKindOfClass:[LuggTileOverlayView class]]) {
      [_provider addTileOverlayView:(LuggTileOverlayView *)subview];
    }
  }
}

#pragma mark - MapProviderDelegate

- (void)mapProviderDidReady {
  ReadyEvent::emit<LuggMapViewEventEmitter>(_eventEmitter);
}

- (void)mapProviderDidCaptureStaticImage:(UIImage *)image {
  // The appearance changed during the render and a re-render is pending;
  // the image may show either one
  if (_theme == LuggMapViewTheme::System &&
      self.traitCollection.userInterfaceStyle != _staticStyle)
    return;

  NSString *key = [self staticSnapshotCacheKey];
  if (key) {
    CGImageRef cgImage = image.CGImage;
    NSUInteger cost =
        CGImageGetBytesPerRow(cgImage) * CGImageGetHeight(cgImage);
    [StaticSnapshotCache() setObject:image forKey:key cost:cost];
  }
}

- (void)mapProviderDidMoveCamera:(double)latitude
                       longitude:(double)longitude
                            zoom:(double)zoom
                         gesture:(BOOL)gesture {
  CameraMoveEvent{latitude, longitude, zoom, static_cast<bool>(gesture)}
      .emit<LuggMapViewEventEmitter>(_eventEmitter);
}

- (void)mapProviderDidIdleCamera:(double)latitude
                       longitude:(double)longitude
                            zoom:(double)zoom
                         gesture:(BOOL)gesture {
  CameraIdleEvent{latitude, longitude, zoom, static_cast<bool>(gesture)}
      .emit<LuggMapViewEventEmitter>(_eventEmitter);
}

- (void)mapProviderDidPress:(double)latitude
                  longitude:(double)longitude
                          x:(double)x
                          y:(double)y {
  PressEvent{latitude, longitude, x, y}.emit<LuggMapViewEventEmitter>(
      _eventEmitter);
}

- (void)mapProviderDidLongPress:(double)latitude
                      longitude:(double)longitude
                              x:(double)x
                              y:(double)y {
  LongPressEvent{latitude, longitude, x, y}.emit<LuggMapViewEventEmitter>(
      _eventEmitter);
}

#pragma mark - Property Setters

- (void)applyProps {
  [_provider setZoomEnabled:_zoomEnabled];
  [_provider setScrollEnabled:_scrollEnabled];
  [_provider setRotateEnabled:_rotateEnabled];
  [_provider setPitchEnabled:_pitchEnabled];
  [_provider setCompassEnabled:_compassEnabled];
  [_provider setIndoorEnabled:_indoorEnabled];
  [_provider setUserLocationEnabled:_userLocationEnabled];
  [_provider setMapType:_mapType];
  [_provider setTheme:_theme];
  [_provider setIdleFrameRate:_idleFrameRate];
  [_provider setPoiEnabled:_poiEnabled];
  [_provider setPoiFilterMode:_poiFilterMode];
  [_provider setPoiFilterCategories:_poiFilterCategories];
  [_provider setMinZoom:_minZoom];
  [_provider setMaxZoom:_maxZoom];
  [_provider setInsetAdjustment:_insetAdjustment];
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &newViewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(props);
  const auto &prevViewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(_props);

  _providerType = newViewProps.provider;
  _staticMode = newViewProps.staticMode;

  NSString *newStaticKey =
      [NSString stringWithUTF8String:newViewProps.staticKey.c_str()];
  BOOL staticKeyChanged = ![newStaticKey isEqualToString:_staticKey];
  _staticKey = newStaticKey;

  NSString *newMapId =
      [NSString stringWithUTF8String:newViewProps.mapId.c_str()];
  if (newMapId.length > 0) {
    _mapId = newMapId;
  }

  if (newViewProps.zoomEnabled != prevViewProps.zoomEnabled) {
    _zoomEnabled = newViewProps.zoomEnabled;
    [_provider setZoomEnabled:_zoomEnabled];
  }
  if (newViewProps.scrollEnabled != prevViewProps.scrollEnabled) {
    _scrollEnabled = newViewProps.scrollEnabled;
    [_provider setScrollEnabled:_scrollEnabled];
  }
  if (newViewProps.rotateEnabled != prevViewProps.rotateEnabled) {
    _rotateEnabled = newViewProps.rotateEnabled;
    [_provider setRotateEnabled:_rotateEnabled];
  }
  if (newViewProps.pitchEnabled != prevViewProps.pitchEnabled) {
    _pitchEnabled = newViewProps.pitchEnabled;
    [_provider setPitchEnabled:_pitchEnabled];
  }
  if (newViewProps.compassEnabled != prevViewProps.compassEnabled) {
    _compassEnabled = newViewProps.compassEnabled;
    [_provider setCompassEnabled:_compassEnabled];
  }
  if (newViewProps.indoorEnabled != prevViewProps.indoorEnabled) {
    _indoorEnabled = newViewProps.indoorEnabled;
    [_provider setIndoorEnabled:_indoorEnabled];
  }
  if (newViewProps.userLocationEnabled != prevViewProps.userLocationEnabled) {
    _userLocationEnabled = newViewProps.userLocationEnabled;
    [_provider setUserLocationEnabled:_userLocationEnabled];
  }
  if (newViewProps.poiEnabled != prevViewProps.poiEnabled) {
    _poiEnabled = newViewProps.poiEnabled;
    [_provider setPoiEnabled:_poiEnabled];
  }
  if (newViewProps.poiFilterMode != prevViewProps.poiFilterMode) {
    _poiFilterMode = newViewProps.poiFilterMode;
    [_provider setPoiFilterMode:_poiFilterMode];
  }
  if (newViewProps.poiFilterCategories != prevViewProps.poiFilterCategories) {
    NSMutableArray<NSString *> *categories = [NSMutableArray array];
    for (const auto &category : newViewProps.poiFilterCategories) {
      [categories addObject:[NSString stringWithUTF8String:category.c_str()]];
    }
    _poiFilterCategories = [categories copy];
    [_provider setPoiFilterCategories:_poiFilterCategories];
  }
  if (newViewProps.mapType != prevViewProps.mapType) {
    _mapType = newViewProps.mapType;
    [_provider setMapType:_mapType];
  }
  if (newViewProps.minZoom != prevViewProps.minZoom) {
    _minZoom = newViewProps.minZoom;
    [_provider setMinZoom:_minZoom];
  }
  if (newViewProps.maxZoom != prevViewProps.maxZoom) {
    _maxZoom = newViewProps.maxZoom;
    [_provider setMaxZoom:_maxZoom];
  }
  BOOL themeChanged = newViewProps.theme != prevViewProps.theme;
  if (themeChanged) {
    _theme = newViewProps.theme;
    [_provider setTheme:_theme];
  }
  if (newViewProps.idleFrameRate != prevViewProps.idleFrameRate) {
    _idleFrameRate = newViewProps.idleFrameRate;
    [_provider setIdleFrameRate:_idleFrameRate];
  }
  if (newViewProps.insetAdjustment != prevViewProps.insetAdjustment) {
    _insetAdjustment = newViewProps.insetAdjustment;
    [_provider setInsetAdjustment:_insetAdjustment];
  }

  UIEdgeInsets newEdgeInsets = UIEdgeInsetsMake(
      newViewProps.edgeInsets.top, newViewProps.edgeInsets.left,
      newViewProps.edgeInsets.bottom, newViewProps.edgeInsets.right);
  // Compare with the last prop, not _edgeInsets: the setEdgeInsets command
  // writes _edgeInsets, and unrelated prop updates carry the old edgeInsets
  if (!UIEdgeInsetsEqualToEdgeInsets(newEdgeInsets, _edgeInsetsProp)) {
    _edgeInsetsProp = newEdgeInsets;
    [self setEdgeInsets:newEdgeInsets.top
                   left:newEdgeInsets.left
                 bottom:newEdgeInsets.bottom
                  right:newEdgeInsets.right
               duration:0];
  }

  [super updateProps:props oldProps:oldProps];

  // The wrapper's style override also styles the base render (the 'system'
  // theme inherits it), so it has to follow the theme. After super so the
  // placeholder sees the new backgroundColor; the re-render is async.
  if (themeChanged && _staticMode && _mapWrapperView) {
    [self applyStaticPlaceholderBackground];
  }

  // After super so the snapshot cache key sees the new camera props
  if (staticKeyChanged && _staticMode && _mapWrapperView) {
    [self resetStaticContent];
  }
}

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  [_provider moveCamera:latitude
              longitude:longitude
                   zoom:zoom
               duration:duration];
}

- (void)fitCoordinates:(NSArray *)coordinates
         edgeInsetsTop:(double)edgeInsetsTop
        edgeInsetsLeft:(double)edgeInsetsLeft
      edgeInsetsBottom:(double)edgeInsetsBottom
       edgeInsetsRight:(double)edgeInsetsRight
              duration:(double)duration {
  [_provider fitCoordinates:coordinates
              edgeInsetsTop:edgeInsetsTop
             edgeInsetsLeft:edgeInsetsLeft
           edgeInsetsBottom:edgeInsetsBottom
            edgeInsetsRight:edgeInsetsRight
                   duration:duration];
}

- (void)setEdgeInsets:(double)top
                 left:(double)left
               bottom:(double)bottom
                right:(double)right
             duration:(double)duration {
  UIEdgeInsets oldInsets = _edgeInsets;
  _edgeInsets = UIEdgeInsetsMake(top, left, bottom, right);
  [_provider setEdgeInsets:_edgeInsets
             oldEdgeInsets:oldInsets
                  duration:duration];
}

// Loads the map again, e.g. to recover from missing tiles. A static map
// drops its cached snapshot and renders the base map again in place.
// Neither SDK can reload a live map's tiles, so the native map view is
// recreated at the current camera (coordinate and zoom; heading and pitch
// reset) with children re-added.
- (void)reload {
  if (_staticMode) {
    NSString *cacheKey = [self staticSnapshotCacheKey];
    if (cacheKey) {
      [StaticSnapshotCache() removeObjectForKey:cacheKey];
    }
    if ([_provider isKindOfClass:[StaticMapProviderBase class]]) {
      [(StaticMapProviderBase *)_provider rerenderBaseMap];
    }
    return;
  }

  if (!_provider)
    return;

  CLLocationCoordinate2D coordinate = _provider.coordinate;
  double zoom = _provider.zoom;
  // Children keep their native marker/overlay objects from the old map;
  // detach them so the new provider creates fresh ones on the flush
  [self removeChildrenFromProvider];
  [_provider destroy];
  _provider = nil;
  _initialized = NO;
  [self initializeProviderWithCoordinate:coordinate zoom:zoom];
  if ([_provider isKindOfClass:[AppleMapProvider class]]) {
    // The captured camera already includes the previous inset offset.
    [_provider moveCamera:coordinate.latitude
                longitude:coordinate.longitude
                     zoom:zoom
                 duration:0];
  }
}

- (void)removeChildrenFromProvider {
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[LuggMarkerView class]]) {
      [_provider removeMarkerView:(LuggMarkerView *)subview];
    } else if ([subview isKindOfClass:[LuggPolylineView class]]) {
      [_provider removePolylineView:(LuggPolylineView *)subview];
    } else if ([subview isKindOfClass:[LuggPolygonView class]]) {
      [_provider removePolygonView:(LuggPolygonView *)subview];
    } else if ([subview isKindOfClass:[LuggCircleView class]]) {
      [_provider removeCircleView:(LuggCircleView *)subview];
    } else if ([subview isKindOfClass:[LuggGroundOverlayView class]]) {
      [_provider removeGroundOverlayView:(LuggGroundOverlayView *)subview];
    } else if ([subview isKindOfClass:[LuggTileOverlayView class]]) {
      [_provider removeTileOverlayView:(LuggTileOverlayView *)subview];
    }
  }
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTLuggMapViewHandleCommand(self, commandName, args);
}

Class<RCTComponentViewProtocol> LuggMapViewCls(void) {
  return LuggMapView.class;
}

@end
