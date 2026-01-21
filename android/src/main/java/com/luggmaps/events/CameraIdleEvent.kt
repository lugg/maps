package com.luggmaps.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.uimanager.events.Event

class CameraIdleEvent(
  surfaceId: Int,
  viewId: Int,
  private val latitude: Double,
  private val longitude: Double,
  private val zoom: Float,
  private val gesture: Boolean
) : Event<CameraIdleEvent>(surfaceId, viewId) {
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
