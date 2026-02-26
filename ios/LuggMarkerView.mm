#import "LuggMarkerView.h"
#import "events/MarkerDragEvent.h"
#import "events/MarkerPressEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

@interface LuggMarkerView () <RCTLuggMarkerViewViewProtocol>
@end

@implementation LuggMarkerView {
  NSString *_name;
  CLLocationCoordinate2D _coordinate;
  NSString *_title;
  NSString *_markerDescription;
  CGPoint _anchor;
  NSInteger _zIndex;
  CLLocationDegrees _rotate;
  CGFloat _scale;
  BOOL _rasterize;
  BOOL _draggable;
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
    _zIndex = 0;
    _rotate = 0;
    _scale = 1;
    _rasterize = YES;
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

  _name = [NSString stringWithUTF8String:newViewProps.name.c_str()];
  _coordinate = CLLocationCoordinate2DMake(newViewProps.coordinate.latitude,
                                           newViewProps.coordinate.longitude);
  _title = [NSString stringWithUTF8String:newViewProps.title.c_str()];
  _markerDescription =
      [NSString stringWithUTF8String:newViewProps.description.c_str()];
  _anchor = CGPointMake(newViewProps.anchor.x, newViewProps.anchor.y);
  _zIndex = newViewProps.zIndex.value_or(0);
  _rotate = newViewProps.rotate;
  _scale = newViewProps.scale;
  _rasterize = newViewProps.rasterize;
  _draggable = newViewProps.draggable;
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

- (NSString *)name {
  return _name;
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

- (NSInteger)zIndex {
  return _zIndex;
}

- (CLLocationDegrees)rotate {
  return _rotate;
}

- (CGFloat)scale {
  return _scale;
}

- (BOOL)rasterize {
  return _rasterize;
}

- (BOOL)draggable {
  return _draggable;
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

- (UIImage *)createIconImage {
  CGSize size = _iconView.bounds.size;
  if (size.width <= 0 || size.height <= 0) {
    return nil;
  }

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat defaultFormat];
  format.scale = [UIScreen mainScreen].scale;
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
    [self->_iconView.layer renderInContext:context.CGContext];
  }];
}

- (UIImage *)createScaledIconImage {
  CGSize size = _iconView.bounds.size;
  if (size.width <= 0 || size.height <= 0) {
    return nil;
  }

  CGSize scaledSize = CGSizeMake(size.width * _scale, size.height * _scale);

  UIGraphicsImageRendererFormat *format =
      [UIGraphicsImageRendererFormat defaultFormat];
  format.scale = [UIScreen mainScreen].scale;
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:scaledSize format:format];

  return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
    CGContextScaleCTM(context.CGContext, self->_scale, self->_scale);
    [self->_iconView.layer renderInContext:context.CGContext];
  }];
}

- (void)emitPressEventWithPoint:(CGPoint)point {
  MarkerPressEvent event{
      .latitude = _coordinate.latitude,
      .longitude = _coordinate.longitude,
      .x = point.x,
      .y = point.y,
  };
  event.emit<LuggMarkerViewEventEmitter>(_eventEmitter);
}

- (void)emitDragStartEventWithPoint:(CGPoint)point {
  MarkerDragStartEvent event{
      .latitude = _coordinate.latitude,
      .longitude = _coordinate.longitude,
      .x = point.x,
      .y = point.y,
  };
  event.emit<LuggMarkerViewEventEmitter>(_eventEmitter);
}

- (void)emitDragChangeEventWithPoint:(CGPoint)point {
  MarkerDragChangeEvent event{
      .latitude = _coordinate.latitude,
      .longitude = _coordinate.longitude,
      .x = point.x,
      .y = point.y,
  };
  event.emit<LuggMarkerViewEventEmitter>(_eventEmitter);
}

- (void)emitDragEndEventWithPoint:(CGPoint)point {
  MarkerDragEndEvent event{
      .latitude = _coordinate.latitude,
      .longitude = _coordinate.longitude,
      .x = point.x,
      .y = point.y,
  };
  event.emit<LuggMarkerViewEventEmitter>(_eventEmitter);
}

- (void)updateCoordinate:(CLLocationCoordinate2D)coordinate {
  _coordinate = coordinate;
}

- (void)resetIconViewTransform {
  _iconView.transform = CGAffineTransformIdentity;
  _iconView.layer.anchorPoint = CGPointMake(0.5, 0.5);
  _iconView.frame = CGRectMake(0, 0, _iconView.bounds.size.width,
                               _iconView.bounds.size.height);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  _didLayout = NO;
  self.marker = nil;
  self.delegate = nil;
  [self resetIconViewTransform];
  for (UIView *subview in _iconView.subviews) {
    [subview removeFromSuperview];
  }
}

Class<RCTComponentViewProtocol> LuggMarkerViewCls(void) {
  return LuggMarkerView.class;
}

@end
