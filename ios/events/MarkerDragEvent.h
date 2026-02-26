#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct MarkerDragStartEvent {
  double latitude;
  double longitude;
  double x;
  double y;

  template <typename Emitter>
  void emit(const facebook::react::SharedEventEmitter &eventEmitter) const {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnMarkerDragStart event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.point.x = x;
    event.point.y = y;
    emitter->onMarkerDragStart(event);
  }
};

struct MarkerDragChangeEvent {
  double latitude;
  double longitude;
  double x;
  double y;

  template <typename Emitter>
  void emit(const facebook::react::SharedEventEmitter &eventEmitter) const {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnMarkerDragChange event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.point.x = x;
    event.point.y = y;
    emitter->onMarkerDragChange(event);
  }
};

struct MarkerDragEndEvent {
  double latitude;
  double longitude;
  double x;
  double y;

  template <typename Emitter>
  void emit(const facebook::react::SharedEventEmitter &eventEmitter) const {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnMarkerDragEnd event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.point.x = x;
    event.point.y = y;
    emitter->onMarkerDragEnd(event);
  }
};

} // namespace events
} // namespace luggmaps
