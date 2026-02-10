#import "GMSPolylineAnimator.h"
#import <QuartzCore/QuartzCore.h>

static const NSUInteger kMaxAnimationSpans = 16;

@interface GMSDisplayLinkProxy : NSObject
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL selector;
@end

@implementation GMSDisplayLinkProxy
- (instancetype)initWithTarget:(id)target selector:(SEL)selector {
  if (self = [super init]) {
    _target = target;
    _selector = selector;
  }
  return self;
}
- (void)tick:(CADisplayLink *)displayLink {
  if (_target) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:displayLink];
#pragma clang diagnostic pop
  } else {
    [displayLink invalidate];
  }
}
@end

@implementation GMSPolylineAnimator {
  CADisplayLink *_displayLink;
  GMSDisplayLinkProxy *_displayLinkProxy;
  CGFloat _animationProgress;
  CGFloat _delayRemaining;
  NSArray<NSNumber *> *_cumulativeDistances;
  CGFloat _totalLength;
}

@synthesize animatedOptions = _animatedOptions;

- (void)dealloc {
  [self stopAnimation];
}

- (void)setCoordinates:(NSArray<CLLocation *> *)coordinates {
  [super setCoordinates:coordinates];
  if (_animated && _displayLink) {
    [self computeCumulativeDistances];
  }
}

- (void)setAnimated:(BOOL)animated {
  if (_animated == animated) {
    return;
  }
  _animated = animated;

  if (_animated) {
    [self startAnimation];
  } else {
    [self stopAnimation];
    [self update];
  }
}

- (void)setAnimatedOptions:(PolylineAnimatedOptions *)animatedOptions {
  _animatedOptions = animatedOptions ?: [PolylineAnimatedOptions defaultOptions];
  if (_animated && _displayLink) {
    [self stopAnimation];
    [self startAnimation];
  }
}

- (void)startAnimation {
  if (_displayLink) {
    return;
  }
  [self computeCumulativeDistances];
  _animationProgress = 0;
  _delayRemaining = self.animatedOptions.delay / 1000.0;
  _displayLinkProxy = [[GMSDisplayLinkProxy alloc] initWithTarget:self selector:@selector(animationTick:)];
  _displayLink = [CADisplayLink displayLinkWithTarget:_displayLinkProxy selector:@selector(tick:)];
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)computeCumulativeDistances {
  NSMutableArray<NSNumber *> *distances = [NSMutableArray array];
  CGFloat total = 0;
  [distances addObject:@(0)];

  for (NSUInteger i = 1; i < self.coordinates.count; i++) {
    CLLocation *prev = self.coordinates[i - 1];
    CLLocation *curr = self.coordinates[i];
    total += [prev distanceFromLocation:curr];
    [distances addObject:@(total)];
  }

  _cumulativeDistances = [distances copy];
  _totalLength = total;
}

- (void)stopAnimation {
  [_displayLink invalidate];
  _displayLink = nil;
  _displayLinkProxy = nil;
}

- (void)pause {
  _displayLink.paused = YES;
}

- (void)resume {
  _displayLink.paused = NO;
}

- (void)animationTick:(CADisplayLink *)displayLink {
  if (_delayRemaining > 0) {
    _delayRemaining -= displayLink.duration;
    return;
  }

  CGFloat duration = self.animatedOptions.duration / 1000.0;
  if (duration <= 0) duration = 2.15;

  CGFloat trailLength = MAX(0.01, MIN(1.0, self.animatedOptions.trailLength));
  CGFloat maxProgress = (trailLength < 1.0) ? 1.0 : 2.15;

  CGFloat speed = displayLink.duration / duration;
  _animationProgress += speed;

  if (_animationProgress >= maxProgress) {
    _animationProgress = 0;
    _delayRemaining = self.animatedOptions.delay / 1000.0;
  }

  [self updateAnimatedPolyline];
}

- (void)update {
  if (_animated) {
    return;
  }

  if (!_polyline || self.coordinates.count < 2) {
    return;
  }

  GMSMutablePath *path = [GMSMutablePath path];
  for (CLLocation *location in self.coordinates) {
    [path addCoordinate:location.coordinate];
  }
  _polyline.path = path;

  if (self.strokeColors.count > 1) {
    _polyline.spans = [self createGradientSpans];
  } else {
    _polyline.strokeColor = self.strokeColors.firstObject ?: [UIColor blackColor];
  }
}

- (NSUInteger)indexForDistance:(CGFloat)distance {
  NSUInteger left = 0;
  NSUInteger right = _cumulativeDistances.count - 1;

  while (left < right) {
    NSUInteger mid = (left + right + 1) / 2;
    if (_cumulativeDistances[mid].doubleValue <= distance) {
      left = mid;
    } else {
      right = mid - 1;
    }
  }

  return MIN(left, _cumulativeDistances.count - 2);
}

- (CLLocationCoordinate2D)coordinateAtDistance:(CGFloat)distance {
  if (distance <= 0) {
    return self.coordinates.firstObject.coordinate;
  }
  if (distance >= _totalLength) {
    return self.coordinates.lastObject.coordinate;
  }

  NSUInteger idx = [self indexForDistance:distance];
  CGFloat segStart = _cumulativeDistances[idx].doubleValue;
  CGFloat segEnd = _cumulativeDistances[idx + 1].doubleValue;
  CGFloat segLength = segEnd - segStart;

  CGFloat t = (segLength > 0) ? (distance - segStart) / segLength : 0;
  CLLocationCoordinate2D c1 = self.coordinates[idx].coordinate;
  CLLocationCoordinate2D c2 = self.coordinates[idx + 1].coordinate;

  return CLLocationCoordinate2DMake(c1.latitude + (c2.latitude - c1.latitude) * t,
                                    c1.longitude + (c2.longitude - c1.longitude) * t);
}

- (void)updateAnimatedPolyline {
  if (!_polyline || self.coordinates.count < 2 || _totalLength <= 0) {
    return;
  }

  CGFloat trailLength = MAX(0.01, MIN(1.0, self.animatedOptions.trailLength));
  CGFloat maxProgress = (trailLength < 1.0) ? 1.0 : 2.0;
  CGFloat progress = MIN(_animationProgress, maxProgress);
  CGFloat easedProgress = [self applyEasing:progress / maxProgress] * maxProgress;

  CGFloat headDist, tailDist;

  if (trailLength < 1.0) {
    headDist = easedProgress * _totalLength;
    tailDist = MAX(0, headDist - _totalLength * trailLength);
  } else if (easedProgress <= 1.0) {
    tailDist = 0;
    headDist = easedProgress * _totalLength;
  } else {
    CGFloat shrinkProgress = easedProgress - 1.0;
    tailDist = shrinkProgress * _totalLength;
    headDist = _totalLength;
  }

  if (headDist <= tailDist) {
    _polyline.path = [GMSMutablePath path];
    return;
  }

  CGFloat visibleLength = headDist - tailDist;
  NSUInteger startIndex = [self indexForDistance:tailDist];
  NSUInteger endIndex = [self indexForDistance:headDist];

  GMSMutablePath *path = [GMSMutablePath path];
  NSMutableArray<GMSStyleSpan *> *spans = [NSMutableArray array];

  CLLocationCoordinate2D startCoord = [self coordinateAtDistance:tailDist];
  [path addCoordinate:startCoord];

  for (NSUInteger i = startIndex + 1; i <= endIndex; i++) {
    [path addCoordinate:self.coordinates[i].coordinate];
  }

  CLLocationCoordinate2D endCoord = [self coordinateAtDistance:headDist];
  CLLocationCoordinate2D lastAdded =
      (endIndex < self.coordinates.count) ? self.coordinates[endIndex].coordinate : endCoord;
  if (endCoord.latitude != lastAdded.latitude || endCoord.longitude != lastAdded.longitude) {
    [path addCoordinate:endCoord];
  }

  NSUInteger pathCount = path.count;
  NSUInteger segmentCount = pathCount - 1;

  if (self.strokeColors.count <= 1) {
    _polyline.path = path;
    _polyline.strokeColor = self.strokeColors.firstObject ?: [UIColor blackColor];
    return;
  }

  NSUInteger spanCount = MIN(segmentCount, kMaxAnimationSpans);
  double segmentsPerSpan = (double)segmentCount / spanCount;

  for (NSUInteger i = 0; i < spanCount; i++) {
    CGFloat gradientPos = ((CGFloat)i + 0.5) / spanCount;
    UIColor *color = [self colorAtGradientPosition:gradientPos];
    GMSStrokeStyle *style = [GMSStrokeStyle solidColor:color];
    [spans addObject:[GMSStyleSpan spanWithStyle:style segments:segmentsPerSpan]];
  }

  _polyline.path = path;
  _polyline.spans = spans;
}

- (NSArray<GMSStyleSpan *> *)createGradientSpans {
  NSMutableArray<GMSStyleSpan *> *spans = [NSMutableArray array];
  NSUInteger segmentCount = self.coordinates.count - 1;

  for (NSUInteger i = 0; i < segmentCount; i++) {
    CGFloat position = (CGFloat)i / (CGFloat)segmentCount;
    UIColor *color = [self colorAtGradientPosition:position];
    GMSStrokeStyle *style = [GMSStrokeStyle solidColor:color];
    [spans addObject:[GMSStyleSpan spanWithStyle:style]];
  }

  return spans;
}

@end
