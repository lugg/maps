#import "GoogleMapProvider.h"
#import "../LuggCalloutView.h"
#import "../LuggCircleView.h"
#import "../LuggGroundOverlayView.h"
#import "../LuggMarkerView.h"
#import "../LuggPolygonView.h"
#import "../LuggPolylineView.h"
#import "../LuggTileOverlayView.h"
#import "GMSPolylineAnimator.h"
#import "PolylineAnimatorBase.h"

static NSString *const kDemoMapId = @"DEMO_MAP_ID";

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
  NSInteger _theme;
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

  // Edge insets animation
  CADisplayLink *_edgeInsetsDisplayLink;
  UIEdgeInsets _edgeInsetsFrom;
  UIEdgeInsets _edgeInsetsTo;
  CFTimeInterval _edgeInsetsAnimationStart;
  CFTimeInterval _edgeInsetsAnimationDuration;
}

@synthesize delegate = _delegate;

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

  GMSMapID *gmsMapId;
  if ([_mapId isEqualToString:kDemoMapId] || _mapId.length == 0) {
    gmsMapId = [GMSMapID demoMapID];
  } else {
    gmsMapId = [GMSMapID mapIDWithIdentifier:_mapId];
  }

  GMSCameraPosition *camera =
      [GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                  longitude:coordinate.longitude
                                       zoom:zoom];

  GMSMapViewOptions *options = [[GMSMapViewOptions alloc] init];
  options.frame = wrapperView.bounds;
  options.camera = camera;
  options.mapID = gmsMapId;

  _mapView = [[GMSMapView alloc] initWithOptions:options];
  _mapView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _mapView.delegate = self;
  _mapView.paddingAdjustmentBehavior =
      kGMSMapViewPaddingAdjustmentBehaviorNever;

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
  [_mapView clear];
  [_mapView removeFromSuperview];
  _mapView = nil;
  _isMapReady = NO;
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

- (void)setUserLocationEnabled:(BOOL)enabled {
  _mapView.myLocationEnabled = enabled;
}

- (void)setTheme:(NSInteger)theme {
  _theme = theme;
  [self applyTheme];
}

- (void)applyTheme {
  if (!_mapView)
    return;

  switch (_theme) {
  case 1: // Dark
    _mapView.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    break;
  case 0: // Light
    _mapView.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    break;
  default: // System
    _mapView.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    break;
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

  // Ease out cubic
  CGFloat t = 1.0 - (1.0 - progress) * (1.0 - progress) * (1.0 - progress);

  UIEdgeInsets current = UIEdgeInsetsMake(
      _edgeInsetsFrom.top + (_edgeInsetsTo.top - _edgeInsetsFrom.top) * t,
      _edgeInsetsFrom.left + (_edgeInsetsTo.left - _edgeInsetsFrom.left) * t,
      _edgeInsetsFrom.bottom +
          (_edgeInsetsTo.bottom - _edgeInsetsFrom.bottom) * t,
      _edgeInsetsFrom.right +
          (_edgeInsetsTo.right - _edgeInsetsFrom.right) * t);

  _mapView.padding = current;

  if (progress >= 1.0) {
    [self stopEdgeInsetsAnimation];
  }
}

- (void)stopEdgeInsetsAnimation {
  [_edgeInsetsDisplayLink invalidate];
  _edgeInsetsDisplayLink = nil;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
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
    CGPoint point = [_mapView.projection pointForCoordinate:marker.position];
    [markerView emitPressEventWithPoint:point];

    LuggCalloutView *calloutView = markerView.calloutView;
    if (calloutView && calloutView.hasCustomContent) {
      [mapView animateToLocation:marker.position];

      dispatch_async(dispatch_get_main_queue(), ^{
        if (calloutView.bubbled) {
          mapView.selectedMarker = marker;
        } else {
          [self showNonBubbledCallout:markerView];
        }
      });
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
  [self syncMarkerView:markerView];
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
    marker.iconView = nil;
    marker.map = nil;
    markerView.marker = nil;
  }
  [markerView resetIconViewTransform];
}

- (void)syncMarkerView:(LuggMarkerView *)markerView {
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

  GMSAdvancedMarker *marker = (GMSAdvancedMarker *)markerView.marker;
  marker.position = markerView.coordinate;
  marker.title = markerView.title.length > 0 ? markerView.title : nil;
  marker.snippet = markerView.markerDescription.length > 0
                       ? markerView.markerDescription
                       : nil;
  marker.zIndex = (int)markerView.zIndex;
  marker.draggable = markerView.draggable;
  [self applyMarkerStyle:markerView marker:marker];
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
}

- (void)applyMarkerStyle:(LuggMarkerView *)markerView
                  marker:(GMSAdvancedMarker *)marker {
  if (markerView.hasCustomView) {
    if (markerView.rasterize) {
      marker.iconView = nil;
      marker.icon = [markerView createScaledIconImage];
      marker.rotation = markerView.rotate;
    } else {
      UIView *iconView = markerView.iconView;
      if (marker.iconView != iconView) {
        [iconView removeFromSuperview];
        marker.iconView = iconView;
      }
      CGFloat scale = markerView.scale;
      CGFloat radians = markerView.rotate * M_PI / 180.0;
      iconView.transform =
          CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale),
                                  CGAffineTransformMakeRotation(radians));
      marker.rotation = 0;
    }
    marker.groundAnchor = markerView.anchor;
  } else {
    marker.iconView = nil;
    marker.icon = nil;
    marker.rotation = markerView.rotate;
    marker.groundAnchor = CGPointMake(0.5, 1);
  }
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
}

- (void)resumeAnimations {
  for (GMSPolylineAnimator *animator in _polylineAnimators.objectEnumerator) {
    [animator resume];
  }
}

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  if (!_mapView)
    return;

  float targetZoom = zoom > 0 ? (float)zoom : _mapView.camera.zoom;
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude
                                                          longitude:longitude
                                                               zoom:targetZoom];
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
  GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate fitBounds:bounds
                                              withEdgeInsets:insets];

  if (duration < 0) {
    [_mapView animateWithCameraUpdate:cameraUpdate];
  } else if (duration > 0) {
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration / 1000.0];
    [_mapView animateWithCameraUpdate:cameraUpdate];
    [CATransaction commit];
  } else {
    [_mapView moveCamera:cameraUpdate];
  }
}

@end
