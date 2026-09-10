#pragma once

#import <UIKit/UIKit.h>

static inline CGPoint LuggMapInsetOffset(UIEdgeInsets insets) {
  return CGPointMake((insets.left - insets.right) / 2.0,
                     (insets.top - insets.bottom) / 2.0);
}

static inline UIEdgeInsets
LuggMapInsetsAtProgress(UIEdgeInsets from, UIEdgeInsets to, CGFloat progress) {
  // Ease out cubic
  CGFloat t = 1.0 - (1.0 - progress) * (1.0 - progress) * (1.0 - progress);
  return UIEdgeInsetsMake(from.top + (to.top - from.top) * t,
                          from.left + (to.left - from.left) * t,
                          from.bottom + (to.bottom - from.bottom) * t,
                          from.right + (to.right - from.right) * t);
}
