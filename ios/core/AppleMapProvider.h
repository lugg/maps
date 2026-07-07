#import "MapProviderDelegate.h"
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

/// POI filter for the given props, shared by the live map view and the
/// static snapshotter. Returns nil for "show everything".
MKPointOfInterestFilter *_Nullable LuggPointOfInterestFilter(
    BOOL poiEnabled, facebook::react::LuggMapViewPoiFilterMode filterMode,
    NSArray<NSString *> *filterCategories);

MKMapType LuggMKMapTypeFromMapType(facebook::react::LuggMapViewMapType mapType);

@interface LuggAppleMapViewContent : MKMapView
@end

@interface AppleMapProvider : NSObject <MapProvider, MKMapViewDelegate>

@property(nonatomic, readonly, nullable) MKMapView *mapView;

@end

NS_ASSUME_NONNULL_END
