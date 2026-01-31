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

data class AnimatedOptions(
  val duration: Long = 2150L,
  val easing: String = "linear",
  val trailLength: Float = 1f,
  val delay: Long = 0L
)

class LuggPolylineView(context: Context) : ReactViewGroup(context) {
  var coordinates: List<LatLng> = emptyList()
    private set

  var strokeColors: List<Int> = listOf(Color.BLACK)
    private set

  var strokeWidth: Float = 1f
    private set

  var animated: Boolean = false
    private set

  var animatedOptions: AnimatedOptions = AnimatedOptions()
    private set

  var zIndex: Float = 0f
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

  fun setAnimatedOptions(options: AnimatedOptions) {
    animatedOptions = options
  }

  fun setZIndex(value: Float) {
    zIndex = value
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
