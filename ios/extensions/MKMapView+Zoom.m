#import "MKMapView+Zoom.h"

@implementation MKMapView (Zoom)

- (MKCoordinateSpan)coordinateSpanForZoomLevel:(double)zoomLevel centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
{
    // Google Maps: zoom level defines how many 256px tiles fit the world
    // At zoom 0, 1 tile = 360 degrees
    // Each zoom level doubles the number of tiles (halves the degrees per tile)
    // Offset of ~0.5 adjusts for difference between Google Maps and MKMapView rendering
    double adjustedZoom = zoomLevel - 0.5;
    double latitudeDelta = 360.0 / pow(2, adjustedZoom);
    
    // Adjust longitude delta for latitude (Mercator projection)
    double longitudeDelta = latitudeDelta / cos(centerCoordinate.latitude * M_PI / 180.0);
    
    return MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
}

#pragma mark - Public Methods

// Constant for altitude/zoom conversion (meters at zoom level 0)
static const double kAltitudeAtZoomZero = 220000000.0;

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(double)zoomLevel
                   animated:(BOOL)animated
{
    // Use camera API directly to avoid region/margin interaction
    CLLocationDistance altitude = kAltitudeAtZoomZero / pow(2, zoomLevel);
    MKMapCamera *camera = [MKMapCamera cameraLookingAtCenterCoordinate:centerCoordinate
                                                    fromEyeCoordinate:centerCoordinate
                                                          eyeAltitude:altitude];
    camera.pitch = self.camera.pitch;
    camera.heading = self.camera.heading;
    [self setCamera:camera animated:animated];
}

- (MKCoordinateRegion)regionForCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                      zoomLevel:(double)zoomLevel
{
    zoomLevel = MIN(zoomLevel, 28);
    MKCoordinateSpan span = [self coordinateSpanForZoomLevel:zoomLevel centerCoordinate:centerCoordinate];
    return MKCoordinateRegionMake(centerCoordinate, span);
}

- (double)zoomLevel
{
    // Use camera altitude which isn't affected by layoutMargins
    CLLocationDistance altitude = self.camera.altitude;
    double zoomLevel = log2(kAltitudeAtZoomZero / altitude);
    return zoomLevel;
}

@end
