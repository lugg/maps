#import "LuggGroundOverlayView.h"
#import "events/GroundOverlayPressEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

@interface LuggGroundOverlayView () <RCTLuggGroundOverlayViewViewProtocol>
@end

@implementation LuggGroundOverlayView {
  NSString *_imageUri;
  CLLocationCoordinate2D _northeast;
  CLLocationCoordinate2D _southwest;
  CGFloat _opacity;
  CGFloat _bearing;
  NSInteger _zIndex;
  BOOL _tappable;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggGroundOverlayViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggGroundOverlayViewProps>();
    _props = defaultProps;

    _imageUri = @"";
    _northeast = CLLocationCoordinate2DMake(0, 0);
    _southwest = CLLocationCoordinate2DMake(0, 0);
    _opacity = 1.0;
    _bearing = 0.0;

    self.hidden = YES;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props
           oldProps:(Props::Shared const &)oldProps {
  [super updateProps:props oldProps:oldProps];
  const auto &newViewProps =
      *std::static_pointer_cast<LuggGroundOverlayViewProps const>(props);

  _imageUri = [NSString stringWithUTF8String:newViewProps.image.c_str()];

  _northeast =
      CLLocationCoordinate2DMake(newViewProps.bounds.northeast.latitude,
                                 newViewProps.bounds.northeast.longitude);
  _southwest =
      CLLocationCoordinate2DMake(newViewProps.bounds.southwest.latitude,
                                 newViewProps.bounds.southwest.longitude);

  _opacity = newViewProps.opacity;
  _bearing = newViewProps.bearing;
  _zIndex = newViewProps.zIndex.value_or(0);
  _tappable = newViewProps.tappable;
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask {
  [super finalizeUpdates:updateMask];

  if (updateMask & RNComponentViewUpdateMaskProps) {
    if ([self.delegate
            respondsToSelector:@selector(groundOverlayViewDidUpdate:)]) {
      [self.delegate groundOverlayViewDidUpdate:self];
    }
  }
}

- (NSString *)imageUri {
  return _imageUri;
}

- (CLLocationCoordinate2D)northeast {
  return _northeast;
}

- (CLLocationCoordinate2D)southwest {
  return _southwest;
}

- (CGFloat)opacity {
  return _opacity;
}

- (CGFloat)bearing {
  return _bearing;
}

- (NSInteger)zIndex {
  return _zIndex;
}

- (BOOL)tappable {
  return _tappable;
}

- (void)emitPressEvent {
  GroundOverlayPressEvent::emit<LuggGroundOverlayViewEventEmitter>(
      _eventEmitter);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  self.overlay = nil;
  self.delegate = nil;
}

Class<RCTComponentViewProtocol> LuggGroundOverlayViewCls(void) {
  return LuggGroundOverlayView.class;
}

@end
