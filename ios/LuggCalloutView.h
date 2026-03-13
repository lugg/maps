#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuggCalloutView : RCTViewComponentView

@property(nonatomic, readonly) BOOL hasCustomContent;
@property(nonatomic, readonly) UIView *contentView;

- (void)emitPressEvent;

@end

NS_ASSUME_NONNULL_END
