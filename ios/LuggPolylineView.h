#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggPolylineView;

@protocol LuggPolylineViewDelegate <NSObject>
@optional
- (void)polylineViewDidUpdate:(LuggPolylineView *)polylineView;
@end

@interface LuggPolylineView : RCTViewComponentView

@property(nonatomic, readonly) NSArray<CLLocation *> *coordinates;
@property(nonatomic, readonly) NSArray<UIColor *> *strokeColors;
@property(nonatomic, readonly) BOOL animated;
@property(nonatomic, readonly) CGFloat strokeWidth;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, weak, nullable) id<LuggPolylineViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *polyline;
@property(nonatomic, weak, nullable) NSObject *renderer;
@property(nonatomic, strong, nullable) NSArray *cachedSpans;

@end

NS_ASSUME_NONNULL_END
