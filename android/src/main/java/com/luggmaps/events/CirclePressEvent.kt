package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class CirclePressEvent(view: View) : Event<CirclePressEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topCirclePress"

  override fun getEventData() = Arguments.createMap()
}
