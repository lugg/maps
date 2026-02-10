#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggMarkerView;
@class LuggPolylineView;

@protocol MapProviderDelegate <NSObject>
- (void)mapProviderDidReady;
- (void)mapProviderDidMoveCamera:(double)latitude
                       longitude:(double)longitude
                            zoom:(double)zoom
                         gesture:(BOOL)gesture;
- (void)mapProviderDidIdleCamera:(double)latitude
                       longitude:(double)longitude
                            zoom:(double)zoom
                         gesture:(BOOL)gesture;
@end

@protocol MapProvider <NSObject>

@property(nonatomic, weak, nullable) id<MapProviderDelegate> delegate;
@property(nonatomic, readonly) BOOL isMapReady;

- (void)initializeMapInView:(UIView *)wrapperView
          initialCoordinate:(CLLocationCoordinate2D)coordinate
                initialZoom:(double)zoom;
- (void)destroy;

// Props
- (void)setZoomEnabled:(BOOL)enabled;
- (void)setScrollEnabled:(BOOL)enabled;
- (void)setRotateEnabled:(BOOL)enabled;
- (void)setPitchEnabled:(BOOL)enabled;
- (void)setUserLocationEnabled:(BOOL)enabled;
- (void)setTheme:(NSString *)theme;
- (void)setMinZoom:(double)minZoom;
- (void)setMaxZoom:(double)maxZoom;
- (void)setPadding:(UIEdgeInsets)padding oldPadding:(UIEdgeInsets)oldPadding;

// Children
- (void)addMarkerView:(LuggMarkerView *)markerView;
- (void)removeMarkerView:(LuggMarkerView *)markerView;
- (void)syncMarkerView:(LuggMarkerView *)markerView;
- (void)addPolylineView:(LuggPolylineView *)polylineView;
- (void)removePolylineView:(LuggPolylineView *)polylineView;
- (void)syncPolylineView:(LuggPolylineView *)polylineView;

// Lifecycle
- (void)pauseAnimations;
- (void)resumeAnimations;

// Commands
- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration;
- (void)fitCoordinates:(NSArray *)coordinates
            paddingTop:(double)paddingTop
           paddingLeft:(double)paddingLeft
         paddingBottom:(double)paddingBottom
          paddingRight:(double)paddingRight
              duration:(double)duration;

@end

NS_ASSUME_NONNULL_END
