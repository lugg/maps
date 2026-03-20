package com.luggmaps

import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggTileOverlayViewManagerDelegate
import com.facebook.react.viewmanagers.LuggTileOverlayViewManagerInterface

@ReactModule(name = LuggTileOverlayViewManager.NAME)
class LuggTileOverlayViewManager :
  ViewGroupManager<LuggTileOverlayView>(),
  LuggTileOverlayViewManagerInterface<LuggTileOverlayView> {
  private val delegate: ViewManagerDelegate<LuggTileOverlayView> = LuggTileOverlayViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggTileOverlayView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggTileOverlayView = LuggTileOverlayView(context)

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    mapOf("topTileOverlayPress" to mapOf("registrationName" to "onTileOverlayPress"))

  override fun onDropViewInstance(view: LuggTileOverlayView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun onAfterUpdateTransaction(view: LuggTileOverlayView) {
    super.onAfterUpdateTransaction(view)
    view.onAfterUpdateTransaction()
  }

  @ReactProp(name = "urlTemplate")
  override fun setUrlTemplate(view: LuggTileOverlayView, value: String?) {
    view.setUrlTemplate(value ?: "")
  }

  @ReactProp(name = "tileSize", defaultInt = 256)
  override fun setTileSize(view: LuggTileOverlayView, value: Int) {
    view.setTileSize(value)
  }

  @ReactProp(name = "opacity", defaultDouble = 1.0)
  override fun setOpacity(view: LuggTileOverlayView, value: Double) {
    view.setOverlayOpacity(value.toFloat())
  }

  @ReactProp(name = "bounds")
  override fun setBounds(view: LuggTileOverlayView, value: ReadableMap?) {
    if (value == null) {
      view.clearBounds()
      return
    }
    val ne = value.getMap("northeast")
    val sw = value.getMap("southwest")
    view.setBounds(
      sw?.getDouble("latitude") ?: 0.0,
      sw?.getDouble("longitude") ?: 0.0,
      ne?.getDouble("latitude") ?: 0.0,
      ne?.getDouble("longitude") ?: 0.0
    )
  }

  @ReactProp(name = "tappable")
  override fun setTappable(view: LuggTileOverlayView, value: Boolean) {
    view.setTappable(value)
  }

  @ReactProp(name = "zIndex", defaultFloat = 0f)
  override fun setZIndex(view: LuggTileOverlayView, value: Float) {
    super.setZIndex(view, value)
    view.setZIndex(value)
  }

  companion object {
    const val NAME = "LuggTileOverlayView"
  }
}
