#import "LuggMapView.h"
#import "LuggGroundOverlayView.h"
#import "LuggMapWrapperView.h"
#import "LuggMarkerView.h"
#import "LuggPolygonView.h"
#import "LuggPolylineView.h"
#import "LuggTileOverlayView.h"
#import "core/AppleMapProvider.h"
#import "core/GoogleMapProvider.h"
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
  BOOL _userLocationEnabled;
  LuggMapViewTheme _theme;
  double _minZoom;
  double _maxZoom;
  UIEdgeInsets _edgeInsets;
  UIEdgeInsets _oldEdgeInsets;
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
    _userLocationEnabled = NO;
    _theme = LuggMapViewTheme::System;
    _edgeInsets = UIEdgeInsetsZero;
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
  if (self.window) {
    if (!_provider && _mapWrapperView) {
      [self initializeProvider];
    }
    [_provider resumeAnimations];
  } else {
    [_provider pauseAnimations];
  }
}

- (void)prepareForRecycle {
  [super prepareForRecycle];

  [_provider destroy];
  _provider = nil;
  _mapWrapperView = nil;
  _initialized = NO;
}

#pragma mark - Provider Initialization

- (void)initializeProvider {
  if (_provider || !_mapWrapperView)
    return;

  const auto &viewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(_props);

  if (_providerType == LuggMapViewProvider::Apple) {
    _provider = [[AppleMapProvider alloc] init];
  } else {
    GoogleMapProvider *google = [[GoogleMapProvider alloc] init];
    google.mapId = _mapId;
    _provider = google;
  }

  _provider.delegate = self;

  CLLocationCoordinate2D coordinate =
      CLLocationCoordinate2DMake(viewProps.initialCoordinate.latitude,
                                 viewProps.initialCoordinate.longitude);

  [_provider initializeMapInView:_mapWrapperView
               initialCoordinate:coordinate
                     initialZoom:viewProps.initialZoom];

  // Apply cached props after map view is created
  [self applyProps];
  [_provider setEdgeInsets:_edgeInsets oldEdgeInsets:UIEdgeInsetsZero];

  _initialized = YES;

  // Flush any children that were mounted before content was created
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[LuggMarkerView class]]) {
      [_provider addMarkerView:(LuggMarkerView *)subview];
    } else if ([subview isKindOfClass:[LuggPolylineView class]]) {
      [_provider addPolylineView:(LuggPolylineView *)subview];
    } else if ([subview isKindOfClass:[LuggPolygonView class]]) {
      [_provider addPolygonView:(LuggPolygonView *)subview];
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
  [_provider setUserLocationEnabled:_userLocationEnabled];
  [_provider setTheme:(NSInteger)_theme];
  [_provider setMinZoom:_minZoom];
  [_provider setMaxZoom:_maxZoom];
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &newViewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(props);
  const auto &prevViewProps =
      *std::static_pointer_cast<LuggMapViewProps const>(_props);

  _providerType = newViewProps.provider;

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
  if (newViewProps.userLocationEnabled != prevViewProps.userLocationEnabled) {
    _userLocationEnabled = newViewProps.userLocationEnabled;
    [_provider setUserLocationEnabled:_userLocationEnabled];
  }
  if (newViewProps.minZoom != prevViewProps.minZoom) {
    _minZoom = newViewProps.minZoom;
    [_provider setMinZoom:_minZoom];
  }
  if (newViewProps.maxZoom != prevViewProps.maxZoom) {
    _maxZoom = newViewProps.maxZoom;
    [_provider setMaxZoom:_maxZoom];
  }
  if (newViewProps.theme != prevViewProps.theme) {
    _theme = newViewProps.theme;
    [_provider setTheme:(NSInteger)_theme];
  }

  UIEdgeInsets newEdgeInsets = UIEdgeInsetsMake(
      newViewProps.edgeInsets.top, newViewProps.edgeInsets.left,
      newViewProps.edgeInsets.bottom, newViewProps.edgeInsets.right);
  if (!UIEdgeInsetsEqualToEdgeInsets(newEdgeInsets, _edgeInsets)) {
    _oldEdgeInsets = _edgeInsets;
    _edgeInsets = newEdgeInsets;
    [_provider setEdgeInsets:_edgeInsets oldEdgeInsets:_oldEdgeInsets];
  }

  [super updateProps:props oldProps:oldProps];
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

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTLuggMapViewHandleCommand(self, commandName, args);
}

Class<RCTComponentViewProtocol> LuggMapViewCls(void) {
  return LuggMapView.class;
}

@end
