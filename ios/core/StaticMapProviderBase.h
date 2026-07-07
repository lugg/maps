#import "MapProviderDelegate.h"
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Projects a coordinate into view points for a static map covering mapRect
CGPoint LuggStaticPointForCoordinate(MKMapRect mapRect, CGSize size,
                                     CLLocationCoordinate2D coordinate);

/**
 * Shared behavior for static (non-interactive) map providers - the iOS
 * equivalent of Android's lite mode. The base map renders asynchronously
 * (subclass-specific), so static maps keep loading while the user scrolls
 * without blocking the main thread.
 *
 * Markers are live views positioned over the base map via a mercator
 * projection (mirroring Android's live markers on lite maps), so async
 * marker content (e.g. remote images) still updates when it loads.
 * Polylines, polygons, circles and ground overlays are drawn into a
 * single CoreGraphics overlay view. All overlays stay hidden over the
 * placeholder and reveal together with the base map. Tile overlays are
 * not supported.
 */
@interface StaticMapProviderBase : NSObject <MapProvider>

/// Previously captured base map for the same cache key; when set, the base
/// render is skipped and the image is shown immediately.
@property(nonatomic, strong, nullable) UIImage *cachedBaseImage;

// State for subclasses
@property(nonatomic, readonly, nullable) UIView *wrapperView;
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) double zoom;
@property(nonatomic, readonly) MKMapRect mapRect;
@property(nonatomic, readonly) CGSize projectedSize;
@property(nonatomic, readonly) BOOL projectionReady;
@property(nonatomic, readonly) facebook::react::LuggMapViewMapType mapType;
@property(nonatomic, readonly) facebook::react::LuggMapViewTheme theme;

/// Shows the base image below the overlays, emits the static snapshot
/// delegate callbacks and marks the base render done.
- (void)displayBaseImage:(UIImage *)image fromCache:(BOOL)fromCache;

/// Shows the marker and shape overlays (idempotent). Called automatically
/// when the base image displays; subclasses whose base map is already
/// visible earlier (e.g. a live warmup map) can call it sooner.
- (void)revealOverlays;

#pragma mark - Subclass hooks

/// The map rect the base render covers for the given view size; must match
/// the SDK's camera framing so overlays align with the base map exactly.
- (MKMapRect)mapRectForSize:(CGSize)size;

/// Overlay view shown for markers without a custom child view.
- (UIView *)newDefaultMarkerOverlayView;

/// Starts rendering the base map for the current projection (guaranteed
/// projectionReady, no cached image). Called after mount (once initial
/// props have applied), after a resize, and from resumeAnimations to retry
/// a failed or cancelled render (e.g. device back online).
- (void)renderBaseMap;

/// Cancels an in-flight base render (resize or teardown).
- (void)cancelBaseRender;

@end

NS_ASSUME_NONNULL_END
