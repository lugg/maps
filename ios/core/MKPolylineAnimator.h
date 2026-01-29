#import <MapKit/MapKit.h>

@interface MKPolylineAnimator : MKOverlayPathRenderer

- (id)initWithPolyline:(MKPolyline *)polyline;

@property(nonatomic, strong) NSArray<UIColor *> *strokeColors;
@property(nonatomic, assign) BOOL animated;

- (void)updatePolyline:(MKPolyline *)polyline;
- (void)pause;
- (void)resume;

@end
