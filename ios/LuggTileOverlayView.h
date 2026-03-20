#import <CoreLocation/CoreLocation.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LuggTileOverlayView;

@protocol LuggTileOverlayViewDelegate <NSObject>
@optional
- (void)tileOverlayViewDidUpdate:(LuggTileOverlayView *)tileOverlayView;
@end

@interface LuggTileOverlayView : RCTViewComponentView

@property(nonatomic, readonly) NSString *urlTemplate;
@property(nonatomic, readonly) NSInteger tileSize;
@property(nonatomic, readonly) CGFloat opacity;
@property(nonatomic, readonly) BOOL hasBounds;
@property(nonatomic, readonly) CLLocationCoordinate2D northeast;
@property(nonatomic, readonly) CLLocationCoordinate2D southwest;
@property(nonatomic, readonly) NSInteger zIndex;
@property(nonatomic, readonly) BOOL tappable;
@property(nonatomic, weak, nullable) id<LuggTileOverlayViewDelegate> delegate;
@property(nonatomic, strong, nullable) NSObject *overlay;

- (void)emitPressEvent;

@end

NS_ASSUME_NONNULL_END
