#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Calls `tick` from a display link while started, at up to `framesPerSecond` (0
// for every frame). Moves path markers that Core Animation can't animate.
@interface MarkerPathTicker : NSObject

@property(nonatomic) float framesPerSecond;
@property(nonatomic) BOOL paused;

- (instancetype)initWithTick:(void (^)(void))tick;
- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
