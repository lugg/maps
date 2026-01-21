#import "LuggMarkerView.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface LuggMarkerView () <RCTLuggMarkerViewViewProtocol>
@end

@implementation LuggMarkerView {
  CLLocationCoordinate2D _coordinate;
  NSString *_title;
  NSString *_markerDescription;
  CGPoint _anchor;
  BOOL _didLayout;
  UIView *_iconView;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggMarkerViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggMarkerViewProps>();
    _props = defaultProps;

    _coordinate = CLLocationCoordinate2DMake(0, 0);
    _anchor = CGPointMake(0.5, 1.0);
    _didLayout = NO;

    _iconView = [[UIView alloc] init];
    _iconView.backgroundColor = [UIColor clearColor];

    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  [super updateProps:props oldProps:oldProps];
  const auto &newViewProps =
      *std::static_pointer_cast<LuggMarkerViewProps const>(props);

  _coordinate = CLLocationCoordinate2DMake(newViewProps.coordinate.latitude,
                                           newViewProps.coordinate.longitude);
  _title = [NSString stringWithUTF8String:newViewProps.title.c_str()];
  _markerDescription =
      [NSString stringWithUTF8String:newViewProps.description.c_str()];
  _anchor = CGPointMake(newViewProps.anchor.x, newViewProps.anchor.y);
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask {
  [super finalizeUpdates:updateMask];

  if (updateMask & RNComponentViewUpdateMaskProps) {
    if ([self.delegate respondsToSelector:@selector(markerViewDidUpdate:)]) {
      [self.delegate markerViewDidUpdate:self];
    }
  }
}

- (void)mountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                          index:(NSInteger)index {
  [_iconView insertSubview:childComponentView atIndex:index];
  _didLayout = NO;
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  [childComponentView removeFromSuperview];
  _didLayout = NO;
}

- (void)layoutSubviews {
  [super layoutSubviews];

  if (self.hasCustomView) {
    CGFloat width = 0;
    CGFloat height = 0;

    for (UIView *subview in _iconView.subviews) {
      CGFloat fw = subview.frame.origin.x + subview.frame.size.width;
      CGFloat fh = subview.frame.origin.y + subview.frame.size.height;
      width = MAX(fw, width);
      height = MAX(fh, height);
    }

    if (width > 0 && height > 0) {
      _iconView.frame = CGRectMake(0, 0, width, height);
    }
  }

  if (!_didLayout) {
    _didLayout = YES;
    [self.delegate markerViewDidLayout:self];
  }
}

- (CLLocationCoordinate2D)coordinate {
  return _coordinate;
}

- (NSString *)title {
  return _title;
}

- (NSString *)markerDescription {
  return _markerDescription;
}

- (CGPoint)anchor {
  return _anchor;
}

- (BOOL)hasCustomView {
  return _iconView.subviews.count > 0;
}

- (BOOL)didLayout {
  return _didLayout;
}

- (UIView *)iconView {
  return _iconView;
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  _didLayout = NO;
  self.marker = nil;
  self.delegate = nil;
  for (UIView *subview in _iconView.subviews) {
    [subview removeFromSuperview];
  }
}

Class<RCTComponentViewProtocol> LuggMarkerViewCls(void) {
  return LuggMarkerView.class;
}

@end
