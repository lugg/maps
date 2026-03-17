package com.luggmaps

import android.annotation.SuppressLint
import android.view.MotionEvent
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.views.view.ReactViewGroup

@SuppressLint("ViewConstructor")
class LuggMapWrapperView(context: ThemedReactContext) : ReactViewGroup(context) {

  var touchEventHandler: ((MotionEvent) -> Unit)? = null

  override fun dispatchTouchEvent(event: MotionEvent): Boolean {
    touchEventHandler?.invoke(event)
    return super.dispatchTouchEvent(event)
  }

  override fun onLayout(
    changed: Boolean,
    left: Int,
    top: Int,
    right: Int,
    bottom: Int
  ) {
    super.onLayout(changed, left, top, right, bottom)
    val w = right - left
    val h = bottom - top
    getChildAt(0)?.let {
      it.measure(
        MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY),
        MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY)
      )
      it.layout(0, 0, w, h)
    }
  }
}
