#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct MarkerPressEvent {
  double latitude;
  double longitude;
  double x;
  double y;

  // Holder type is templated to bridge RN versions: SharedEventEmitter went
  // from shared_ptr<const EventEmitter> to shared_ptr<EventEmitter> in 0.85.
  template <typename Emitter, typename EventEmitterPtr>
  void emit(const EventEmitterPtr &eventEmitter) const {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnMarkerPress event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.point.x = x;
    event.point.y = y;
    emitter->onMarkerPress(event);
  }
};

} // namespace events
} // namespace luggmaps
