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
  CGPoint _offset;
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
    _offset = CGPointZero;
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
    if (newViewProps.offset.x != oldViewProps.offset.x ||
        newViewProps.offset.y != oldViewProps.offset.y) {
      _offset = CGPointMake(newViewProps.offset.x, newViewProps.offset.y);
    }
  } else if (newViewProps.offset.x != 0 || newViewProps.offset.y != 0) {
    _offset = CGPointMake(newViewProps.offset.x, newViewProps.offset.y);
  }

  [super updateProps:props oldProps:oldProps];
  [_delegate calloutViewDidUpdate:self];
}

- (BOOL)bubbled {
  return _bubbled;
}

- (CGPoint)offset {
  return _offset;
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
