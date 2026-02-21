package com.luggmaps

import android.content.Context
import android.graphics.Color
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Polygon
import com.luggmaps.events.PolygonPressEvent
import com.luggmaps.extensions.dispatchEvent

interface LuggPolygonViewDelegate {
  fun polygonViewDidUpdate(polygonView: LuggPolygonView)
}

class LuggPolygonView(context: Context) : ReactViewGroup(context) {
  var coordinates: List<LatLng> = emptyList()
    private set

  var strokeColor: Int = Color.BLACK
    private set

  var fillColor: Int = Color.argb(77, 0, 0, 0)
    private set

  var strokeWidth: Float = 1f
    private set

  var zIndex: Float = 0f
    private set

  var tappable: Boolean = false
    private set

  var delegate: LuggPolygonViewDelegate? = null
  var polygon: Polygon? = null

  init {
    visibility = GONE
  }

  fun setCoordinates(coords: List<LatLng>) {
    coordinates = coords
  }

  fun setStrokeColor(color: Int) {
    strokeColor = color
  }

  fun setFillColor(color: Int) {
    fillColor = color
  }

  fun setStrokeWidth(width: Float) {
    strokeWidth = width
  }

  fun setZIndex(value: Float) {
    zIndex = value
  }

  fun setTappable(value: Boolean) {
    tappable = value
  }

  fun emitPressEvent() {
    dispatchEvent(PolygonPressEvent(this))
  }

  fun onAfterUpdateTransaction() {
    delegate?.polygonViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    delegate = null
    polygon?.remove()
    polygon = null
  }
}
