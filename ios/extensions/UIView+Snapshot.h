#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (LuggSnapshot)

/**
 * Renders the currently presented content into an image view matching
 * this view's frame and autoresizing behavior. Returns nil if the view
 * has no size or the snapshot could not be rendered.
 */
- (nullable UIImageView *)lugg_snapshotImageView;

@end

NS_ASSUME_NONNULL_END
