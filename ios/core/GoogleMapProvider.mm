#import "GoogleMapProvider.h"
#import "../LuggMarkerView.h"
#import "../LuggPolygonView.h"
#import "../LuggPolylineView.h"
#import "GMSPolylineAnimator.h"
#import "PolylineAnimatorBase.h"

static NSString *const kDemoMapId = @"DEMO_MAP_ID";

@interface GoogleMapProvider () <
    LuggMarkerViewDelegate, LuggPolylineViewDelegate, LuggPolygonViewDelegate,
    UIGestureRecognizerDelegate>
@end

@implementation GoogleMapProvider {
  GMSMapView *_mapView;
  BOOL _isMapReady;
  BOOL _isDragging;
  NSInteger _theme;
  UIEdgeInsets _edgeInsets;
  NSMutableArray<LuggMarkerView *> *_pendingMarkerViews;
  NSMutableArray<LuggPolylineView *> *_pendingPolylineViews;
  NSMutableArray<LuggPolygonView *> *_pendingPolygonViews;
  NSMapTable<LuggPolylineView *, GMSPolylineAnimator *> *_polylineAnimators;
  NSMapTable<GMSPolygon *, LuggPolygonView *> *_polygonToViewMap;
  UILongPressGestureRecognizer *_polygonPressGesture;
  LuggPolygonView *_pressedPolygonView;
  GMSPolygon *_pressedPolygon;

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
    _polylineAnimators = [NSMapTable weakToStrongObjectsMapTable];
    _polygonToViewMap = [NSMapTable strongToWeakObjectsMapTable];
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

  _polygonPressGesture = [[UILongPressGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(handlePolygonPress:)];
  _polygonPressGesture.minimumPressDuration = 0;
  _polygonPressGesture.cancelsTouchesInView = NO;
  _polygonPressGesture.delegate = self;
  [_mapView addGestureRecognizer:_polygonPressGesture];

  [wrapperView addSubview:_mapView];

  [self applyTheme];

  _isMapReady = YES;
  [self processPendingMarkers];
  [self processPendingPolylines];
  [self processPendingPolygons];

  [_delegate mapProviderDidReady];
}

- (void)destroy {
  [self stopEdgeInsetsAnimation];
  [_pendingMarkerViews removeAllObjects];
  [_pendingPolylineViews removeAllObjects];
  [_pendingPolygonViews removeAllObjects];
  [_polylineAnimators removeAllObjects];
  [_polygonToViewMap removeAllObjects];
  if (_polygonPressGesture) {
    [_mapView removeGestureRecognizer:_polygonPressGesture];
    _polygonPressGesture = nil;
  }
  _pressedPolygonView = nil;
  _pressedPolygon = nil;
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

- (void)handlePolygonPress:(UILongPressGestureRecognizer *)gesture {
  if (gesture.state == UIGestureRecognizerStateBegan) {
    CGPoint point = [gesture locationInView:_mapView];
    CLLocationCoordinate2D coord =
        [_mapView.projection coordinateForPoint:point];

    for (GMSPolygon *polygon in _polygonToViewMap) {
      LuggPolygonView *polygonView = [_polygonToViewMap objectForKey:polygon];
      if (!polygonView || !polygonView.tappable)
        continue;

      if ([self coordinate:coord isInsidePolygon:polygonView.coordinates]) {
        _pressedPolygon = polygon;
        _pressedPolygonView = polygonView;
        [self applyPolygonHighlight];
        return;
      }
    }
  } else if (gesture.state == UIGestureRecognizerStateEnded) {
    if (_pressedPolygonView) {
      [self restorePolygonHighlight];
      [_pressedPolygonView emitPressEvent];
      _pressedPolygonView = nil;
      _pressedPolygon = nil;
    }
  } else if (gesture.state == UIGestureRecognizerStateCancelled ||
             gesture.state == UIGestureRecognizerStateFailed) {
    if (_pressedPolygonView) {
      [self restorePolygonHighlight];
      _pressedPolygonView = nil;
      _pressedPolygon = nil;
    }
  }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (BOOL)coordinate:(CLLocationCoordinate2D)coord
    isInsidePolygon:(NSArray<CLLocation *> *)coordinates {
  if (coordinates.count == 0)
    return NO;

  NSUInteger count = coordinates.count;
  BOOL inside = NO;
  for (NSUInteger i = 0, j = count - 1; i < count; j = i++) {
    CLLocationCoordinate2D pi = coordinates[i].coordinate;
    CLLocationCoordinate2D pj = coordinates[j].coordinate;
    if (((pi.latitude > coord.latitude) != (pj.latitude > coord.latitude)) &&
        (coord.longitude < (pj.longitude - pi.longitude) *
                                   (coord.latitude - pi.latitude) /
                                   (pj.latitude - pi.latitude) +
                               pi.longitude)) {
      inside = !inside;
    }
  }
  return inside;
}

- (void)applyPolygonHighlight {
  UIColor *fill = _pressedPolygonView.fillColor;
  UIColor *stroke = _pressedPolygonView.strokeColor;
  CGFloat fillAlpha = 0, strokeAlpha = 0;
  [fill getRed:NULL green:NULL blue:NULL alpha:&fillAlpha];
  [stroke getRed:NULL green:NULL blue:NULL alpha:&strokeAlpha];
  _pressedPolygon.fillColor = [fill colorWithAlphaComponent:fillAlpha * 0.5];
  _pressedPolygon.strokeColor =
      [stroke colorWithAlphaComponent:strokeAlpha * 0.5];
}

- (void)restorePolygonHighlight {
  _pressedPolygon.fillColor = _pressedPolygonView.fillColor;
  _pressedPolygon.strokeColor = _pressedPolygonView.strokeColor;
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

#pragma mark - Marker Management

- (void)addMarkerView:(LuggMarkerView *)markerView {
  markerView.delegate = self;
  [self syncMarkerView:markerView];
}

- (void)removeMarkerView:(LuggMarkerView *)markerView {
  GMSAdvancedMarker *marker = (GMSAdvancedMarker *)markerView.marker;
  if (marker) {
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
  marker.title = markerView.title;
  marker.snippet = markerView.markerDescription;
  marker.zIndex = (int)markerView.zIndex;
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
  marker.title = markerView.title;
  marker.snippet = markerView.markerDescription;
  marker.zIndex = (int)markerView.zIndex;

  [self applyMarkerStyle:markerView marker:marker];

  marker.map = _mapView;
  markerView.marker = marker;
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
  polygon.fillColor = polygonView.fillColor;
  polygon.strokeColor = polygonView.strokeColor;
  polygon.strokeWidth = polygonView.strokeWidth;
  polygon.zIndex = (int)polygonView.zIndex;
  polygon.tappable = NO;
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
  polygon.fillColor = polygonView.fillColor;
  polygon.strokeColor = polygonView.strokeColor;
  polygon.strokeWidth = polygonView.strokeWidth;
  polygon.zIndex = (int)polygonView.zIndex;
  polygon.tappable = NO;
  polygon.map = _mapView;
  polygonView.polygon = polygon;
  [_polygonToViewMap setObject:polygonView forKey:polygon];
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
