#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggMarkerView;
@class LuggCalloutView;

static inline double LuggWallClockMilliseconds(void) {
  return (CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970) * 1000;
}

// A timed path from the `path*` props. Immutable: a new object means a new path.
@interface LuggMarkerPath : NSObject

@property(nonatomic, readonly) NSUInteger count;
@property(nonatomic, readonly) const CLLocationCoordinate2D *coordinates;
// Milliseconds after the first keyframe.
@property(nonatomic, readonly) const double *times;
// Degrees, or NULL when the path has no rotations.
@property(nonatomic, readonly, nullable) const double *rotations;
// Wall-clock milliseconds at the first keyframe.
@property(nonatomic, readonly) double startTime;
// Milliseconds from the first keyframe to the last.
@property(nonatomic, readonly) double duration;
@property(nonatomic, readonly) BOOL loop;

// Milliseconds into the path at wall-clock `now`, wrapped into a lap when looping.
- (double)progressAt:(double)now;
// Position at wall-clock `now`. Sets `rotation` only when the path has rotations.
- (CLLocationCoordinate2D)coordinateAt:(double)now
                              rotation:(nullable CLLocationDegrees *)rotation;

@end

@protocol LuggMarkerViewDelegate <NSObject>
@optional
- (void)markerViewDidLayout:(LuggMarkerView *)markerView;
- (void)markerViewDidUpdate:(LuggMarkerView *)markerView;
- (void)showCalloutForMarkerView:(LuggMarkerView *)markerView;
- (void)hideCalloutForMarkerView:(LuggMarkerView *)markerView;
@end

@interface LuggMarkerView : RCTViewComponentView

@property(nonatomic, readonly, nullable) NSString *name;
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly, nullable) NSString *title;
@property(nonatomic, readonly, nullable) NSString *markerDescription;
@property(nonatomic, readonly) CGPoint anchor;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, readonly) CLLocationDegrees rotate;
@property(nonatomic, readonly) CGFloat scale;
@property(nonatomic, readonly) BOOL rasterize;
@property(nonatomic, readonly) BOOL centerOnPress;
@property(nonatomic, readonly) BOOL draggable;
@property(nonatomic, readonly, nullable) LuggMarkerPath *path;
@property(nonatomic, readonly) BOOL hasCustomView;
@property(nonatomic, readonly) BOOL didLayout;
@property(nonatomic, readonly) UIView *iconView;
@property(nonatomic, readonly, nullable) LuggCalloutView *calloutView;
@property(nonatomic, weak, nullable) id<LuggMarkerViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *marker;

- (nullable UIImage *)createIconImage;
- (nullable UIImage *)createScaledIconImage;
- (void)resetIconViewTransform;
- (void)emitPressEventWithPoint:(CGPoint)point;
- (void)emitDragStartEventWithPoint:(CGPoint)point;
- (void)emitDragChangeEventWithPoint:(CGPoint)point;
- (void)emitDragEndEventWithPoint:(CGPoint)point;
- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate;

@end

NS_ASSUME_NONNULL_END
