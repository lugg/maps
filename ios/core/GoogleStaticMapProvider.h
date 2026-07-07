#import "StaticMapProviderBase.h"
#import <GoogleMaps/GoogleMaps.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Static Google map. The Google Maps SDK has no async snapshotter, so the
 * base map briefly warms up on a live, tiles-only GMSMapView inserted below
 * the overlays, then is swapped with a rendered image and the map view is
 * pooled for reuse. Markers and shapes are overlay views (shared with
 * Apple static maps) that reveal with the base map, so the warmup map
 * never renders its own markers. Warmup cost scales with how many static
 * maps mount at once - bound that with list props (windowSize etc.).
 */
@interface GoogleStaticMapProvider : StaticMapProviderBase <GMSMapViewDelegate>

@property(nonatomic, copy, nullable) NSString *mapId;

@end

NS_ASSUME_NONNULL_END
