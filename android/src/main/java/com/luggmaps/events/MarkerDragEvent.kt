package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class MarkerDragEvent(
  view: View,
  private val eventType: String,
  private val latitude: Double,
  private val longitude: Double,
  private val x: Float,
  private val y: Float
) : Event<MarkerDragEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = eventType

  override fun getEventData() =
    Arguments.createMap().apply {
      putMap(
        "coordinate",
        Arguments.createMap().apply {
          putDouble("latitude", latitude)
          putDouble("longitude", longitude)
        }
      )
      putMap(
        "point",
        Arguments.createMap().apply {
          putDouble("x", x.toDouble())
          putDouble("y", y.toDouble())
        }
      )
    }

  companion object {
    const val DRAG_START = "topMarkerDragStart"
    const val DRAG_CHANGE = "topMarkerDragChange"
    const val DRAG_END = "topMarkerDragEnd"
  }
}
