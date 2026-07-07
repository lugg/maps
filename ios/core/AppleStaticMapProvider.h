#import "StaticMapProviderBase.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Static Apple map rendered with MKMapSnapshotter. The base map renders
 * fully asynchronously (no live MKMapView is ever created), so static maps
 * keep loading while the user scrolls without blocking the main thread.
 */
@interface AppleStaticMapProvider : StaticMapProviderBase

@end

NS_ASSUME_NONNULL_END
