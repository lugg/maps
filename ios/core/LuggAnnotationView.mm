#import "LuggAnnotationView.h"

BOOL LuggAnnotationPointInside(UIView *self, CGPoint point, UIEvent *event) {
  for (UIView *subview in self.subviews) {
    CGPoint subviewPoint = [subview convertPoint:point fromView:self];
    if ([subview pointInside:subviewPoint withEvent:event])
      return YES;
  }
  return NO;
}

UIView *_Nullable LuggAnnotationHitTest(UIView *self, CGPoint point,
                                         UIEvent *event) {
  for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
    CGPoint subviewPoint = [subview convertPoint:point fromView:self];
    UIView *result = [subview hitTest:subviewPoint withEvent:event];
    if (result)
      return result;
  }
  return nil;
}

@implementation LuggAnnotationView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  if ([super pointInside:point withEvent:event])
    return YES;
  return LuggAnnotationPointInside(self, point, event);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *result = [super hitTest:point withEvent:event];
  if (result)
    return result;
  return LuggAnnotationHitTest(self, point, event);
}

@end

@implementation LuggMarkerAnnotationView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  if ([super pointInside:point withEvent:event])
    return YES;
  return LuggAnnotationPointInside(self, point, event);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *result = [super hitTest:point withEvent:event];
  if (result)
    return result;
  return LuggAnnotationHitTest(self, point, event);
}

@end
