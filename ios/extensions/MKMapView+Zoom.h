#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMapView (Zoom)

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(double)zoomLevel
                   animated:(BOOL)animated;

/// Returns a camera for the given center and zoom level, preserving the current
/// heading and pitch
- (MKMapCamera *)cameraForCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 zoomLevel:(double)zoomLevel;

- (MKCoordinateRegion)regionForCenterCoordinate:
                          (CLLocationCoordinate2D)centerCoordinate
                                      zoomLevel:(double)zoomLevel;

/// Returns the zoom level based on the full map region, not affected by
/// layoutMargins
- (double)zoomLevel;

@end

NS_ASSUME_NONNULL_END
