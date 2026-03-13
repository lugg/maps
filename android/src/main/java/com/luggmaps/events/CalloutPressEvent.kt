package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class CalloutPressEvent(
  view: View
) : Event<CalloutPressEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topCalloutPress"

  override fun getEventData() = Arguments.createMap()
}
