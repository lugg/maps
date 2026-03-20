#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggGroundOverlayView;

@protocol LuggGroundOverlayViewDelegate <NSObject>
@optional
- (void)groundOverlayViewDidUpdate:(LuggGroundOverlayView *)groundOverlayView;
@end

@interface LuggGroundOverlayView : RCTViewComponentView

@property(nonatomic, readonly) NSString *imageUri;
@property(nonatomic, readonly) CLLocationCoordinate2D northeast;
@property(nonatomic, readonly) CLLocationCoordinate2D southwest;
@property(nonatomic, readonly) CGFloat opacity;
@property(nonatomic, readonly) CGFloat bearing;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, readonly) BOOL tappable;
@property(nonatomic, weak, nullable) id<LuggGroundOverlayViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *overlay;

- (void)emitPressEvent;

@end

NS_ASSUME_NONNULL_END
