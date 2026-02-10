#import "AppleMapProvider.h"
#import "../LuggMarkerView.h"
#import "../LuggPolylineView.h"
#import "../extensions/MKMapView+Zoom.h"
#import "MKPolylineAnimator.h"

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

@interface AppleMapProvider () <LuggMarkerViewDelegate,
                                LuggPolylineViewDelegate>
@end

@implementation AppleMapProvider {
  LuggAppleMapViewContent *_mapView;
  BOOL _isMapReady;
  BOOL _isDragging;
  double _minZoom;
  double _maxZoom;
  NSMapTable<id<MKOverlay>, LuggPolylineView *> *_overlayToPolylineMap;
}

@synthesize delegate = _delegate;

- (instancetype)init {
  if (self = [super init]) {
    _overlayToPolylineMap = [NSMapTable strongToWeakObjectsMapTable];
  }
  return self;
}

- (BOOL)isMapReady {
  return _isMapReady;
}

- (MKMapView *)mapView {
  return _mapView;
}

#pragma mark - MapProvider

- (void)initializeMapInView:(UIView *)wrapperView
          initialCoordinate:(CLLocationCoordinate2D)coordinate
                initialZoom:(double)zoom {
  if (_mapView)
    return;

  _mapView = [[LuggAppleMapViewContent alloc] initWithFrame:wrapperView.bounds];
  _mapView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _mapView.delegate = self;
  _mapView.insetsLayoutMarginsFromSafeArea = NO;

  [self applyZoomRange];

  [wrapperView addSubview:_mapView];

  MKCoordinateRegion region = [_mapView regionForCenterCoordinate:coordinate
                                                        zoomLevel:zoom];
  [_mapView setRegion:region animated:NO];

  _isMapReady = YES;

  [_delegate mapProviderDidReady];
}

- (void)destroy {
  [_mapView removeFromSuperview];
  _mapView = nil;
  _isMapReady = NO;
}

#pragma mark - Props

- (void)setZoomEnabled:(BOOL)enabled {
  _mapView.zoomEnabled = enabled;
}

- (void)setScrollEnabled:(BOOL)enabled {
  _mapView.scrollEnabled = enabled;
}

- (void)setRotateEnabled:(BOOL)enabled {
  _mapView.rotateEnabled = enabled;
}

- (void)setPitchEnabled:(BOOL)enabled {
  _mapView.pitchEnabled = enabled;
}

- (void)setUserLocationEnabled:(BOOL)enabled {
  _mapView.showsUserLocation = enabled;
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
  _minZoom = minZoom;
  [self applyZoomRange];
}

- (void)setMaxZoom:(double)maxZoom {
  _maxZoom = maxZoom;
  [self applyZoomRange];
}

- (void)setPadding:(UIEdgeInsets)padding oldPadding:(UIEdgeInsets)oldPadding {
  CGFloat oldOffsetX = (oldPadding.left - oldPadding.right) / 2.0;
  CGFloat oldOffsetY = (oldPadding.top - oldPadding.bottom) / 2.0;
  CGFloat newOffsetX = (padding.left - padding.right) / 2.0;
  CGFloat newOffsetY = (padding.top - padding.bottom) / 2.0;

  CGFloat deltaX = newOffsetX - oldOffsetX;
  CGFloat deltaY = newOffsetY - oldOffsetY;

  _mapView.layoutMargins = padding;

  if (deltaX != 0 || deltaY != 0) {
    CLLocationCoordinate2D currentCenter = _mapView.centerCoordinate;
    CGPoint centerPoint = [_mapView convertCoordinate:currentCenter
                                        toPointToView:_mapView];
    CGPoint newPoint =
        CGPointMake(centerPoint.x - deltaX, centerPoint.y - deltaY);
    CLLocationCoordinate2D newCenter = [_mapView convertPoint:newPoint
                                         toCoordinateFromView:_mapView];
    [_mapView setCenterCoordinate:newCenter animated:NO];
  }
}

- (CLLocationDistance)cameraDistanceForZoomLevel:(double)zoomLevel {
  return 128000000.0 / pow(2, zoomLevel);
}

- (void)applyZoomRange {
  if (!_mapView)
    return;

  CLLocationDistance minDistance =
      _maxZoom > 0 ? [self cameraDistanceForZoomLevel:_maxZoom] : 0;
  CLLocationDistance maxDistance =
      _minZoom > 0 ? [self cameraDistanceForZoomLevel:_minZoom] : -1;

  MKMapCameraZoomRange *zoomRange = [[MKMapCameraZoomRange alloc]
      initWithMinCenterCoordinateDistance:minDistance
              maxCenterCoordinateDistance:maxDistance];
  _mapView.cameraZoomRange = zoomRange;
}

#pragma mark - MKMapViewDelegate

- (BOOL)isUserInteracting {
  UIView *mapContainerView = _mapView.subviews.firstObject;
  for (UIGestureRecognizer *gesture in mapContainerView.gestureRecognizers) {
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged) {
      return YES;
    }
  }
  return NO;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
  _isDragging = [self isUserInteracting];
  if (_isDragging) {
    for (LuggPolylineView *polylineView in _overlayToPolylineMap
             .objectEnumerator) {
      MKPolylineAnimator *renderer =
          (MKPolylineAnimator *)polylineView.renderer;
      [renderer pause];
    }
  }
}

- (void)mapViewDidChangeVisibleRegion:(MKMapView *)mapView {
  [_delegate mapProviderDidMoveCamera:mapView.centerCoordinate.latitude
                            longitude:mapView.centerCoordinate.longitude
                                 zoom:mapView.zoomLevel
                              gesture:_isDragging];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
  BOOL wasDragging = _isDragging;
  _isDragging = NO;
  if (wasDragging) {
    for (LuggPolylineView *polylineView in _overlayToPolylineMap
             .objectEnumerator) {
      MKPolylineAnimator *renderer =
          (MKPolylineAnimator *)polylineView.renderer;
      [renderer resume];
    }
  }
  [_delegate mapProviderDidIdleCamera:mapView.centerCoordinate.latitude
                            longitude:mapView.centerCoordinate.longitude
                                 zoom:mapView.zoomLevel
                              gesture:wasDragging];
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
  annotationView.layer.zPosition = markerView.zIndex;
  annotationView.zPriority = markerView.zIndex;

  if (!markerView.rasterize) {
    UIView *iconView = markerView.iconView;
    [iconView removeFromSuperview];
    [annotationView addSubview:iconView];
  }

  [self applyMarkerStyle:markerView annotationView:annotationView];
  markerAnnotation.annotationView = annotationView;

  return annotationView;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay {
  if ([overlay isKindOfClass:[MKPolyline class]]) {
    LuggPolylineView *polylineView =
        [_overlayToPolylineMap objectForKey:overlay];
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
      renderer.animatedOptions = polylineView.animatedOptions;
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

  if (!annotation)
    return;

  annotation.coordinate = markerView.coordinate;
  annotation.title = markerView.title;
  annotation.subtitle = markerView.markerDescription;

  MKAnnotationView *annotationView = annotation.annotationView;
  if (annotationView) {
    annotationView.layer.zPosition = markerView.zIndex;
    annotationView.zPriority = markerView.zIndex;
  }

  [self updateAnnotationViewFrame:annotation];
}

#pragma mark - PolylineViewDelegate

- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView {
  [self syncPolylineView:polylineView];
}

#pragma mark - Marker Management

- (void)addMarkerView:(LuggMarkerView *)markerView {
  markerView.delegate = self;

  AppleMarkerAnnotation *annotation = [[AppleMarkerAnnotation alloc] init];
  annotation.markerView = markerView;
  markerView.marker = annotation;

  if (_mapView) {
    [_mapView addAnnotation:annotation];
  }

  [self markerViewDidUpdate:markerView];
}

- (void)removeMarkerView:(LuggMarkerView *)markerView {
  markerView.delegate = nil;

  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)markerView.marker;

  if (annotation) {
    annotation.annotationView.transform = CGAffineTransformIdentity;
    annotation.markerView = nil;
    annotation.annotationView = nil;
    [_mapView removeAnnotation:annotation];
    markerView.marker = nil;
  }
  [markerView resetIconViewTransform];
}

- (void)syncMarkerView:(LuggMarkerView *)markerView {
  [self markerViewDidUpdate:markerView];
}

- (void)applyMarkerStyle:(LuggMarkerView *)markerView
          annotationView:(MKAnnotationView *)annotationView {
  annotationView.transform = CGAffineTransformIdentity;

  UIView *iconView = markerView.iconView;
  CGRect frame = iconView.frame;
  if (frame.size.width <= 0 || frame.size.height <= 0)
    return;

  CGFloat scale = markerView.scale;
  CGPoint anchor = markerView.anchor;

  if (markerView.rasterize) {
    annotationView.image = [markerView createScaledIconImage];
  } else {
    iconView.layer.anchorPoint = anchor;
    iconView.transform = CGAffineTransformMakeScale(scale, scale);
    iconView.frame =
        CGRectMake(frame.size.width * (0.5 - anchor.x) * (scale - 1),
                   frame.size.height * (0.5 - anchor.y) * (scale - 1),
                   frame.size.width, frame.size.height);
  }

  annotationView.bounds =
      CGRectMake(0, 0, frame.size.width * scale, frame.size.height * scale);
  annotationView.centerOffset =
      CGPointMake(frame.size.width * scale * (anchor.x - 0.5),
                  -frame.size.height * scale * (anchor.y - 0.5));
  annotationView.transform =
      CGAffineTransformMakeRotation(markerView.rotate * M_PI / 180.0);
}

- (void)updateAnnotationViewFrame:(AppleMarkerAnnotation *)annotation {
  MKAnnotationView *annotationView = annotation.annotationView;
  LuggMarkerView *markerView = annotation.markerView;

  if (!annotationView || !markerView)
    return;

  [self applyMarkerStyle:markerView annotationView:annotationView];
}

#pragma mark - Polyline Management

- (void)addPolylineView:(LuggPolylineView *)polylineView {
  polylineView.delegate = self;
  [self addPolylineOverlayToMap:polylineView];
}

- (void)removePolylineView:(LuggPolylineView *)polylineView {
  polylineView.delegate = nil;
  MKPolyline *polyline = (MKPolyline *)polylineView.polyline;
  if (polyline) {
    [_overlayToPolylineMap removeObjectForKey:polyline];
    [_mapView removeOverlay:polyline];
    polylineView.polyline = nil;
  }
}

- (void)syncPolylineView:(LuggPolylineView *)polylineView {
  if (!_mapView)
    return;

  MKPolylineAnimator *renderer = (MKPolylineAnimator *)polylineView.renderer;
  MKPolyline *oldPolyline = (MKPolyline *)polylineView.polyline;

  NSArray<CLLocation *> *coordinates = polylineView.coordinates;
  if (coordinates.count == 0) {
    if (renderer) {
      renderer.animated = NO;
    }
    if (oldPolyline) {
      [_overlayToPolylineMap removeObjectForKey:oldPolyline];
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
  [_overlayToPolylineMap setObject:polylineView forKey:newPolyline];

  if (renderer && oldPolyline) {
    [_overlayToPolylineMap removeObjectForKey:oldPolyline];
    [_mapView removeOverlay:oldPolyline];
    [self insertOverlay:newPolyline withZIndex:polylineView.zIndex];
    [renderer updatePolyline:newPolyline];
    renderer.lineWidth = polylineView.strokeWidth;
    renderer.strokeColor = polylineView.strokeColors.firstObject;
    renderer.strokeColors =
        polylineView.strokeColors.count > 1 ? polylineView.strokeColors : nil;
    renderer.animatedOptions = polylineView.animatedOptions;
    renderer.animated = polylineView.animated;
    return;
  }

  if (oldPolyline) {
    [_overlayToPolylineMap removeObjectForKey:oldPolyline];
    [_mapView removeOverlay:oldPolyline];
  }
  [self insertOverlay:newPolyline withZIndex:polylineView.zIndex];
}

- (void)addPolylineOverlayToMap:(LuggPolylineView *)polylineView {
  if (!_mapView)
    return;

  NSArray<CLLocation *> *coordinates = polylineView.coordinates;
  if (coordinates.count == 0)
    return;

  CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(
      sizeof(CLLocationCoordinate2D) * coordinates.count);
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    coords[i] = coordinates[i].coordinate;
  }

  MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords
                                                       count:coordinates.count];
  free(coords);

  polylineView.polyline = polyline;
  [_overlayToPolylineMap setObject:polylineView forKey:polyline];
  [self insertOverlay:polyline withZIndex:polylineView.zIndex];
}

- (void)insertOverlay:(id<MKOverlay>)overlay withZIndex:(NSInteger)zIndex {
  if (zIndex == 0) {
    [_mapView addOverlay:overlay];
    return;
  }

  NSArray<id<MKOverlay>> *overlays = _mapView.overlays;
  NSInteger insertIndex = overlays.count;

  for (NSInteger i = 0; i < overlays.count; i++) {
    LuggPolylineView *existingPolylineView =
        [_overlayToPolylineMap objectForKey:overlays[i]];
    if (existingPolylineView && existingPolylineView.zIndex > zIndex) {
      insertIndex = i;
      break;
    }
  }

  [_mapView insertOverlay:overlay atIndex:insertIndex];
}

#pragma mark - Lifecycle

- (void)pauseAnimations {
  for (LuggPolylineView *polylineView in _overlayToPolylineMap
           .objectEnumerator) {
    MKPolylineAnimator *renderer = (MKPolylineAnimator *)polylineView.renderer;
    [renderer pause];
  }
}

- (void)resumeAnimations {
  for (LuggPolylineView *polylineView in _overlayToPolylineMap
           .objectEnumerator) {
    MKPolylineAnimator *renderer = (MKPolylineAnimator *)polylineView.renderer;
    [renderer resume];
  }
}

#pragma mark - Commands

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
  if (!_mapView)
    return;

  double targetZoom = zoom > 0 ? zoom : _mapView.zoomLevel;

  if (duration < 0) {
    [_mapView
        setCenterCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                  zoomLevel:targetZoom
                   animated:YES];
  } else if (duration > 0) {
    CLLocationCoordinate2D center =
        CLLocationCoordinate2DMake(latitude, longitude);
    MKCoordinateRegion region = [_mapView regionForCenterCoordinate:center
                                                          zoomLevel:targetZoom];
    [UIView animateWithDuration:duration / 1000.0
                     animations:^{
                       [self->_mapView setRegion:region animated:NO];
                     }];
  } else {
    [_mapView
        setCenterCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                  zoomLevel:targetZoom
                   animated:NO];
  }
}

- (void)fitCoordinates:(NSArray *)coordinates
            paddingTop:(double)paddingTop
           paddingLeft:(double)paddingLeft
         paddingBottom:(double)paddingBottom
          paddingRight:(double)paddingRight
              duration:(double)duration {
  if (!_mapView || coordinates.count == 0)
    return;

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
      UIEdgeInsetsMake(paddingTop, paddingLeft, paddingBottom, paddingRight);

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

@end
