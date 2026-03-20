package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class TileOverlayPressEvent(view: View) : Event<TileOverlayPressEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topTileOverlayPress"

  override fun getEventData() = Arguments.createMap()
}
