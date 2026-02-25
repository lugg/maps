#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct LongPressEvent {
  double latitude;
  double longitude;
  double x;
  double y;

  template <typename Emitter>
  void emit(const facebook::react::SharedEventEmitter &eventEmitter) const {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnMapLongPress event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.point.x = x;
    event.point.y = y;
    emitter->onMapLongPress(event);
  }
};

} // namespace events
} // namespace luggmaps
