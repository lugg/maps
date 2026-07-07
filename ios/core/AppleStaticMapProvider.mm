#import "AppleStaticMapProvider.h"

using facebook::react::LuggMapViewInsetAdjustment;
using facebook::react::LuggMapViewMapType;
using facebook::react::LuggMapViewPoiFilterMode;
using facebook::react::LuggMapViewTheme;

#import "../LuggCircleView.h"
#import "../LuggGroundOverlayView.h"
#import "../LuggMapWrapperView.h"
#import "../LuggMarkerView.h"
#import "../LuggPolygonView.h"
#import "../LuggPolylineView.h"
#import "../extensions/MKMapView+Zoom.h"
#import "AppleMapProvider.h"
#import "LuggAnnotationView.h"

// Standard MKMarkerAnnotationView balloon size; standalone (off-map) views
// don't size themselves
static const CGSize kDefaultMarkerSize = {28, 33};

#pragma mark - Projection

// The rect the snapshot renders: the region for the requested zoom, expanded
// on the short axis to the view's aspect ratio - the same fit MKMapView
// applies in setRegion, so static and live maps frame alike. Passing this
// exact rect to MKMapSnapshotter makes the projection below exact.
static MKMapRect LuggStaticFittedMapRect(CLLocationCoordinate2D center,
                                         double zoom, CGSize size) {
  MKCoordinateSpan span = LuggCoordinateSpanForZoomLevel(MIN(zoom, 28), center);
  MKMapPoint topLeft = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
      MIN(center.latitude + span.latitudeDelta / 2, 90.0),
      center.longitude - span.longitudeDelta / 2));
  MKMapPoint bottomRight = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
      MAX(center.latitude - span.latitudeDelta / 2, -90.0),
      center.longitude + span.longitudeDelta / 2));
  MKMapRect rect =
      MKMapRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x,
                    bottomRight.y - topLeft.y);

  double viewAspect = size.width / size.height;
  double rectAspect = rect.size.width / rect.size.height;
  if (rectAspect > viewAspect) {
    double height = rect.size.width / viewAspect;
    rect.origin.y -= (height - rect.size.height) / 2;
    rect.size.height = height;
  } else {
    double width = rect.size.height * viewAspect;
    rect.origin.x -= (width - rect.size.width) / 2;
    rect.size.width = width;
  }
  return rect;
}

static CGPoint LuggStaticPointForCoordinate(MKMapRect mapRect, CGSize size,
                                            CLLocationCoordinate2D coordinate) {
  MKMapPoint point = MKMapPointForCoordinate(coordinate);
  return CGPointMake(
      (point.x - mapRect.origin.x) / mapRect.size.width * size.width,
      (point.y - mapRect.origin.y) / mapRect.size.height * size.height);
}

#pragma mark - Shape overlay

// Draws polylines, polygons, circles and ground overlays over the base
// snapshot with CoreGraphics; MKMapSnapshotter renders map tiles only
@interface LuggStaticShapeOverlayView : UIView
@property(nonatomic, assign) MKMapRect mapRect;
@property(nonatomic, assign) BOOL projectionReady;
@property(nonatomic, strong) NSMutableArray<LuggPolylineView *> *polylineViews;
@property(nonatomic, strong) NSMutableArray<LuggPolygonView *> *polygonViews;
@property(nonatomic, strong) NSMutableArray<LuggCircleView *> *circleViews;
@property(nonatomic, strong)
    NSMutableArray<LuggGroundOverlayView *> *groundOverlayViews;
@property(nonatomic, strong)
    NSMapTable<LuggGroundOverlayView *, UIImage *> *groundOverlayImages;
@end

@implementation LuggStaticShapeOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.opaque = NO;
    self.backgroundColor = UIColor.clearColor;
    self.userInteractionEnabled = NO;
    self.contentMode = UIViewContentModeRedraw;
    _polylineViews = [NSMutableArray array];
    _polygonViews = [NSMutableArray array];
    _circleViews = [NSMutableArray array];
    _groundOverlayViews = [NSMutableArray array];
    _groundOverlayImages = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

static NSInteger shapeZIndex(UIView *shape) {
  if ([shape isKindOfClass:[LuggPolylineView class]])
    return ((LuggPolylineView *)shape).zIndex;
  if ([shape isKindOfClass:[LuggPolygonView class]])
    return ((LuggPolygonView *)shape).zIndex;
  if ([shape isKindOfClass:[LuggCircleView class]])
    return ((LuggCircleView *)shape).zIndex;
  if ([shape isKindOfClass:[LuggGroundOverlayView class]])
    return ((LuggGroundOverlayView *)shape).zIndex;
  return 0;
}

- (CGPoint)pointForCoordinate:(CLLocationCoordinate2D)coordinate {
  return LuggStaticPointForCoordinate(_mapRect, self.bounds.size, coordinate);
}

- (void)addPath:(CGContextRef)context
           ring:(NSArray<CLLocation *> *)coordinates {
  for (NSUInteger i = 0; i < coordinates.count; i++) {
    CGPoint point = [self pointForCoordinate:coordinates[i].coordinate];
    if (i == 0) {
      CGContextMoveToPoint(context, point.x, point.y);
    } else {
      CGContextAddLineToPoint(context, point.x, point.y);
    }
  }
}

- (void)drawPolyline:(LuggPolylineView *)polylineView
           inContext:(CGContextRef)context {
  NSArray<CLLocation *> *coordinates = polylineView.coordinates;
  UIColor *color = polylineView.strokeColors.firstObject;
  if (coordinates.count < 2 || !color || polylineView.strokeWidth <= 0)
    return;

  CGContextSaveGState(context);
  [self addPath:context ring:coordinates];
  CGContextSetLineWidth(context, polylineView.strokeWidth);
  CGContextSetLineCap(context, kCGLineCapRound);
  CGContextSetLineJoin(context, kCGLineJoinRound);
  CGContextSetStrokeColorWithColor(context, color.CGColor);
  CGContextStrokePath(context);
  CGContextRestoreGState(context);
}

- (void)drawPolygon:(LuggPolygonView *)polygonView
          inContext:(CGContextRef)context {
  NSArray<CLLocation *> *coordinates = polygonView.coordinates;
  if (coordinates.count < 3)
    return;

  CGContextSaveGState(context);

  if (polygonView.fillColor) {
    [self addPath:context ring:coordinates];
    CGContextClosePath(context);
    for (NSArray<CLLocation *> *hole in polygonView.holes) {
      [self addPath:context ring:hole];
      CGContextClosePath(context);
    }
    CGContextSetFillColorWithColor(context, polygonView.fillColor.CGColor);
    CGContextEOFillPath(context);
  }

  if (polygonView.strokeColor && polygonView.strokeWidth > 0) {
    [self addPath:context ring:coordinates];
    CGContextClosePath(context);
    for (NSArray<CLLocation *> *hole in polygonView.holes) {
      [self addPath:context ring:hole];
      CGContextClosePath(context);
    }
    CGContextSetLineWidth(context, polygonView.strokeWidth);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetStrokeColorWithColor(context, polygonView.strokeColor.CGColor);
    CGContextStrokePath(context);
  }

  CGContextRestoreGState(context);
}

- (void)drawCircle:(LuggCircleView *)circleView
         inContext:(CGContextRef)context {
  if (circleView.radius <= 0)
    return;

  CGPoint center = [self pointForCoordinate:circleView.center];
  double pointsPerMapPoint = self.bounds.size.width / _mapRect.size.width;
  double radius = circleView.radius *
                  MKMapPointsPerMeterAtLatitude(circleView.center.latitude) *
                  pointsPerMapPoint;
  CGRect ellipse =
      CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2);

  CGContextSaveGState(context);
  if (circleView.fillColor) {
    CGContextSetFillColorWithColor(context, circleView.fillColor.CGColor);
    CGContextFillEllipseInRect(context, ellipse);
  }
  if (circleView.strokeColor && circleView.strokeWidth > 0) {
    CGContextSetLineWidth(context, circleView.strokeWidth);
    CGContextSetStrokeColorWithColor(context, circleView.strokeColor.CGColor);
    CGContextStrokeEllipseInRect(context, ellipse);
  }
  CGContextRestoreGState(context);
}

- (void)drawGroundOverlay:(LuggGroundOverlayView *)groundOverlayView {
  UIImage *image = [_groundOverlayImages objectForKey:groundOverlayView];
  if (!image)
    return;

  CGPoint topLeft =
      [self pointForCoordinate:CLLocationCoordinate2DMake(
                                   groundOverlayView.northeast.latitude,
                                   groundOverlayView.southwest.longitude)];
  CGPoint bottomRight =
      [self pointForCoordinate:CLLocationCoordinate2DMake(
                                   groundOverlayView.southwest.latitude,
                                   groundOverlayView.northeast.longitude)];
  CGRect rect = CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x,
                           bottomRight.y - topLeft.y);
  [image drawInRect:rect
          blendMode:kCGBlendModeNormal
              alpha:groundOverlayView.opacity];
}

- (void)drawRect:(CGRect)rect {
  if (!_projectionReady)
    return;

  CGContextRef context = UIGraphicsGetCurrentContext();
  if (!context)
    return;

  NSMutableArray<UIView *> *shapes = [NSMutableArray array];
  [shapes addObjectsFromArray:_groundOverlayViews];
  [shapes addObjectsFromArray:_polygonViews];
  [shapes addObjectsFromArray:_circleViews];
  [shapes addObjectsFromArray:_polylineViews];
  NSArray<UIView *> *ordered =
      [shapes sortedArrayWithOptions:NSSortStable
                     usingComparator:^NSComparisonResult(UIView *a, UIView *b) {
                       NSInteger za = shapeZIndex(a), zb = shapeZIndex(b);
                       if (za < zb)
                         return NSOrderedAscending;
                       if (za > zb)
                         return NSOrderedDescending;
                       return NSOrderedSame;
                     }];

  for (UIView *shape in ordered) {
    if ([shape isKindOfClass:[LuggGroundOverlayView class]]) {
      [self drawGroundOverlay:(LuggGroundOverlayView *)shape];
    } else if ([shape isKindOfClass:[LuggPolygonView class]]) {
      [self drawPolygon:(LuggPolygonView *)shape inContext:context];
    } else if ([shape isKindOfClass:[LuggCircleView class]]) {
      [self drawCircle:(LuggCircleView *)shape inContext:context];
    } else if ([shape isKindOfClass:[LuggPolylineView class]]) {
      [self drawPolyline:(LuggPolylineView *)shape inContext:context];
    }
  }
}

@end

#pragma mark - Provider

@interface AppleStaticMapProvider () <
    LuggMarkerViewDelegate, LuggPolylineViewDelegate, LuggPolygonViewDelegate,
    LuggCircleViewDelegate, LuggGroundOverlayViewDelegate>
@end

@implementation AppleStaticMapProvider {
  UIView *_wrapperView;
  CLLocationCoordinate2D _coordinate;
  double _zoom;
  BOOL _isMapReady;

  MKMapRect _mapRect;
  CGSize _projectedSize;
  BOOL _projectionReady;

  MKMapSnapshotter *_snapshotter;
  UIImageView *_baseImageView;
  BOOL _snapshotDone;

  LuggStaticShapeOverlayView *_shapeOverlayView;
  NSMutableArray<LuggMarkerView *> *_markerViews;
  NSMapTable<LuggMarkerView *, MKAnnotationView *> *_defaultMarkerOverlays;

  LuggMapViewMapType _mapType;
  LuggMapViewTheme _theme;
  BOOL _poiEnabled;
  LuggMapViewPoiFilterMode _poiFilterMode;
  NSArray<NSString *> *_poiFilterCategories;
}

@synthesize delegate = _delegate;
@synthesize staticMode = _staticMode;

- (instancetype)init {
  if (self = [super init]) {
    _markerViews = [NSMutableArray array];
    _defaultMarkerOverlays = [NSMapTable weakToStrongObjectsMapTable];
    _mapType = LuggMapViewMapType::Standard;
    _theme = LuggMapViewTheme::System;
    _poiEnabled = YES;
    _poiFilterMode = LuggMapViewPoiFilterMode::Including;
    _poiFilterCategories = @[];
  }
  return self;
}

- (BOOL)isMapReady {
  return _isMapReady;
}

#pragma mark - MapProvider

- (void)initializeMapInView:(UIView *)wrapperView
          initialCoordinate:(CLLocationCoordinate2D)coordinate
                initialZoom:(double)zoom {
  if (_wrapperView)
    return;

  _wrapperView = wrapperView;
  _coordinate = coordinate;
  _zoom = zoom;

  _shapeOverlayView =
      [[LuggStaticShapeOverlayView alloc] initWithFrame:wrapperView.bounds];
  _shapeOverlayView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [wrapperView addSubview:_shapeOverlayView];

  [self updateProjection];

  __weak AppleStaticMapProvider *weakSelf = self;
  if ([wrapperView isKindOfClass:[LuggMapWrapperView class]]) {
    ((LuggMapWrapperView *)wrapperView).layoutHandler = ^{
      [weakSelf wrapperDidLayout];
    };
  }

  _isMapReady = YES;

  // Start after the current mount pass so map settings props applied right
  // after this call shape the snapshot options
  dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf startSnapshotIfNeeded];
  });
}

- (void)destroy {
  [_snapshotter cancel];
  _snapshotter = nil;

  if ([_wrapperView isKindOfClass:[LuggMapWrapperView class]]) {
    ((LuggMapWrapperView *)_wrapperView).layoutHandler = nil;
  }

  for (LuggMarkerView *markerView in _markerViews) {
    markerView.delegate = nil;
    UIView *iconView = markerView.iconView;
    if (iconView.superview == _wrapperView) {
      [iconView removeFromSuperview];
    }
    [markerView resetIconViewTransform];
  }
  [_markerViews removeAllObjects];
  for (MKAnnotationView *pin in _defaultMarkerOverlays.objectEnumerator) {
    [pin removeFromSuperview];
  }
  [_defaultMarkerOverlays removeAllObjects];

  for (LuggPolylineView *view in _shapeOverlayView.polylineViews) {
    view.delegate = nil;
  }
  for (LuggPolygonView *view in _shapeOverlayView.polygonViews) {
    view.delegate = nil;
  }
  for (LuggCircleView *view in _shapeOverlayView.circleViews) {
    view.delegate = nil;
  }
  for (LuggGroundOverlayView *view in _shapeOverlayView.groundOverlayViews) {
    view.delegate = nil;
  }
  [_shapeOverlayView removeFromSuperview];
  _shapeOverlayView = nil;

  [_baseImageView removeFromSuperview];
  _baseImageView = nil;

  _snapshotDone = NO;
  _projectionReady = NO;
  _wrapperView = nil;
  _isMapReady = NO;
}

#pragma mark - Snapshot

- (void)updateProjection {
  CGSize size = _wrapperView.bounds.size;
  if (size.width <= 0 || size.height <= 0)
    return;

  _projectedSize = size;
  _mapRect = LuggStaticFittedMapRect(_coordinate, _zoom, size);
  _projectionReady = YES;

  _shapeOverlayView.mapRect = _mapRect;
  _shapeOverlayView.projectionReady = YES;
  [_shapeOverlayView setNeedsDisplay];

  for (LuggMarkerView *markerView in _markerViews) {
    [self positionMarkerOverlay:markerView];
  }
}

// A snapshot can't autoresize like a live map; when the wrapper gets its
// first real size (or resizes later) recompute the projection and
// (re)render the base image at the new size
- (void)wrapperDidLayout {
  CGSize size = _wrapperView.bounds.size;
  if (size.width <= 0 || size.height <= 0 ||
      CGSizeEqualToSize(size, _projectedSize))
    return;

  BOOL hadRender = _snapshotDone || _snapshotter != nil;
  [self updateProjection];

  if (hadRender) {
    [_snapshotter cancel];
    _snapshotter = nil;
    _snapshotDone = NO;
    self.cachedBaseImage = nil;
  }
  [self startSnapshotIfNeeded];
}

- (UITraitCollection *)snapshotTraitCollection {
  UITraitCollection *base = _wrapperView.traitCollection;
  UIUserInterfaceStyle style;
  switch (_theme) {
  case LuggMapViewTheme::Dark:
    style = UIUserInterfaceStyleDark;
    break;
  case LuggMapViewTheme::Light:
    style = UIUserInterfaceStyleLight;
    break;
  default:
    return base;
  }
  return [UITraitCollection traitCollectionWithTraitsFromCollections:@[
    base, [UITraitCollection traitCollectionWithUserInterfaceStyle:style]
  ]];
}

- (void)startSnapshotIfNeeded {
  if (_snapshotDone || _snapshotter || !_projectionReady || !_wrapperView)
    return;

  if (self.cachedBaseImage) {
    [self displayBaseImage:self.cachedBaseImage fromCache:YES];
    return;
  }

  MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
  options.mapRect = _mapRect;
  options.size = _projectedSize;
  options.mapType = LuggMKMapTypeFromMapType(_mapType);
  options.pointOfInterestFilter = LuggPointOfInterestFilter(
      _poiEnabled, _poiFilterMode, _poiFilterCategories);
  options.traitCollection = [self snapshotTraitCollection];

  MKMapSnapshotter *snapshotter =
      [[MKMapSnapshotter alloc] initWithOptions:options];
  _snapshotter = snapshotter;

  __weak AppleStaticMapProvider *weakSelf = self;
  [snapshotter startWithQueue:dispatch_get_main_queue()
            completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
              AppleStaticMapProvider *strongSelf = weakSelf;
              if (!strongSelf || strongSelf->_snapshotter != snapshotter)
                return;
              strongSelf->_snapshotter = nil;
              if (error || !snapshot) {
                // Keep the placeholder; resumeAnimations retries (e.g. back
                // online)
                return;
              }
              [strongSelf displayBaseImage:snapshot.image fromCache:NO];
            }];
}

- (void)displayBaseImage:(UIImage *)image fromCache:(BOOL)fromCache {
  if (!_baseImageView) {
    _baseImageView = [[UIImageView alloc] initWithFrame:_wrapperView.bounds];
    _baseImageView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_wrapperView insertSubview:_baseImageView atIndex:0];
  }
  _baseImageView.image = image;
  _snapshotDone = YES;

  if (!fromCache) {
    [_delegate mapProviderDidCaptureStaticImage:image];
  }
  [_delegate mapProviderDidFinishStaticSnapshot];
  [_delegate mapProviderDidReady];
}

#pragma mark - Props

- (void)setMapType:(LuggMapViewMapType)mapType {
  _mapType = mapType;
}

- (void)setTheme:(LuggMapViewTheme)theme {
  _theme = theme;
}

- (void)setPoiEnabled:(BOOL)enabled {
  _poiEnabled = enabled;
}

- (void)setPoiFilterMode:(LuggMapViewPoiFilterMode)mode {
  _poiFilterMode = mode;
}

- (void)setPoiFilterCategories:(NSArray<NSString *> *)categories {
  _poiFilterCategories = categories;
}

// Interaction and camera props don't apply to a static snapshot
- (void)setInsetAdjustment:(LuggMapViewInsetAdjustment)insetAdjustment {
}
- (void)setZoomEnabled:(BOOL)enabled {
}
- (void)setScrollEnabled:(BOOL)enabled {
}
- (void)setRotateEnabled:(BOOL)enabled {
}
- (void)setPitchEnabled:(BOOL)enabled {
}
- (void)setCompassEnabled:(BOOL)enabled {
}
- (void)setUserLocationEnabled:(BOOL)enabled {
}
- (void)setMinZoom:(double)minZoom {
}
- (void)setMaxZoom:(double)maxZoom {
}
- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets {
}
- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets
             duration:(double)duration {
}

#pragma mark - Markers

// Markers are live views over the snapshot (like Android lite mode's live
// markers), so async content such as remote images shows up when it loads

- (void)addMarkerView:(LuggMarkerView *)markerView {
  markerView.delegate = self;
  if (![_markerViews containsObject:markerView]) {
    [_markerViews addObject:markerView];
  }
  [self syncMarkerView:markerView];
}

- (void)removeMarkerView:(LuggMarkerView *)markerView {
  markerView.delegate = nil;
  [_markerViews removeObject:markerView];

  MKAnnotationView *pin = [_defaultMarkerOverlays objectForKey:markerView];
  if (pin) {
    [pin removeFromSuperview];
    [_defaultMarkerOverlays removeObjectForKey:markerView];
  }

  UIView *iconView = markerView.iconView;
  if (iconView.superview == _wrapperView) {
    [iconView removeFromSuperview];
  }
  [markerView resetIconViewTransform];
}

- (void)syncMarkerView:(LuggMarkerView *)markerView {
  if (!_wrapperView)
    return;

  MKAnnotationView *pin = [_defaultMarkerOverlays objectForKey:markerView];

  if (markerView.hasCustomView) {
    if (pin) {
      [pin removeFromSuperview];
      [_defaultMarkerOverlays removeObjectForKey:markerView];
    }
    UIView *iconView = markerView.iconView;
    if (iconView.superview != _wrapperView) {
      [iconView removeFromSuperview];
      iconView.userInteractionEnabled = NO;
      [_wrapperView addSubview:iconView];
    }
  } else {
    UIView *iconView = markerView.iconView;
    if (iconView.superview == _wrapperView) {
      [iconView removeFromSuperview];
      [markerView resetIconViewTransform];
    }
    if (!pin) {
      pin = [[LuggMarkerAnnotationView alloc] initWithAnnotation:nil
                                                 reuseIdentifier:nil];
      pin.userInteractionEnabled = NO;
      pin.bounds =
          CGRectMake(0, 0, kDefaultMarkerSize.width, kDefaultMarkerSize.height);
      [_wrapperView addSubview:pin];
      [_defaultMarkerOverlays setObject:pin forKey:markerView];
    }
  }

  [self positionMarkerOverlay:markerView];
}

- (void)positionMarkerOverlay:(LuggMarkerView *)markerView {
  if (!_projectionReady)
    return;

  CGPoint point = LuggStaticPointForCoordinate(_mapRect, _projectedSize,
                                               markerView.coordinate);

  if (markerView.hasCustomView) {
    UIView *iconView = markerView.iconView;
    CGSize size = iconView.bounds.size;
    if (size.width <= 0 || size.height <= 0) {
      // Not laid out yet; markerViewDidLayout re-runs this
      return;
    }
    CGFloat scale = markerView.scale;
    CGFloat radians = markerView.rotate * M_PI / 180.0;
    iconView.layer.anchorPoint = markerView.anchor;
    iconView.transform =
        CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale),
                                CGAffineTransformMakeRotation(radians));
    // center positions the layer's anchorPoint, so the marker's anchor
    // lands exactly on the projected coordinate
    iconView.center = point;
    iconView.layer.zPosition = markerView.zIndex;
  } else {
    MKAnnotationView *pin = [_defaultMarkerOverlays objectForKey:markerView];
    pin.layer.anchorPoint = CGPointMake(0.5, 1.0);
    pin.center = point;
    pin.layer.zPosition = markerView.zIndex;
  }
}

#pragma mark - LuggMarkerViewDelegate

- (void)markerViewDidLayout:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView];
}

- (void)markerViewDidUpdate:(LuggMarkerView *)markerView {
  [self syncMarkerView:markerView];
}

#pragma mark - Shapes

- (void)addPolylineView:(LuggPolylineView *)polylineView {
  polylineView.delegate = self;
  if (![_shapeOverlayView.polylineViews containsObject:polylineView]) {
    [_shapeOverlayView.polylineViews addObject:polylineView];
  }
  [_shapeOverlayView setNeedsDisplay];
}

- (void)removePolylineView:(LuggPolylineView *)polylineView {
  polylineView.delegate = nil;
  [_shapeOverlayView.polylineViews removeObject:polylineView];
  [_shapeOverlayView setNeedsDisplay];
}

- (void)syncPolylineView:(LuggPolylineView *)polylineView {
  [_shapeOverlayView setNeedsDisplay];
}

- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView {
  [_shapeOverlayView setNeedsDisplay];
}

- (void)addPolygonView:(LuggPolygonView *)polygonView {
  polygonView.delegate = self;
  if (![_shapeOverlayView.polygonViews containsObject:polygonView]) {
    [_shapeOverlayView.polygonViews addObject:polygonView];
  }
  [_shapeOverlayView setNeedsDisplay];
}

- (void)removePolygonView:(LuggPolygonView *)polygonView {
  polygonView.delegate = nil;
  [_shapeOverlayView.polygonViews removeObject:polygonView];
  [_shapeOverlayView setNeedsDisplay];
}

- (void)syncPolygonView:(LuggPolygonView *)polygonView {
  [_shapeOverlayView setNeedsDisplay];
}

- (void)polygonViewDidUpdate:(LuggPolygonView *)polygonView {
  [_shapeOverlayView setNeedsDisplay];
}

- (void)addCircleView:(LuggCircleView *)circleView {
  circleView.delegate = self;
  if (![_shapeOverlayView.circleViews containsObject:circleView]) {
    [_shapeOverlayView.circleViews addObject:circleView];
  }
  [_shapeOverlayView setNeedsDisplay];
}

- (void)removeCircleView:(LuggCircleView *)circleView {
  circleView.delegate = nil;
  [_shapeOverlayView.circleViews removeObject:circleView];
  [_shapeOverlayView setNeedsDisplay];
}

- (void)syncCircleView:(LuggCircleView *)circleView {
  [_shapeOverlayView setNeedsDisplay];
}

- (void)circleViewDidUpdate:(LuggCircleView *)circleView {
  [_shapeOverlayView setNeedsDisplay];
}

- (void)addGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  groundOverlayView.delegate = self;
  if (![_shapeOverlayView.groundOverlayViews
          containsObject:groundOverlayView]) {
    [_shapeOverlayView.groundOverlayViews addObject:groundOverlayView];
  }
  [self loadGroundOverlayImage:groundOverlayView];
}

- (void)removeGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  groundOverlayView.delegate = nil;
  [_shapeOverlayView.groundOverlayViews removeObject:groundOverlayView];
  [_shapeOverlayView.groundOverlayImages removeObjectForKey:groundOverlayView];
  [_shapeOverlayView setNeedsDisplay];
}

- (void)syncGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView {
  [self loadGroundOverlayImage:groundOverlayView];
}

- (void)groundOverlayViewDidUpdate:(LuggGroundOverlayView *)groundOverlayView {
  [self loadGroundOverlayImage:groundOverlayView];
}

- (void)loadGroundOverlayImage:(LuggGroundOverlayView *)groundOverlayView {
  NSURL *url = [NSURL URLWithString:groundOverlayView.imageUri];
  if (!url)
    return;

  __weak AppleStaticMapProvider *weakSelf = self;
  __weak LuggGroundOverlayView *weakOverlayView = groundOverlayView;
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          AppleStaticMapProvider *strongSelf = weakSelf;
          LuggGroundOverlayView *overlayView = weakOverlayView;
          if (!strongSelf || !overlayView || !image)
            return;
          LuggStaticShapeOverlayView *shapeView = strongSelf->_shapeOverlayView;
          if (![shapeView.groundOverlayViews containsObject:overlayView])
            return;
          [shapeView.groundOverlayImages setObject:image forKey:overlayView];
          [shapeView setNeedsDisplay];
        });
      });
}

// Tile overlays need a live map to fetch and compose tiles; unsupported on
// static Apple maps
- (void)addTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
}
- (void)removeTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
}
- (void)syncTileOverlayView:(LuggTileOverlayView *)tileOverlayView {
}

#pragma mark - Lifecycle

- (void)pauseAnimations {
}

- (void)resumeAnimations {
  // Retry a failed or cancelled snapshot (e.g. device back online)
  [self startSnapshotIfNeeded];
}

#pragma mark - Commands

// Static maps render once with their initial camera

- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration {
}

- (void)fitCoordinates:(NSArray *)coordinates
         edgeInsetsTop:(double)edgeInsetsTop
        edgeInsetsLeft:(double)edgeInsetsLeft
      edgeInsetsBottom:(double)edgeInsetsBottom
       edgeInsetsRight:(double)edgeInsetsRight
              duration:(double)duration {
}

@end
