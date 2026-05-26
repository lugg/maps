#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct TileOverlayPressEvent {
  // Holder type is templated to bridge RN versions: SharedEventEmitter went
  // from shared_ptr<const EventEmitter> to shared_ptr<EventEmitter> in 0.85.
  template <typename Emitter, typename EventEmitterPtr>
  static void emit(const EventEmitterPtr &eventEmitter) {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnTileOverlayPress event;
    emitter->onTileOverlayPress(event);
  }
};

} // namespace events
} // namespace luggmaps
