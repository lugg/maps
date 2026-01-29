#import "LuggGoogleMapView.h"
#import "LuggMarkerView.h"
#import "LuggPolylineView.h"
#import "core/GMSPolylineAnimator.h"
#import "core/PolylineAnimatorBase.h"
#import "events/CameraIdleEvent.h"
#import "events/CameraMoveEvent.h"
#import "events/ReadyEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

#import "LuggMapWrapperView.h"

static NSString *const kDemoMapId = @"DEMO_MAP_ID";

@interface LuggGoogleMapView () <RCTLuggGoogleMapViewViewProtocol,
                                 GMSMapViewDelegate, LuggMarkerViewDelegate,
                                 LuggPolylineViewDelegate>
@end

@implementation LuggGoogleMapView {
  GMSMapView *_mapView;
  LuggMapWrapperView *_mapWrapperView;
  BOOL _isMapReady;
  BOOL _isDragging;
  NSString *_mapId;
  NSMutableArray<LuggMarkerView *> *_pendingMarkerViews;
  NSMutableArray<LuggPolylineView *> *_pendingPolylineViews;
  NSMapTable<LuggPolylineView *, GMSPolylineAnimator *> *_polylineAnimators;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggGoogleMapViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggGoogleMapViewProps>();
    _props = defaultProps;

    _isMapReady = NO;
    _mapId = kDemoMapId;
    _pendingMarkerViews = [NSMutableArray array];
    _pendingPolylineViews = [NSMutableArray array];
    _polylineAnimators = [NSMapTable weakToStrongObjectsMapTable];
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
    markerView.delegate = self;
    [self syncMarkerView:markerView caller:@"mountChildComponentView"];
  } else if ([childComponentView isKindOfClass:[LuggPolylineView class]]) {
    LuggPolylineView *polylineView = (LuggPolylineView *)childComponentView;
    polylineView.delegate = self;
    [self syncPolylineView:polylineView];
  }
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  if ([childComponentView isKindOfClass:[LuggMarkerView class]]) {
    LuggMarkerView *markerView = (LuggMarkerView *)childComponentView;
    GMSAdvancedMarker *marker = (GMSAdvancedMarker *)markerView.marker;
    if (marker) {
      marker.iconView = nil;
      marker.map = nil;
      markerView.marker = nil;
    }
    [markerView resetIconViewTransform];
  } else if ([childComponentView isKindOfClass:[LuggPolylineView class]]) {
    LuggPolylineView *polylineView = (LuggPolylineView *)childComponentView;
    [_polylineAnimators removeObjectForKey:polylineView];
    GMSPolyline *polyline = (GMSPolyline *)polylineView.polyline;
    if (polyline) {
      polyline.map = nil;
      polylineView.polyline = nil;
    }
  }

  [super unmountChildComponentView:childComponentView index:index];
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.window && !_mapView && _mapWrapperView) {
    [self initializeMap];
  }
}

- (void)prepareForRecycle {
  [super prepareForRecycle];

  [_pendingMarkerViews removeAllObjects];
  [_pendingPolylineViews removeAllObjects];
  [_polylineAnimators removeAllObjects];
  [_mapView clear];
  [_mapView removeFromSuperview];
  _mapView = nil;
  _mapWrapperView = nil;
  _isMapReady = NO;
}

#pragma mark - Map Initialization

- (void)initializeMap {
  if (_mapView || !_mapWrapperView) {
    return;
  }

  const auto &viewProps =
      *std::static_pointer_cast<LuggGoogleMapViewProps const>(_props);

  GMSMapID *gmsMapId;
  if ([_mapId isEqualToString:kDemoMapId] || _mapId.length == 0) {
    gmsMapId = [GMSMapID demoMapID];
  } else {
    gmsMapId = [GMSMapID mapIDWithIdentifier:_mapId];
  }

  GMSCameraPosition *camera = [GMSCameraPosition
      cameraWithLatitude:viewProps.initialCoordinate.latitude
               longitude:viewProps.initialCoordinate.longitude
                    zoom:viewProps.initialZoom];

  GMSMapViewOptions *options = [[GMSMapViewOptions alloc] init];
  options.frame = _mapWrapperView.bounds;
  options.camera = camera;
  options.mapID = gmsMapId;

  _mapView = [[GMSMapView alloc] initWithOptions:options];
  _mapView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _mapView.delegate = self;
  _mapView.paddingAdjustmentBehavior =
      kGMSMapViewPaddingAdjustmentBehaviorNever;
  _mapView.settings.zoomGestures = viewProps.zoomEnabled;
  _mapView.settings.scrollGestures = viewProps.scrollEnabled;
  _mapView.settings.rotateGestures = viewProps.rotateEnabled;
  _mapView.settings.tiltGestures = viewProps.pitchEnabled;
  _mapView.myLocationEnabled = viewProps.userLocationEnabled;

  if (viewProps.minZoom > 0) {
    [_mapView setMinZoom:(float)viewProps.minZoom maxZoom:_mapView.maxZoom];
  }
  if (viewProps.maxZoom > 0) {
    [_mapView setMinZoom:_mapView.minZoom maxZoom:(float)viewProps.maxZoom];
  }

  _mapView.padding =
      UIEdgeInsetsMake(viewProps.padding.top, viewProps.padding.left,
                       viewProps.padding.bottom, viewProps.padding.right);

  [_mapWrapperView addSubview:_mapView];

  _isMapReady = YES;
  [self processPendingMarkers];
  [self processPendingPolylines];

  ReadyEvent::emit<LuggGoogleMapViewEventEmitter>(_eventEmitter);
}

- (GMSMapView *)mapView {
  return _mapView;
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
  CameraMoveEvent{position.target.latitude, position.target.longitude,
                  position.zoom, _isDragging}
      .emit<LuggGoogleMapViewEventEmitter>(_eventEmitter);
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
  CameraIdleEvent{position.target.latitude, position.target.longitude,
                  position.zoom, static_cast<bool>(wasDragging)}
      .emit<LuggGoogleMapViewEventEmitter>(_eventEmitter);
}

#pragma mark - PolylineViewDelegate

- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView {
  [self syncPolylineView:polylineView];
}

#pragma mark - MarkerViewDelegate

- (void)markerViewDidLayout:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView caller:@"markerViewDidLayout"];
}

- (void)markerViewDidUpdate:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView caller:@"markerViewDidUpdate"];
}

#pragma mark - Marker Management

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
      iconView.transform = CGAffineTransformConcat(
          CGAffineTransformMakeScale(scale, scale),
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

- (void)syncMarkerView:(LuggMarkerView *)markerView caller:(NSString *)caller {
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
  if (!_mapView) {
    return;
  }

  for (LuggMarkerView *markerView in _pendingMarkerViews) {
    [self addMarkerViewToMap:markerView];
  }
  [_pendingMarkerViews removeAllObjects];
}

- (void)addMarkerViewToMap:(LuggMarkerView *)markerView {
  if (!_mapView) {
    RCTLogWarn(@"Lugg: addMarkerViewToMap called without a map");
    return;
  }

  GMSAdvancedMarker *marker = [[GMSAdvancedMarker alloc] init];
  marker.position = markerView.coordinate;
  marker.title = markerView.title;
  marker.snippet = markerView.markerDescription;
  marker.zIndex = (int)markerView.zIndex;

  [self applyMarkerStyle:markerView marker:marker];

  marker.map = _mapView;
  markerView.marker = marker;
}

#pragma mark - Polyline Management

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
    animator.animated = polylineView.animated;
    [animator update];
  }
}

- (void)processPendingPolylines {
  if (!_mapView) {
    return;
  }

  for (LuggPolylineView *polylineView in _pendingPolylineViews) {
    [self addPolylineViewToMap:polylineView];
  }
  [_pendingPolylineViews removeAllObjects];
}

- (void)addPolylineViewToMap:(LuggPolylineView *)polylineView {
  if (!_mapView) {
    return;
  }

  GMSPolyline *polyline = [GMSPolyline polylineWithPath:[GMSMutablePath path]];
  polyline.strokeWidth = polylineView.strokeWidth;
  polyline.zIndex = (int)polylineView.zIndex;
  polyline.map = _mapView;
  polylineView.polyline = polyline;

  GMSPolylineAnimator *animator = [[GMSPolylineAnimator alloc] init];
  animator.polyline = polyline;
  animator.coordinates = polylineView.coordinates;
  animator.strokeColors = polylineView.strokeColors;
  animator.animated = polylineView.animated;
  [animator update];

  [_polylineAnimators setObject:animator forKey:polylineView];
}

#pragma mark - Property Setters

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &newViewProps =
      *std::static_pointer_cast<LuggGoogleMapViewProps const>(props);

  if (_mapView == nil) {
    NSString *newMapId =
        [NSString stringWithUTF8String:newViewProps.mapId.c_str()];
    if (newMapId.length > 0) {
      _mapId = newMapId;
    }
  }

  if (_mapView) {
    _mapView.settings.zoomGestures = newViewProps.zoomEnabled;
    _mapView.settings.scrollGestures = newViewProps.scrollEnabled;
    _mapView.settings.rotateGestures = newViewProps.rotateEnabled;
    _mapView.settings.tiltGestures = newViewProps.pitchEnabled;
    _mapView.myLocationEnabled = newViewProps.userLocationEnabled;
    _mapView.padding = UIEdgeInsetsMake(
        newViewProps.padding.top, newViewProps.padding.left,
        newViewProps.padding.bottom, newViewProps.padding.right);

    float minZoom = newViewProps.minZoom > 0 ? (float)newViewProps.minZoom
                                             : _mapView.minZoom;
    float maxZoom = newViewProps.maxZoom > 0 ? (float)newViewProps.maxZoom
                                             : _mapView.maxZoom;
    [_mapView setMinZoom:minZoom maxZoom:maxZoom];
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  if (!_mapView) {
    return;
  }

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
  if (!_mapView || coordinates.count == 0) {
    return;
  }

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

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTLuggGoogleMapViewHandleCommand(self, commandName, args);
}

Class<RCTComponentViewProtocol> LuggGoogleMapViewCls(void) {
  return LuggGoogleMapView.class;
}

@end
