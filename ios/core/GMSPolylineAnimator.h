#import "PolylineAnimatorBase.h"
#import <GoogleMaps/GoogleMaps.h>

@interface GMSPolylineAnimator : PolylineAnimatorBase <PolylineAnimator>

@property(nonatomic, weak) GMSPolyline *polyline;
@property(nonatomic, assign) BOOL animated;
@property(nonatomic, strong) PolylineAnimatedOptions *animatedOptions;

- (void)update;
- (void)pause;
- (void)resume;

@end
