package com.luggmaps

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggPolylineViewManagerDelegate
import com.facebook.react.viewmanagers.LuggPolylineViewManagerInterface
import com.google.android.gms.maps.model.LatLng

@ReactModule(name = LuggPolylineViewManager.NAME)
class LuggPolylineViewManager :
  ViewGroupManager<LuggPolylineView>(),
  LuggPolylineViewManagerInterface<LuggPolylineView> {
  private val delegate: ViewManagerDelegate<LuggPolylineView> = LuggPolylineViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggPolylineView> = delegate
  override fun getName(): String = NAME
  override fun createViewInstance(context: ThemedReactContext): LuggPolylineView = LuggPolylineView(context)

  override fun onDropViewInstance(view: LuggPolylineView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun onAfterUpdateTransaction(view: LuggPolylineView) {
    super.onAfterUpdateTransaction(view)
    view.onAfterUpdateTransaction()
  }

  @ReactProp(name = "coordinates")
  override fun setCoordinates(view: LuggPolylineView, value: ReadableArray?) {
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

  @ReactProp(name = "strokeColors")
  override fun setStrokeColors(view: LuggPolylineView, value: ReadableArray?) {
    val colors = mutableListOf<Int>()
    value?.let { array ->
      for (i in 0 until array.size()) {
        colors.add(array.getInt(i))
      }
    }
    view.setStrokeColors(colors)
  }

  @ReactProp(name = "strokeWidth", defaultDouble = 1.0)
  override fun setStrokeWidth(view: LuggPolylineView, value: Double) {
    view.setStrokeWidth(value.toFloat())
  }

  @ReactProp(name = "animated", defaultBoolean = false)
  override fun setAnimated(view: LuggPolylineView, value: Boolean) {
    view.setAnimated(value)
  }

  @ReactProp(name = "zIndex", defaultFloat = 0f)
  override fun setZIndex(view: LuggPolylineView, value: Float) {
    super.setZIndex(view, value)
    view.setZIndex(value)
  }

  companion object {
    const val NAME = "LuggPolylineView"
  }
}
