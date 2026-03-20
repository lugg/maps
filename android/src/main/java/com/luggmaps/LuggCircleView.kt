package com.luggmaps

import android.content.Context
import android.graphics.Color
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.Circle
import com.google.android.gms.maps.model.LatLng
import com.luggmaps.events.CirclePressEvent
import com.luggmaps.extensions.dispatchEvent

interface LuggCircleViewDelegate {
  fun circleViewDidUpdate(circleView: LuggCircleView)
}

class LuggCircleView(context: Context) : ReactViewGroup(context) {
  var center: LatLng = LatLng(0.0, 0.0)
    private set

  var radius: Double = 0.0
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

  var delegate: LuggCircleViewDelegate? = null
  var circle: Circle? = null

  init {
    visibility = GONE
  }

  fun setCenter(value: LatLng) {
    center = value
  }

  fun setRadius(value: Double) {
    radius = value
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
    dispatchEvent(CirclePressEvent(this))
  }

  fun onAfterUpdateTransaction() {
    delegate?.circleViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    delegate = null
    circle?.remove()
    circle = null
  }
}
