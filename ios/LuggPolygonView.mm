#import "LuggPolygonView.h"
#import "events/PolygonPressEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <React/RCTConversions.h>

using namespace facebook::react;
using namespace luggmaps::events;

@interface LuggPolygonView () <RCTLuggPolygonViewViewProtocol>
@end

@implementation LuggPolygonView {
  NSArray<CLLocation *> *_coordinates;
  NSArray<NSArray<CLLocation *> *> *_holes;
  UIColor *_strokeColor;
  UIColor *_fillColor;
  CGFloat _strokeWidth;
  NSInteger _zIndex;
  BOOL _tappable;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggPolygonViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggPolygonViewProps>();
    _props = defaultProps;

    _coordinates = @[];
    _holes = @[];
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
      *std::static_pointer_cast<LuggPolygonViewProps const>(props);

  NSMutableArray<CLLocation *> *coords = [NSMutableArray array];
  for (const auto &coord : newViewProps.coordinates) {
    CLLocation *location =
        [[CLLocation alloc] initWithLatitude:coord.latitude
                                   longitude:coord.longitude];
    [coords addObject:location];
  }
  _coordinates = [coords copy];

  NSMutableArray<NSArray<CLLocation *> *> *holesArray = [NSMutableArray array];
  for (const auto &hole : newViewProps.holes) {
    NSMutableArray<CLLocation *> *holeCoords = [NSMutableArray array];
    for (const auto &coord : hole) {
      CLLocation *location =
          [[CLLocation alloc] initWithLatitude:coord.latitude
                                     longitude:coord.longitude];
      [holeCoords addObject:location];
    }
    [holesArray addObject:[holeCoords copy]];
  }
  _holes = [holesArray copy];

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
    if ([self.delegate respondsToSelector:@selector(polygonViewDidUpdate:)]) {
      [self.delegate polygonViewDidUpdate:self];
    }
  }
}

- (NSArray<CLLocation *> *)coordinates {
  return _coordinates;
}

- (NSArray<NSArray<CLLocation *> *> *)holes {
  return _holes;
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
  PolygonPressEvent::emit<LuggPolygonViewEventEmitter>(_eventEmitter);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  self.polygon = nil;
  self.renderer = nil;
  self.delegate = nil;
}

Class<RCTComponentViewProtocol> LuggPolygonViewCls(void) {
  return LuggPolygonView.class;
}

@end
