#import "AppleMapProvider.h"
#import "../LuggCalloutView.h"
#import "../LuggGroundOverlayView.h"
#import "../LuggMarkerView.h"
#import "../LuggPolygonView.h"
#import "../LuggPolylineView.h"
#import "../LuggTileOverlayView.h"
#import "../extensions/MKMapView+Zoom.h"
#import "LuggAnnotationView.h"
#import "MKPolylineAnimator.h"

@interface AppleMarkerAnnotation : NSObject <MKAnnotation>
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy, nullable) NSString *title;
@property(nonatomic, copy, nullable) NSString *subtitle;
@property(nonatomic, strong) LuggMarkerView *markerView;
@property(nonatomic, weak) MKAnnotationView *annotationView;
@property(nonatomic, copy, nullable) dispatch_block_t pendingScaleAnimation;
@end

@implementation AppleMarkerAnnotation
@end

@interface GroundImageOverlay : NSObject <MKOverlay>
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, assign) MKMapRect boundingMapRect;
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, assign) CGFloat opacity;
@end

@implementation GroundImageOverlay
@end

@interface BoundedTileOverlay : MKTileOverlay
@property(nonatomic, assign) CLLocationCoordinate2D southwest;
@property(nonatomic, assign) CLLocationCoordinate2D northeast;
@end

@implementation BoundedTileOverlay

static double tileToLat(NSInteger y, NSInteger z) {
  double n = M_PI - 2.0 * M_PI * y / pow(2.0, z);
  return 180.0 / M_PI * atan(0.5 * (exp(n) - exp(-n)));
}

static double tileToLng(NSInteger x, NSInteger z) {
  return x / pow(2.0, z) * 360.0 - 180.0;
}

- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *_Nullable, NSError *_Nullable))result {
  double tileSW_lat = tileToLat(path.y + 1, path.z);
  double tileNE_lat = tileToLat(path.y, path.z);
  double tileSW_lng = tileToLng(path.x, path.z);
  double tileNE_lng = tileToLng(path.x + 1, path.z);

  if (tileNE_lat < self.southwest.latitude ||
      tileSW_lat > self.northeast.latitude ||
      tileNE_lng < self.southwest.longitude ||
      tileSW_lng > self.northeast.longitude) {
    result(nil, nil);
    return;
  }

  [super loadTileAtPath:path result:result];
}

@end

@interface GroundImageOverlayRenderer : MKOverlayRenderer
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, assign) CGFloat overlayOpacity;
@end

@implementation GroundImageOverlayRenderer

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context {
  MKMapRect overlayRect = self.overlay.boundingMapRect;
  CGRect drawRect = [self rectForMapRect:overlayRect];

  CGContextSaveGState(context);
  CGContextSetAlpha(context, self.overlayOpacity);

  // Flip the context for UIImage drawing
  CGContextTranslateCTM(context, drawRect.origin.x,
                        drawRect.origin.y + drawRect.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);

  CGRect imageRect =
      CGRectMake(0, 0, drawRect.size.width, drawRect.size.height);
  CGContextDrawImage(context, imageRect, self.image.CGImage);

  CGContextRestoreGState(context);
}

@end

@implementation LuggAppleMapViewContent
@end

@interface AppleMapProvider () <
    LuggMarkerViewDelegate, LuggCalloutViewDelegate, LuggPolylineViewDelegate,
    LuggPolygonViewDelegate, LuggGroundOverlayViewDelegate,
    LuggTileOverlayViewDelegate, UIGestureRecognizerDelegate>
@end

@implementation AppleMapProvider {
  UIView *_wrapperView;
  LuggAppleMapViewContent *_mapView;
  BOOL _isMapReady;
  BOOL _isDragging;
  double _minZoom;
  double _maxZoom;
  NSMapTable<id<MKOverlay>, LuggPolylineView *> *_overlayToPolylineMap;
  NSMapTable<id<MKOverlay>, LuggPolygonView *> *_overlayToPolygonMap;
  NSMapTable<id<MKOverlay>, LuggGroundOverlayView *>
      *_overlayToGroundOverlayMap;
  NSMapTable<id<MKOverlay>, LuggTileOverlayView *> *_overlayToTileOverlayMap;
  UITapGestureRecognizer *_tapGesture;
  UILongPressGestureRecognizer *_longPressGesture;
  LuggMarkerView *_activeNonBubbledMarker;
  BOOL _isReselectingAnnotation;
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
    _overlayToPolylineMap = [NSMapTable strongToWeakObjectsMapTable];
    _overlayToPolygonMap = [NSMapTable strongToWeakObjectsMapTable];
    _overlayToGroundOverlayMap = [NSMapTable strongToWeakObjectsMapTable];
    _overlayToTileOverlayMap = [NSMapTable strongToWeakObjectsMapTable];
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

  _tapGesture =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handleTap:)];
  _tapGesture.cancelsTouchesInView = NO;
  _tapGesture.delegate = self;
  [_mapView addGestureRecognizer:_tapGesture];

  _longPressGesture = [[UILongPressGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(handleLongPress:)];
  _longPressGesture.delegate = self;
  [_mapView addGestureRecognizer:_longPressGesture];

  [_tapGesture requireGestureRecognizerToFail:_longPressGesture];

  _wrapperView = wrapperView;
  [wrapperView addSubview:_mapView];

  MKCoordinateRegion region = [_mapView regionForCenterCoordinate:coordinate
                                                        zoomLevel:zoom];
  [_mapView setRegion:region animated:NO];

  _isMapReady = YES;

  [_delegate mapProviderDidReady];
}

- (void)destroy {
  [self dismissNonBubbledCallout];
  [self stopEdgeInsetsAnimation];
  if (_tapGesture) {
    [_mapView removeGestureRecognizer:_tapGesture];
    _tapGesture = nil;
  }
  if (_longPressGesture) {
    [_mapView removeGestureRecognizer:_longPressGesture];
    _longPressGesture = nil;
  }
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

- (void)setTheme:(NSInteger)theme {
  switch (theme) {
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
  _minZoom = minZoom;
  [self applyZoomRange];
}

- (void)setMaxZoom:(double)maxZoom {
  _maxZoom = maxZoom;
  [self applyZoomRange];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets {
  CGFloat oldOffsetX = (oldEdgeInsets.left - oldEdgeInsets.right) / 2.0;
  CGFloat oldOffsetY = (oldEdgeInsets.top - oldEdgeInsets.bottom) / 2.0;
  CGFloat newOffsetX = (edgeInsets.left - edgeInsets.right) / 2.0;
  CGFloat newOffsetY = (edgeInsets.top - edgeInsets.bottom) / 2.0;

  CGFloat deltaX = newOffsetX - oldOffsetX;
  CGFloat deltaY = newOffsetY - oldOffsetY;

  _mapView.layoutMargins = edgeInsets;

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

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets
             duration:(double)duration {
  [self stopEdgeInsetsAnimation];

  if (duration != 0 && _mapView) {
    double actualDuration = duration < 0 ? 0.3 : duration / 1000.0;
    _edgeInsetsFrom = oldEdgeInsets;
    _edgeInsetsTo = edgeInsets;
    _edgeInsetsAnimationDuration = actualDuration;
    _edgeInsetsAnimationStart = CACurrentMediaTime();

    _edgeInsetsDisplayLink = [CADisplayLink
        displayLinkWithTarget:self
                     selector:@selector(edgeInsetsAnimationTick:)];
    [_edgeInsetsDisplayLink addToRunLoop:[NSRunLoop mainRunLoop]
                                 forMode:NSRunLoopCommonModes];
  } else {
    [self setEdgeInsets:edgeInsets oldEdgeInsets:oldEdgeInsets];
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

  [self setEdgeInsets:current oldEdgeInsets:_mapView.layoutMargins];

  if (progress >= 1.0) {
    [self stopEdgeInsetsAnimation];
  }
}

- (void)stopEdgeInsetsAnimation {
  [_edgeInsetsDisplayLink invalidate];
  _edgeInsetsDisplayLink = nil;
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

- (LuggPolygonView *)hitTestPolygonAtPoint:(CGPoint)point {
  CLLocationCoordinate2D tapCoordinate = [_mapView convertPoint:point
                                           toCoordinateFromView:_mapView];
  MKMapPoint mapPoint = MKMapPointForCoordinate(tapCoordinate);
  CGPoint mapPointAsCGP = CGPointMake(mapPoint.x, mapPoint.y);

  NSArray<id<MKOverlay>> *overlays = _mapView.overlays;
  for (NSInteger i = overlays.count - 1; i >= 0; i--) {
    id<MKOverlay> overlay = overlays[i];
    if (![overlay isKindOfClass:[MKPolygon class]])
      continue;

    LuggPolygonView *polygonView = [_overlayToPolygonMap objectForKey:overlay];
    if (!polygonView || !polygonView.tappable)
      continue;

    NSArray<CLLocation *> *coordinates = polygonView.coordinates;
    if (coordinates.count == 0)
      continue;

    CGMutablePathRef path = CGPathCreateMutable();
    for (NSUInteger j = 0; j < coordinates.count; j++) {
      MKMapPoint mp = MKMapPointForCoordinate(coordinates[j].coordinate);
      if (j == 0) {
        CGPathMoveToPoint(path, NULL, mp.x, mp.y);
      } else {
        CGPathAddLineToPoint(path, NULL, mp.x, mp.y);
      }
    }
    CGPathCloseSubpath(path);

    for (NSArray<CLLocation *> *hole in polygonView.holes) {
      for (NSUInteger j = 0; j < hole.count; j++) {
        MKMapPoint mp = MKMapPointForCoordinate(hole[j].coordinate);
        if (j == 0) {
          CGPathMoveToPoint(path, NULL, mp.x, mp.y);
        } else {
          CGPathAddLineToPoint(path, NULL, mp.x, mp.y);
        }
      }
      CGPathCloseSubpath(path);
    }

    BOOL contains = CGPathContainsPoint(path, NULL, mapPointAsCGP, YES);
    CGPathRelease(path);

    if (contains)
      return polygonView;
  }
  return nil;
}

- (LuggGroundOverlayView *)hitTestGroundOverlayAtPoint:(CGPoint)point {
  CLLocationCoordinate2D tapCoordinate = [_mapView convertPoint:point
                                           toCoordinateFromView:_mapView];

  NSArray<id<MKOverlay>> *overlays = _mapView.overlays;
  for (NSInteger i = overlays.count - 1; i >= 0; i--) {
    id<MKOverlay> overlay = overlays[i];
    if (![overlay isKindOfClass:[GroundImageOverlay class]])
      continue;

    LuggGroundOverlayView *view =
        [_overlayToGroundOverlayMap objectForKey:overlay];
    if (!view || !view.tappable)
      continue;

    MKMapPoint mapPoint = MKMapPointForCoordinate(tapCoordinate);
    if (MKMapRectContainsPoint(overlay.boundingMapRect, mapPoint))
      return view;
  }
  return nil;
}

- (BOOL)hitTestAnnotationAtPoint:(CGPoint)point {
  for (id<MKAnnotation> annotation in _mapView.annotations) {
    MKAnnotationView *view = [_mapView viewForAnnotation:annotation];
    if (!view)
      continue;
    CGPoint local = [view convertPoint:point fromView:_mapView];
    if ([view pointInside:local withEvent:nil])
      return YES;
  }
  return NO;
}

- (BOOL)hitTestCalloutAtPoint:(CGPoint)point {
  if (!_activeNonBubbledMarker)
    return NO;

  UIView *contentView = _activeNonBubbledMarker.calloutView.contentView;
  CGPoint local = [contentView convertPoint:point fromView:_mapView];
  return [contentView pointInside:local withEvent:nil];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  if (gesture.state != UIGestureRecognizerStateEnded)
    return;

  CGPoint point = [gesture locationInView:_mapView];
  if ([self hitTestCalloutAtPoint:point])
    return;

  [self dismissNonBubbledCallout];

  if ([self hitTestAnnotationAtPoint:point])
    return;

  LuggGroundOverlayView *groundOverlayView =
      [self hitTestGroundOverlayAtPoint:point];
  if (groundOverlayView) {
    [groundOverlayView emitPressEvent];
    return;
  }

  LuggPolygonView *polygonView = [self hitTestPolygonAtPoint:point];
  if (polygonView) {
    [polygonView emitPressEvent];
  } else {
    CLLocationCoordinate2D coordinate = [_mapView convertPoint:point
                                          toCoordinateFromView:_mapView];
    [_delegate mapProviderDidPress:coordinate.latitude
                         longitude:coordinate.longitude
                                 x:point.x
                                 y:point.y];
  }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
  if (gesture.state != UIGestureRecognizerStateBegan)
    return;

  CGPoint point = [gesture locationInView:_mapView];
  CLLocationCoordinate2D coordinate = [_mapView convertPoint:point
                                        toCoordinateFromView:_mapView];
  [_delegate mapProviderDidLongPress:coordinate.latitude
                           longitude:coordinate.longitude
                                   x:point.x
                                   y:point.y];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
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
  [self positionNonBubbledCallout];
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

  if (!markerView) {
    return nil;
  }

  if (!markerView.hasCustomView) {
    LuggMarkerAnnotationView *markerAnnotationView =
        [[LuggMarkerAnnotationView alloc] initWithAnnotation:annotation
                                             reuseIdentifier:nil];
    markerAnnotationView.canShowCallout = YES;
    markerAnnotationView.displayPriority = MKFeatureDisplayPriorityRequired;
    markerAnnotationView.layer.zPosition = markerView.zIndex;
    markerAnnotationView.zPriority = markerView.zIndex;
    markerAnnotationView.draggable = markerView.draggable;
    [self applyCalloutView:markerView annotationView:markerAnnotationView];
    [self addCenterTapGesture:markerAnnotationView];
    markerAnnotation.annotationView = markerAnnotationView;
    return markerAnnotationView;
  }

  LuggAnnotationView *annotationView =
      [[LuggAnnotationView alloc] initWithAnnotation:annotation
                                     reuseIdentifier:nil];
  annotationView.canShowCallout = YES;
  annotationView.displayPriority = MKFeatureDisplayPriorityRequired;
  annotationView.layer.zPosition = markerView.zIndex;
  annotationView.zPriority = markerView.zIndex;
  annotationView.draggable = markerView.draggable;
  [self addCenterTapGesture:annotationView];

  [self applyCalloutView:markerView annotationView:annotationView];

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

  if ([overlay isKindOfClass:[MKPolygon class]]) {
    LuggPolygonView *polygonView = [_overlayToPolygonMap objectForKey:overlay];
    MKPolygon *polygon = (MKPolygon *)overlay;

    MKPolygonRenderer *renderer =
        [[MKPolygonRenderer alloc] initWithPolygon:polygon];
    if (polygonView) {
      renderer.fillColor = polygonView.fillColor;
      renderer.strokeColor = polygonView.strokeColor;
      renderer.lineWidth = polygonView.strokeWidth;
      polygonView.renderer = renderer;
    }
    return renderer;
  }

  if ([overlay isKindOfClass:[GroundImageOverlay class]]) {
    GroundImageOverlay *groundOverlay = (GroundImageOverlay *)overlay;
    GroundImageOverlayRenderer *renderer =
        [[GroundImageOverlayRenderer alloc] initWithOverlay:overlay];
    renderer.image = groundOverlay.image;
    renderer.overlayOpacity = groundOverlay.opacity;
    return renderer;
  }

  if ([overlay isKindOfClass:[MKTileOverlay class]]) {
    MKTileOverlay *tileOverlay = (MKTileOverlay *)overlay;
    MKTileOverlayRenderer *renderer =
        [[MKTileOverlayRenderer alloc] initWithTileOverlay:tileOverlay];
    return renderer;
  }

  return nil;
}

- (void)mapView:(MKMapView *)mapView
    didSelectAnnotationView:(MKAnnotationView *)view {
  if (![view.annotation isKindOfClass:[AppleMarkerAnnotation class]])
    return;

  AppleMarkerAnnotation *annotation = (AppleMarkerAnnotation *)view.annotation;
  LuggMarkerView *markerView = annotation.markerView;

  if (markerView) {
    CGPoint point = [_mapView convertCoordinate:markerView.coordinate
                                  toPointToView:_mapView];
    [markerView emitPressEventWithPoint:point];

    LuggCalloutView *calloutView = markerView.calloutView;
    if (calloutView && !calloutView.bubbled && calloutView.hasCustomContent) {
      [self showNonBubbledCallout:markerView];
    }
  }
}

- (void)mapView:(MKMapView *)mapView
    didDeselectAnnotationView:(MKAnnotationView *)view {
  if (![view.annotation isKindOfClass:[AppleMarkerAnnotation class]])
    return;

  AppleMarkerAnnotation *annotation = (AppleMarkerAnnotation *)view.annotation;
  LuggMarkerView *markerView = annotation.markerView;

  if (markerView && _activeNonBubbledMarker == markerView &&
      !_isReselectingAnnotation) {
    _isReselectingAnnotation = YES;
    [_mapView selectAnnotation:annotation animated:NO];
    _isReselectingAnnotation = NO;
  }
}

- (void)showNonBubbledCallout:(LuggMarkerView *)markerView {
  [self dismissNonBubbledCallout];

  LuggCalloutView *calloutView = markerView.calloutView;
  UIView *contentView = calloutView.contentView;
  [contentView removeFromSuperview];

  contentView.userInteractionEnabled = YES;
  contentView.hidden = YES;
  calloutView.delegate = self;

  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)markerView.marker;
  MKAnnotationView *annotationView = annotation.annotationView;
  if (annotationView) {
    annotationView.clipsToBounds = NO;
    [annotationView addSubview:contentView];
  } else {
    [_wrapperView addSubview:contentView];
  }

  _activeNonBubbledMarker = markerView;
  [self positionNonBubbledCallout];
}

- (void)calloutViewDidUpdate:(LuggCalloutView *)calloutView {
  [self positionNonBubbledCallout];
}

- (void)positionNonBubbledCallout {
  if (!_activeNonBubbledMarker)
    return;

  LuggCalloutView *calloutView = _activeNonBubbledMarker.calloutView;
  UIView *contentView = calloutView.contentView;
  CGSize contentSize = contentView.bounds.size;
  if (contentSize.width <= 0 || contentSize.height <= 0)
    return;

  CGPoint anchor = calloutView.anchor;

  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)_activeNonBubbledMarker.marker;
  MKAnnotationView *annotationView = annotation.annotationView;

  if (annotationView && contentView.superview == annotationView) {
    CGPoint center = CGPointMake(annotationView.bounds.size.width / 2.0 +
                                     contentSize.width * (0.5 - anchor.x),
                                 contentSize.height * (0.5 - anchor.y));
    contentView.center = center;
  } else {
    CGPoint point =
        [_mapView convertCoordinate:_activeNonBubbledMarker.coordinate
                      toPointToView:_wrapperView];
    contentView.center =
        CGPointMake(point.x + contentSize.width * (0.5 - anchor.x),
                    point.y + contentSize.height * (0.5 - anchor.y));
  }

  contentView.hidden = NO;
}

- (void)dismissNonBubbledCallout {
  if (!_activeNonBubbledMarker)
    return;

  LuggMarkerView *markerView = _activeNonBubbledMarker;
  _activeNonBubbledMarker = nil;

  markerView.calloutView.delegate = nil;
  [markerView.calloutView.contentView removeFromSuperview];

  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)markerView.marker;
  if (annotation) {
    [_mapView deselectAnnotation:annotation animated:NO];
  }
}

- (void)mapView:(MKMapView *)mapView
        annotationView:(MKAnnotationView *)view
    didChangeDragState:(MKAnnotationViewDragState)newState
          fromOldState:(MKAnnotationViewDragState)oldState {
  if (![view.annotation isKindOfClass:[AppleMarkerAnnotation class]])
    return;

  AppleMarkerAnnotation *annotation = (AppleMarkerAnnotation *)view.annotation;
  LuggMarkerView *markerView = annotation.markerView;
  if (!markerView)
    return;

  CLLocationCoordinate2D coord = annotation.coordinate;
  CGPoint point = [_mapView convertCoordinate:coord toPointToView:_mapView];

  switch (newState) {
  case MKAnnotationViewDragStateStarting:
    [markerView updateCoordinate:coord];
    [markerView emitDragStartEventWithPoint:point];
    [view setDragState:MKAnnotationViewDragStateDragging animated:YES];
    break;
  case MKAnnotationViewDragStateDragging:
    [markerView updateCoordinate:coord];
    [markerView emitDragChangeEventWithPoint:point];
    break;
  case MKAnnotationViewDragStateEnding:
    [markerView updateCoordinate:coord];
    [markerView emitDragEndEventWithPoint:point];
    [view setDragState:MKAnnotationViewDragStateNone animated:YES];
    break;
  case MKAnnotationViewDragStateCanceling:
    [view setDragState:MKAnnotationViewDragStateNone animated:YES];
    break;
  default:
    break;
  }
}

- (void)addCenterTapGesture:(MKAnnotationView *)view {
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(handleAnnotationTap:)];
  tap.cancelsTouchesInView = NO;
  [view addGestureRecognizer:tap];
}

- (void)handleAnnotationTap:(UITapGestureRecognizer *)gesture {
  MKAnnotationView *view = (MKAnnotationView *)gesture.view;
  if ([view.annotation isKindOfClass:[AppleMarkerAnnotation class]]) {
    AppleMarkerAnnotation *annotation =
        (AppleMarkerAnnotation *)view.annotation;
    [_mapView setCenterCoordinate:annotation.coordinate animated:YES];
  }
}

- (void)applyCalloutView:(LuggMarkerView *)markerView
          annotationView:(MKAnnotationView *)annotationView {
  LuggCalloutView *calloutView = markerView.calloutView;
  if (!calloutView) {
    annotationView.detailCalloutAccessoryView = nil;
    annotationView.rightCalloutAccessoryView = nil;
    return;
  }

  annotationView.rightCalloutAccessoryView = nil;

  if (!calloutView.bubbled) {
    annotationView.canShowCallout = NO;
    annotationView.detailCalloutAccessoryView = nil;
    return;
  }

  annotationView.detailCalloutAccessoryView =
      calloutView.hasCustomContent ? calloutView.contentView : nil;
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
    annotationView.draggable = markerView.draggable;
    annotationView.layer.zPosition = markerView.zIndex;
    annotationView.zPriority = markerView.zIndex;
    [self applyCalloutView:markerView annotationView:annotationView];
  }

  [self updateAnnotationViewFrame:annotation];
}

#pragma mark - PolylineViewDelegate

- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView {
  [self syncPolylineView:polylineView];
}

#pragma mark - PolygonViewDelegate

- (void)polygonViewDidUpdate:(LuggPolygonView *)polygonView {
  [self syncPolygonView:polygonView];
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
    if (annotation.pendingScaleAnimation) {
      dispatch_block_cancel(annotation.pendingScaleAnimation);
      annotation.pendingScaleAnimation = nil;
    }
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
  iconView.transform = CGAffineTransformIdentity;

  // Clean up iconView from in-progress rasterize animation
  if (markerView.rasterize && [iconView superview] == annotationView) {
    [iconView removeFromSuperview];
    iconView.layer.anchorPoint = CGPointMake(0.5, 0.5);
  }

  CGSize size = iconView.bounds.size;
  if (size.width <= 0 || size.height <= 0)
    return;

  CGFloat scale = markerView.scale;
  CGPoint anchor = markerView.anchor;
  CGFloat scaledWidth = size.width * scale;
  CGFloat scaledHeight = size.height * scale;

  AppleMarkerAnnotation *annotation =
      (AppleMarkerAnnotation *)markerView.marker;

  // Cancel any pending rasterize
  if (annotation.pendingScaleAnimation) {
    dispatch_block_cancel(annotation.pendingScaleAnimation);
    annotation.pendingScaleAnimation = nil;
  }

  // Use live iconView during rapid updates (skip expensive rasterize per frame)
  if (markerView.rasterize && [iconView superview] != annotationView) {
    annotationView.image = nil;
    [annotationView addSubview:iconView];
  }

  iconView.layer.anchorPoint = anchor;
  iconView.bounds = CGRectMake(0, 0, size.width, size.height);
  iconView.center =
      CGPointMake(scaledWidth * anchor.x, scaledHeight * anchor.y);
  iconView.transform = CGAffineTransformMakeScale(scale, scale);

  annotationView.bounds = CGRectMake(0, 0, scaledWidth, scaledHeight);
  annotationView.centerOffset = CGPointMake(scaledWidth * (0.5 - anchor.x),
                                            scaledHeight * (0.5 - anchor.y));
  annotationView.transform =
      CGAffineTransformMakeRotation(markerView.rotate * M_PI / 180.0);

  // Debounce: rasterize once updates settle
  if (markerView.rasterize) {
    dispatch_block_t rasterizeBlock =
        dispatch_block_create((dispatch_block_flags_t)0, ^{
          annotation.pendingScaleAnimation = nil;
          annotationView.image = [markerView createScaledIconImage];
          [iconView removeFromSuperview];
          [markerView resetIconViewTransform];
        });

    annotation.pendingScaleAnimation = rasterizeBlock;
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(150 * NSEC_PER_MSEC)),
        dispatch_get_main_queue(), rasterizeBlock);
  }
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

#pragma mark - Polygon Management

- (void)addPolygonView:(LuggPolygonView *)polygonView {
  polygonView.delegate = self;
  [self addPolygonOverlayToMap:polygonView];
}

- (void)removePolygonView:(LuggPolygonView *)polygonView {
  polygonView.delegate = nil;
  MKPolygon *polygon = (MKPolygon *)polygonView.polygon;
  if (polygon) {
    [_overlayToPolygonMap removeObjectForKey:polygon];
    [_mapView removeOverlay:polygon];
    polygonView.polygon = nil;
  }
}

- (void)syncPolygonView:(LuggPolygonView *)polygonView {
  if (!_mapView)
    return;

  MKPolygon *oldPolygon = (MKPolygon *)polygonView.polygon;

  NSArray<CLLocation *> *coordinates = polygonView.coordinates;
  if (coordinates.count == 0) {
    if (oldPolygon) {
      [_overlayToPolygonMap removeObjectForKey:oldPolygon];
      [_mapView removeOverlay:oldPolygon];
      polygonView.polygon = nil;
      polygonView.renderer = nil;
    }
    return;
  }

  CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(
      sizeof(CLLocationCoordinate2D) * coordinates.count);
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    coords[i] = coordinates[i].coordinate;
  }
  NSArray<MKPolygon *> *interiorPolygons =
      [self interiorPolygonsFromHoles:polygonView.holes];
  MKPolygon *newPolygon = [MKPolygon polygonWithCoordinates:coords
                                                      count:coordinates.count
                                           interiorPolygons:interiorPolygons];
  free(coords);

  polygonView.polygon = newPolygon;
  [_overlayToPolygonMap setObject:polygonView forKey:newPolygon];

  MKPolygonRenderer *renderer = (MKPolygonRenderer *)polygonView.renderer;
  if (renderer && oldPolygon) {
    [_overlayToPolygonMap removeObjectForKey:oldPolygon];
    [_mapView removeOverlay:oldPolygon];
    [self insertOverlay:newPolygon withZIndex:polygonView.zIndex];
    polygonView.renderer = nil;
    return;
  }

  if (oldPolygon) {
    [_overlayToPolygonMap removeObjectForKey:oldPolygon];
    [_mapView removeOverlay:oldPolygon];
  }
  [self insertOverlay:newPolygon withZIndex:polygonView.zIndex];
}

- (void)addPolygonOverlayToMap:(LuggPolygonView *)polygonView {
  if (!_mapView)
    return;

  NSArray<CLLocation *> *coordinates = polygonView.coordinates;
  if (coordinates.count == 0)
    return;

  CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(
      sizeof(CLLocationCoordinate2D) * coordinates.count);
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    coords[i] = coordinates[i].coordinate;
  }

  NSArray<MKPolygon *> *interiorPolygons =
      [self interiorPolygonsFromHoles:polygonView.holes];
  MKPolygon *polygon = [MKPolygon polygonWithCoordinates:coords
                                                   count:coordinates.count
                                        interiorPolygons:interiorPolygons];
  free(coords);

  polygonView.polygon = polygon;
  [_overlayToPolygonMap setObject:polygonView forKey:polygon];
  [self insertOverlay:polygon withZIndex:polygonView.zIndex];
}

- (NSArray<MKPolygon *> *)interiorPolygonsFromHoles:
    (NSArray<NSArray<CLLocation *> *> *)holes {
  if (holes.count == 0)
    return @[];

  NSMutableArray<MKPolygon *> *interiorPolygons = [NSMutableArray array];
  for (NSArray<CLLocation *> *hole in holes) {
    if (hole.count == 0)
      continue;
    CLLocationCoordinate2D *holeCoords = (CLLocationCoordinate2D *)malloc(
        sizeof(CLLocationCoordinate2D) * hole.count);
    for (NSUInteger i = 0; i < hole.count; i++) {
      holeCoords[i] = hole[i].coordinate;
    }
    MKPolygon *interiorPolygon = [MKPolygon polygonWithCoordinates:holeCoords
                                                             count:hole.count];
    free(holeCoords);
    [interiorPolygons addObject:interiorPolygon];
  }
  return [interiorPolygons copy];
}

#pragma mark - Ground Overlay Management

- (void)addGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  groundOverlayView.delegate = self;
  [self syncGroundOverlayView:groundOverlayView];
}

- (void)removeGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  groundOverlayView.delegate = nil;
  GroundImageOverlay *overlay = (GroundImageOverlay *)groundOverlayView.overlay;
  if (overlay) {
    [_overlayToGroundOverlayMap removeObjectForKey:overlay];
    [_mapView removeOverlay:overlay];
    groundOverlayView.overlay = nil;
  }
}

- (void)syncGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  if (!_mapView)
    return;

  NSString *imageUri = groundOverlayView.imageUri;
  if (imageUri.length == 0)
    return;

  // Remove old overlay
  GroundImageOverlay *oldOverlay =
      (GroundImageOverlay *)groundOverlayView.overlay;
  if (oldOverlay) {
    [_overlayToGroundOverlayMap removeObjectForKey:oldOverlay];
    [_mapView removeOverlay:oldOverlay];
    groundOverlayView.overlay = nil;
  }

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

  MKMapPoint sw = MKMapPointForCoordinate(groundOverlayView.southwest);
  MKMapPoint ne = MKMapPointForCoordinate(groundOverlayView.northeast);

  MKMapRect mapRect = MKMapRectMake(MIN(sw.x, ne.x), MIN(sw.y, ne.y),
                                    fabs(ne.x - sw.x), fabs(ne.y - sw.y));

  CLLocationCoordinate2D center =
      CLLocationCoordinate2DMake((groundOverlayView.northeast.latitude +
                                  groundOverlayView.southwest.latitude) /
                                     2.0,
                                 (groundOverlayView.northeast.longitude +
                                  groundOverlayView.southwest.longitude) /
                                     2.0);

  GroundImageOverlay *overlay = [[GroundImageOverlay alloc] init];
  overlay.coordinate = center;
  overlay.boundingMapRect = mapRect;
  overlay.image = image;
  overlay.opacity = groundOverlayView.opacity;

  groundOverlayView.overlay = overlay;
  [_overlayToGroundOverlayMap setObject:groundOverlayView forKey:overlay];
  [self insertOverlay:overlay withZIndex:groundOverlayView.zIndex];
}

#pragma mark - Tile Overlay Management

- (void)addTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
  tileOverlayView.delegate = self;
  [self syncTileOverlayView:tileOverlayView];
}

- (void)removeTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
  tileOverlayView.delegate = nil;
  MKTileOverlay *overlay = (MKTileOverlay *)tileOverlayView.overlay;
  if (overlay) {
    [_overlayToTileOverlayMap removeObjectForKey:overlay];
    [_mapView removeOverlay:overlay];
    tileOverlayView.overlay = nil;
  }
}

- (void)syncTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
  if (!_mapView)
    return;

  NSString *urlTemplate = tileOverlayView.urlTemplate;
  if (urlTemplate.length == 0)
    return;

  // Remove old overlay
  MKTileOverlay *oldOverlay = (MKTileOverlay *)tileOverlayView.overlay;
  if (oldOverlay) {
    [_overlayToTileOverlayMap removeObjectForKey:oldOverlay];
    [_mapView removeOverlay:oldOverlay];
    tileOverlayView.overlay = nil;
  }

  MKTileOverlay *tileOverlay;
  if (tileOverlayView.hasBounds) {
    BoundedTileOverlay *bounded =
        [[BoundedTileOverlay alloc] initWithURLTemplate:urlTemplate];
    bounded.southwest = tileOverlayView.southwest;
    bounded.northeast = tileOverlayView.northeast;
    tileOverlay = bounded;
  } else {
    tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:urlTemplate];
  }

  tileOverlay.tileSize =
      CGSizeMake(tileOverlayView.tileSize, tileOverlayView.tileSize);
  tileOverlay.canReplaceMapContent = NO;

  tileOverlayView.overlay = tileOverlay;
  [_overlayToTileOverlayMap setObject:tileOverlayView forKey:tileOverlay];
  [_mapView addOverlay:tileOverlay level:MKOverlayLevelAboveRoads];
}

- (void)insertOverlay:(id<MKOverlay>)overlay withZIndex:(NSInteger)zIndex {
  if (zIndex == 0) {
    [_mapView addOverlay:overlay];
    return;
  }

  NSArray<id<MKOverlay>> *overlays = _mapView.overlays;
  NSInteger insertIndex = overlays.count;

  for (NSInteger i = 0; i < overlays.count; i++) {
    NSInteger existingZIndex = 0;
    LuggPolylineView *existingPolylineView =
        [_overlayToPolylineMap objectForKey:overlays[i]];
    LuggPolygonView *existingPolygonView =
        [_overlayToPolygonMap objectForKey:overlays[i]];
    LuggGroundOverlayView *existingGroundOverlayView =
        [_overlayToGroundOverlayMap objectForKey:overlays[i]];
    if (existingPolylineView) {
      existingZIndex = existingPolylineView.zIndex;
    } else if (existingPolygonView) {
      existingZIndex = existingPolygonView.zIndex;
    } else if (existingGroundOverlayView) {
      existingZIndex = existingGroundOverlayView.zIndex;
    } else {
      continue;
    }
    if (existingZIndex > zIndex) {
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
         edgeInsetsTop:(double)edgeInsetsTop
        edgeInsetsLeft:(double)edgeInsetsLeft
      edgeInsetsBottom:(double)edgeInsetsBottom
       edgeInsetsRight:(double)edgeInsetsRight
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

  UIEdgeInsets insets = UIEdgeInsetsMake(edgeInsetsTop, edgeInsetsLeft,
                                         edgeInsetsBottom, edgeInsetsRight);

  if (duration < 0) {
    [_mapView setVisibleMapRect:mapRect edgePadding:insets animated:YES];
  } else if (duration > 0) {
    [UIView animateWithDuration:duration / 1000.0
                     animations:^{
                       [self->_mapView setVisibleMapRect:mapRect
                                             edgePadding:insets
                                                animated:NO];
                     }];
  } else {
    [_mapView setVisibleMapRect:mapRect edgePadding:insets animated:NO];
  }
}

@end
