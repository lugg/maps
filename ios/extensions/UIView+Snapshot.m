#import "UIView+Snapshot.h"

@implementation UIView (LuggSnapshot)

- (nullable UIImageView *)lugg_snapshotImageView {
  CGRect bounds = self.bounds;
  if (bounds.size.width <= 0 || bounds.size.height <= 0)
    return nil;

  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithBounds:bounds];
  UIImage *image = [renderer
      imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [self drawViewHierarchyInRect:bounds afterScreenUpdates:YES];
      }];

  UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.frame];
  imageView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  imageView.image = image;
  return imageView;
}

@end
