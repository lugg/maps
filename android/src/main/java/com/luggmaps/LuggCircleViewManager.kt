package com.luggmaps

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggCircleViewManagerDelegate
import com.facebook.react.viewmanagers.LuggCircleViewManagerInterface
import com.google.android.gms.maps.model.LatLng

@ReactModule(name = LuggCircleViewManager.NAME)
class LuggCircleViewManager :
  ViewGroupManager<LuggCircleView>(),
  LuggCircleViewManagerInterface<LuggCircleView> {
  private val delegate: ViewManagerDelegate<LuggCircleView> = LuggCircleViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggCircleView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggCircleView = LuggCircleView(context)

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    mapOf("topCirclePress" to mapOf("registrationName" to "onCirclePress"))

  override fun onDropViewInstance(view: LuggCircleView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun onAfterUpdateTransaction(view: LuggCircleView) {
    super.onAfterUpdateTransaction(view)
    view.onAfterUpdateTransaction()
  }

  @ReactProp(name = "center")
  override fun setCenter(view: LuggCircleView, value: ReadableMap?) {
    value?.let { map ->
      val lat = map.getDouble("latitude")
      val lng = map.getDouble("longitude")
      view.setCenter(LatLng(lat, lng))
    }
  }

  @ReactProp(name = "radius", defaultDouble = 0.0)
  override fun setRadius(view: LuggCircleView, value: Double) {
    view.setRadius(value)
  }

  @ReactProp(name = "strokeColor", customType = "Color")
  override fun setStrokeColor(view: LuggCircleView, value: Int?) {
    view.setStrokeColor(value ?: android.graphics.Color.BLACK)
  }

  @ReactProp(name = "fillColor", customType = "Color")
  override fun setFillColor(view: LuggCircleView, value: Int?) {
    view.setFillColor(value ?: android.graphics.Color.argb(77, 0, 0, 0))
  }

  @ReactProp(name = "strokeWidth", defaultDouble = 1.0)
  override fun setStrokeWidth(view: LuggCircleView, value: Double) {
    view.setStrokeWidth(value.toFloat())
  }

  @ReactProp(name = "tappable")
  override fun setTappable(view: LuggCircleView, value: Boolean) {
    view.setTappable(value)
  }

  @ReactProp(name = "zIndex", defaultFloat = 0f)
  override fun setZIndex(view: LuggCircleView, value: Float) {
    super.setZIndex(view, value)
    view.setZIndex(value)
  }

  companion object {
    const val NAME = "LuggCircleView"
  }
}
