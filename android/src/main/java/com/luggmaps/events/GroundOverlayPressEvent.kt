package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class GroundOverlayPressEvent(view: View) : Event<GroundOverlayPressEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topGroundOverlayPress"

  override fun getEventData() = Arguments.createMap()
}
