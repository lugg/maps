#import "LuggAppleMapView.h"
#import "LuggMapWrapperView.h"
#import "LuggMarkerView.h"
#import "LuggPolylineView.h"
#import "core/MKPolylineAnimator.h"
#import "events/CameraIdleEvent.h"
#import "events/CameraMoveEvent.h"
#import "events/ReadyEvent.h"
#import "extensions/MKMapView+Zoom.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

@interface AppleMarkerAnnotation : NSObject <MKAnnotation>
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy, nullable) NSString *title;
@property(nonatomic, copy, nullable) NSString *subtitle;
@property(nonatomic, strong) LuggMarkerView *markerView;
@property(nonatomic, weak) MKAnnotationView *annotationView;
@end

@implementation AppleMarkerAnnotation
@end

@implementation LuggAppleMapViewContent
@end

@interface LuggAppleMapView () <RCTLuggAppleMapViewViewProtocol,
                                MKMapViewDelegate, LuggMarkerViewDelegate,
                                LuggPolylineViewDelegate>
@end

@implementation LuggAppleMapView {
  LuggAppleMapViewContent *_mapView;
  LuggMapWrapperView *_mapWrapperView;
  BOOL _isMapReady;
  BOOL _isDragging;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggAppleMapViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggAppleMapViewProps>();
    _props = defaultProps;
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

    AppleMarkerAnnotation *annotation = [[AppleMarkerAnnotation alloc] init];
    annotation.markerView = markerView;
    markerView.marker = annotation;

    if (_mapView) {
      [_mapView addAnnotation:annotation];
    }

    [self markerViewDidUpdate:markerView];
  } else if ([childComponentView isKindOfClass:[LuggPolylineView class]]) {
    LuggPolylineView *polylineView = (LuggPolylineView *)childComponentView;
    polylineView.delegate = self;
    [self addPolylineViewToMap:polylineView];
  }
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  if ([childComponentView isKindOfClass:[LuggMarkerView class]]) {
    LuggMarkerView *markerView = (LuggMarkerView *)childComponentView;
    markerView.delegate = nil;

    AppleMarkerAnnotation *annotation =
        (AppleMarkerAnnotation *)markerView.marker;

    if (annotation) {
      annotation.markerView = nil;
      annotation.annotationView = nil;
      [_mapView removeAnnotation:annotation];
      markerView.marker = nil;
    }
  } else if ([childComponentView isKindOfClass:[LuggPolylineView class]]) {
    LuggPolylineView *polylineView = (LuggPolylineView *)childComponentView;
    polylineView.delegate = nil;
    MKPolyline *polyline = (MKPolyline *)polylineView.polyline;
    if (polyline) {
      [_mapView removeOverlay:polyline];
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
      *std::static_pointer_cast<LuggAppleMapViewProps const>(_props);

  _mapView =
      [[LuggAppleMapViewContent alloc] initWithFrame:_mapWrapperView.bounds];
  _mapView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _mapView.delegate = self;
  _mapView.insetsLayoutMarginsFromSafeArea = NO;
  _mapView.zoomEnabled = viewProps.zoomEnabled;
  _mapView.scrollEnabled = viewProps.scrollEnabled;
  _mapView.rotateEnabled = viewProps.rotateEnabled;
  _mapView.pitchEnabled = viewProps.pitchEnabled;

  [_mapWrapperView addSubview:_mapView];

  [self setCameraWithLatitude:viewProps.initialCoordinate.latitude
                    longitude:viewProps.initialCoordinate.longitude
                         zoom:viewProps.initialZoom
                     animated:NO];

  // Add annotations for any markers that were mounted before map was ready
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[LuggMarkerView class]]) {
      LuggMarkerView *markerView = (LuggMarkerView *)subview;
      AppleMarkerAnnotation *annotation =
          (AppleMarkerAnnotation *)markerView.marker;
      if (annotation) {
        [_mapView addAnnotation:annotation];
      }
    } else if ([subview isKindOfClass:[LuggPolylineView class]]) {
      LuggPolylineView *polylineView = (LuggPolylineView *)subview;
      [self addPolylineViewToMap:polylineView];
    }
  }

  _isMapReady = YES;

  ReadyEvent::emit<LuggAppleMapViewEventEmitter>(_eventEmitter);
}

- (void)setCameraWithLatitude:(double)latitude
                    longitude:(double)longitude
                         zoom:(double)zoom
                     animated:(BOOL)animated {
  CLLocationCoordinate2D center =
      CLLocationCoordinate2DMake(latitude, longitude);
  [_mapView setCenterCoordinate:center zoomLevel:zoom animated:animated];
}

- (MKMapView *)mapView {
  return _mapView;
}

#pragma mark - Property Setters

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  const auto &newViewProps =
      *std::static_pointer_cast<LuggAppleMapViewProps const>(props);

  if (_mapView) {
    _mapView.zoomEnabled = newViewProps.zoomEnabled;
    _mapView.scrollEnabled = newViewProps.scrollEnabled;
    _mapView.rotateEnabled = newViewProps.rotateEnabled;
    _mapView.pitchEnabled = newViewProps.pitchEnabled;
    _mapView.layoutMargins = UIEdgeInsetsMake(
        newViewProps.padding.top, newViewProps.padding.left,
        newViewProps.padding.bottom, newViewProps.padding.right);
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - Annotation Helpers

- (void)updateAnnotationViewFrame:(AppleMarkerAnnotation *)annotation {
  MKAnnotationView *annotationView = annotation.annotationView;
  LuggMarkerView *markerView = annotation.markerView;

  if (!annotationView || !markerView) {
    return;
  }

  UIView *iconView = markerView.iconView;
  CGRect frame = iconView.frame;
  if (frame.size.width > 0 && frame.size.height > 0) {
    annotationView.frame = frame;

    CGPoint anchor = markerView.anchor;
    annotationView.centerOffset =
        CGPointMake(frame.size.width * (anchor.x - 0.5),
                    -frame.size.height * (anchor.y - 0.5));
  }
}

#pragma mark - PolylineViewDelegate

- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView {
  [self syncPolylineView:polylineView];
}

#pragma mark - Polyline Management

- (void)addPolylineViewToMap:(LuggPolylineView *)polylineView {
  if (!_mapView) {
    return;
  }

  NSArray<CLLocation *> *coordinates = polylineView.coordinates;
  if (coordinates.count == 0) {
    return;
  }

  CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(
      sizeof(CLLocationCoordinate2D) * coordinates.count);
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    coords[i] = coordinates[i].coordinate;
  }

  MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords
                                                       count:coordinates.count];
  free(coords);

  polylineView.polyline = polyline;
  [_mapView addOverlay:polyline];
}

- (void)syncPolylineView:(LuggPolylineView *)polylineView {
  if (!_mapView) {
    return;
  }

  MKPolylineAnimator *renderer = (MKPolylineAnimator *)polylineView.renderer;
  MKPolyline *oldPolyline = (MKPolyline *)polylineView.polyline;

  // Build new polyline from coordinates
  NSArray<CLLocation *> *coordinates = polylineView.coordinates;
  if (coordinates.count == 0) {
    if (oldPolyline) {
      [_mapView removeOverlay:oldPolyline];
      polylineView.polyline = nil;
      polylineView.renderer = nil;
    }
    return;
  }

  CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(
      sizeof(CLLocationCoordinate2D) * coordinates.count);
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    coords[i] = coordinates[i].coordinate;
  }
  MKPolyline *newPolyline =
      [MKPolyline polylineWithCoordinates:coords count:coordinates.count];
  free(coords);

  polylineView.polyline = newPolyline;

  // If we have an existing renderer, update it in place
  if (renderer && oldPolyline) {
    [renderer updatePolyline:newPolyline];
    renderer.lineWidth = polylineView.strokeWidth;
    renderer.strokeColor = polylineView.strokeColors.firstObject;
    renderer.strokeColors =
        polylineView.strokeColors.count > 1 ? polylineView.strokeColors : nil;
    renderer.animated = polylineView.animated;
    return;
  }

  // Otherwise do full add
  if (oldPolyline) {
    [_mapView removeOverlay:oldPolyline];
  }
  [_mapView addOverlay:newPolyline];
}

- (LuggPolylineView *)findPolylineViewForOverlay:(id<MKOverlay>)overlay {
  for (UIView *subview in self.subviews) {
    if ([subview isKindOfClass:[LuggPolylineView class]]) {
      LuggPolylineView *polylineView = (LuggPolylineView *)subview;
      if (polylineView.polyline == overlay) {
        return polylineView;
      }
    }
  }
  return nil;
}

#pragma mark - MarkerViewDelegate

- (void)markerViewDidLayout:(LuggMarkerView *)markerView {
  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)markerView.marker;
  if (annotation) {
    [self updateAnnotationViewFrame:annotation];
  }
}

- (void)markerViewDidUpdate:(LuggMarkerView *)markerView {
  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)markerView.marker;

  if (!annotation) {
    RCTLogWarn(@"markerViewDidUpdate called without annotation");
    return;
  }

  annotation.coordinate = markerView.coordinate;
  annotation.title = markerView.title;
  annotation.subtitle = markerView.markerDescription;

  [self updateAnnotationViewFrame:annotation];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
  _isDragging = [self isUserInteracting:mapView];
}

- (BOOL)isUserInteracting:(MKMapView *)mapView {
  UIView *mapContainerView = mapView.subviews.firstObject;
  for (UIGestureRecognizer *gesture in mapContainerView.gestureRecognizers) {
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged) {
      return YES;
    }
  }
  return NO;
}

- (void)mapViewDidChangeVisibleRegion:(MKMapView *)mapView {
  CameraMoveEvent{mapView.centerCoordinate.latitude,
                  mapView.centerCoordinate.longitude, mapView.zoomLevel,
                  _isDragging}
      .emit<LuggAppleMapViewEventEmitter>(_eventEmitter);
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
  BOOL wasDragging = _isDragging;
  _isDragging = NO;
  CameraIdleEvent{mapView.centerCoordinate.latitude,
                  mapView.centerCoordinate.longitude, mapView.zoomLevel,
                  static_cast<bool>(wasDragging)}
      .emit<LuggAppleMapViewEventEmitter>(_eventEmitter);
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation {
  if (![annotation isKindOfClass:[AppleMarkerAnnotation class]]) {
    return nil;
  }

  AppleMarkerAnnotation *markerAnnotation = (AppleMarkerAnnotation *)annotation;
  LuggMarkerView *markerView = markerAnnotation.markerView;

  if (!markerView || !markerView.hasCustomView) {
    return nil;
  }

  MKAnnotationView *annotationView =
      [[MKAnnotationView alloc] initWithAnnotation:annotation
                                   reuseIdentifier:nil];
  annotationView.canShowCallout = YES;
  annotationView.displayPriority = MKFeatureDisplayPriorityRequired;
  annotationView.collisionMode = MKAnnotationViewCollisionModeNone;

  UIView *iconView = markerView.iconView;
  [iconView removeFromSuperview];
  [annotationView addSubview:iconView];

  // Set frame and centerOffset based on iconView
  CGRect frame = iconView.frame;
  if (frame.size.width > 0 && frame.size.height > 0) {
    annotationView.frame =
        CGRectMake(0, 0, frame.size.width, frame.size.height);
    iconView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);

    CGPoint anchor = markerView.anchor;
    annotationView.centerOffset =
        CGPointMake(frame.size.width * (anchor.x - 0.5),
                    -frame.size.height * (anchor.y - 0.5));
  }

  markerAnnotation.annotationView = annotationView;

  return annotationView;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay {
  if ([overlay isKindOfClass:[MKPolyline class]]) {
    LuggPolylineView *polylineView = [self findPolylineViewForOverlay:overlay];
    MKPolyline *polyline = (MKPolyline *)overlay;

    if (polylineView) {
      NSArray<UIColor *> *colors = polylineView.strokeColors;

      MKPolylineAnimator *renderer =
          [[MKPolylineAnimator alloc] initWithPolyline:polyline];
      renderer.lineWidth = polylineView.strokeWidth;
      renderer.strokeColor = colors.firstObject;
      if (colors.count > 1) {
        renderer.strokeColors = colors;
      }
      renderer.animated = polylineView.animated;
      polylineView.renderer = renderer;
      return renderer;
    }

    MKPolylineRenderer *renderer =
        [[MKPolylineRenderer alloc] initWithPolyline:polyline];
    return renderer;
  }
  return nil;
}

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  if (!_mapView) {
    return;
  }

  if (duration < 0) {
    [self setCameraWithLatitude:latitude
                      longitude:longitude
                           zoom:zoom
                       animated:YES];
  } else if (duration > 0) {
    CLLocationCoordinate2D center =
        CLLocationCoordinate2DMake(latitude, longitude);
    MKCoordinateRegion region = [_mapView regionForCenterCoordinate:center
                                                          zoomLevel:zoom];
    [UIView animateWithDuration:duration / 1000.0
                     animations:^{
                       [self->_mapView setRegion:region animated:NO];
                     }];
  } else {
    [self setCameraWithLatitude:latitude
                      longitude:longitude
                           zoom:zoom
                       animated:NO];
  }
}

- (void)fitCoordinates:(NSArray *)coordinates
               padding:(double)padding
              duration:(double)duration {
  if (!_mapView || coordinates.count == 0) {
    return;
  }

  CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(
      sizeof(CLLocationCoordinate2D) * coordinates.count);
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    NSDictionary *coord = coordinates[i];
    coords[i] = CLLocationCoordinate2DMake([coord[@"latitude"] doubleValue],
                                           [coord[@"longitude"] doubleValue]);
  }

  MKMapRect mapRect = MKMapRectNull;
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    MKMapPoint point = MKMapPointForCoordinate(coords[i]);
    MKMapRect pointRect = MKMapRectMake(point.x, point.y, 0, 0);
    mapRect = MKMapRectUnion(mapRect, pointRect);
  }
  free(coords);

  UIEdgeInsets edgePadding =
      UIEdgeInsetsMake(padding, padding, padding, padding);

  if (duration < 0) {
    [_mapView setVisibleMapRect:mapRect edgePadding:edgePadding animated:YES];
  } else if (duration > 0) {
    [UIView animateWithDuration:duration / 1000.0
                     animations:^{
                       [self->_mapView setVisibleMapRect:mapRect
                                             edgePadding:edgePadding
                                                animated:NO];
                     }];
  } else {
    [_mapView setVisibleMapRect:mapRect edgePadding:edgePadding animated:NO];
  }
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTLuggAppleMapViewHandleCommand(self, commandName, args);
}

Class<RCTComponentViewProtocol> LuggAppleMapViewCls(void) {
  return LuggAppleMapView.class;
}

@end
