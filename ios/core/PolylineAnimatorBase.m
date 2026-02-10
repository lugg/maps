#import "PolylineAnimatorBase.h"

@implementation PolylineAnimatedOptions

+ (instancetype)defaultOptions {
  PolylineAnimatedOptions *options = [[PolylineAnimatedOptions alloc] init];
  options.duration = 2.15;
  options.easing = @"linear";
  options.trailLength = 1.0;
  options.delay = 0;
  return options;
}

@end

@implementation PolylineAnimatorBase

- (instancetype)init {
  if (self = [super init]) {
    _animatedOptions = [PolylineAnimatedOptions defaultOptions];
    _colorCache = NULL;
    _colorCacheCount = 0;
  }
  return self;
}

- (void)dealloc {
  free(_colorCache);
}

- (void)setStrokeColors:(NSArray<UIColor *> *)strokeColors {
  _strokeColors = strokeColors;
  [self rebuildColorCache];
}

- (void)rebuildColorCache {
  free(_colorCache);
  _colorCache = NULL;
  _colorCacheCount = _strokeColors.count;
  if (_colorCacheCount == 0) return;

  _colorCache = (RGBAComponents *)malloc(sizeof(RGBAComponents) * _colorCacheCount);
  for (NSUInteger i = 0; i < _colorCacheCount; i++) {
    [_strokeColors[i] getRed:&_colorCache[i].r
                       green:&_colorCache[i].g
                        blue:&_colorCache[i].b
                       alpha:&_colorCache[i].a];
  }
}

- (CGFloat)applyEasing:(CGFloat)t {
  NSString *easing = self.animatedOptions.easing ?: @"linear";

  if ([easing isEqualToString:@"easeIn"]) {
    return t * t;
  } else if ([easing isEqualToString:@"easeOut"]) {
    return t * (2 - t);
  } else if ([easing isEqualToString:@"easeInOut"]) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }
  return t;
}

- (void)colorAtGradientPosition:(CGFloat)position rgba:(RGBAComponents *)out {
  if (_colorCacheCount == 0) {
    *out = (RGBAComponents){0, 0, 0, 1};
    return;
  }
  if (_colorCacheCount == 1) {
    *out = _colorCache[0];
    return;
  }

  position = MAX(0, MIN(1, position));
  CGFloat scaledPos = position * (_colorCacheCount - 1);
  NSUInteger index = (NSUInteger)scaledPos;
  CGFloat t = scaledPos - index;

  if (index >= _colorCacheCount - 1) {
    *out = _colorCache[_colorCacheCount - 1];
    return;
  }

  RGBAComponents c1 = _colorCache[index];
  RGBAComponents c2 = _colorCache[index + 1];
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

@end
