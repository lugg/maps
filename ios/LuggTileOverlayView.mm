#import "LuggTileOverlayView.h"
#import "events/TileOverlayPressEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

@interface LuggTileOverlayView () <RCTLuggTileOverlayViewViewProtocol>
@end

@implementation LuggTileOverlayView {
  NSString *_urlTemplate;
  NSInteger _tileSize;
  CGFloat _opacity;
  BOOL _hasBounds;
  CLLocationCoordinate2D _northeast;
  CLLocationCoordinate2D _southwest;
  NSInteger _zIndex;
  BOOL _tappable;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggTileOverlayViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggTileOverlayViewProps>();
    _props = defaultProps;

    _urlTemplate = @"";
    _tileSize = 256;
    _opacity = 1.0;

    self.hidden = YES;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  [super updateProps:props oldProps:oldProps];
  const auto &newViewProps =
      *std::static_pointer_cast<LuggTileOverlayViewProps const>(props);

  _urlTemplate =
      [NSString stringWithUTF8String:newViewProps.urlTemplate.c_str()];
  _tileSize = newViewProps.tileSize;
  _opacity = newViewProps.opacity;

  auto ne = newViewProps.bounds.northeast;
  auto sw = newViewProps.bounds.southwest;
  _hasBounds = (ne.latitude != 0 || ne.longitude != 0 || sw.latitude != 0 ||
                sw.longitude != 0);
  if (_hasBounds) {
    _northeast = CLLocationCoordinate2DMake(ne.latitude, ne.longitude);
    _southwest = CLLocationCoordinate2DMake(sw.latitude, sw.longitude);
  }

  _zIndex = newViewProps.zIndex.value_or(0);
  _tappable = newViewProps.tappable;
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask {
  [super finalizeUpdates:updateMask];

  if (updateMask & RNComponentViewUpdateMaskProps) {
    if ([self.delegate
            respondsToSelector:@selector(tileOverlayViewDidUpdate:)]) {
      [self.delegate tileOverlayViewDidUpdate:self];
    }
  }
}

- (NSString *)urlTemplate {
  return _urlTemplate;
}

- (NSInteger)tileSize {
  return _tileSize;
}

- (CGFloat)opacity {
  return _opacity;
}

- (BOOL)hasBounds {
  return _hasBounds;
}

- (CLLocationCoordinate2D)northeast {
  return _northeast;
}

- (CLLocationCoordinate2D)southwest {
  return _southwest;
}

- (NSInteger)zIndex {
  return _zIndex;
}

- (BOOL)tappable {
  return _tappable;
}

- (void)emitPressEvent {
  TileOverlayPressEvent::emit<LuggTileOverlayViewEventEmitter>(_eventEmitter);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  self.overlay = nil;
  self.delegate = nil;
}

Class<RCTComponentViewProtocol> LuggTileOverlayViewCls(void) {
  return LuggTileOverlayView.class;
}

@end
