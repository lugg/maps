package com.luggmaps

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.view.ViewGroup
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.AdvancedMarker
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import androidx.core.graphics.createBitmap
import androidx.core.view.isNotEmpty

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

  var zIndex: Float = 0f
    private set

  var rasterize: Boolean = true
    private set

  var didLayout: Boolean = false
    private set

  var isPendingUpdate: Boolean = false

  val hasCustomView: Boolean
    get() = iconView.isNotEmpty()

  val iconView: ReactViewGroup = ReactViewGroup(context)

  private fun measureIconViewBounds(): Pair<Int, Int> {
    var maxWidth = 0
    var maxHeight = 0
    for (i in 0 until iconView.childCount) {
      val child = iconView.getChildAt(i)
      val childRight = child.left + child.width
      val childBottom = child.top + child.height
      if (childRight > maxWidth) maxWidth = childRight
      if (childBottom > maxHeight) maxHeight = childBottom
    }
    return Pair(maxWidth, maxHeight)
  }

  private fun createIconBitmap(): BitmapDescriptor? {
    val (width, height) = measureIconViewBounds()
    if (width <= 0 || height <= 0) return null

    val bitmap = createBitmap(width, height)
    val canvas = Canvas(bitmap)
    iconView.draw(canvas)
    return BitmapDescriptorFactory.fromBitmap(bitmap)
  }

  private fun createIconViewWrapper(): View {
    val (width, height) = measureIconViewBounds()

    (iconView.parent as? ViewGroup)?.removeView(iconView)

    return object : ReactViewGroup(context) {
      init {
        addView(iconView)
      }

      override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(width, height)
      }
    }
  }

  fun applyIconToMarker() {
    val m = marker ?: return
    if (!hasCustomView) return

    if (rasterize) {
      m.iconView = null
      createIconBitmap()?.let { m.setIcon(it) }
    } else {
      m.iconView = createIconViewWrapper()
    }
  }

  fun updateIcon(onAddMarker: () -> Unit) {
    if (!hasCustomView) return
    if (isPendingUpdate) return
    isPendingUpdate = true

    if (rasterize) {
      post {
        isPendingUpdate = false
        if (marker == null) {
          onAddMarker()
        } else {
          applyIconToMarker()
        }
      }
    } else {
      marker?.remove()
      marker = null
      post {
        isPendingUpdate = false
        onAddMarker()
      }
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

  fun setZIndex(zIndex: Float) {
    this.zIndex = zIndex
  }

  fun setRasterize(rasterize: Boolean) {
    this.rasterize = rasterize
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

}
