package com.luggmaps

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import androidx.core.graphics.createBitmap
import androidx.core.view.isNotEmpty
import com.facebook.react.views.view.ReactViewGroup

class LuggCalloutView(context: Context) : ReactViewGroup(context) {
  val contentView: ReactViewGroup = ReactViewGroup(context)
  var bubbled: Boolean = true
  var anchorX: Float = 0.5f
    set(value) {
      field = value
      onUpdate?.invoke()
    }
  var anchorY: Float = 1.0f
    set(value) {
      field = value
      onUpdate?.invoke()
    }
  var onUpdate: (() -> Unit)? = null

  val hasCustomContent: Boolean
    get() = contentView.isNotEmpty()

  init {
    visibility = GONE
  }

  override fun addView(child: View, index: Int) {
    contentView.addView(child, index)
    child.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
      onUpdate?.invoke()
    }
  }

  override fun removeView(child: View) {
    contentView.removeView(child)
  }

  override fun removeViewAt(index: Int) {
    contentView.removeViewAt(index)
  }

  override fun getChildCount(): Int = contentView.childCount

  override fun getChildAt(index: Int): View? = contentView.getChildAt(index)

  fun createContentBitmap(): Bitmap? {
    var maxWidth = 0
    var maxHeight = 0
    for (i in 0 until contentView.childCount) {
      val child = contentView.getChildAt(i)
      val childRight = child.left + child.width
      val childBottom = child.top + child.height
      if (childRight > maxWidth) maxWidth = childRight
      if (childBottom > maxHeight) maxHeight = childBottom
    }

    if (maxWidth <= 0 || maxHeight <= 0) return null

    val bitmap = createBitmap(maxWidth, maxHeight)
    val canvas = Canvas(bitmap)
    contentView.draw(canvas)
    return bitmap
  }

  fun onDropViewInstance() {
    contentView.removeAllViews()
  }
}
