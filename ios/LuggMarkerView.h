#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggMarkerView;
@class LuggCalloutView;

@protocol LuggMarkerViewDelegate <NSObject>
@optional
- (void)markerViewDidLayout:(LuggMarkerView *)markerView;
- (void)markerViewDidUpdate:(LuggMarkerView *)markerView;
- (void)showCalloutForMarkerView:(LuggMarkerView *)markerView;
- (void)hideCalloutForMarkerView:(LuggMarkerView *)markerView;
@end

@interface LuggMarkerView : RCTViewComponentView

@property(nonatomic, readonly, nullable) NSString *name;
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly, nullable) NSString *title;
@property(nonatomic, readonly, nullable) NSString *markerDescription;
@property(nonatomic, readonly) CGPoint anchor;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, readonly) CLLocationDegrees rotate;
@property(nonatomic, readonly) CGFloat scale;
@property(nonatomic, readonly) BOOL rasterize;
@property(nonatomic, readonly) BOOL draggable;
@property(nonatomic, readonly) BOOL hasCustomView;
@property(nonatomic, readonly) BOOL didLayout;
@property(nonatomic, readonly) UIView *iconView;
@property(nonatomic, readonly, nullable) LuggCalloutView *calloutView;
@property(nonatomic, weak, nullable) id<LuggMarkerViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *marker;

- (nullable UIImage *)createIconImage;
- (nullable UIImage *)createScaledIconImage;
- (void)resetIconViewTransform;
- (void)emitPressEventWithPoint:(CGPoint)point;
- (void)emitDragStartEventWithPoint:(CGPoint)point;
- (void)emitDragChangeEventWithPoint:(CGPoint)point;
- (void)emitDragEndEventWithPoint:(CGPoint)point;
- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate;

@end

NS_ASSUME_NONNULL_END
