#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Coordinate span for a Google-style zoom level, shared by the live map
/// (MKMapView region) and the static snapshotter (no map view)
MKCoordinateSpan LuggCoordinateSpanForZoomLevel(
    double zoomLevel, CLLocationCoordinate2D centerCoordinate);

#ifdef __cplusplus
}
#endif

@interface MKMapView (Zoom)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(double)zoomLevel
                   animated:(BOOL)animated;

/// Returns a camera for the given center and zoom level, preserving the current
/// heading and pitch
- (MKMapCamera *)cameraForCenterCoordinate:
                     (CLLocationCoordinate2D)centerCoordinate
                                 zoomLevel:(double)zoomLevel;

- (MKCoordinateRegion)regionForCenterCoordinate:
                          (CLLocationCoordinate2D)centerCoordinate
                                      zoomLevel:(double)zoomLevel;

/// Returns the zoom level based on the full map region, not affected by
/// layoutMargins
- (double)zoomLevel;

@end

NS_ASSUME_NONNULL_END
