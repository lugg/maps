package com.luggmaps

import android.content.Context
import android.util.Log
import android.view.View
import androidx.core.view.isNotEmpty
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.AdvancedMarker

interface LuggMarkerViewDelegate {
  fun markerViewDidUpdate(markerView: LuggMarkerView)
  fun markerViewDidLayout(markerView: LuggMarkerView)
}

class LuggMarkerView(context: Context) : ReactViewGroup(context) {
  var name: String? = null
    private set

  var latitude: Double = 0.0
    private set
  var longitude: Double = 0.0
    private set

  var title: String? = null
    private set
  var description: String? = null
    private set

  var delegate: LuggMarkerViewDelegate? = null
  var marker: AdvancedMarker? = null

  var anchorX: Float = 0.5f
    private set
  var anchorY: Float = 1.0f
    private set

  var didLayout: Boolean = false
    private set

  val hasCustomView: Boolean
    get() = iconView.isNotEmpty()

  val iconView: ReactViewGroup = object : ReactViewGroup(context) {
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
      var maxWidth = 0
      var maxHeight = 0
      for (i in 0 until childCount) {
        val child = getChildAt(i)
        if (child.width > maxWidth) maxWidth = child.width
        if (child.height > maxHeight) maxHeight = child.height
      }

      setMeasuredDimension(maxWidth, maxHeight)
    }
  }

  init {
    visibility = GONE
  }

  override fun addView(child: View, index: Int) {
    iconView.addView(child, index)
    didLayout = false
  }

  override fun removeView(child: View) {
    iconView.removeView(child)
    didLayout = false
  }

  override fun removeViewAt(index: Int) {
    iconView.removeViewAt(index)
    didLayout = false
  }

  override fun getChildCount(): Int = iconView.childCount

  override fun getChildAt(index: Int): View? = iconView.getChildAt(index)

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    didLayout = false
  }

  override fun onLayout(
    changed: Boolean,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int
  ) {
    super.onLayout(changed, left, top, right, bottom)
    if (changed && !didLayout) {
      didLayout = true
      delegate?.markerViewDidLayout(this)
    }
  }

  fun setCoordinate(latitude: Double, longitude: Double) {
    this.latitude = latitude
    this.longitude = longitude
  }

  fun setTitle(title: String?) {
    this.title = title
  }

  fun setDescription(description: String?) {
    this.description = description
  }

  fun setAnchor(x: Double, y: Double) {
    anchorX = x.toFloat()
    anchorY = y.toFloat()
  }

  fun setName(name: String?) {
    this.name = name
  }

  fun onAfterUpdateTransaction() {
    delegate?.markerViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    didLayout = false
    delegate = null
    iconView.removeAllViews()
  }

  companion object {
    private const val TAG = "Lugg"
  }
}
