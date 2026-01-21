#import <GoogleMaps/GoogleMaps.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuggGoogleMapView : RCTViewComponentView

@property(nonatomic, readonly, nullable) GMSMapView *mapView;

@end

NS_ASSUME_NONNULL_END
