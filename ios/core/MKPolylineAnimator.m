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
  NSArray<NSNumber *> *_cumulativeDistances;
  CGFloat _totalLength;
  CGColorSpaceRef _colorSpace;
}

- (id)initWithPolyline:(MKPolyline *)polyline {
  self = [super initWithOverlay:polyline];
  if (self) {
    _polyline = polyline;
    _animationProgress = 0;
    _colorSpace = CGColorSpaceCreateDeviceRGB();
    [self createPath];
  }
  return self;
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

- (void)animationTick:(CADisplayLink *)displayLink {
  CGFloat speed = displayLink.duration / 1.0;
  _animationProgress += speed;

  if (_animationProgress >= 2.15) {
    _animationProgress = 0;
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

- (UIColor *)colorAtGradientPosition:(CGFloat)position {
  if (!_strokeColors || _strokeColors.count == 0) {
    return self.strokeColor;
  }
  if (_strokeColors.count == 1) {
    return _strokeColors[0];
  }

  position = MAX(0, MIN(1, position));
  CGFloat scaledPos = position * (_strokeColors.count - 1);
  NSUInteger index = (NSUInteger)floor(scaledPos);
  CGFloat t = scaledPos - index;

  if (index >= _strokeColors.count - 1) {
    return _strokeColors.lastObject;
  }

  UIColor *c1 = _strokeColors[index];
  UIColor *c2 = _strokeColors[index + 1];

  CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
  [c1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  [c2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

  return [UIColor colorWithRed:r1 + (r2 - r1) * t
                         green:g1 + (g2 - g1) * t
                          blue:b1 + (b2 - b1) * t
                         alpha:a1 + (a2 - a1) * t];
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

  NSUInteger segmentCount = _polyline.pointCount - 1;
  if (segmentCount == 0) {
    return;
  }

  // Snake animation: grow from start, then shrink from start
  if (_animated && _polyline.pointCount > 1 && _totalLength > 0) {
    CGFloat progress = MIN(_animationProgress, 2.0);
    CGFloat headDist, tailDist;

    if (progress <= 1.0) {
      tailDist = 0;
      headDist = progress * _totalLength;
    } else {
      CGFloat shrinkProgress = progress - 1.0;
      tailDist = shrinkProgress * _totalLength;
      headDist = _totalLength;
    }

    if (headDist <= tailDist) {
      return;
    }

    CGFloat visibleLength = headDist - tailDist;
    NSUInteger startIndex = [self indexForDistance:tailDist];
    NSUInteger endIndex = [self indexForDistance:headDist];

    for (NSUInteger i = startIndex; i <= endIndex && i < segmentCount; i++) {
      CGFloat segStartDist = _cumulativeDistances[i].doubleValue;
      CGFloat segEndDist = _cumulativeDistances[i + 1].doubleValue;

      if (segEndDist <= tailDist || segStartDist >= headDist) {
        continue;
      }

      CGPoint segStart = [self pointForMapPoint:_polyline.points[i]];
      CGPoint segEnd = [self pointForMapPoint:_polyline.points[i + 1]];

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

      UIColor *startColor = [self colorAtGradientPosition:gradientStart];
      UIColor *endColor = [self colorAtGradientPosition:gradientEnd];

      NSArray *colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
      CGGradientRef gradient = CGGradientCreateWithColors(_colorSpace, (__bridge CFArrayRef)colors, NULL);

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
      CGPoint startPoint = [self pointForMapPoint:_polyline.points[i]];
      CGPoint endPoint = [self pointForMapPoint:_polyline.points[i + 1]];

      CGFloat gradientStart = (CGFloat)i / segmentCount;
      CGFloat gradientEnd = (CGFloat)(i + 1) / segmentCount;

      UIColor *startColor = [self colorAtGradientPosition:gradientStart];
      UIColor *endColor = [self colorAtGradientPosition:gradientEnd];

      NSArray *colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
      CGGradientRef gradient = CGGradientCreateWithColors(_colorSpace, (__bridge CFArrayRef)colors, NULL);

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
