#import "MKPolylineAnimator.h"
#import <QuartzCore/QuartzCore.h>

@interface MKDisplayLinkProxy : NSObject
@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL selector;
@end

@implementation MKDisplayLinkProxy
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

@implementation MKPolylineAnimator {
  MKPolyline *_polyline;
  CADisplayLink *_displayLink;
  MKDisplayLinkProxy *_displayLinkProxy;
  CGFloat _animationProgress;
  CGFloat _delayRemaining;
  NSArray<NSNumber *> *_cumulativeDistances;
  CGFloat _totalLength;
  CGColorSpaceRef _colorSpace;
  // Immutable snapshot read by background draws; rebuilt (never mutated)
  // on the main thread
  NSData *_colorCacheData;
}

- (id)initWithPolyline:(MKPolyline *)polyline {
  self = [super initWithOverlay:polyline];
  if (self) {
    _polyline = polyline;
    _animationProgress = 0;
    _animatedOptions = [PolylineAnimatedOptions defaultOptions];
    _colorSpace = CGColorSpaceCreateDeviceRGB();
    [self createPath];
  }
  return self;
}

- (void)setAnimatedOptions:(PolylineAnimatedOptions *)animatedOptions {
  _animatedOptions = animatedOptions ?: [PolylineAnimatedOptions defaultOptions];
  if (_animated && _displayLink) {
    [self stopAnimation];
    [self startAnimation];
  }
}

- (void)dealloc {
  [self stopAnimation];
  if (_colorSpace) {
    CGColorSpaceRelease(_colorSpace);
    _colorSpace = NULL;
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
  }
}

- (void)startAnimation {
  if (_displayLink) {
    return;
  }
  [self computeCumulativeDistances];
  _animationProgress = 0;
  _delayRemaining = _animatedOptions.delay / 1000.0;
  _displayLinkProxy = [[MKDisplayLinkProxy alloc] initWithTarget:self selector:@selector(animationTick:)];
  _displayLink = [CADisplayLink displayLinkWithTarget:_displayLinkProxy selector:@selector(tick:)];
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)computeCumulativeDistances {
  NSMutableArray<NSNumber *> *distances = [NSMutableArray array];
  CGFloat total = 0;
  [distances addObject:@(0)];

  for (NSUInteger i = 1; i < _polyline.pointCount; i++) {
    MKMapPoint p1 = _polyline.points[i - 1];
    MKMapPoint p2 = _polyline.points[i];
    total += MKMetersBetweenMapPoints(p1, p2);
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

- (NSUInteger)indexForDistance:(CGFloat)distance
                   inDistances:(NSArray<NSNumber *> *)distances {
  if (distances.count < 2) {
    return 0;
  }

  NSUInteger left = 0;
  NSUInteger right = distances.count - 1;

  while (left < right) {
    NSUInteger mid = (left + right + 1) / 2;
    if (distances[mid].doubleValue <= distance) {
      left = mid;
    } else {
      right = mid - 1;
    }
  }

  return MIN(left, distances.count - 2);
}

- (CGFloat)applyEasing:(CGFloat)t {
  NSString *easing = _animatedOptions.easing ?: @"linear";

  if ([easing isEqualToString:@"easeIn"]) {
    return t * t;
  } else if ([easing isEqualToString:@"easeOut"]) {
    return t * (2 - t);
  } else if ([easing isEqualToString:@"easeInOut"]) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }
  return t;
}

- (void)animationTick:(CADisplayLink *)displayLink {
  if (_delayRemaining > 0) {
    _delayRemaining -= displayLink.duration;
    return;
  }

  CGFloat duration = _animatedOptions.duration / 1000.0;
  if (duration <= 0) duration = 2.15;

  CGFloat trailLength = MAX(0.01, MIN(1.0, _animatedOptions.trailLength));
  CGFloat maxProgress = (trailLength < 1.0) ? 1.0 : 2.15;

  CGFloat speed = displayLink.duration / duration;
  _animationProgress += speed;

  if (_animationProgress >= maxProgress) {
    _animationProgress = 0;
    _delayRemaining = _animatedOptions.delay / 1000.0;
  }

  MKMapRect bounds = _polyline.boundingMapRect;
  bounds = MKMapRectInset(bounds, -bounds.size.width * 0.1, -bounds.size.height * 0.1);
  [self setNeedsDisplayInMapRect:bounds];
}

- (void)updatePolyline:(MKPolyline *)polyline {
  _polyline = polyline;
  [self invalidatePath];
  [self createPath];
  if (_animated) {
    [self computeCumulativeDistances];
  }
  [self setNeedsDisplay];
}

- (void)createPath {
  CGMutablePathRef path = CGPathCreateMutable();
  BOOL first = YES;
  for (NSUInteger i = 0; i < _polyline.pointCount; i++) {
    CGPoint point = [self pointForMapPoint:_polyline.points[i]];
    if (first) {
      CGPathMoveToPoint(path, nil, point.x, point.y);
      first = NO;
    } else {
      CGPathAddLineToPoint(path, nil, point.x, point.y);
    }
  }
  self.path = path;
}

- (void)setStrokeColors:(NSArray<UIColor *> *)strokeColors {
  _strokeColors = strokeColors;
  [self rebuildColorCache];
}

- (void)rebuildColorCache {
  NSUInteger count = _strokeColors.count;
  if (count == 0) {
    _colorCacheData = nil;
    return;
  }

  NSMutableData *data =
      [NSMutableData dataWithLength:sizeof(RGBAComponents) * count];
  RGBAComponents *cache = (RGBAComponents *)data.mutableBytes;
  for (NSUInteger i = 0; i < count; i++) {
    [_strokeColors[i] getRed:&cache[i].r
                       green:&cache[i].g
                        blue:&cache[i].b
                       alpha:&cache[i].a];
  }
  _colorCacheData = data;
}

- (void)colorAtGradientPosition:(CGFloat)position rgba:(RGBAComponents *)out {
  NSData *cacheData = _colorCacheData;
  const RGBAComponents *cache = (const RGBAComponents *)cacheData.bytes;
  NSUInteger count = cacheData.length / sizeof(RGBAComponents);

  if (count == 0) {
    CGFloat r, g, b, a;
    [self.strokeColor getRed:&r green:&g blue:&b alpha:&a];
    *out = (RGBAComponents){r, g, b, a};
    return;
  }
  if (count == 1) {
    *out = cache[0];
    return;
  }

  position = MAX(0, MIN(1, position));
  CGFloat scaledPos = position * (count - 1);
  NSUInteger index = (NSUInteger)scaledPos;
  CGFloat t = scaledPos - index;

  if (index >= count - 1) {
    *out = cache[count - 1];
    return;
  }

  RGBAComponents c1 = cache[index];
  RGBAComponents c2 = cache[index + 1];
  out->r = c1.r + (c2.r - c1.r) * t;
  out->g = c1.g + (c2.g - c1.g) * t;
  out->b = c1.b + (c2.b - c1.b) * t;
  out->a = c1.a + (c2.a - c1.a) * t;
}

- (UIColor *)colorAtGradientPosition:(CGFloat)position {
  RGBAComponents rgba;
  [self colorAtGradientPosition:position rgba:&rgba];
  return [UIColor colorWithRed:rgba.r green:rgba.g blue:rgba.b alpha:rgba.a];
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context {
  CGRect pointsRect = CGPathGetBoundingBox(self.path);
  CGRect mapRectCG = [self rectForMapRect:mapRect];
  if (!CGRectIntersectsRect(pointsRect, mapRectCG)) {
    return;
  }

  CGFloat lineWidth = self.lineWidth / zoomScale;
  CGContextSetLineWidth(context, lineWidth);
  CGContextSetLineCap(context, self.lineCap);
  CGContextSetLineJoin(context, self.lineJoin);

  // drawMapRect: runs on MapKit's background render queues while
  // updatePolyline: swaps these ivars on the main thread; snapshot them so
  // one frame draws from a consistent pair
  MKPolyline *polyline = _polyline;
  NSArray<NSNumber *> *distances = _cumulativeDistances;
  CGFloat totalLength = _totalLength;

  if (polyline.pointCount < 2) {
    return;
  }
  NSUInteger segmentCount = polyline.pointCount - 1;

  // Snake animation: grow from start, then shrink from start
  if (_animated && distances.count > 1 && totalLength > 0) {
    CGFloat trailLength = MAX(0.01, MIN(1.0, _animatedOptions.trailLength));
    CGFloat maxProgress = (trailLength < 1.0) ? 1.0 : 2.0;
    CGFloat progress = MIN(_animationProgress, maxProgress);
    CGFloat easedProgress = [self applyEasing:progress / maxProgress] * maxProgress;

    CGFloat headDist, tailDist;

    if (trailLength < 1.0) {
      headDist = easedProgress * totalLength;
      tailDist = MAX(0, headDist - totalLength * trailLength);
    } else if (easedProgress <= 1.0) {
      tailDist = 0;
      headDist = easedProgress * totalLength;
    } else {
      CGFloat shrinkProgress = easedProgress - 1.0;
      tailDist = shrinkProgress * totalLength;
      headDist = totalLength;
    }

    if (headDist <= tailDist) {
      return;
    }

    CGFloat visibleLength = headDist - tailDist;
    NSUInteger startIndex = [self indexForDistance:tailDist inDistances:distances];
    NSUInteger endIndex = [self indexForDistance:headDist inDistances:distances];

    // distances may lag behind the polyline (or vice versa) for a frame;
    // never index past either
    NSUInteger maxSegment = MIN(segmentCount, distances.count - 1);

    for (NSUInteger i = startIndex; i <= endIndex && i < maxSegment; i++) {
      CGFloat segStartDist = distances[i].doubleValue;
      CGFloat segEndDist = distances[i + 1].doubleValue;

      if (segEndDist <= tailDist || segStartDist >= headDist) {
        continue;
      }

      CGPoint segStart = [self pointForMapPoint:polyline.points[i]];
      CGPoint segEnd = [self pointForMapPoint:polyline.points[i + 1]];

      CGPoint drawStart = segStart;
      CGPoint drawEnd = segEnd;
      CGFloat drawStartDist = segStartDist;
      CGFloat drawEndDist = segEndDist;
      CGFloat segLength = segEndDist - segStartDist;

      if (segStartDist < tailDist && segLength > 0) {
        CGFloat t = (tailDist - segStartDist) / segLength;
        drawStart.x = segStart.x + (segEnd.x - segStart.x) * t;
        drawStart.y = segStart.y + (segEnd.y - segStart.y) * t;
        drawStartDist = tailDist;
      }

      if (segEndDist > headDist && segLength > 0) {
        CGFloat t = (headDist - segStartDist) / segLength;
        drawEnd.x = segStart.x + (segEnd.x - segStart.x) * t;
        drawEnd.y = segStart.y + (segEnd.y - segStart.y) * t;
        drawEndDist = headDist;
      }

      CGFloat gradientStart = (drawStartDist - tailDist) / visibleLength;
      CGFloat gradientEnd = (drawEndDist - tailDist) / visibleLength;

      RGBAComponents startRGBA, endRGBA;
      [self colorAtGradientPosition:gradientStart rgba:&startRGBA];
      [self colorAtGradientPosition:gradientEnd rgba:&endRGBA];

      CGFloat components[] = {
        startRGBA.r, startRGBA.g, startRGBA.b, startRGBA.a,
        endRGBA.r, endRGBA.g, endRGBA.b, endRGBA.a
      };
      CGGradientRef gradient = CGGradientCreateWithColorComponents(_colorSpace, components, NULL, 2);

      CGContextSaveGState(context);
      CGContextBeginPath(context);
      CGContextMoveToPoint(context, drawStart.x, drawStart.y);
      CGContextAddLineToPoint(context, drawEnd.x, drawEnd.y);
      CGContextReplacePathWithStrokedPath(context);
      CGContextClip(context);

      CGContextDrawLinearGradient(context, gradient, drawStart, drawEnd, 0);

      CGContextRestoreGState(context);
      CGGradientRelease(gradient);
    }
    return;
  }

  // Static gradient rendering
  if (_strokeColors && _strokeColors.count > 1) {
    for (NSUInteger i = 0; i < segmentCount; i++) {
      CGPoint startPoint = [self pointForMapPoint:polyline.points[i]];
      CGPoint endPoint = [self pointForMapPoint:polyline.points[i + 1]];

      CGFloat gradientStart = (CGFloat)i / segmentCount;
      CGFloat gradientEnd = (CGFloat)(i + 1) / segmentCount;

      RGBAComponents startRGBA, endRGBA;
      [self colorAtGradientPosition:gradientStart rgba:&startRGBA];
      [self colorAtGradientPosition:gradientEnd rgba:&endRGBA];

      CGFloat components[] = {
        startRGBA.r, startRGBA.g, startRGBA.b, startRGBA.a,
        endRGBA.r, endRGBA.g, endRGBA.b, endRGBA.a
      };
      CGGradientRef gradient = CGGradientCreateWithColorComponents(_colorSpace, components, NULL, 2);

      CGContextSaveGState(context);
      CGContextBeginPath(context);
      CGContextMoveToPoint(context, startPoint.x, startPoint.y);
      CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
      CGContextReplacePathWithStrokedPath(context);
      CGContextClip(context);

      CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

      CGContextRestoreGState(context);
      CGGradientRelease(gradient);
    }
    return;
  }

  // Single color
  CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
  CGContextAddPath(context, self.path);
  CGContextStrokePath(context);
}

@end
