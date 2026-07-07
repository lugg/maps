#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuggMapWrapperView : RCTViewComponentView

/// Called after layout; lets the static snapshotter start (or restart)
/// once the wrapper has a real size, since a snapshot can't autoresize
@property(nonatomic, copy, nullable) void (^layoutHandler)(void);

@end

NS_ASSUME_NONNULL_END
