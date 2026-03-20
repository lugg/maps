package com.luggmaps

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggGroundOverlayViewManagerDelegate
import com.facebook.react.viewmanagers.LuggGroundOverlayViewManagerInterface
import com.google.android.gms.maps.model.LatLng

@ReactModule(name = LuggGroundOverlayViewManager.NAME)
class LuggGroundOverlayViewManager :
  ViewGroupManager<LuggGroundOverlayView>(),
  LuggGroundOverlayViewManagerInterface<LuggGroundOverlayView> {
  private val delegate: ViewManagerDelegate<LuggGroundOverlayView> = LuggGroundOverlayViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggGroundOverlayView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggGroundOverlayView = LuggGroundOverlayView(context)

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    mapOf("topGroundOverlayPress" to mapOf("registrationName" to "onGroundOverlayPress"))

  override fun onDropViewInstance(view: LuggGroundOverlayView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun onAfterUpdateTransaction(view: LuggGroundOverlayView) {
    super.onAfterUpdateTransaction(view)
    view.onAfterUpdateTransaction()
  }

  @ReactProp(name = "image")
  override fun setImage(view: LuggGroundOverlayView, value: String?) {
    view.setImageUri(value ?: "")
  }

  @ReactProp(name = "bounds")
  override fun setBounds(view: LuggGroundOverlayView, value: ReadableMap?) {
    value?.let { map ->
      val ne = map.getMap("northeast")
      val sw = map.getMap("southwest")
      val northeast = LatLng(
        ne?.getDouble("latitude") ?: 0.0,
        ne?.getDouble("longitude") ?: 0.0
      )
      val southwest = LatLng(
        sw?.getDouble("latitude") ?: 0.0,
        sw?.getDouble("longitude") ?: 0.0
      )
      view.setBounds(northeast, southwest)
    }
  }

  @ReactProp(name = "opacity", defaultDouble = 1.0)
  override fun setOpacity(view: LuggGroundOverlayView, value: Double) {
    view.setOverlayOpacity(value.toFloat())
  }

  @ReactProp(name = "bearing", defaultDouble = 0.0)
  override fun setBearing(view: LuggGroundOverlayView, value: Double) {
    view.setBearing(value.toFloat())
  }

  @ReactProp(name = "tappable")
  override fun setTappable(view: LuggGroundOverlayView, value: Boolean) {
    view.setTappable(value)
  }

  @ReactProp(name = "zIndex", defaultFloat = 0f)
  override fun setZIndex(view: LuggGroundOverlayView, value: Float) {
    super.setZIndex(view, value)
    view.setZIndex(value)
  }

  companion object {
    const val NAME = "LuggGroundOverlayView"
  }
}
