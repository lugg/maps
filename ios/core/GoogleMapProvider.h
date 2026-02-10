#import "MapProviderDelegate.h"
#import <GoogleMaps/GoogleMaps.h>

NS_ASSUME_NONNULL_BEGIN

@interface GoogleMapProvider : NSObject <MapProvider, GMSMapViewDelegate>

@property(nonatomic, copy, nullable) NSString *mapId;
@property(nonatomic, readonly, nullable) GMSMapView *mapView;

@end

NS_ASSUME_NONNULL_END
