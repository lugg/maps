#import <MapKit/MapKit.h>
#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LuggAppleMapViewContent : MKMapView
@end

@interface LuggAppleMapView : RCTViewComponentView

- (MKMapView *)mapView;

@end

NS_ASSUME_NONNULL_END
