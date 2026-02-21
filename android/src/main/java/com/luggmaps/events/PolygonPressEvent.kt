package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class PolygonPressEvent(view: View) : Event<PolygonPressEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topPress"

  override fun getEventData() = Arguments.createMap()
}
