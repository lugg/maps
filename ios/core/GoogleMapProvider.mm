#import "GoogleMapProvider.h"
#import "GMSPolylineAnimator.h"
#import "PolylineAnimatorBase.h"
#import "../LuggMarkerView.h"
#import "../LuggPolylineView.h"

static NSString *const kDemoMapId = @"DEMO_MAP_ID";

@interface GoogleMapProvider () <LuggMarkerViewDelegate,
                                 LuggPolylineViewDelegate>
@end

@implementation GoogleMapProvider {
  GMSMapView *_mapView;
  BOOL _isMapReady;
  BOOL _isDragging;
  NSMutableArray<LuggMarkerView *> *_pendingMarkerViews;
  NSMutableArray<LuggPolylineView *> *_pendingPolylineViews;
  NSMapTable<LuggPolylineView *, GMSPolylineAnimator *> *_polylineAnimators;
}

@synthesize delegate = _delegate;

- (instancetype)init {
  if (self = [super init]) {
    _isMapReady = NO;
    _mapId = kDemoMapId;
    _pendingMarkerViews = [NSMutableArray array];
    _pendingPolylineViews = [NSMutableArray array];
    _polylineAnimators = [NSMapTable weakToStrongObjectsMapTable];
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
  if (_mapView) return;

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

  [wrapperView addSubview:_mapView];

  _isMapReady = YES;
  [self processPendingMarkers];
  [self processPendingPolylines];

  [_delegate mapProviderDidReady];
}

- (void)destroy {
  [_pendingMarkerViews removeAllObjects];
  [_pendingPolylineViews removeAllObjects];
  [_polylineAnimators removeAllObjects];
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

- (void)setTheme:(NSString *)theme {
  if ([theme isEqualToString:@"dark"]) {
    _mapView.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
  } else if ([theme isEqualToString:@"light"]) {
    _mapView.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
  } else {
    _mapView.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
  }
}

- (void)setMinZoom:(double)minZoom {
  if (!_mapView) return;
  float min = minZoom > 0 ? (float)minZoom : _mapView.minZoom;
  [_mapView setMinZoom:min maxZoom:_mapView.maxZoom];
}

- (void)setMaxZoom:(double)maxZoom {
  if (!_mapView) return;
  float max = maxZoom > 0 ? (float)maxZoom : _mapView.maxZoom;
  [_mapView setMinZoom:_mapView.minZoom maxZoom:max];
}

- (void)setPadding:(UIEdgeInsets)padding oldPadding:(UIEdgeInsets)oldPadding {
  _mapView.padding = padding;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
  _isDragging = gesture;
  if (_isDragging) {
    for (GMSPolylineAnimator *animator in
         _polylineAnimators.objectEnumerator) {
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
    for (GMSPolylineAnimator *animator in
         _polylineAnimators.objectEnumerator) {
      [animator resume];
    }
  }
  [_delegate mapProviderDidIdleCamera:position.target.latitude
                            longitude:position.target.longitude
                                 zoom:position.zoom
                              gesture:wasDragging];
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
  if (!_mapView) return;

  for (LuggMarkerView *markerView in _pendingMarkerViews) {
    [self addMarkerViewToMap:markerView];
  }
  [_pendingMarkerViews removeAllObjects];
}

- (void)addMarkerViewToMap:(LuggMarkerView *)markerView {
  if (!_mapView) return;

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
  if (!_mapView) return;

  for (LuggPolylineView *polylineView in _pendingPolylineViews) {
    [self addPolylineViewToMap:polylineView];
  }
  [_pendingPolylineViews removeAllObjects];
}

- (void)addPolylineViewToMap:(LuggPolylineView *)polylineView {
  if (!_mapView) return;

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

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  if (!_mapView) return;

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
            paddingTop:(double)paddingTop
           paddingLeft:(double)paddingLeft
         paddingBottom:(double)paddingBottom
          paddingRight:(double)paddingRight
              duration:(double)duration {
  if (!_mapView || coordinates.count == 0) return;

  GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] init];
  for (NSDictionary *coord in coordinates) {
    double lat = [coord[@"latitude"] doubleValue];
    double lng = [coord[@"longitude"] doubleValue];
    bounds = [bounds includingCoordinate:CLLocationCoordinate2DMake(lat, lng)];
  }

  UIEdgeInsets edgePadding =
      UIEdgeInsetsMake(paddingTop, paddingLeft, paddingBottom, paddingRight);
  GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate fitBounds:bounds
                                              withEdgeInsets:edgePadding];

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
