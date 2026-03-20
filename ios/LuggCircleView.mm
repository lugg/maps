#import "LuggCircleView.h"
#import "events/CirclePressEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>

using namespace facebook::react;
using namespace luggmaps::events;

@interface LuggCircleView () <RCTLuggCircleViewViewProtocol>
@end

@implementation LuggCircleView {
  CLLocationCoordinate2D _center;
  CLLocationDistance _radius;
  UIColor *_strokeColor;
  UIColor *_fillColor;
  CGFloat _strokeWidth;
  NSInteger _zIndex;
  BOOL _tappable;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggCircleViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggCircleViewProps>();
    _props = defaultProps;

    _center = CLLocationCoordinate2DMake(0, 0);
    _radius = 0;
    _strokeColor = [UIColor blackColor];
    _fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    _strokeWidth = 1.0;

    self.hidden = YES;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  [super updateProps:props oldProps:oldProps];
  const auto &newViewProps =
      *std::static_pointer_cast<LuggCircleViewProps const>(props);

  _center = CLLocationCoordinate2DMake(newViewProps.center.latitude,
                                       newViewProps.center.longitude);
  _radius = newViewProps.radius;

  if (newViewProps.strokeColor) {
    UIColor *color = RCTUIColorFromSharedColor(newViewProps.strokeColor);
    if (color) {
      _strokeColor = color;
    }
  }

  if (newViewProps.fillColor) {
    UIColor *color = RCTUIColorFromSharedColor(newViewProps.fillColor);
    if (color) {
      _fillColor = color;
    }
  }

  _strokeWidth = newViewProps.strokeWidth > 0 ? newViewProps.strokeWidth : 1.0;
  _zIndex = newViewProps.zIndex.value_or(0);
  _tappable = newViewProps.tappable;
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask {
  [super finalizeUpdates:updateMask];

  if (updateMask & RNComponentViewUpdateMaskProps) {
    if ([self.delegate respondsToSelector:@selector(circleViewDidUpdate:)]) {
      [self.delegate circleViewDidUpdate:self];
    }
  }
}

- (CLLocationCoordinate2D)center {
  return _center;
}

- (CLLocationDistance)radius {
  return _radius;
}

- (UIColor *)strokeColor {
  return _strokeColor;
}

- (UIColor *)fillColor {
  return _fillColor;
}

- (CGFloat)strokeWidth {
  return _strokeWidth;
}

- (NSInteger)zIndex {
  return _zIndex;
}

- (BOOL)tappable {
  return _tappable;
}

- (void)emitPressEvent {
  CirclePressEvent::emit<LuggCircleViewEventEmitter>(_eventEmitter);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  self.circle = nil;
  self.renderer = nil;
  self.delegate = nil;
}

Class<RCTComponentViewProtocol> LuggCircleViewCls(void) {
  return LuggCircleView.class;
}

@end
