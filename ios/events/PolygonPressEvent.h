#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct PolygonPressEvent {
  template <typename Emitter>
  static void emit(const facebook::react::SharedEventEmitter &eventEmitter) {
    if (!eventEmitter)
      return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnPress event;
    emitter->onPress(event);
  }
};

} // namespace events
} // namespace luggmaps
