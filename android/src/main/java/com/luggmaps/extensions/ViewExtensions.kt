package com.luggmaps.extensions

import android.view.View
import android.view.ViewGroup
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event

fun View.dispatchEvent(event: Event<*>) {
  val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(
    context as ThemedReactContext,
    id
  )
  eventDispatcher?.dispatchEvent(event)
}

fun View.findViewByTag(tag: String): View? {
  if (this.tag?.toString() == tag) return this
  if (this !is ViewGroup) return null
  for (i in 0 until childCount) {
    val found = getChildAt(i).findViewByTag(tag)
    if (found != null) return found
  }
  return null
}
