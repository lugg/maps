#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct TileOverlayPressEvent {
  template <typename Emitter>
  static void emit(const facebook::react::SharedEventEmitter &eventEmitter) {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnTileOverlayPress event;
    emitter->onTileOverlayPress(event);
  }
};

} // namespace events
} // namespace luggmaps
