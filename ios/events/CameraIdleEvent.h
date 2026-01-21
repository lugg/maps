#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct CameraIdleEvent {
  double latitude;
  double longitude;
  double zoom;
  bool dragging;

  template <typename Emitter>
  void emit(std::shared_ptr<Emitter const> emitter) const {
    typename Emitter::OnCameraIdle event;
    event.coordinate.latitude = latitude;
    event.coordinate.longitude = longitude;
    event.zoom = zoom;
    event.dragging = dragging;
    emitter->onCameraIdle(event);
  }
};

} // namespace events
} // namespace luggmaps
