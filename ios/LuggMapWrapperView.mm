#import "LuggMapWrapperView.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;

@interface LuggMapWrapperView () <RCTLuggMapWrapperViewViewProtocol>
@end

@implementation LuggMapWrapperView

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<
      LuggMapWrapperViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps =
        std::make_shared<const LuggMapWrapperViewProps>();
    _props = defaultProps;
  }

  return self;
}

Class<RCTComponentViewProtocol> LuggMapWrapperViewCls(void) {
  return LuggMapWrapperView.class;
}

@end
