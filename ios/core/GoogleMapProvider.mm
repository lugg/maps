#import "GoogleMapProvider.h"

using facebook::react::LuggMapViewIdleFrameRate;
using facebook::react::LuggMapViewInsetAdjustment;
using facebook::react::LuggMapViewMapType;
using facebook::react::LuggMapViewPoiFilterMode;
using facebook::react::LuggMapViewTheme;

#import "../LuggCalloutView.h"
#import "../LuggCircleView.h"
#import "../LuggGroundOverlayView.h"
#import "../LuggMarkerView.h"
#import "../LuggPolygonView.h"
#import "../LuggPolylineView.h"
#import "../LuggTileOverlayView.h"
#import "GMSPolylineAnimator.h"
#import "MapEdgeInsets.h"
#import "MarkerPathTicker.h"
#import "PolylineAnimatorBase.h"

static NSString *const kDemoMapId = @"DEMO_MAP_ID";
static NSString *const kPathLatitudeAnimationKey = @"luggPathLatitude";
static NSString *const kPathLongitudeAnimationKey = @"luggPathLongitude";
static NSString *const kPathRotationAnimationKey = @"luggPathRotation";
// Core Animation scans every keyframe each frame, so each marker animates only
// the next minute of its path, and a timer replaces those animations twice a
// minute.
static const double kPathWindowMilliseconds = 60000;
static const NSTimeInterval kPathRefreshInterval = 30;

static float LuggFramesPerSecond(GMSFrameRate frameRate) {
  switch (frameRate) {
  case kGMSFrameRatePowerSave:
    return 15;
  case kGMSFrameRateConservative:
    return 30;
  default:
    return 0;
  }
}

GMSMapID *LuggGMSMapIDFromString(NSString *_Nullable mapId) {
  if (mapId.length == 0 || [mapId isEqualToString:kDemoMapId]) {
    return [GMSMapID demoMapID];
  }
  return [GMSMapID mapIDWithIdentifier:mapId];
}

GMSMapViewType
LuggGMSMapTypeFromMapType(facebook::react::LuggMapViewMapType mapType) {
  switch (mapType) {
  case LuggMapViewMapType::Satellite:
    return kGMSTypeSatellite;
  case LuggMapViewMapType::Terrain:
    return kGMSTypeTerrain;
  case LuggMapViewMapType::Hybrid:
    return kGMSTypeHybrid;
  default:
    return kGMSTypeNormal;
  }
}

UIUserInterfaceStyle
LuggInterfaceStyleFromTheme(facebook::react::LuggMapViewTheme theme) {
  switch (theme) {
  case LuggMapViewTheme::Dark:
    return UIUserInterfaceStyleDark;
  case LuggMapViewTheme::Light:
    return UIUserInterfaceStyleLight;
  default:
    return UIUserInterfaceStyleUnspecified;
  }
}

@interface GoogleMapProvider () <
    LuggMarkerViewDelegate, LuggCalloutViewDelegate, LuggPolylineViewDelegate,
    LuggPolygonViewDelegate, LuggCircleViewDelegate,
    LuggGroundOverlayViewDelegate, LuggTileOverlayViewDelegate>
@end

@implementation GoogleMapProvider {
  UIView *_wrapperView;
  GMSMapView *_mapView;
  BOOL _isMapReady;
  BOOL _isDragging;
  BOOL _didRenderTiles;
  LuggMapViewTheme _theme;
  UIEdgeInsets _edgeInsets;
  NSMutableArray<LuggMarkerView *> *_pendingMarkerViews;
  NSMutableArray<LuggPolylineView *> *_pendingPolylineViews;
  NSMutableArray<LuggPolygonView *> *_pendingPolygonViews;
  NSMutableArray<LuggCircleView *> *_pendingCircleViews;
  NSMutableArray<LuggGroundOverlayView *> *_pendingGroundOverlayViews;
  NSMutableArray<LuggTileOverlayView *> *_pendingTileOverlayViews;
  NSMapTable<LuggPolylineView *, GMSPolylineAnimator *> *_polylineAnimators;
  NSMapTable<GMSPolygon *, LuggPolygonView *> *_polygonToViewMap;
  NSMapTable<GMSCircle *, LuggCircleView *> *_circleToViewMap;
  NSMapTable<GMSMarker *, LuggMarkerView *> *_markerToViewMap;
  NSMapTable<GMSGroundOverlay *, LuggGroundOverlayView *>
      *_groundOverlayToViewMap;
  LuggMarkerView *_activeNonBubbledMarker;

  // Path markers and the idle frame rate
  NSMapTable<GMSMarker *, LuggMarkerPath *> *_markerPaths;
  NSHashTable<GMSMarker *> *_tickedMarkers;
  NSHashTable<GMSMarker *> *_animatedMarkers;
  NSTimer *_pathRefreshTimer;
  MarkerPathTicker *_pathTicker;
  GMSFrameRate _idleFrameRate;
  BOOL _cameraMoving;
  dispatch_block_t _pendingIdleFrameRate;

  // Edge insets animation
  CADisplayLink *_edgeInsetsDisplayLink;
  UIEdgeInsets _edgeInsetsFrom;
  UIEdgeInsets _edgeInsetsTo;
  CFTimeInterval _edgeInsetsAnimationStart;
  CFTimeInterval _edgeInsetsAnimationDuration;
}

@synthesize delegate = _delegate;
@synthesize staticMode = _staticMode;

- (instancetype)init {
  if (self = [super init]) {
    _isMapReady = NO;
    _mapId = kDemoMapId;
    _pendingMarkerViews = [NSMutableArray array];
    _pendingPolylineViews = [NSMutableArray array];
    _pendingPolygonViews = [NSMutableArray array];
    _pendingCircleViews = [NSMutableArray array];
    _pendingGroundOverlayViews = [NSMutableArray array];
    _pendingTileOverlayViews = [NSMutableArray array];
    _polylineAnimators = [NSMapTable weakToStrongObjectsMapTable];
    _polygonToViewMap = [NSMapTable strongToWeakObjectsMapTable];
    _circleToViewMap = [NSMapTable strongToWeakObjectsMapTable];
    _markerToViewMap = [NSMapTable strongToWeakObjectsMapTable];
    _groundOverlayToViewMap = [NSMapTable strongToWeakObjectsMapTable];
    _markerPaths = [NSMapTable weakToStrongObjectsMapTable];
    _tickedMarkers = [NSHashTable weakObjectsHashTable];
    _animatedMarkers = [NSHashTable weakObjectsHashTable];
    _idleFrameRate = kGMSFrameRateMaximum;
  }
  return self;
}

- (BOOL)isMapReady {
  return _isMapReady;
}

- (GMSMapView *)mapView {
  return _mapView;
}

#pragma mark - MapProvider

- (void)initializeMapInView:(UIView *)wrapperView
          initialCoordinate:(CLLocationCoordinate2D)coordinate
                initialZoom:(double)zoom {
  if (_mapView)
    return;

  GMSCameraPosition *camera =
      [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                  longitude:coordinate.longitude
                                       zoom:zoom];

  GMSMapViewOptions *options = [[GMSMapViewOptions alloc] init];
  options.frame = wrapperView.bounds;
  options.camera = camera;
  options.mapID = LuggGMSMapIDFromString(_mapId);

  _mapView = [[GMSMapView alloc] initWithOptions:options];
  _mapView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _mapView.delegate = self;
  _mapView.paddingAdjustmentBehavior =
      kGMSMapViewPaddingAdjustmentBehaviorNever;
  _mapView.preferredFrameRate = _idleFrameRate;

  _wrapperView = wrapperView;
  [wrapperView addSubview:_mapView];

  [self applyTheme];

  _isMapReady = YES;
  [self processPendingMarkers];
  [self processPendingPolylines];
  [self processPendingPolygons];
  [self processPendingCircles];
  [self processPendingGroundOverlays];
  [self processPendingTileOverlays];

  [_delegate mapProviderDidReady];
}

- (void)destroy {
  [self stopEdgeInsetsAnimation];
  if (_pendingIdleFrameRate) {
    dispatch_block_cancel(_pendingIdleFrameRate);
    _pendingIdleFrameRate = nil;
  }
  [_pathTicker stop];
  _pathTicker = nil;
  [_pathRefreshTimer invalidate];
  _pathRefreshTimer = nil;
  [_markerPaths removeAllObjects];
  [_tickedMarkers removeAllObjects];
  [_animatedMarkers removeAllObjects];
  [_pendingMarkerViews removeAllObjects];
  [_pendingPolylineViews removeAllObjects];
  [_pendingPolygonViews removeAllObjects];
  [_pendingCircleViews removeAllObjects];
  [_pendingGroundOverlayViews removeAllObjects];
  [_pendingTileOverlayViews removeAllObjects];
  [_polylineAnimators removeAllObjects];
  [_polygonToViewMap removeAllObjects];
  [_circleToViewMap removeAllObjects];
  [_markerToViewMap removeAllObjects];
  [_groundOverlayToViewMap removeAllObjects];
  [self destroyMapView];
  _isMapReady = NO;
}

- (void)destroyMapView {
  if (!_mapView)
    return;

  _mapView.delegate = nil;
  [_mapView removeFromSuperview];
  [_mapView clear];
  _mapView = nil;
}

- (CLLocationCoordinate2D)coordinate {
  return _mapView.camera.target;
}

- (double)zoom {
  return _mapView.camera.zoom;
}

#pragma mark - Props

- (void)setZoomEnabled:(BOOL)enabled {
  _mapView.settings.zoomGestures = enabled;
}

- (void)setScrollEnabled:(BOOL)enabled {
  _mapView.settings.scrollGestures = enabled;
}

- (void)setRotateEnabled:(BOOL)enabled {
  _mapView.settings.rotateGestures = enabled;
}

- (void)setPitchEnabled:(BOOL)enabled {
  _mapView.settings.tiltGestures = enabled;
}

- (void)setCompassEnabled:(BOOL)enabled {
  _mapView.settings.compassButton = enabled;
}

- (void)setUserLocationEnabled:(BOOL)enabled {
  _mapView.myLocationEnabled = enabled;
}

- (void)setInsetAdjustment:(LuggMapViewInsetAdjustment)insetAdjustment {
  _mapView.paddingAdjustmentBehavior =
      (insetAdjustment == LuggMapViewInsetAdjustment::Automatic)
          ? kGMSMapViewPaddingAdjustmentBehaviorAlways
          : kGMSMapViewPaddingAdjustmentBehaviorNever;
}

- (void)setPoiEnabled:(BOOL)enabled {
}

- (void)setPoiFilterMode:(LuggMapViewPoiFilterMode)mode {
}

- (void)setPoiFilterCategories:(NSArray<NSString *> *)categories {
}

- (void)setMapType:(LuggMapViewMapType)mapType {
  _mapView.mapType = LuggGMSMapTypeFromMapType(mapType);
}

- (void)setTheme:(LuggMapViewTheme)theme {
  _theme = theme;
  [self applyTheme];
}

- (void)applyTheme {
  _mapView.overrideUserInterfaceStyle = LuggInterfaceStyleFromTheme(_theme);
}

- (void)setIdleFrameRate:(LuggMapViewIdleFrameRate)idleFrameRate {
  switch (idleFrameRate) {
  case LuggMapViewIdleFrameRate::PowerSave:
    _idleFrameRate = kGMSFrameRatePowerSave;
    break;
  case LuggMapViewIdleFrameRate::Conservative:
    _idleFrameRate = kGMSFrameRateConservative;
    break;
  case LuggMapViewIdleFrameRate::Maximum:
    _idleFrameRate = kGMSFrameRateMaximum;
    break;
  }
  _pathTicker.framesPerSecond = LuggFramesPerSecond(_idleFrameRate);
  if (!_cameraMoving) {
    _mapView.preferredFrameRate = _idleFrameRate;
  }
}

// The map renders at full rate while the camera moves, and drops back to the
// idle rate after a short hold so a double-tap zoom and its follow-through stay
// smooth.
- (void)cameraWillMove {
  _cameraMoving = YES;
  if (_pendingIdleFrameRate) {
    dispatch_block_cancel(_pendingIdleFrameRate);
    _pendingIdleFrameRate = nil;
  }
  _mapView.preferredFrameRate = kGMSFrameRateMaximum;
}

- (void)cameraDidIdle {
  _cameraMoving = NO;
  if (_idleFrameRate == kGMSFrameRateMaximum || _edgeInsetsDisplayLink) {
    return;
  }
  if (_pendingIdleFrameRate) {
    dispatch_block_cancel(_pendingIdleFrameRate);
  }
  __weak GoogleMapProvider *weakSelf = self;
  _pendingIdleFrameRate = dispatch_block_create((dispatch_block_flags_t)0, ^{
    [weakSelf applyIdleFrameRate];
  });
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)),
      dispatch_get_main_queue(), _pendingIdleFrameRate);
}

- (void)applyIdleFrameRate {
  _pendingIdleFrameRate = nil;
  if (!_cameraMoving) {
    _mapView.preferredFrameRate = _idleFrameRate;
  }
}

- (void)setMinZoom:(double)minZoom {
  if (!_mapView)
    return;
  float min = minZoom > 0 ? (float)minZoom : _mapView.minZoom;
  [_mapView setMinZoom:min maxZoom:_mapView.maxZoom];
}

- (void)setMaxZoom:(double)maxZoom {
  if (!_mapView)
    return;
  float max = maxZoom > 0 ? (float)maxZoom : _mapView.maxZoom;
  [_mapView setMinZoom:_mapView.minZoom maxZoom:max];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets {
  [self setEdgeInsets:edgeInsets oldEdgeInsets:oldEdgeInsets duration:0];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets
             duration:(double)duration {
  if (UIEdgeInsetsEqualToEdgeInsets(_edgeInsets, edgeInsets))
    return;

  [self stopEdgeInsetsAnimation];

  if (duration != 0 && _mapView) {
    double actualDuration = duration < 0 ? 0.3 : duration / 1000.0;
    _edgeInsetsFrom = _edgeInsets;
    _edgeInsetsTo = edgeInsets;
    _edgeInsets = edgeInsets;
    _edgeInsetsAnimationDuration = actualDuration;
    _edgeInsetsAnimationStart = CACurrentMediaTime();

    _edgeInsetsDisplayLink = [CADisplayLink
        displayLinkWithTarget:self
                     selector:@selector(edgeInsetsAnimationTick:)];
    [self cameraWillMove];
    [_edgeInsetsDisplayLink addToRunLoop:[NSRunLoop mainRunLoop]
                                 forMode:NSRunLoopCommonModes];
  } else {
    _edgeInsets = edgeInsets;
    _mapView.padding = edgeInsets;
  }
}

- (void)edgeInsetsAnimationTick:(CADisplayLink *)displayLink {
  CFTimeInterval elapsed = CACurrentMediaTime() - _edgeInsetsAnimationStart;
  CGFloat progress = MIN(elapsed / _edgeInsetsAnimationDuration, 1.0);

  UIEdgeInsets current =
      LuggMapInsetsAtProgress(_edgeInsetsFrom, _edgeInsetsTo, progress);

  _mapView.padding = current;

  if (progress >= 1.0) {
    [self stopEdgeInsetsAnimation];
  }
}

- (void)stopEdgeInsetsAnimation {
  if (!_edgeInsetsDisplayLink) {
    return;
  }
  [_edgeInsetsDisplayLink invalidate];
  _edgeInsetsDisplayLink = nil;
  [self cameraDidIdle];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
  [self cameraWillMove];
  _isDragging = gesture;
  if (_isDragging) {
    for (GMSPolylineAnimator *animator in _polylineAnimators.objectEnumerator) {
      [animator pause];
    }
  }
}

- (void)mapView:(GMSMapView *)mapView
    didChangeCameraPosition:(GMSCameraPosition *)position {
  [_delegate mapProviderDidMoveCamera:position.target.latitude
                            longitude:position.target.longitude
                                 zoom:position.zoom
                              gesture:_isDragging];
  [self positionNonBubbledCallout];
}

- (void)mapView:(GMSMapView *)mapView
    idleAtCameraPosition:(GMSCameraPosition *)position {
  [self cameraDidIdle];
  BOOL wasDragging = _isDragging;
  _isDragging = NO;
  if (wasDragging) {
    for (GMSPolylineAnimator *animator in _polylineAnimators.objectEnumerator) {
      [animator resume];
    }
  }
  [_delegate mapProviderDidIdleCamera:position.target.latitude
                            longitude:position.target.longitude
                                 zoom:position.zoom
                              gesture:wasDragging];
}

// The SDK can drop marker icons set before any map in the process has finished
// rendering, as on a cold start straight into a screen with markers. Set them
// again once this map first renders.
- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView {
  if (_didRenderTiles)
    return;
  _didRenderTiles = YES;
  for (GMSMarker *marker in _markerToViewMap) {
    LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
    if (markerView) {
      [self applyMarkerStyle:markerView marker:(GMSAdvancedMarker *)marker];
    }
  }
}

- (void)mapView:(GMSMapView *)mapView
    didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
  [self dismissNonBubbledCallout];
  CGPoint point = [mapView.projection pointForCoordinate:coordinate];
  [_delegate mapProviderDidPress:coordinate.latitude
                       longitude:coordinate.longitude
                               x:point.x
                               y:point.y];
}

- (void)mapView:(GMSMapView *)mapView
    didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
  CGPoint point = [mapView.projection pointForCoordinate:coordinate];
  [_delegate mapProviderDidLongPress:coordinate.latitude
                           longitude:coordinate.longitude
                                   x:point.x
                                   y:point.y];
}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay {
  if ([overlay isKindOfClass:[GMSPolygon class]]) {
    GMSPolygon *polygon = (GMSPolygon *)overlay;
    LuggPolygonView *polygonView = [_polygonToViewMap objectForKey:polygon];
    if (polygonView && polygonView.tappable) {
      [polygonView emitPressEvent];
    }
  } else if ([overlay isKindOfClass:[GMSCircle class]]) {
    GMSCircle *circle = (GMSCircle *)overlay;
    LuggCircleView *circleView = [_circleToViewMap objectForKey:circle];
    if (circleView && circleView.tappable) {
      [circleView emitPressEvent];
    }
  } else if ([overlay isKindOfClass:[GMSGroundOverlay class]]) {
    GMSGroundOverlay *groundOverlay = (GMSGroundOverlay *)overlay;
    LuggGroundOverlayView *groundOverlayView =
        [_groundOverlayToViewMap objectForKey:groundOverlay];
    if (groundOverlayView && groundOverlayView.tappable) {
      [groundOverlayView emitPressEvent];
    }
  }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
  [self dismissNonBubbledCallout];

  LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
  if (markerView) {
    CLLocationCoordinate2D position = marker.position;
    LuggMarkerPath *path = [_markerPaths objectForKey:marker];
    if (path) {
      position = [path coordinateAt:LuggWallClockMilliseconds() rotation:NULL];
      [markerView updateCoordinate:position];
    }
    CGPoint point = [_mapView.projection pointForCoordinate:position];
    [markerView emitPressEventWithPoint:point];

    LuggCalloutView *calloutView = markerView.calloutView;
    if (calloutView && calloutView.hasCustomContent) {
      if (markerView.centerOnPress) {
        [mapView animateToLocation:position];
      }

      mapView.selectedMarker = marker;

      if (!calloutView.bubbled) {
        [self showNonBubbledCallout:markerView];
      }

      return YES;
    }

    // The SDK would center on the marker's model position, which a path
    // animation doesn't move.
    if (path && markerView.centerOnPress) {
      [mapView animateToLocation:position];
      return YES;
    }

    if (!markerView.centerOnPress) {
      mapView.selectedMarker = marker;
      return YES;
    }
  }
  return NO;
}

- (void)mapView:(GMSMapView *)mapView
    didBeginDraggingMarker:(GMSMarker *)marker {
  LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
  if (markerView) {
    [markerView updateCoordinate:marker.position];
    CGPoint point = [_mapView.projection pointForCoordinate:marker.position];
    [markerView emitDragStartEventWithPoint:point];
  }
}

- (void)mapView:(GMSMapView *)mapView didDragMarker:(GMSMarker *)marker {
  LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
  if (markerView) {
    [markerView updateCoordinate:marker.position];
    CGPoint point = [_mapView.projection pointForCoordinate:marker.position];
    [markerView emitDragChangeEventWithPoint:point];
  }
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(GMSMarker *)marker {
  LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
  if (markerView) {
    [markerView updateCoordinate:marker.position];
    CGPoint point = [_mapView.projection pointForCoordinate:marker.position];
    [markerView emitDragEndEventWithPoint:point];
  }
}

- (UIView *)rasterizedCalloutView:(LuggCalloutView *)calloutView {
  UIView *contentView = calloutView.contentView;
  [contentView layoutIfNeeded];

  CGSize size = contentView.bounds.size;
  if (size.width <= 0 || size.height <= 0)
    return nil;

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat defaultFormat];
  format.scale = [UIScreen mainScreen].scale;
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
  UIImage *image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [contentView.layer renderInContext:context.CGContext];
      }];

  return [[UIImageView alloc] initWithImage:image];
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
  // Non-bubbled callouts are rendered as live views, not info windows
  return nil;
}

- (UIView *)mapView:(GMSMapView *)mapView
    markerInfoContents:(GMSMarker *)marker {
  LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
  if (!markerView || !markerView.calloutView ||
      !markerView.calloutView.hasCustomContent)
    return nil;

  if (markerView.calloutView.bubbled) {
    return [self rasterizedCalloutView:markerView.calloutView];
  }

  return nil;
}

- (void)showNonBubbledCallout:(LuggMarkerView *)markerView {
  [self dismissNonBubbledCallout];
  _mapView.selectedMarker = nil;

  LuggCalloutView *calloutView = markerView.calloutView;
  UIView *contentView = calloutView.contentView;
  [contentView removeFromSuperview];

  contentView.userInteractionEnabled = YES;
  contentView.hidden = YES;
  calloutView.delegate = self;
  [_wrapperView addSubview:contentView];

  _activeNonBubbledMarker = markerView;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self positionNonBubbledCallout];
    contentView.hidden = NO;
  });
}

- (void)calloutViewDidUpdate:(LuggCalloutView *)calloutView {
  [self positionNonBubbledCallout];
}

- (void)dismissNonBubbledCallout {
  if (!_activeNonBubbledMarker)
    return;

  LuggCalloutView *calloutView = _activeNonBubbledMarker.calloutView;
  calloutView.delegate = nil;
  [calloutView.contentView removeFromSuperview];
  _activeNonBubbledMarker = nil;
}

- (void)positionNonBubbledCallout {
  if (!_activeNonBubbledMarker)
    return;

  LuggCalloutView *calloutView = _activeNonBubbledMarker.calloutView;
  UIView *contentView = calloutView.contentView;
  CGSize contentSize = contentView.bounds.size;
  if (contentSize.width <= 0 || contentSize.height <= 0)
    return;

  CGPoint offset = calloutView.offset;
  CGPoint point = [_mapView.projection
      pointForCoordinate:_activeNonBubbledMarker.coordinate];

  UIView *iconView = _activeNonBubbledMarker.iconView;
  CGFloat markerHeight =
      iconView.bounds.size.height * _activeNonBubbledMarker.scale;

  contentView.center =
      CGPointMake(point.x + offset.x,
                  point.y - markerHeight * _activeNonBubbledMarker.anchor.y -
                      contentSize.height / 2.0 + offset.y);
}

- (void)showCalloutForMarkerView:(LuggMarkerView *)markerView {
  LuggCalloutView *calloutView = markerView.calloutView;
  if (calloutView && calloutView.hasCustomContent) {
    [self dismissNonBubbledCallout];
    GMSMarker *marker = (GMSMarker *)markerView.marker;
    if (calloutView.bubbled) {
      _mapView.selectedMarker = marker;
    } else {
      [self showNonBubbledCallout:markerView];
    }
    return;
  }

  if (markerView.title.length > 0) {
    _mapView.selectedMarker = (GMSMarker *)markerView.marker;
  }
}

- (void)hideCalloutForMarkerView:(LuggMarkerView *)markerView {
  [self dismissNonBubbledCallout];
  if (_mapView.selectedMarker == markerView.marker) {
    _mapView.selectedMarker = nil;
  }
}

#pragma mark - MarkerViewDelegate

- (void)markerViewDidLayout:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView];
}

- (void)markerViewDidUpdate:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView restyle:markerView.styleChanged];
}

#pragma mark - PolylineViewDelegate

- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView {
  [self syncPolylineView:polylineView];
}

#pragma mark - PolygonViewDelegate

- (void)polygonViewDidUpdate:(LuggPolygonView *)polygonView {
  [self syncPolygonView:polygonView];
}

#pragma mark - CircleViewDelegate

- (void)circleViewDidUpdate:(LuggCircleView *)circleView {
  [self syncCircleView:circleView];
}

#pragma mark - GroundOverlayViewDelegate

- (void)groundOverlayViewDidUpdate:(LuggGroundOverlayView *)groundOverlayView {
  [self syncGroundOverlayView:groundOverlayView];
}

#pragma mark - TileOverlayViewDelegate

- (void)tileOverlayViewDidUpdate:(LuggTileOverlayView *)tileOverlayView {
  [self syncTileOverlayView:tileOverlayView];
}

#pragma mark - Marker Management

- (void)addMarkerView:(LuggMarkerView *)markerView {
  markerView.delegate = self;
  [self syncMarkerView:markerView];
}

- (void)removeMarkerView:(LuggMarkerView *)markerView {
  GMSAdvancedMarker *marker = (GMSAdvancedMarker *)markerView.marker;
  if (marker) {
    [_markerToViewMap removeObjectForKey:marker];
    [_markerPaths removeObjectForKey:marker];
    [_tickedMarkers removeObject:marker];
    [_animatedMarkers removeObject:marker];
    [self updatePathTicker];
    marker.iconView = nil;
    marker.map = nil;
    markerView.marker = nil;
  }
  [markerView resetIconViewTransform];
}

- (void)syncMarkerView:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView restyle:YES];
}

- (void)syncMarkerView:(LuggMarkerView *)markerView restyle:(BOOL)restyle {
  if (!_mapView) {
    if (![_pendingMarkerViews containsObject:markerView]) {
      [_pendingMarkerViews addObject:markerView];
    }
    return;
  }

  if (!markerView.marker) {
    [self addMarkerViewToMap:markerView];
    return;
  }

  // The SDK does work (and logs) for every setter call, so only changed values
  // are set
  GMSAdvancedMarker *marker = (GMSAdvancedMarker *)markerView.marker;
  CLLocationCoordinate2D coordinate = markerView.coordinate;
  if (!markerView.path && (coordinate.latitude != marker.position.latitude ||
                           coordinate.longitude != marker.position.longitude)) {
    marker.position = coordinate;
  }
  NSString *title = markerView.title.length > 0 ? markerView.title : nil;
  if (title != marker.title && ![title isEqualToString:marker.title]) {
    marker.title = title;
  }
  NSString *snippet = markerView.markerDescription.length > 0
                          ? markerView.markerDescription
                          : nil;
  if (snippet != marker.snippet && ![snippet isEqualToString:marker.snippet]) {
    marker.snippet = snippet;
  }
  if (marker.zIndex != (int)markerView.zIndex) {
    marker.zIndex = (int)markerView.zIndex;
  }
  if (marker.draggable != markerView.draggable) {
    marker.draggable = markerView.draggable;
  }
  // Restyling re-rasterizes the icon, so position and rotation updates skip it
  if (restyle) {
    [self applyMarkerStyle:markerView marker:marker];
  } else {
    [self applyMarkerRotation:markerView marker:marker];
  }
  [self applyPathForMarkerView:markerView marker:marker];
}

- (void)processPendingMarkers {
  if (!_mapView)
    return;

  for (LuggMarkerView *markerView in _pendingMarkerViews) {
    [self addMarkerViewToMap:markerView];
  }
  [_pendingMarkerViews removeAllObjects];
}

- (void)addMarkerViewToMap:(LuggMarkerView *)markerView {
  if (!_mapView)
    return;

  // Custom icons rasterize from layout; adding before that shows the SDK's
  // default pin until markerViewDidLayout re-syncs.
  if (markerView.hasCustomView && !markerView.didLayout)
    return;

  GMSAdvancedMarker *marker = [[GMSAdvancedMarker alloc] init];
  marker.position = markerView.coordinate;
  marker.title = markerView.title.length > 0 ? markerView.title : nil;
  marker.snippet = markerView.markerDescription.length > 0
                       ? markerView.markerDescription
                       : nil;
  marker.zIndex = (int)markerView.zIndex;
  marker.draggable = markerView.draggable;

  [self applyMarkerStyle:markerView marker:marker];

  marker.map = _mapView;
  markerView.marker = marker;
  [_markerToViewMap setObject:markerView forKey:marker];
  [self applyPathForMarkerView:markerView marker:marker];
}

- (void)applyMarkerStyle:(LuggMarkerView *)markerView
                  marker:(GMSAdvancedMarker *)marker {
  if (markerView.hasCustomView) {
    if (markerView.rasterize) {
      marker.iconView = nil;
      marker.icon = [markerView createScaledIconImage];
    } else {
      UIView *iconView = markerView.iconView;
      if (marker.iconView != iconView) {
        [iconView removeFromSuperview];
        marker.iconView = iconView;
      }
    }
    marker.groundAnchor = markerView.anchor;
  } else {
    marker.iconView = nil;
    marker.icon = nil;
    marker.groundAnchor = CGPointMake(0.5, 1);
  }
  [self applyMarkerRotation:markerView marker:marker];
}

// Live icon views rotate (and scale) in their transform; the rest rotate the
// marker. A path with rotations rotates image markers itself.
- (void)applyMarkerRotation:(LuggMarkerView *)markerView
                     marker:(GMSAdvancedMarker *)marker {
  if (markerView.hasCustomView && !markerView.rasterize) {
    CLLocationDegrees rotation = markerView.rotate;
    [markerView.path coordinateAt:LuggWallClockMilliseconds()
                         rotation:&rotation];
    [self applyIconViewTransform:markerView rotation:rotation];
    if (marker.rotation != 0) {
      marker.rotation = 0;
    }
  } else if (!markerView.path.rotations &&
             marker.rotation != markerView.rotate) {
    marker.rotation = markerView.rotate;
  }
}

- (void)applyIconViewTransform:(LuggMarkerView *)markerView
                      rotation:(CLLocationDegrees)rotation {
  CGFloat scale = markerView.scale;
  markerView.iconView.transform = CGAffineTransformConcat(
      CGAffineTransformMakeScale(scale, scale),
      CGAffineTransformMakeRotation(rotation * M_PI / 180.0));
}

#pragma mark - Path markers

// Markers with an image follow their path with Core Animation on the marker
// layer, so the map moves them on its own frames. Icon-view markers ignore
// those animations, so the ticker moves them.
- (void)applyPathForMarkerView:(LuggMarkerView *)markerView
                        marker:(GMSMarker *)marker {
  LuggMarkerPath *path = markerView.path;
  BOOL ticked = path && marker.iconView;
  if ([_markerPaths objectForKey:marker] == path &&
      [_tickedMarkers containsObject:marker] == ticked) {
    return;
  }

  [marker.layer removeAnimationForKey:kPathLatitudeAnimationKey];
  [marker.layer removeAnimationForKey:kPathLongitudeAnimationKey];
  [marker.layer removeAnimationForKey:kPathRotationAnimationKey];
  [_tickedMarkers removeObject:marker];
  [_animatedMarkers removeObject:marker];

  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  if (path) {
    [_markerPaths setObject:path forKey:marker];
    double now = LuggWallClockMilliseconds();
    CLLocationDegrees rotation = markerView.rotate;
    marker.position = [path coordinateAt:now rotation:&rotation];
    if (ticked) {
      [_tickedMarkers addObject:marker];
    } else {
      if (path.rotations) {
        marker.rotation = rotation;
      }
      [_animatedMarkers addObject:marker];
      [self animateMarker:marker alongPath:path now:now];
    }
  } else {
    [_markerPaths removeObjectForKey:marker];
    marker.position = markerView.coordinate;
  }
  [CATransaction commit];
  [self updatePathTicker];
}

- (void)animateMarker:(GMSMarker *)marker
            alongPath:(LuggMarkerPath *)path
                  now:(double)now {
  if (path.duration <= 0) {
    return;
  }
  NSMutableArray<NSNumber *> *keyTimes = [NSMutableArray array];
  NSMutableArray<NSNumber *> *latitudes = [NSMutableArray array];
  NSMutableArray<NSNumber *> *longitudes = [NSMutableArray array];
  NSMutableArray<NSNumber *> *rotations = [NSMutableArray array];
  void (^add)(double, CLLocationCoordinate2D, CLLocationDegrees) =
      ^(double at, CLLocationCoordinate2D coordinate,
        CLLocationDegrees rotation) {
        [keyTimes addObject:@((at - now) / kPathWindowMilliseconds)];
        [latitudes addObject:@(coordinate.latitude)];
        [longitudes addObject:@(coordinate.longitude)];
        [rotations addObject:@(rotation)];
      };

  // Where the marker is now, the keyframes in the next minute (unrolling laps
  // when the path loops), and where it is at the end of that minute.
  CLLocationDegrees rotation = 0;
  add(now, [path coordinateAt:now rotation:&rotation], rotation);
  double end = now + kPathWindowMilliseconds;
  double lapStart = path.loop ? now - [path progressAt:now] : path.startTime;
  for (; lapStart < end; lapStart += path.duration) {
    for (NSUInteger i = 0; i < path.count; i++) {
      double at = lapStart + path.times[i];
      if (at > now && at < end) {
        add(at, path.coordinates[i], path.rotations ? path.rotations[i] : 0);
      }
    }
    if (!path.loop) {
      break;
    }
  }
  CLLocationDegrees endRotation = rotation;
  CLLocationCoordinate2D endCoordinate = [path coordinateAt:end
                                                   rotation:&endRotation];
  if (path.loop && path.rotations) {
    // coordinateAt: unwraps rotations within a lap; continue from the last
    // keyframe instead.
    CLLocationDegrees previous = rotations.lastObject.doubleValue;
    endRotation =
        previous + fmod(fmod(endRotation - previous, 360) + 540, 360) - 180;
  }
  add(end, endCoordinate, endRotation);

  CFTimeInterval beginTime = [marker.layer convertTime:CACurrentMediaTime()
                                             fromLayer:nil];
  void (^animate)(NSString *, NSArray *, NSString *) =
      ^(NSString *keyPath, NSArray *values, NSString *key) {
        CAKeyframeAnimation *animation =
            [CAKeyframeAnimation animationWithKeyPath:keyPath];
        animation.values = values;
        animation.keyTimes = keyTimes;
        animation.calculationMode = kCAAnimationLinear;
        animation.duration = kPathWindowMilliseconds / 1000;
        animation.beginTime = beginTime;
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        [marker.layer addAnimation:animation forKey:key];
      };
  animate(kGMSMarkerLayerLatitude, latitudes, kPathLatitudeAnimationKey);
  animate(kGMSMarkerLayerLongitude, longitudes, kPathLongitudeAnimationKey);
  if (path.rotations) {
    animate(kGMSMarkerLayerRotation, rotations, kPathRotationAnimationKey);
  }
}

- (void)refreshPathAnimations {
  double now = LuggWallClockMilliseconds();
  for (GMSMarker *marker in _animatedMarkers) {
    LuggMarkerPath *path = [_markerPaths objectForKey:marker];
    if (path) {
      [self animateMarker:marker alongPath:path now:now];
    }
  }
}

- (void)updatePathTicker {
  if (_animatedMarkers.count == 0) {
    [_pathRefreshTimer invalidate];
    _pathRefreshTimer = nil;
  } else if (!_pathRefreshTimer) {
    __weak GoogleMapProvider *weakSelf = self;
    _pathRefreshTimer =
        [NSTimer timerWithTimeInterval:kPathRefreshInterval
                               repeats:YES
                                 block:^(NSTimer *timer) {
                                   [weakSelf refreshPathAnimations];
                                 }];
    [[NSRunLoop mainRunLoop] addTimer:_pathRefreshTimer
                              forMode:NSRunLoopCommonModes];
  }

  if (_tickedMarkers.count == 0) {
    [_pathTicker stop];
    return;
  }
  if (!_pathTicker) {
    __weak GoogleMapProvider *weakSelf = self;
    _pathTicker = [[MarkerPathTicker alloc] initWithTick:^{
      [weakSelf tickPathMarkers];
    }];
  }
  _pathTicker.framesPerSecond = LuggFramesPerSecond(_idleFrameRate);
  [_pathTicker start];
}

- (void)tickPathMarkers {
  double now = LuggWallClockMilliseconds();
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  for (GMSMarker *marker in _tickedMarkers) {
    LuggMarkerView *markerView = [_markerToViewMap objectForKey:marker];
    LuggMarkerPath *path = markerView.path;
    if (!path) {
      continue;
    }
    CLLocationDegrees rotation = markerView.rotate;
    CLLocationCoordinate2D position = [path coordinateAt:now
                                                rotation:&rotation];
    if (position.latitude != marker.position.latitude ||
        position.longitude != marker.position.longitude) {
      marker.position = position;
    }
    if (path.rotations) {
      [self applyIconViewTransform:markerView rotation:rotation];
    }
  }
  [CATransaction commit];
}

#pragma mark - Polyline Management

- (void)addPolylineView:(LuggPolylineView *)polylineView {
  polylineView.delegate = self;
  [self syncPolylineView:polylineView];
}

- (void)removePolylineView:(LuggPolylineView *)polylineView {
  [_polylineAnimators removeObjectForKey:polylineView];
  GMSPolyline *polyline = (GMSPolyline *)polylineView.polyline;
  if (polyline) {
    polyline.map = nil;
    polylineView.polyline = nil;
  }
}

- (void)syncPolylineView:(LuggPolylineView *)polylineView {
  if (!_mapView) {
    if (![_pendingPolylineViews containsObject:polylineView]) {
      [_pendingPolylineViews addObject:polylineView];
    }
    return;
  }

  if (!polylineView.polyline) {
    [self addPolylineViewToMap:polylineView];
    return;
  }

  GMSPolyline *polyline = (GMSPolyline *)polylineView.polyline;
  polyline.strokeWidth = polylineView.strokeWidth;
  polyline.zIndex = (int)polylineView.zIndex;

  GMSPolylineAnimator *animator =
      [_polylineAnimators objectForKey:polylineView];
  if (animator) {
    animator.coordinates = polylineView.coordinates;
    animator.strokeColors = polylineView.strokeColors;
    animator.animatedOptions = polylineView.animatedOptions;
    animator.animated = polylineView.animated;
    [animator update];
  }
}

- (void)processPendingPolylines {
  if (!_mapView)
    return;

  for (LuggPolylineView *polylineView in _pendingPolylineViews) {
    [self addPolylineViewToMap:polylineView];
  }
  [_pendingPolylineViews removeAllObjects];
}

- (void)addPolylineViewToMap:(LuggPolylineView *)polylineView {
  if (!_mapView)
    return;

  GMSPolyline *polyline = [GMSPolyline polylineWithPath:[GMSMutablePath path]];
  polyline.strokeWidth = polylineView.strokeWidth;
  polyline.zIndex = (int)polylineView.zIndex;
  polyline.map = _mapView;
  polylineView.polyline = polyline;

  GMSPolylineAnimator *animator = [[GMSPolylineAnimator alloc] init];
  animator.polyline = polyline;
  animator.coordinates = polylineView.coordinates;
  animator.strokeColors = polylineView.strokeColors;
  animator.animatedOptions = polylineView.animatedOptions;
  animator.animated = polylineView.animated;
  [animator update];

  [_polylineAnimators setObject:animator forKey:polylineView];
}

#pragma mark - Polygon Management

- (void)addPolygonView:(LuggPolygonView *)polygonView {
  polygonView.delegate = self;
  [self syncPolygonView:polygonView];
}

- (void)removePolygonView:(LuggPolygonView *)polygonView {
  GMSPolygon *polygon = (GMSPolygon *)polygonView.polygon;
  if (polygon) {
    [_polygonToViewMap removeObjectForKey:polygon];
    polygon.map = nil;
    polygonView.polygon = nil;
  }
}

- (void)syncPolygonView:(LuggPolygonView *)polygonView {
  if (!_mapView) {
    if (![_pendingPolygonViews containsObject:polygonView]) {
      [_pendingPolygonViews addObject:polygonView];
    }
    return;
  }

  if (!polygonView.polygon) {
    [self addPolygonViewToMap:polygonView];
    return;
  }

  GMSPolygon *polygon = (GMSPolygon *)polygonView.polygon;

  GMSMutablePath *path = [GMSMutablePath path];
  for (CLLocation *location in polygonView.coordinates) {
    [path addCoordinate:location.coordinate];
  }
  polygon.path = path;
  polygon.holes = [self holesPathsFromPolygonView:polygonView];
  polygon.fillColor = polygonView.fillColor;
  polygon.strokeColor = polygonView.strokeColor;
  polygon.strokeWidth = polygonView.strokeWidth;
  polygon.zIndex = (int)polygonView.zIndex;
  polygon.tappable = polygonView.tappable;
}

- (NSArray<GMSPath *> *)holesPathsFromPolygonView:
    (LuggPolygonView *)polygonView {
  NSMutableArray<GMSPath *> *holePaths = [NSMutableArray array];
  for (NSArray<CLLocation *> *hole in polygonView.holes) {
    GMSMutablePath *holePath = [GMSMutablePath path];
    for (CLLocation *location in hole) {
      [holePath addCoordinate:location.coordinate];
    }
    [holePaths addObject:holePath];
  }
  return [holePaths copy];
}

- (void)processPendingPolygons {
  if (!_mapView)
    return;

  for (LuggPolygonView *polygonView in _pendingPolygonViews) {
    [self addPolygonViewToMap:polygonView];
  }
  [_pendingPolygonViews removeAllObjects];
}

- (void)addPolygonViewToMap:(LuggPolygonView *)polygonView {
  if (!_mapView)
    return;

  GMSMutablePath *path = [GMSMutablePath path];
  for (CLLocation *location in polygonView.coordinates) {
    [path addCoordinate:location.coordinate];
  }

  GMSPolygon *polygon = [GMSPolygon polygonWithPath:path];
  polygon.holes = [self holesPathsFromPolygonView:polygonView];
  polygon.fillColor = polygonView.fillColor;
  polygon.strokeColor = polygonView.strokeColor;
  polygon.strokeWidth = polygonView.strokeWidth;
  polygon.zIndex = (int)polygonView.zIndex;
  polygon.tappable = polygonView.tappable;
  polygon.map = _mapView;
  polygonView.polygon = polygon;
  [_polygonToViewMap setObject:polygonView forKey:polygon];
}

#pragma mark - Circle Management

- (void)addCircleView:(LuggCircleView *)circleView {
  circleView.delegate = self;
  [self syncCircleView:circleView];
}

- (void)removeCircleView:(LuggCircleView *)circleView {
  GMSCircle *circle = (GMSCircle *)circleView.circle;
  if (circle) {
    [_circleToViewMap removeObjectForKey:circle];
    circle.map = nil;
    circleView.circle = nil;
  }
}

- (void)syncCircleView:(LuggCircleView *)circleView {
  if (!_mapView) {
    if (![_pendingCircleViews containsObject:circleView]) {
      [_pendingCircleViews addObject:circleView];
    }
    return;
  }

  if (!circleView.circle) {
    [self addCircleViewToMap:circleView];
    return;
  }

  GMSCircle *circle = (GMSCircle *)circleView.circle;
  circle.position = circleView.center;
  circle.radius = circleView.radius;
  circle.fillColor = circleView.fillColor;
  circle.strokeColor = circleView.strokeColor;
  circle.strokeWidth = circleView.strokeWidth;
  circle.zIndex = (int)circleView.zIndex;
  circle.tappable = circleView.tappable;
}

- (void)processPendingCircles {
  if (!_mapView)
    return;

  for (LuggCircleView *circleView in _pendingCircleViews) {
    [self addCircleViewToMap:circleView];
  }
  [_pendingCircleViews removeAllObjects];
}

- (void)addCircleViewToMap:(LuggCircleView *)circleView {
  if (!_mapView)
    return;

  GMSCircle *circle = [GMSCircle circleWithPosition:circleView.center
                                             radius:circleView.radius];
  circle.fillColor = circleView.fillColor;
  circle.strokeColor = circleView.strokeColor;
  circle.strokeWidth = circleView.strokeWidth;
  circle.zIndex = (int)circleView.zIndex;
  circle.tappable = circleView.tappable;
  circle.map = _mapView;
  circleView.circle = circle;
  [_circleToViewMap setObject:circleView forKey:circle];
}

#pragma mark - Ground Overlay Management

- (void)addGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  groundOverlayView.delegate = self;
  [self syncGroundOverlayView:groundOverlayView];
}

- (void)removeGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  groundOverlayView.delegate = nil;
  GMSGroundOverlay *overlay = (GMSGroundOverlay *)groundOverlayView.overlay;
  if (overlay) {
    [_groundOverlayToViewMap removeObjectForKey:overlay];
    overlay.map = nil;
    groundOverlayView.overlay = nil;
  }
}

- (void)syncGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  if (!_mapView) {
    if (![_pendingGroundOverlayViews containsObject:groundOverlayView]) {
      [_pendingGroundOverlayViews addObject:groundOverlayView];
    }
    return;
  }

  NSString *imageUri = groundOverlayView.imageUri;
  if (imageUri.length == 0)
    return;

  // Remove old overlay
  GMSGroundOverlay *oldOverlay = (GMSGroundOverlay *)groundOverlayView.overlay;
  if (oldOverlay) {
    [_groundOverlayToViewMap removeObjectForKey:oldOverlay];
    oldOverlay.map = nil;
    groundOverlayView.overlay = nil;
  }

  // Load image and create overlay
  NSURL *url = [NSURL URLWithString:imageUri];
  if (!url)
    return;

  __weak __typeof(self) weakSelf = self;
  __weak LuggGroundOverlayView *weakOverlayView = groundOverlayView;
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf addGroundOverlayToMap:weakOverlayView image:image];
        });
      });
}

- (void)addGroundOverlayToMap:(LuggGroundOverlayView *)groundOverlayView
                        image:(UIImage *)image {
  if (!_mapView || !groundOverlayView || !image)
    return;

  GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc]
      initWithCoordinate:groundOverlayView.southwest
              coordinate:groundOverlayView.northeast];

  GMSGroundOverlay *overlay = [GMSGroundOverlay groundOverlayWithBounds:bounds
                                                                   icon:image];
  overlay.opacity = groundOverlayView.opacity;
  overlay.bearing = groundOverlayView.bearing;
  overlay.zIndex = (int)groundOverlayView.zIndex;
  overlay.tappable = groundOverlayView.tappable;
  overlay.map = _mapView;

  groundOverlayView.overlay = overlay;
  [_groundOverlayToViewMap setObject:groundOverlayView forKey:overlay];
}

- (void)processPendingGroundOverlays {
  if (!_mapView)
    return;

  for (LuggGroundOverlayView *view in _pendingGroundOverlayViews) {
    [self syncGroundOverlayView:view];
  }
  [_pendingGroundOverlayViews removeAllObjects];
}

#pragma mark - Tile Overlay Management

- (void)addTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
  tileOverlayView.delegate = self;
  [self syncTileOverlayView:tileOverlayView];
}

- (void)removeTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
  tileOverlayView.delegate = nil;
  GMSTileLayer *tileLayer = (GMSTileLayer *)tileOverlayView.overlay;
  if (tileLayer) {
    tileLayer.map = nil;
    tileOverlayView.overlay = nil;
  }
}

- (void)syncTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
  if (!_mapView) {
    if (![_pendingTileOverlayViews containsObject:tileOverlayView]) {
      [_pendingTileOverlayViews addObject:tileOverlayView];
    }
    return;
  }

  NSString *urlTemplate = tileOverlayView.urlTemplate;
  if (urlTemplate.length == 0)
    return;

  // Remove old tile layer
  GMSTileLayer *oldLayer = (GMSTileLayer *)tileOverlayView.overlay;
  if (oldLayer) {
    oldLayer.map = nil;
    tileOverlayView.overlay = nil;
  }

  BOOL hasBounds = tileOverlayView.hasBounds;
  CLLocationCoordinate2D sw = tileOverlayView.southwest;
  CLLocationCoordinate2D ne = tileOverlayView.northeast;

  GMSTileURLConstructor constructor = ^NSURL *(NSUInteger x, NSUInteger y,
                                               NSUInteger zoom) {
    if (hasBounds) {
      double n = pow(2.0, zoom);
      double tileSW_lat =
          180.0 / M_PI * atan(sinh(M_PI * (1 - 2.0 * (y + 1) / n)));
      double tileNE_lat = 180.0 / M_PI * atan(sinh(M_PI * (1 - 2.0 * y / n)));
      double tileSW_lng = x / n * 360.0 - 180.0;
      double tileNE_lng = (x + 1) / n * 360.0 - 180.0;

      if (tileNE_lat < sw.latitude || tileSW_lat > ne.latitude ||
          tileNE_lng < sw.longitude || tileSW_lng > ne.longitude) {
        return nil;
      }
    }

    NSString *urlString =
        [urlTemplate stringByReplacingOccurrencesOfString:@"{x}"
                                               withString:[@(x) stringValue]];
    urlString =
        [urlString stringByReplacingOccurrencesOfString:@"{y}"
                                             withString:[@(y) stringValue]];
    urlString =
        [urlString stringByReplacingOccurrencesOfString:@"{z}"
                                             withString:[@(zoom) stringValue]];
    return [NSURL URLWithString:urlString];
  };

  GMSURLTileLayer *tileLayer =
      [GMSURLTileLayer tileLayerWithURLConstructor:constructor];
  tileLayer.tileSize = tileOverlayView.tileSize;
  tileLayer.opacity = tileOverlayView.opacity;
  tileLayer.zIndex = (int)tileOverlayView.zIndex;
  tileLayer.map = _mapView;

  tileOverlayView.overlay = tileLayer;
}

- (void)processPendingTileOverlays {
  if (!_mapView)
    return;

  for (LuggTileOverlayView *view in _pendingTileOverlayViews) {
    [self syncTileOverlayView:view];
  }
  [_pendingTileOverlayViews removeAllObjects];
}

#pragma mark - Lifecycle

- (void)pauseAnimations {
  for (GMSPolylineAnimator *animator in _polylineAnimators.objectEnumerator) {
    [animator pause];
  }
  _pathTicker.paused = YES;
}

- (void)resumeAnimations {
  for (GMSPolylineAnimator *animator in _polylineAnimators.objectEnumerator) {
    [animator resume];
  }
  _pathTicker.paused = NO;
  // Windows that ran out in the background would hold their last position.
  [self refreshPathAnimations];
}

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  if (!_mapView)
    return;

  float targetZoom = zoom > 0 ? (float)zoom : _mapView.camera.zoom;
  GMSCameraPosition *camera = [GMSCameraPosition
      cameraWithTarget:CLLocationCoordinate2DMake(latitude, longitude)
                  zoom:targetZoom
               bearing:_mapView.camera.bearing
          viewingAngle:_mapView.camera.viewingAngle];
  if (duration < 0) {
    [_mapView animateToCameraPosition:camera];
  } else if (duration > 0) {
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration / 1000.0];
    [_mapView animateToCameraPosition:camera];
    [CATransaction commit];
  } else {
    [_mapView setCamera:camera];
  }
}

- (void)fitCoordinates:(NSArray *)coordinates
         edgeInsetsTop:(double)edgeInsetsTop
        edgeInsetsLeft:(double)edgeInsetsLeft
      edgeInsetsBottom:(double)edgeInsetsBottom
       edgeInsetsRight:(double)edgeInsetsRight
              duration:(double)duration {
  if (!_mapView || coordinates.count == 0)
    return;

  GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
  for (NSDictionary *coord in coordinates) {
    double lat = [coord[@"latitude"] doubleValue];
    double lng = [coord[@"longitude"] doubleValue];
    bounds = [bounds includingCoordinate:CLLocationCoordinate2DMake(lat, lng)];
  }

  UIEdgeInsets insets = UIEdgeInsetsMake(edgeInsetsTop, edgeInsetsLeft,
                                         edgeInsetsBottom, edgeInsetsRight);

  // An inset animation may still be moving the padding toward _edgeInsets.
  // Fit against the padding it ends at: the camera target stays centered in
  // the padding while the animation finishes.
  UIEdgeInsets padding = _mapView.padding;
  _mapView.padding = _edgeInsets;
  GMSCameraPosition *camera = [_mapView cameraForBounds:bounds insets:insets];
  _mapView.padding = padding;
  if (!camera)
    return;

  if (duration < 0) {
    [_mapView animateToCameraPosition:camera];
  } else if (duration > 0) {
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration / 1000.0];
    [_mapView animateToCameraPosition:camera];
    [CATransaction commit];
  } else {
    [_mapView setCamera:camera];
  }
}

@end
