#import "AppleStaticMapProvider.h"

using facebook::react::LuggMapViewPoiFilterMode;
using facebook::react::LuggMapViewTheme;

#import "../extensions/MKMapView+Zoom.h"
#import "AppleMapProvider.h"
#import "LuggAnnotationView.h"

// Standard MKMarkerAnnotationView balloon size; standalone (off-map) views
// don't size themselves
static const CGSize kDefaultMarkerSize = {28, 33};

// The rect the snapshot renders: the region for the requested zoom, expanded
// on the short axis to the view's aspect ratio - the same fit MKMapView
// applies in setRegion, so static and live maps frame alike. Passing this
// exact rect to MKMapSnapshotter makes the projection exact.
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

@implementation AppleStaticMapProvider {
  MKMapSnapshotter *_snapshotter;

  BOOL _poiEnabled;
  LuggMapViewPoiFilterMode _poiFilterMode;
  NSArray<NSString *> *_poiFilterCategories;
}

- (instancetype)init {
  if (self = [super init]) {
    _poiEnabled = YES;
    _poiFilterMode = LuggMapViewPoiFilterMode::Including;
    _poiFilterCategories = @[];
  }
  return self;
}

#pragma mark - StaticMapProviderBase

- (MKMapRect)mapRectForSize:(CGSize)size {
  return LuggStaticFittedMapRect(self.coordinate, self.zoom, size);
}

- (UIView *)newDefaultMarkerOverlayView {
  MKAnnotationView *pin =
      [[LuggMarkerAnnotationView alloc] initWithAnnotation:nil
                                           reuseIdentifier:nil];
  pin.bounds =
      CGRectMake(0, 0, kDefaultMarkerSize.width, kDefaultMarkerSize.height);
  return pin;
}

// Inverse of LuggStaticFittedMapRect: the pre-fit rect is square in map
// points with side latitudeDelta * worldHeight / (360 * cos(lat)), and the
// aspect fit scales it to the view's short side
- (double)zoomForMapPointsPerPoint:(double)mapPointsPerPoint {
  CGSize size = self.projectedSize;
  double side = mapPointsPerPoint * MIN(size.width, size.height);
  double latitudeDelta = side * 360.0 *
                         cos(self.coordinate.latitude * M_PI / 180.0) /
                         MKMapSizeWorld.height;
  double zoom = 0.5 + log2(360.0 / latitudeDelta);
  return MAX(MIN(zoom, 28.0), 0.0);
}

- (UITraitCollection *)snapshotTraitCollection {
  UITraitCollection *base = self.wrapperView.traitCollection;
  UIUserInterfaceStyle style;
  switch (self.theme) {
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

- (void)renderBaseMap {
  if (_snapshotter)
    return;

  MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
  options.mapRect = self.mapRect;
  options.size = self.projectedSize;
  options.mapType = LuggMKMapTypeFromMapType(self.mapType);
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

- (void)cancelBaseRender {
  [_snapshotter cancel];
  _snapshotter = nil;
}

#pragma mark - Props

- (void)setPoiEnabled:(BOOL)enabled {
  _poiEnabled = enabled;
}

- (void)setPoiFilterMode:(LuggMapViewPoiFilterMode)mode {
  _poiFilterMode = mode;
}

- (void)setPoiFilterCategories:(NSArray<NSString *> *)categories {
  _poiFilterCategories = categories;
}

@end
