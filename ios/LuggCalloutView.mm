#import "LuggCalloutView.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface LuggCalloutContentView : UIView
- (void)updateContentSize;
@end

@implementation LuggCalloutContentView

- (CGSize)intrinsicContentSize {
  CGFloat width = 0;
  CGFloat height = 0;
  for (UIView *subview in self.subviews) {
    width = MAX(width, CGRectGetMaxX(subview.frame));
    height = MAX(height, CGRectGetMaxY(subview.frame));
  }
  if (width > 0 && height > 0) {
    return CGSizeMake(width, height);
  }
  return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
}

- (void)updateContentSize {
  CGSize size = [self intrinsicContentSize];
  if (size.width > 0 && size.height > 0) {
    self.frame = CGRectMake(0, 0, size.width, size.height);
  }
  [self invalidateIntrinsicContentSize];
}

@end

@interface LuggCalloutView () <RCTLuggCalloutViewViewProtocol>
@end

@implementation LuggCalloutView {
  LuggCalloutContentView *_contentView;
  BOOL _bubbled;
  CGPoint _anchor;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggCalloutViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggCalloutViewProps>();
    _props = defaultProps;

    _bubbled = YES;
    _anchor = CGPointMake(0.5, 1.0);
    _contentView = [[LuggCalloutContentView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];

    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
  }

  return self;
}

- (void)updateProps:(const Props::Shared &)props
           oldProps:(const Props::Shared &)oldProps {
  const auto &newViewProps =
      *std::static_pointer_cast<LuggCalloutViewProps const>(props);

  _bubbled = newViewProps.bubbled;

  if (oldProps) {
    const auto &oldViewProps =
        *std::static_pointer_cast<LuggCalloutViewProps const>(oldProps);
    if (newViewProps.anchor.x != oldViewProps.anchor.x ||
        newViewProps.anchor.y != oldViewProps.anchor.y) {
      _anchor = CGPointMake(newViewProps.anchor.x, newViewProps.anchor.y);
    }
  } else if (newViewProps.anchor.x != 0 || newViewProps.anchor.y != 0) {
    _anchor = CGPointMake(newViewProps.anchor.x, newViewProps.anchor.y);
  }

  [super updateProps:props oldProps:oldProps];
  [_delegate calloutViewDidUpdate:self];
}

- (BOOL)bubbled {
  return _bubbled;
}

- (CGPoint)anchor {
  return _anchor;
}

- (void)mountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                          index:(NSInteger)index {
  [_contentView insertSubview:childComponentView atIndex:index];
  [_contentView updateContentSize];
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  [childComponentView removeFromSuperview];
  [_contentView updateContentSize];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGSize oldSize = _contentView.bounds.size;
  [_contentView updateContentSize];
  CGSize newSize = _contentView.bounds.size;
  if (!CGSizeEqualToSize(oldSize, newSize)) {
    [_delegate calloutViewDidUpdate:self];
  }
}

- (BOOL)hasCustomContent {
  return _contentView.subviews.count > 0;
}

- (UIView *)contentView {
  return _contentView;
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  for (UIView *subview in _contentView.subviews) {
    [subview removeFromSuperview];
  }
}

Class<RCTComponentViewProtocol> LuggCalloutViewCls(void) {
  return LuggCalloutView.class;
}

@end
