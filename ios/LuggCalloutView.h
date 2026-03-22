#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggCalloutView;

@protocol LuggCalloutViewDelegate <NSObject>
@optional
- (void)calloutViewDidUpdate:(LuggCalloutView *)calloutView;
@end

@interface LuggCalloutView : RCTViewComponentView

@property(nonatomic, readonly) BOOL bubbled;
@property(nonatomic, readonly) CGPoint offset;
@property(nonatomic, readonly) BOOL hasCustomContent;
@property(nonatomic, readonly) UIView *contentView;
@property(nonatomic, weak, nullable) id<LuggCalloutViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
