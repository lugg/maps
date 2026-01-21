package com.luggmaps.extensions

import android.view.View
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
