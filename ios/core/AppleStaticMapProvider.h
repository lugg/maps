#import "MapProviderDelegate.h"
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Static (non-interactive) Apple map rendered with MKMapSnapshotter -
 * the iOS equivalent of Android's lite mode. The base map renders fully
 * asynchronously (no live MKMapView is ever created), so static maps
 * keep loading while the user scrolls without blocking the main thread.
 *
 * Markers are live views positioned over the snapshot via a mercator
 * projection (mirroring Android's live markers on lite maps), so
 * async marker content (e.g. remote images) appears when it loads.
 * Polylines, polygons, circles and ground overlays are drawn into a
 * single CoreGraphics overlay view. Tile overlays are not supported.
 */
@interface AppleStaticMapProvider : NSObject <MapProvider>

/// Previously captured base map for the same cache key; when set, the
/// snapshotter is skipped and the image is shown immediately.
@property(nonatomic, strong, nullable) UIImage *cachedBaseImage;

@end

NS_ASSUME_NONNULL_END
