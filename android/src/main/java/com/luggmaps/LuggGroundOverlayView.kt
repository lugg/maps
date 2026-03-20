package com.luggmaps

import android.content.Context
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.GroundOverlay
import com.google.android.gms.maps.model.LatLng
import com.luggmaps.events.GroundOverlayPressEvent
import com.luggmaps.extensions.dispatchEvent

interface LuggGroundOverlayViewDelegate {
  fun groundOverlayViewDidUpdate(groundOverlayView: LuggGroundOverlayView)
}

class LuggGroundOverlayView(context: Context) : ReactViewGroup(context) {
  var imageUri: String = ""
    private set

  var northeast: LatLng = LatLng(0.0, 0.0)
    private set

  var southwest: LatLng = LatLng(0.0, 0.0)
    private set

  var overlayOpacity: Float = 1f
    private set

  var bearing: Float = 0f
    private set

  var zIndex: Float = 0f
    private set

  var tappable: Boolean = false
    private set

  var delegate: LuggGroundOverlayViewDelegate? = null
  var groundOverlay: GroundOverlay? = null

  init {
    visibility = GONE
  }

  fun setImageUri(value: String) {
    imageUri = value
  }

  fun setBounds(ne: LatLng, sw: LatLng) {
    northeast = ne
    southwest = sw
  }

  fun setOverlayOpacity(value: Float) {
    overlayOpacity = value
  }

  fun setBearing(value: Float) {
    bearing = value
  }

  fun setZIndex(value: Float) {
    zIndex = value
  }

  fun setTappable(value: Boolean) {
    tappable = value
  }

  fun emitPressEvent() {
    dispatchEvent(GroundOverlayPressEvent(this))
  }

  fun onAfterUpdateTransaction() {
    delegate?.groundOverlayViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    delegate = null
    groundOverlay?.remove()
    groundOverlay = null
  }
}
