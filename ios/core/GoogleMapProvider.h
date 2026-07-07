#import "MapProviderDelegate.h"
#import <GoogleMaps/GoogleMaps.h>

NS_ASSUME_NONNULL_BEGIN

/// Resolves a mapId prop value ("" or "DEMO_MAP_ID" -> demo map ID),
/// shared by the live and static Google providers.
GMSMapID *LuggGMSMapIDFromString(NSString *_Nullable mapId);

GMSMapViewType LuggGMSMapTypeFromMapType(
    facebook::react::LuggMapViewMapType mapType);

UIUserInterfaceStyle LuggInterfaceStyleFromTheme(
    facebook::react::LuggMapViewTheme theme);

@interface GoogleMapProvider : NSObject <MapProvider, GMSMapViewDelegate>

@property(nonatomic, copy, nullable) NSString *mapId;
@property(nonatomic, readonly, nullable) GMSMapView *mapView;

@end

NS_ASSUME_NONNULL_END
