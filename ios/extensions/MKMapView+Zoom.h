#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMapView (Zoom)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(double)zoomLevel
                   animated:(BOOL)animated;

- (MKCoordinateRegion)regionForCenterCoordinate:
                          (CLLocationCoordinate2D)centerCoordinate
                                      zoomLevel:(double)zoomLevel;

/// Returns the zoom level based on the full map region, not affected by layoutMargins
- (double)zoomLevel;

@end

NS_ASSUME_NONNULL_END
