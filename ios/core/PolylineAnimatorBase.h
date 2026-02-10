#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PolylineAnimatedOptions : NSObject

@property(nonatomic, assign) NSTimeInterval duration;
@property(nonatomic, copy) NSString *easing;
@property(nonatomic, assign) CGFloat trailLength;
@property(nonatomic, assign) NSTimeInterval delay;

+ (instancetype)defaultOptions;

@end

@protocol PolylineAnimator <NSObject>

@property(nonatomic, strong) NSArray<CLLocation *> *coordinates;
@property(nonatomic, strong) NSArray<UIColor *> *strokeColors;
@property(nonatomic, assign) BOOL animated;
@property(nonatomic, strong) PolylineAnimatedOptions *animatedOptions;

- (void)update;

@end

typedef struct {
  CGFloat r, g, b, a;
} RGBAComponents;

@interface PolylineAnimatorBase : NSObject {
@protected
  RGBAComponents *_colorCache;
  NSUInteger _colorCacheCount;
}

@property(nonatomic, strong) NSArray<CLLocation *> *coordinates;
@property(nonatomic, strong) NSArray<UIColor *> *strokeColors;
@property(nonatomic, strong) PolylineAnimatedOptions *animatedOptions;

- (UIColor *)colorAtGradientPosition:(CGFloat)position;
- (void)colorAtGradientPosition:(CGFloat)position rgba:(RGBAComponents *)out;
- (CGFloat)applyEasing:(CGFloat)t;

@end
