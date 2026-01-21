#pragma once

#import <react/renderer/components/RNMapsSpec/EventEmitters.h>

namespace luggmaps {
namespace events {

struct ReadyEvent {
  template <typename Emitter>
  static void emit(const facebook::react::SharedEventEmitter &eventEmitter) {
    if (!eventEmitter) return;
    auto emitter = std::static_pointer_cast<Emitter const>(eventEmitter);
    typename Emitter::OnReady event;
    emitter->onReady(event);
  }
};

} // namespace events
} // namespace luggmaps
