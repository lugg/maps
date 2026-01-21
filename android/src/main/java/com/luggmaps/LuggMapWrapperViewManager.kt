package com.luggmaps

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.LuggMapWrapperViewManagerDelegate
import com.facebook.react.viewmanagers.LuggMapWrapperViewManagerInterface

@ReactModule(name = LuggMapWrapperViewManager.NAME)
class LuggMapWrapperViewManager :
  ViewGroupManager<LuggMapWrapperView>(),
  LuggMapWrapperViewManagerInterface<LuggMapWrapperView> {
  private val delegate: ViewManagerDelegate<LuggMapWrapperView> = LuggMapWrapperViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggMapWrapperView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): LuggMapWrapperView = LuggMapWrapperView(context)

  companion object {
    const val NAME = "LuggMapWrapperView"
  }
}
