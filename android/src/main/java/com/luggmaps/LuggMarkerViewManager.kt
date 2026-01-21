package com.luggmaps

import android.util.Log
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggMarkerViewManagerDelegate
import com.facebook.react.viewmanagers.LuggMarkerViewManagerInterface

@ReactModule(name = LuggMarkerViewManager.NAME)
class LuggMarkerViewManager :
  ViewGroupManager<LuggMarkerView>(),
  LuggMarkerViewManagerInterface<LuggMarkerView> {
  private val delegate: ViewManagerDelegate<LuggMarkerView> = LuggMarkerViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggMarkerView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggMarkerView = LuggMarkerView(context)

  override fun onDropViewInstance(view: LuggMarkerView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun onAfterUpdateTransaction(view: LuggMarkerView) {
    super.onAfterUpdateTransaction(view)
    view.onAfterUpdateTransaction()
  }

  @ReactProp(name = "coordinate")
  override fun setCoordinate(view: LuggMarkerView, value: ReadableMap?) {
    value?.let {
      val latitude = if (it.hasKey("latitude")) it.getDouble("latitude") else 0.0
      val longitude = if (it.hasKey("longitude")) it.getDouble("longitude") else 0.0
      view.setCoordinate(latitude, longitude)
    }
  }

  @ReactProp(name = "name")
  override fun setName(view: LuggMarkerView, value: String?) {
    view.setName(value)
  }

  @ReactProp(name = "title")
  override fun setTitle(view: LuggMarkerView, value: String?) {
    view.setTitle(value)
  }

  @ReactProp(name = "description")
  override fun setDescription(view: LuggMarkerView, value: String?) {
    view.setDescription(value)
  }

  @ReactProp(name = "anchor")
  override fun setAnchor(view: LuggMarkerView, value: ReadableMap?) {
    value?.let {
      val x = if (it.hasKey("x")) it.getDouble("x") else 0.5
      val y = if (it.hasKey("y")) it.getDouble("y") else 1.0
      view.setAnchor(x, y)
    }
  }

  companion object {
    const val NAME = "LuggMarkerView"
  }
}
