package com.luggmaps

import android.annotation.SuppressLint
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.views.view.ReactViewGroup

@SuppressLint("ViewConstructor")
class LuggMapWrapperView(context: ThemedReactContext) : ReactViewGroup(context) {

  override fun requestLayout() {
    super.requestLayout()
    getChildAt(0)?.let {
      it.measure(
        MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
        MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY)
      )
      it.layout(0, 0, width, height)
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
