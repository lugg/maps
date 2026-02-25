package com.luggmaps

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggPolygonViewManagerDelegate
import com.facebook.react.viewmanagers.LuggPolygonViewManagerInterface
import com.google.android.gms.maps.model.LatLng

@ReactModule(name = LuggPolygonViewManager.NAME)
class LuggPolygonViewManager :
  ViewGroupManager<LuggPolygonView>(),
  LuggPolygonViewManagerInterface<LuggPolygonView> {
  private val delegate: ViewManagerDelegate<LuggPolygonView> = LuggPolygonViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggPolygonView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggPolygonView = LuggPolygonView(context)

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    mapOf("topPolygonPress" to mapOf("registrationName" to "onPolygonPress"))

  override fun onDropViewInstance(view: LuggPolygonView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun onAfterUpdateTransaction(view: LuggPolygonView) {
    super.onAfterUpdateTransaction(view)
    view.onAfterUpdateTransaction()
  }

  @ReactProp(name = "coordinates")
  override fun setCoordinates(view: LuggPolygonView, value: ReadableArray?) {
    value?.let { array ->
      val coords = mutableListOf<LatLng>()
      for (i in 0 until array.size()) {
        val coord = array.getMap(i)
        val lat = coord?.getDouble("latitude") ?: 0.0
        val lng = coord?.getDouble("longitude") ?: 0.0
        coords.add(LatLng(lat, lng))
      }
      view.setCoordinates(coords)
    }
  }

  @ReactProp(name = "strokeColor", customType = "Color")
  override fun setStrokeColor(view: LuggPolygonView, value: Int?) {
    view.setStrokeColor(value ?: android.graphics.Color.BLACK)
  }

  @ReactProp(name = "fillColor", customType = "Color")
  override fun setFillColor(view: LuggPolygonView, value: Int?) {
    view.setFillColor(value ?: android.graphics.Color.argb(77, 0, 0, 0))
  }

  @ReactProp(name = "strokeWidth", defaultDouble = 1.0)
  override fun setStrokeWidth(view: LuggPolygonView, value: Double) {
    view.setStrokeWidth(value.toFloat())
  }

  @ReactProp(name = "tappable")
  override fun setTappable(view: LuggPolygonView, value: Boolean) {
    view.setTappable(value)
  }

  @ReactProp(name = "zIndex", defaultFloat = 0f)
  override fun setZIndex(view: LuggPolygonView, value: Float) {
    super.setZIndex(view, value)
    view.setZIndex(value)
  }

  companion object {
    const val NAME = "LuggPolygonView"
  }
}
