#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggPolygonView;

@protocol LuggPolygonViewDelegate <NSObject>
@optional
- (void)polygonViewDidUpdate:(LuggPolygonView *)polygonView;
@end

@interface LuggPolygonView : RCTViewComponentView

@property(nonatomic, readonly) NSArray<CLLocation *> *coordinates;
@property(nonatomic, readonly) NSArray<NSArray<CLLocation *> *> *holes;
@property(nonatomic, readonly) UIColor *strokeColor;
@property(nonatomic, readonly) UIColor *fillColor;
@property(nonatomic, readonly) CGFloat strokeWidth;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, readonly) BOOL tappable;
@property(nonatomic, weak, nullable) id<LuggPolygonViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *polygon;
@property(nonatomic, weak, nullable) NSObject *renderer;

- (void)emitPressEvent;

@end

NS_ASSUME_NONNULL_END
