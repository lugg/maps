package com.luggmaps.events

import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

class CameraIdleEvent(
  view: View,
  private val latitude: Double,
  private val longitude: Double,
  private val zoom: Float,
  private val gesture: Boolean
) : Event<CameraIdleEvent>(UIManagerHelper.getSurfaceId(view), view.id) {
  override fun getEventName() = "topCameraIdle"

  override fun getEventData() =
    Arguments.createMap().apply {
      putMap(
        "coordinate",
        Arguments.createMap().apply {
          putDouble("latitude", latitude)
          putDouble("longitude", longitude)
        }
      )
      putDouble("zoom", zoom.toDouble())
      putBoolean("gesture", gesture)
    }
}
