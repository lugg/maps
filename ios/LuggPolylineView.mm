#import "LuggPolylineView.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>

using namespace facebook::react;

@interface LuggPolylineView () <RCTLuggPolylineViewViewProtocol>
@end

@implementation LuggPolylineView {
  NSArray<CLLocation *> *_coordinates;
  NSArray<UIColor *> *_strokeColors;
  BOOL _animated;
  CGFloat _strokeWidth;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggPolylineViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggPolylineViewProps>();
    _props = defaultProps;

    _coordinates = @[];
    _strokeColors = @[ [UIColor blackColor] ];
    _strokeWidth = 1.0;

    self.hidden = YES;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  [super updateProps:props oldProps:oldProps];
  const auto &newViewProps =
      *std::static_pointer_cast<LuggPolylineViewProps const>(props);

  NSMutableArray<CLLocation *> *coords = [NSMutableArray array];
  for (const auto &coord : newViewProps.coordinates) {
    CLLocation *location =
        [[CLLocation alloc] initWithLatitude:coord.latitude
                                   longitude:coord.longitude];
    [coords addObject:location];
  }
  _coordinates = [coords copy];

  NSMutableArray<UIColor *> *colors = [NSMutableArray array];
  for (const auto &color : newViewProps.strokeColors) {
    UIColor *uiColor = RCTUIColorFromSharedColor(color);
    if (uiColor) {
      [colors addObject:uiColor];
    }
  }
  NSArray<UIColor *> *newColors =
      colors.count > 0 ? [colors copy] : @[ [UIColor blackColor] ];
  if (![newColors isEqualToArray:_strokeColors]) {
    _strokeColors = newColors;
    self.cachedSpans = nil;
  }

  _animated = newViewProps.animated;

  _strokeWidth = newViewProps.strokeWidth > 0 ? newViewProps.strokeWidth : 1.0;
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask {
  [super finalizeUpdates:updateMask];

  if (updateMask & RNComponentViewUpdateMaskProps) {
    if ([self.delegate respondsToSelector:@selector(polylineViewDidUpdate:)]) {
      [self.delegate polylineViewDidUpdate:self];
    }
  }
}

- (NSArray<CLLocation *> *)coordinates {
  return _coordinates;
}

- (NSArray<UIColor *> *)strokeColors {
  return _strokeColors;
}

- (BOOL)animated {
  return _animated;
}

- (CGFloat)strokeWidth {
  return _strokeWidth;
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  self.polyline = nil;
  self.renderer = nil;
  self.cachedSpans = nil;
  self.delegate = nil;
}

Class<RCTComponentViewProtocol> LuggPolylineViewCls(void) {
  return LuggPolylineView.class;
}

@end
