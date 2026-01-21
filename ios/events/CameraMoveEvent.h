#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct CameraMoveEvent {
  double latitude;
  double longitude;
  double zoom;
  bool gesture;

  template <typename Emitter>
  void emit(std::shared_ptr<Emitter const> emitter) const {
    typename Emitter::OnCameraMove event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.zoom = zoom;
    event.gesture = gesture;
    emitter->onCameraMove(event);
  }
};

} // namespace events
} // namespace luggmaps
