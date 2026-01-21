package com.luggmaps

import android.content.Context
import android.graphics.Color
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Polyline
import com.google.android.gms.maps.model.StrokeStyle
import com.google.android.gms.maps.model.StyleSpan

interface LuggPolylineViewDelegate {
  fun polylineViewDidUpdate(polylineView: LuggPolylineView)
}

class LuggPolylineView(context: Context) : ReactViewGroup(context) {
  var coordinates: List<LatLng> = emptyList()
    private set

  var strokeColors: List<Int> = listOf(Color.BLACK)
    private set

  var strokeWidth: Float = 1f
    private set

  var animated: Boolean = false
    private set

  var cachedSpans: List<StyleSpan>? = null
    private set

  var delegate: LuggPolylineViewDelegate? = null
  var polyline: Polyline? = null

  init {
    visibility = GONE
  }

  fun setCoordinates(coords: List<LatLng>) {
    coordinates = coords
  }

  fun setStrokeColors(colors: List<Int>) {
    val newColors = colors.ifEmpty { listOf(Color.BLACK) }
    if (newColors != strokeColors) {
      strokeColors = newColors
      cachedSpans = null
    }
  }

  fun setStrokeWidth(width: Float) {
    strokeWidth = width
  }

  fun setAnimated(value: Boolean) {
    animated = value
  }

  fun getOrCreateSpans(): List<StyleSpan> {
    cachedSpans?.let { return it }

    val segmentCount = coordinates.size - 1
    val spans = (0 until segmentCount).map { i ->
      val color = strokeColors[i % strokeColors.size]
      StyleSpan(StrokeStyle.colorBuilder(color).build())
    }
    cachedSpans = spans
    return spans
  }

  fun onAfterUpdateTransaction() {
    delegate?.polylineViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    delegate = null
    polyline?.remove()
    polyline = null
  }
}
