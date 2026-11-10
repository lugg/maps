#import "MarkerPathTicker.h"
#import <QuartzCore/QuartzCore.h>

@interface MarkerPathTicker ()
- (void)fire;
@end

// The display link retains its target; the proxy keeps that from retaining the
// ticker.
@interface MarkerPathTickerProxy : NSObject
@property(nonatomic, weak) MarkerPathTicker *ticker;
@end

@implementation MarkerPathTickerProxy
- (void)fire:(CADisplayLink *)displayLink {
  MarkerPathTicker *ticker = _ticker;
  if (ticker) {
    [ticker fire];
  } else {
    [displayLink invalidate];
  }
}
@end

@implementation MarkerPathTicker {
  void (^_tick)(void);
  CADisplayLink *_displayLink;
}

- (instancetype)initWithTick:(void (^)(void))tick {
  if (self = [super init]) {
    _tick = [tick copy];
  }
  return self;
}

- (void)dealloc {
  [_displayLink invalidate];
}

- (void)start {
  if (_displayLink) {
    return;
  }
  MarkerPathTickerProxy *proxy = [[MarkerPathTickerProxy alloc] init];
  proxy.ticker = self;
  _displayLink = [CADisplayLink displayLinkWithTarget:proxy
                                             selector:@selector(fire:)];
  [self applyFrameRate];
  _displayLink.paused = _paused;
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                     forMode:NSRunLoopCommonModes];
}

- (void)stop {
  [_displayLink invalidate];
  _displayLink = nil;
}

- (void)setFramesPerSecond:(float)framesPerSecond {
  _framesPerSecond = framesPerSecond;
  [self applyFrameRate];
}

- (void)setPaused:(BOOL)paused {
  _paused = paused;
  _displayLink.paused = paused;
}

- (void)applyFrameRate {
  _displayLink.preferredFrameRateRange =
      _framesPerSecond > 0
          ? CAFrameRateRangeMake(_framesPerSecond, _framesPerSecond,
                                 _framesPerSecond)
          : CAFrameRateRangeDefault;
}

- (void)fire {
  _tick();
}

@end
