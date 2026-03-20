#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggCircleView;

@protocol LuggCircleViewDelegate <NSObject>
@optional
- (void)circleViewDidUpdate:(LuggCircleView *)circleView;
@end

@interface LuggCircleView : RCTViewComponentView

@property(nonatomic, readonly) CLLocationCoordinate2D center;
@property(nonatomic, readonly) CLLocationDistance radius;
@property(nonatomic, readonly) UIColor *strokeColor;
@property(nonatomic, readonly) UIColor *fillColor;
@property(nonatomic, readonly) CGFloat strokeWidth;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, readonly) BOOL tappable;
@property(nonatomic, weak, nullable) id<LuggCircleViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *circle;
@property(nonatomic, weak, nullable) NSObject *renderer;

- (void)emitPressEvent;

@end

NS_ASSUME_NONNULL_END
