package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class MarkerPressEvent(view: View) : Event<MarkerPressEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topMarkerPress"

  override fun getEventData() = Arguments.createMap()
}
