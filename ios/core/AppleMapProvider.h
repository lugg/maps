#import "MapProviderDelegate.h"
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuggAppleMapViewContent : MKMapView
@end

@interface AppleMapProvider : NSObject <MapProvider, MKMapViewDelegate>

@property(nonatomic, readonly, nullable) MKMapView *mapView;

@end

NS_ASSUME_NONNULL_END
