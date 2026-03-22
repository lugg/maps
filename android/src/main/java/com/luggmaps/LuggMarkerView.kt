package com.luggmaps

import android.content.Context
import android.graphics.Canvas
import android.view.View
import androidx.core.graphics.createBitmap
import androidx.core.view.isNotEmpty
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.AdvancedMarker
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.luggmaps.events.MarkerDragEvent
import com.luggmaps.events.MarkerPressEvent
import com.luggmaps.extensions.dispatchEvent

interface LuggMarkerViewDelegate {
  fun markerViewDidUpdate(markerView: LuggMarkerView)
  fun markerViewDidLayout(markerView: LuggMarkerView)
  fun showCalloutForMarkerView(markerView: LuggMarkerView)
  fun hideCalloutForMarkerView(markerView: LuggMarkerView)
}

class LuggMarkerView(context: Context) : ReactViewGroup(context) {
  private var scaleUpdateRunnable: Runnable? = null

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

  var rotate: Float = 0f
    private set

  var scale: Float = 1f
    private set

  var scaleChanged: Boolean = false
    private set

  var rasterize: Boolean = true
    private set

  var draggable: Boolean = false
    private set

  var isDragging: Boolean = false

  var didLayout: Boolean = false
    private set

  val hasCustomView: Boolean
    get() = contentView.isNotEmpty()

  val contentView: ReactViewGroup = ReactViewGroup(context)

  var onUpdate: (() -> Unit)? = null

  var calloutView: LuggCalloutView? = null
    private set

  private fun measureContentBounds(): Pair<Int, Int> {
    var maxWidth = 0
    var maxHeight = 0
    for (i in 0 until contentView.childCount) {
      val child = contentView.getChildAt(i)
      val childRight = child.left + child.width
      val childBottom = child.top + child.height
      if (childRight > maxWidth) maxWidth = childRight
      if (childBottom > maxHeight) maxHeight = childBottom
    }
    return Pair(maxWidth, maxHeight)
  }

  private fun createContentBitmap(): BitmapDescriptor? {
    val (width, height) = measureContentBounds()
    if (width <= 0 || height <= 0) return null

    val scaledWidth = (width * scale).toInt()
    val scaledHeight = (height * scale).toInt()

    val bitmap = createBitmap(scaledWidth, scaledHeight)
    val canvas = Canvas(bitmap)
    canvas.scale(scale, scale)
    contentView.draw(canvas)
    return BitmapDescriptorFactory.fromBitmap(bitmap)
  }

  fun layoutContentView() {
    val (width, height) = measureContentBounds()
    val scaledWidth = (width * scale).toInt()
    val scaledHeight = (height * scale).toInt()

    contentView.scaleX = scale
    contentView.scaleY = scale
    contentView.pivotX = 0f
    contentView.pivotY = 0f

    contentView.measure(
      View.MeasureSpec.makeMeasureSpec(scaledWidth, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(scaledHeight, View.MeasureSpec.EXACTLY)
    )
    contentView.layout(0, 0, scaledWidth, scaledHeight)
  }

  fun applyIconToMarker() {
    val m = marker ?: return
    if (!hasCustomView) return
    createContentBitmap()?.let { m.setIcon(it) }
  }

  fun applyScaleToMarker() {
    val m = marker ?: return
    if (!hasCustomView) return

    scaleUpdateRunnable?.let { removeCallbacks(it) }
    scaleUpdateRunnable = Runnable {
      if (rasterize) {
        createContentBitmap()?.let { m.setIcon(it) }
      } else {
        layoutContentView()
        onUpdate?.invoke()
      }
    }
    post(scaleUpdateRunnable)
  }

  fun updateIcon(onAddMarker: () -> Unit) {
    if (!hasCustomView) return
    post {
      if (marker == null) {
        onAddMarker()
      } else if (rasterize) {
        applyIconToMarker()
      } else {
        layoutContentView()
        onUpdate?.invoke()
      }
    }
  }

  init {
    visibility = GONE
  }

  override fun addView(child: View, index: Int) {
    if (child is LuggCalloutView) {
      calloutView = child
    } else {
      contentView.addView(child, index)
    }
    didLayout = false
  }

  override fun removeView(child: View) {
    if (child is LuggCalloutView) {
      calloutView = null
    } else {
      contentView.removeView(child)
    }
    didLayout = false
  }

  override fun removeViewAt(index: Int) {
    val child = getChildAt(index)
    if (child is LuggCalloutView) {
      calloutView = null
    } else {
      contentView.removeViewAt(index)
    }
    didLayout = false
  }

  override fun removeViews(start: Int, count: Int) {
    for (i in (start until start + count).reversed()) {
      val child = getChildAt(i)
      if (child is LuggCalloutView) {
        calloutView = null
      } else if (i < contentView.childCount) {
        contentView.removeViewAt(i)
      }
    }
    didLayout = false
  }

  override fun getChildCount(): Int = contentView.childCount + if (calloutView != null) 1 else 0

  override fun getChildAt(index: Int): View? {
    if (index < contentView.childCount) return contentView.getChildAt(index)
    if (index == contentView.childCount && calloutView != null) return calloutView
    return null
  }

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

  fun setRotate(rotate: Float) {
    this.rotate = rotate
  }

  fun setScale(scale: Float) {
    scaleChanged = this.scale != scale
    this.scale = scale
  }

  fun clearScaleChanged() {
    scaleChanged = false
  }

  fun setRasterize(rasterize: Boolean) {
    this.rasterize = rasterize
  }

  fun setDraggable(draggable: Boolean) {
    this.draggable = draggable
  }

  fun emitPressEvent(x: Float, y: Float) {
    dispatchEvent(MarkerPressEvent(this, latitude, longitude, x, y))
  }

  fun emitDragStartEvent(x: Float, y: Float) {
    dispatchEvent(MarkerDragEvent(this, MarkerDragEvent.DRAG_START, latitude, longitude, x, y))
  }

  fun emitDragChangeEvent(x: Float, y: Float) {
    dispatchEvent(MarkerDragEvent(this, MarkerDragEvent.DRAG_CHANGE, latitude, longitude, x, y))
  }

  fun emitDragEndEvent(x: Float, y: Float) {
    dispatchEvent(MarkerDragEvent(this, MarkerDragEvent.DRAG_END, latitude, longitude, x, y))
  }

  fun showCallout() {
    delegate?.showCalloutForMarkerView(this)
  }

  fun hideCallout() {
    delegate?.hideCalloutForMarkerView(this)
  }

  fun setName(name: String?) {
    this.name = name
  }

  fun onAfterUpdateTransaction() {
    delegate?.markerViewDidUpdate(this)
  }

  fun onDropViewInstance() {
    scaleUpdateRunnable?.let { removeCallbacks(it) }
    scaleUpdateRunnable = null
    onUpdate = null
    didLayout = false
    calloutView = null
    delegate = null
    contentView.removeAllViews()
  }
}
