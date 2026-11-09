#import "LuggMarkerView.h"
#import "LuggCalloutView.h"
#import "events/MarkerDragEvent.h"
#import "events/MarkerPressEvent.h"

#import <react/renderer/components/RNMapsSpec/ComponentDescriptors.h>
#import <react/renderer/components/RNMapsSpec/EventEmitters.h>
#import <react/renderer/components/RNMapsSpec/Props.h>
#import <react/renderer/components/RNMapsSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

using namespace facebook::react;
using namespace luggmaps::events;

static BOOL LuggMarkerPathPropsActive(const LuggMarkerViewProps &props) {
  return props.pathCoordinates.size() >= 2 &&
         props.pathTimes.size() == props.pathCoordinates.size();
}

@interface LuggMarkerPath ()
- (nullable instancetype)initWithProps:(const LuggMarkerViewProps &)props;
- (BOOL)matchesProps:(const LuggMarkerViewProps &)props;
@end

@implementation LuggMarkerPath {
  std::vector<CLLocationCoordinate2D> _coordinateValues;
  std::vector<double> _timeValues;
  std::vector<double> _rotationValues;
  std::vector<double> _rotationProps;
}

- (instancetype)initWithProps:(const LuggMarkerViewProps &)props {
  if (!LuggMarkerPathPropsActive(props)) {
    return nil;
  }
  if (self = [super init]) {
    size_t count = props.pathCoordinates.size();
    double first = props.pathTimes.front();
    _coordinateValues.reserve(count);
    _timeValues.reserve(count);
    for (size_t i = 0; i < count; i++) {
      _coordinateValues.push_back(CLLocationCoordinate2DMake(
          props.pathCoordinates[i].latitude, props.pathCoordinates[i].longitude));
      _timeValues.push_back(props.pathTimes[i] - first);
    }
    if (props.pathRotations.size() == count) {
      // Unwrapped so each segment turns the short way (350 then 10 is +20, not -340).
      _rotationProps = props.pathRotations;
      _rotationValues.reserve(count);
      double rotation = props.pathRotations[0];
      _rotationValues.push_back(rotation);
      for (size_t i = 1; i < count; i++) {
        rotation += fmod(fmod(props.pathRotations[i] - rotation, 360) + 540, 360) - 180;
        _rotationValues.push_back(rotation);
      }
    }
    _startTime = props.pathStartTime;
    _loop = props.pathLoop;
    _duration = _timeValues.back();
  }
  return self;
}

- (BOOL)matchesProps:(const LuggMarkerViewProps &)props {
  size_t count = _coordinateValues.size();
  if (props.pathCoordinates.size() != count || props.pathTimes.size() != count ||
      props.pathStartTime != _startTime || props.pathLoop != _loop ||
      (props.pathRotations.size() == count) == _rotationValues.empty()) {
    return NO;
  }
  double first = props.pathTimes.front();
  for (size_t i = 0; i < count; i++) {
    if (props.pathCoordinates[i].latitude != _coordinateValues[i].latitude ||
        props.pathCoordinates[i].longitude != _coordinateValues[i].longitude ||
        props.pathTimes[i] - first != _timeValues[i]) {
      return NO;
    }
  }
  return _rotationValues.empty() || props.pathRotations == _rotationProps;
}

- (NSUInteger)count {
  return _coordinateValues.size();
}

- (const CLLocationCoordinate2D *)coordinates {
  return _coordinateValues.data();
}

- (const double *)times {
  return _timeValues.data();
}

- (const double *)rotations {
  return _rotationValues.empty() ? NULL : _rotationValues.data();
}

- (double)progressAt:(double)now {
  double elapsed = now - _startTime;
  if (_loop && _duration > 0) {
    return fmod(fmod(elapsed, _duration) + _duration, _duration);
  }
  return MIN(MAX(elapsed, 0), _duration);
}

- (CLLocationCoordinate2D)coordinateAt:(double)now
                              rotation:(CLLocationDegrees *)rotation {
  double t = [self progressAt:now];
  size_t lo = 0;
  size_t hi = _timeValues.size() - 1;
  while (hi - lo > 1) {
    size_t mid = (lo + hi) / 2;
    if (_timeValues[mid] <= t) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  double span = _timeValues[hi] - _timeValues[lo];
  double f = span > 0 ? (t - _timeValues[lo]) / span : 0;
  if (rotation && !_rotationValues.empty()) {
    *rotation = _rotationValues[lo] + (_rotationValues[hi] - _rotationValues[lo]) * f;
  }
  const CLLocationCoordinate2D &a = _coordinateValues[lo];
  const CLLocationCoordinate2D &b = _coordinateValues[hi];
  return CLLocationCoordinate2DMake(a.latitude + (b.latitude - a.latitude) * f,
                                    a.longitude + (b.longitude - a.longitude) * f);
}

@end

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
  BOOL _centerOnPress;
  BOOL _draggable;
  LuggMarkerPath *_path;
  BOOL _didLayout;
  UIView *_iconView;
  LuggCalloutView *_calloutView;
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
    _centerOnPress = YES;
    _didLayout = NO;

    _iconView = [[UIView alloc] init];
    _iconView.backgroundColor = [UIColor clearColor];

    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
  }

  return self;
}

- (void)updateLayoutMetrics:(const LayoutMetrics &)layoutMetrics
           oldLayoutMetrics:(const LayoutMetrics &)oldLayoutMetrics {
  [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];

  // RN 0.88+ resets layout metrics on recycle, so the next mount force-applies
  // `hidden` from the display type and would reveal this placeholder view.
  self.hidden = YES;
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
  _centerOnPress = newViewProps.centerOnPress;
  _draggable = newViewProps.draggable;
  if (_path ? ![_path matchesProps:newViewProps]
            : LuggMarkerPathPropsActive(newViewProps)) {
    _path = [[LuggMarkerPath alloc] initWithProps:newViewProps];
  }
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
  if ([childComponentView isKindOfClass:[LuggCalloutView class]]) {
    _calloutView = (LuggCalloutView *)childComponentView;
  } else {
    [_iconView insertSubview:childComponentView atIndex:index];
  }
  _didLayout = NO;
  [self setNeedsLayout];
}

- (void)unmountChildComponentView:
            (UIView<RCTComponentViewProtocol> *)childComponentView
                            index:(NSInteger)index {
  if ([childComponentView isKindOfClass:[LuggCalloutView class]]) {
    _calloutView = nil;
  } else {
    [childComponentView removeFromSuperview];
  }
  _didLayout = NO;
  [self setNeedsLayout];
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

    // Providers own the icon view's position; only resize it and re-sync.
    // Setting the frame on every pass snapped positioned icons to the origin.
    if (width > 0 && height > 0 &&
        !CGSizeEqualToSize(_iconView.bounds.size, CGSizeMake(width, height))) {
      _iconView.frame = CGRectMake(0, 0, width, height);
      _didLayout = NO;
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

- (BOOL)centerOnPress {
  return _centerOnPress;
}

- (BOOL)draggable {
  return _draggable;
}

- (LuggMarkerPath *)path {
  return _path;
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

- (LuggCalloutView *)calloutView {
  return _calloutView;
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
  // Static providers hide the icon view until positioned
  _iconView.hidden = NO;
}

- (void)showCallout {
  if ([self.delegate respondsToSelector:@selector(showCalloutForMarkerView:)]) {
    [self.delegate showCalloutForMarkerView:self];
  }
}

- (void)hideCallout {
  if ([self.delegate respondsToSelector:@selector(hideCalloutForMarkerView:)]) {
    [self.delegate hideCalloutForMarkerView:self];
  }
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTLuggMarkerViewHandleCommand(self, commandName, args);
}

- (void)prepareForRecycle {
  [super prepareForRecycle];
  _didLayout = NO;
  _calloutView = nil;
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
