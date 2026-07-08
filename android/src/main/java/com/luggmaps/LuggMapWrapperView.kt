package com.luggmaps

import android.annotation.SuppressLint
import android.view.MotionEvent
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.views.view.ReactViewGroup

@SuppressLint("ViewConstructor")
class LuggMapWrapperView(context: ThemedReactContext) : ReactViewGroup(context) {

  var touchEventHandler: ((MotionEvent) -> Unit)? = null

  // React Native never runs an Android layout pass on Yoga-managed views, so
  // a child's requestLayout (e.g. a lite mode MapView displaying its bitmap
  // once loaded) would otherwise never result in a measure/layout. Live maps
  // don't need this - their GL surface renders continuously once sized.
  var relayoutChildOnRequest: Boolean = false

  // Invoked on layout once the view has a non-zero size, so the map
  // provider can create a map sized to the view
  var onLayoutReady: (() -> Unit)? = null

  private val measureAndLayoutChild = Runnable { layoutChild(width, height) }

  override fun dispatchTouchEvent(event: MotionEvent): Boolean {
    touchEventHandler?.invoke(event)
    return super.dispatchTouchEvent(event)
  }

  override fun requestLayout() {
    super.requestLayout()
    if (relayoutChildOnRequest) {
      post(measureAndLayoutChild)
    }
  }

  override fun onLayout(
    changed: Boolean,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int
  ) {
    super.onLayout(changed, left, top, right, bottom)
    layoutChild(right - left, bottom - top)
    if (right - left > 0 && bottom - top > 0) {
      onLayoutReady?.invoke()
    }
  }

  private fun layoutChild(w: Int, h: Int) {
    if (w <= 0 || h <= 0) return
    getChildAt(0)?.let {
      it.measure(
        MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY),
        MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
      )
      it.layout(0, 0, w, h)
    }
  }
}
