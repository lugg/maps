package com.luggmaps

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggMapViewManagerDelegate
import com.facebook.react.viewmanagers.LuggMapViewManagerInterface
import com.google.android.gms.maps.model.LatLng
import com.luggmaps.events.CameraIdleEvent
import com.luggmaps.events.CameraMoveEvent
import com.luggmaps.events.ReadyEvent
import com.luggmaps.extensions.dispatchEvent

@ReactModule(name = LuggMapViewManager.NAME)
class LuggMapViewManager :
  ViewGroupManager<LuggMapView>(),
  LuggMapViewManagerInterface<LuggMapView>,
  LuggMapViewEventDelegate {
  private val delegate: ViewManagerDelegate<LuggMapView> = LuggMapViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggMapView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): LuggMapView {
    val view = LuggMapView(context)
    view.eventDelegate = this
    return view
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    mapOf(
      "topCameraMove" to mapOf("registrationName" to "onCameraMove"),
      "topCameraIdle" to mapOf("registrationName" to "onCameraIdle"),
      "topReady" to mapOf("registrationName" to "onReady")
    )

  override fun onCameraMove(
    view: LuggMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  ) {
    view.dispatchEvent(CameraMoveEvent(view, latitude, longitude, zoom, gesture))
  }

  override fun onCameraIdle(
    view: LuggMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  ) {
    view.dispatchEvent(CameraIdleEvent(view, latitude, longitude, zoom, gesture))
  }

  override fun onReady(view: LuggMapView) {
    view.dispatchEvent(ReadyEvent(view))
  }

  @ReactProp(name = "provider")
  override fun setProvider(view: LuggMapView, value: String?) {
    // No-op on Android — always Google Maps
  }

  @ReactProp(name = "mapId")
  override fun setMapId(view: LuggMapView, value: String?) {
    view.setMapId(value)
  }

  @ReactProp(name = "initialCoordinate")
  override fun setInitialCoordinate(view: LuggMapView, value: ReadableMap?) {
    value?.let {
      val latitude = if (it.hasKey("latitude")) it.getDouble("latitude") else 0.0
      val longitude = if (it.hasKey("longitude")) it.getDouble("longitude") else 0.0
      view.setInitialCoordinate(latitude, longitude)
    }
  }

  @ReactProp(name = "initialZoom", defaultDouble = 10.0)
  override fun setInitialZoom(view: LuggMapView, value: Double) {
    view.setInitialZoom(value)
  }

  @ReactProp(name = "zoomEnabled", defaultBoolean = true)
  override fun setZoomEnabled(view: LuggMapView, value: Boolean) {
    view.setZoomEnabled(value)
  }

  @ReactProp(name = "scrollEnabled", defaultBoolean = true)
  override fun setScrollEnabled(view: LuggMapView, value: Boolean) {
    view.setScrollEnabled(value)
  }

  @ReactProp(name = "rotateEnabled", defaultBoolean = true)
  override fun setRotateEnabled(view: LuggMapView, value: Boolean) {
    view.setRotateEnabled(value)
  }

  @ReactProp(name = "pitchEnabled", defaultBoolean = true)
  override fun setPitchEnabled(view: LuggMapView, value: Boolean) {
    view.setPitchEnabled(value)
  }

  @ReactProp(name = "userLocationEnabled", defaultBoolean = false)
  override fun setUserLocationEnabled(view: LuggMapView, value: Boolean) {
    view.setUserLocationEnabled(value)
  }

  @ReactProp(name = "minZoom")
  override fun setMinZoom(view: LuggMapView, value: Double) {
    view.setMinZoom(value)
  }

  @ReactProp(name = "maxZoom")
  override fun setMaxZoom(view: LuggMapView, value: Double) {
    view.setMaxZoom(value)
  }

  @ReactProp(name = "theme")
  override fun setTheme(view: LuggMapView, value: String?) {
    view.setTheme(value ?: "system")
  }

  @ReactProp(name = "padding")
  override fun setPadding(view: LuggMapView, value: ReadableMap?) {
    value?.let {
      val top = if (it.hasKey("top")) it.getDouble("top").toFloat().dpToPx().toInt() else 0
      val left = if (it.hasKey("left")) it.getDouble("left").toFloat().dpToPx().toInt() else 0
      val bottom = if (it.hasKey("bottom")) it.getDouble("bottom").toFloat().dpToPx().toInt() else 0
      val right = if (it.hasKey("right")) it.getDouble("right").toFloat().dpToPx().toInt() else 0
      view.setMapPadding(top, left, bottom, right)
    }
  }

  override fun onDropViewInstance(view: LuggMapView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun moveCamera(
    view: LuggMapView,
    latitude: Double,
    longitude: Double,
    zoom: Double,
    duration: Double
  ) {
    view.moveCamera(latitude, longitude, zoom, duration.toInt())
  }

  override fun fitCoordinates(
    view: LuggMapView,
    coordinates: ReadableArray?,
    paddingTop: Double,
    paddingLeft: Double,
    paddingBottom: Double,
    paddingRight: Double,
    duration: Double
  ) {
    val coords = mutableListOf<LatLng>()
    coordinates?.let {
      for (i in 0 until it.size()) {
        val coord = it.getMap(i)
        val lat = coord?.getDouble("latitude") ?: 0.0
        val lng = coord?.getDouble("longitude") ?: 0.0
        coords.add(LatLng(lat, lng))
      }
    }
    view.fitCoordinates(coords, paddingTop.toInt(), paddingLeft.toInt(), paddingBottom.toInt(), paddingRight.toInt(), duration.toInt())
  }

  companion object {
    const val NAME = "LuggMapView"
  }
}
