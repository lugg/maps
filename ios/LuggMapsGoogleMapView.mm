#import "LuggMapsGoogleMapView.h"
#import "LuggMapsMarkerView.h"
#import "LuggMapsPolylineView.h"
#import "core/GMSPolylineAnimator.h"
#import "core/PolylineAnimatorBase.h"
#import "events/CameraIdleEvent.h"
#import "events/CameraMoveEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

#import "LuggMapsWrapperView.h"

static NSString *const kDemoMapId = @"DEMO_MAP_ID";

@interface LuggMapsGoogleMapView () <
    RCTLuggMapsGoogleMapViewViewProtocol, GMSMapViewDelegate,
    LuggMapsMarkerViewDelegate, LuggMapsPolylineViewDelegate>
@end

@implementation LuggMapsGoogleMapView {
  GMSMapView *_mapView;
  LuggMapsWrapperView *_mapWrapperView;
  BOOL _isMapReady;
  BOOL _isDragging;
  NSString *_mapId;
  NSMutableArray<LuggMapsMarkerView *> *_pendingMarkerViews;
  NSMutableArray<LuggMapsPolylineView *> *_pendingPolylineViews;
  NSMapTable<LuggMapsPolylineView *, GMSPolylineAnimator *> *_polylineAnimators;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggMapsGoogleMapViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggMapsGoogleMapViewProps>();
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

  if ([childComponentView isKindOfClass:[LuggMapsWrapperView class]]) {
    _mapWrapperView = (LuggMapsWrapperView *)childComponentView;
  } else if ([childComponentView isKindOfClass:[LuggMapsMarkerView class]]) {
    LuggMapsMarkerView *markerView = (LuggMapsMarkerView *)childComponentView;
    markerView.delegate = self;
    [self syncMarkerView:markerView caller:@"mountChildComponentView"];
  } else if ([childComponentView isKindOfClass:[LuggMapsPolylineView class]]) {
    LuggMapsPolylineView *polylineView =
        (LuggMapsPolylineView *)childComponentView;
    polylineView.delegate = self;
    [self syncPolylineView:polylineView];
  }
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  if ([childComponentView isKindOfClass:[LuggMapsMarkerView class]]) {
    LuggMapsMarkerView *markerView = (LuggMapsMarkerView *)childComponentView;
    GMSAdvancedMarker *marker = (GMSAdvancedMarker *)markerView.marker;
    if (marker) {
      marker.iconView = nil;
      marker.map = nil;
      markerView.marker = nil;
    }
  } else if ([childComponentView isKindOfClass:[LuggMapsPolylineView class]]) {
    LuggMapsPolylineView *polylineView =
        (LuggMapsPolylineView *)childComponentView;
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
      *std::static_pointer_cast<LuggMapsGoogleMapViewProps const>(_props);

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

  [_mapWrapperView addSubview:_mapView];

  _isMapReady = YES;
  [self processPendingMarkers];
  [self processPendingPolylines];
}

- (GMSMapView *)mapView {
  return _mapView;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
  _isDragging = gesture;
}

- (void)mapView:(GMSMapView *)mapView
    didChangeCameraPosition:(GMSCameraPosition *)position {
  if (_eventEmitter) {
    auto emitter =
        std::static_pointer_cast<LuggMapsGoogleMapViewEventEmitter const>(
            _eventEmitter);
    CameraMoveEvent{position.target.latitude, position.target.longitude,
                    position.zoom, _isDragging}
        .emit(emitter);
  }
}

- (void)mapView:(GMSMapView *)mapView
    idleAtCameraPosition:(GMSCameraPosition *)position {
  BOOL wasDragging = _isDragging;
  _isDragging = NO;
  if (_eventEmitter) {
    auto emitter =
        std::static_pointer_cast<LuggMapsGoogleMapViewEventEmitter const>(
            _eventEmitter);
    CameraIdleEvent{position.target.latitude, position.target.longitude,
                    position.zoom, static_cast<bool>(wasDragging)}
        .emit(emitter);
  }
}

#pragma mark - PolylineViewDelegate

- (void)polylineViewDidUpdate:(LuggMapsPolylineView *)polylineView {
  [self syncPolylineView:polylineView];
}

#pragma mark - MarkerViewDelegate

- (void)markerViewDidLayout:(LuggMapsMarkerView *)markerView {
  [self syncMarkerView:markerView caller:@"markerViewDidLayout"];
}

- (void)markerViewDidUpdate:(LuggMapsMarkerView *)markerView {
  [self syncMarkerView:markerView caller:@"markerViewDidUpdate"];
}

#pragma mark - Marker Management

- (void)syncMarkerView:(LuggMapsMarkerView *)markerView
                caller:(NSString *)caller {
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
  marker.groundAnchor = markerView.anchor;

  if (markerView.hasCustomView) {
    UIView *iconView = markerView.iconView;
    [iconView removeFromSuperview];
    marker.iconView = iconView;
  } else {
    marker.iconView = nil;
  }
}

- (void)processPendingMarkers {
  if (!_mapView) {
    return;
  }

  for (LuggMapsMarkerView *markerView in _pendingMarkerViews) {
    [self addMarkerViewToMap:markerView];
  }
  [_pendingMarkerViews removeAllObjects];
}

- (void)addMarkerViewToMap:(LuggMapsMarkerView *)markerView {
  if (!_mapView) {
    RCTLogWarn(@"LuggMaps: addMarkerViewToMap called without a map");
    return;
  }

  UIView *iconView = markerView.iconView;
  [iconView removeFromSuperview];

  GMSAdvancedMarker *marker = [[GMSAdvancedMarker alloc] init];
  marker.position = markerView.coordinate;
  marker.title = markerView.title;
  marker.snippet = markerView.markerDescription;
  marker.collisionBehavior = GMSCollisionBehaviorRequired;

  if (markerView.hasCustomView) {
    marker.iconView = iconView;
  }

  marker.groundAnchor = markerView.anchor;
  marker.map = _mapView;

  markerView.marker = marker;
}

#pragma mark - Polyline Management

- (void)syncPolylineView:(LuggMapsPolylineView *)polylineView {
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

  for (LuggMapsPolylineView *polylineView in _pendingPolylineViews) {
    [self addPolylineViewToMap:polylineView];
  }
  [_pendingPolylineViews removeAllObjects];
}

- (void)addPolylineViewToMap:(LuggMapsPolylineView *)polylineView {
  if (!_mapView) {
    return;
  }

  GMSPolyline *polyline = [GMSPolyline polylineWithPath:[GMSMutablePath path]];
  polyline.strokeWidth = polylineView.strokeWidth;
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
      *std::static_pointer_cast<LuggMapsGoogleMapViewProps const>(props);

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
    _mapView.padding = UIEdgeInsetsMake(
        newViewProps.padding.top, newViewProps.padding.left,
        newViewProps.padding.bottom, newViewProps.padding.right);
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

  GMSCameraPosition *camera =
      [GMSCameraPosition cameraWithLatitude:latitude
                                  longitude:longitude
                                       zoom:(float)zoom];
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
               padding:(double)padding
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

  GMSCameraUpdate *cameraUpdate = [GMSCameraUpdate fitBounds:bounds
                                                 withPadding:padding];

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
  RCTLuggMapsGoogleMapViewHandleCommand(self, commandName, args);
}

Class<RCTComponentViewProtocol> LuggMapsGoogleMapViewCls(void) {
  return LuggMapsGoogleMapView.class;
}

@end
