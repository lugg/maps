#import <MapKit/MapKit.h>

@interface LuggAnnotationView : MKAnnotationView
@end

@interface LuggMarkerAnnotationView : MKMarkerAnnotationView
@end

// Shared hit-test helpers for annotation views with subviews outside bounds
BOOL LuggAnnotationPointInside(UIView *self, CGPoint point, UIEvent *event);
UIView *_Nullable LuggAnnotationHitTest(UIView *self, CGPoint point,
                                         UIEvent *event);
