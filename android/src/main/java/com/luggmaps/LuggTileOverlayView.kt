package com.luggmaps

import android.content.Context
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.TileOverlay
import com.luggmaps.events.TileOverlayPressEvent
import com.luggmaps.extensions.dispatchEvent

interface LuggTileOverlayViewDelegate {
  fun tileOverlayViewDidUpdate(tileOverlayView: LuggTileOverlayView)
}

class LuggTileOverlayView(context: Context) : ReactViewGroup(context) {
  var urlTemplate: String = ""
    private set

  var tileSize: Int = 256
    private set

  var overlayOpacity: Float = 1f
    private set

  var hasBounds: Boolean = false
    private set
  var boundsSwLat: Double = 0.0
    private set
  var boundsSwLng: Double = 0.0
    private set
  var boundsNeLat: Double = 0.0
    private set
  var boundsNeLng: Double = 0.0
    private set

  var zIndex: Float = 0f
    private set

  var tappable: Boolean = false
    private set

  var delegate: LuggTileOverlayViewDelegate? = null
  var tileOverlay: TileOverlay? = null

  init {
    visibility = GONE
  }

  fun setUrlTemplate(value: String) {
    urlTemplate = value
  }

  fun setTileSize(value: Int) {
    tileSize = value
  }

  fun setOverlayOpacity(value: Float) {
    overlayOpacity = value
  }

  fun setZIndex(value: Float) {
    zIndex = value
  }

  fun setBounds(swLat: Double, swLng: Double, neLat: Double, neLng: Double) {
    hasBounds = true
    boundsSwLat = swLat
    boundsSwLng = swLng
    boundsNeLat = neLat
    boundsNeLng = neLng
  }

  fun clearBounds() {
    hasBounds = false
  }

  fun setTappable(value: Boolean) {
    tappable = value
  }

  fun emitPressEvent() {
    dispatchEvent(TileOverlayPressEvent(this))
  }

  fun onAfterUpdateTransaction() {
    delegate?.tileOverlayViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    delegate = null
    tileOverlay?.remove()
    tileOverlay = null
  }
}
