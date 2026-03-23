#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <react/renderer/components/RNMapsSpec/Props.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggMarkerView;
@class LuggPolylineView;
@class LuggPolygonView;
@class LuggCircleView;
@class LuggGroundOverlayView;
@class LuggTileOverlayView;

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
- (void)mapProviderDidPress:(double)latitude
                  longitude:(double)longitude
                          x:(double)x
                          y:(double)y;
- (void)mapProviderDidLongPress:(double)latitude
                      longitude:(double)longitude
                              x:(double)x
                              y:(double)y;
@end

@protocol MapProvider <NSObject>

@property(nonatomic, weak, nullable) id<MapProviderDelegate> delegate;
@property(nonatomic, readonly) BOOL isMapReady;

- (void)initializeMapInView:(UIView *)wrapperView
          initialCoordinate:(CLLocationCoordinate2D)coordinate
                initialZoom:(double)zoom;
- (void)destroy;

// Props
- (void)setInsetAdjustment:
    (facebook::react::LuggMapViewInsetAdjustment)insetAdjustment;
- (void)setZoomEnabled:(BOOL)enabled;
- (void)setScrollEnabled:(BOOL)enabled;
- (void)setRotateEnabled:(BOOL)enabled;
- (void)setPitchEnabled:(BOOL)enabled;
- (void)setUserLocationEnabled:(BOOL)enabled;
- (void)setMapType:(facebook::react::LuggMapViewMapType)mapType;
- (void)setTheme:(facebook::react::LuggMapViewTheme)theme;
- (void)setMinZoom:(double)minZoom;
- (void)setMaxZoom:(double)maxZoom;
- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets;
- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets
        oldEdgeInsets:(UIEdgeInsets)oldEdgeInsets
             duration:(double)duration;
- (void)setPoiEnabled:(BOOL)enabled;
- (void)setPoiFilterMode:(facebook::react::LuggMapViewPoiFilterMode)mode;
- (void)setPoiFilterCategories:(NSArray<NSString *> *)categories;

// Children
- (void)addMarkerView:(LuggMarkerView *)markerView;
- (void)removeMarkerView:(LuggMarkerView *)markerView;
- (void)syncMarkerView:(LuggMarkerView *)markerView;
- (void)addPolylineView:(LuggPolylineView *)polylineView;
- (void)removePolylineView:(LuggPolylineView *)polylineView;
- (void)syncPolylineView:(LuggPolylineView *)polylineView;
- (void)addPolygonView:(LuggPolygonView *)polygonView;
- (void)removePolygonView:(LuggPolygonView *)polygonView;
- (void)syncPolygonView:(LuggPolygonView *)polygonView;
- (void)addCircleView:(LuggCircleView *)circleView;
- (void)removeCircleView:(LuggCircleView *)circleView;
- (void)syncCircleView:(LuggCircleView *)circleView;
- (void)addGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView;
- (void)removeGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView;
- (void)syncGroundOverlayView:(LuggGroundOverlayView *)groundOverlayView;
- (void)addTileOverlayView:(LuggTileOverlayView *)tileOverlayView;
- (void)removeTileOverlayView:(LuggTileOverlayView *)tileOverlayView;
- (void)syncTileOverlayView:(LuggTileOverlayView *)tileOverlayView;

// Lifecycle
- (void)pauseAnimations;
- (void)resumeAnimations;

// Commands
- (void)moveCamera:(double)latitude
         longitude:(double)longitude
              zoom:(double)zoom
          duration:(double)duration;
- (void)fitCoordinates:(NSArray *)coordinates
         edgeInsetsTop:(double)edgeInsetsTop
        edgeInsetsLeft:(double)edgeInsetsLeft
      edgeInsetsBottom:(double)edgeInsetsBottom
       edgeInsetsRight:(double)edgeInsetsRight
              duration:(double)duration;

@end

NS_ASSUME_NONNULL_END
