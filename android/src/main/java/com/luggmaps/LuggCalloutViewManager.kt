package com.luggmaps

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.LuggCalloutViewManagerDelegate
import com.facebook.react.viewmanagers.LuggCalloutViewManagerInterface

@ReactModule(name = LuggCalloutViewManager.NAME)
class LuggCalloutViewManager :
  ViewGroupManager<LuggCalloutView>(),
  LuggCalloutViewManagerInterface<LuggCalloutView> {
  private val delegate: ViewManagerDelegate<LuggCalloutView> = LuggCalloutViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggCalloutView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggCalloutView = LuggCalloutView(context)

  override fun setBubbled(view: LuggCalloutView, value: Boolean) {
    view.bubbled = value
  }

  override fun setOffset(view: LuggCalloutView, value: ReadableMap?) {
    view.offsetX = value?.getDouble("x")?.toFloat()?.dpToPx() ?: 0f
    view.offsetY = value?.getDouble("y")?.toFloat()?.dpToPx() ?: 0f
  }

  override fun onDropViewInstance(view: LuggCalloutView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  companion object {
    const val NAME = "LuggCalloutView"
  }
}
