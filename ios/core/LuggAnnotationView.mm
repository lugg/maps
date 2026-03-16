#import "LuggAnnotationView.h"

@implementation LuggAnnotationView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  if ([super pointInside:point withEvent:event])
    return YES;

  for (UIView *subview in self.subviews) {
    CGPoint subviewPoint = [subview convertPoint:point fromView:self];
    if ([subview pointInside:subviewPoint withEvent:event])
      return YES;
  }
  return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *result = [super hitTest:point withEvent:event];
  if (result)
    return result;

  for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
    CGPoint subviewPoint = [subview convertPoint:point fromView:self];
    result = [subview hitTest:subviewPoint withEvent:event];
    if (result)
      return result;
  }
  return nil;
}

@end

@implementation LuggMarkerAnnotationView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  if ([super pointInside:point withEvent:event])
    return YES;

  for (UIView *subview in self.subviews) {
    CGPoint subviewPoint = [subview convertPoint:point fromView:self];
    if ([subview pointInside:subviewPoint withEvent:event])
      return YES;
  }
  return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *result = [super hitTest:point withEvent:event];
  if (result)
    return result;

  for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
    CGPoint subviewPoint = [subview convertPoint:point fromView:self];
    result = [subview hitTest:subviewPoint withEvent:event];
    if (result)
      return result;
  }
  return nil;
}

@end
