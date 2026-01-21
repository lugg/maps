package com.luggmaps

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggGoogleMapViewManagerDelegate
import com.facebook.react.viewmanagers.LuggGoogleMapViewManagerInterface
import com.google.android.gms.maps.model.LatLng
import com.luggmaps.events.CameraIdleEvent
import com.luggmaps.events.CameraMoveEvent
import com.luggmaps.events.ReadyEvent
import com.luggmaps.extensions.dispatchEvent

@ReactModule(name = LuggGoogleMapViewManager.NAME)
class LuggGoogleMapViewManager :
  ViewGroupManager<LuggGoogleMapView>(),
  LuggGoogleMapViewManagerInterface<LuggGoogleMapView>,
  LuggGoogleMapViewEventDelegate {
  private val delegate: ViewManagerDelegate<LuggGoogleMapView> = LuggGoogleMapViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggGoogleMapView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): LuggGoogleMapView {
    val view = LuggGoogleMapView(context)
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
    view: LuggGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  ) {
    view.dispatchEvent(CameraMoveEvent(view, latitude, longitude, zoom, gesture))
  }

  override fun onCameraIdle(
    view: LuggGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  ) {
    view.dispatchEvent(CameraIdleEvent(view, latitude, longitude, zoom, gesture))
  }

  override fun onReady(view: LuggGoogleMapView) {
    view.dispatchEvent(ReadyEvent(view))
  }

  @ReactProp(name = "mapId")
  override fun setMapId(view: LuggGoogleMapView, value: String?) {
    view.setMapId(value)
  }

  @ReactProp(name = "initialCoordinate")
  override fun setInitialCoordinate(view: LuggGoogleMapView, value: ReadableMap?) {
    value?.let {
      val latitude = if (it.hasKey("latitude")) it.getDouble("latitude") else 0.0
      val longitude = if (it.hasKey("longitude")) it.getDouble("longitude") else 0.0
      view.setInitialCoordinate(latitude, longitude)
    }
  }

  @ReactProp(name = "initialZoom", defaultDouble = 10.0)
  override fun setInitialZoom(view: LuggGoogleMapView, value: Double) {
    view.setInitialZoom(value)
  }

  @ReactProp(name = "zoomEnabled", defaultBoolean = true)
  override fun setZoomEnabled(view: LuggGoogleMapView, value: Boolean) {
    view.setZoomEnabled(value)
  }

  @ReactProp(name = "scrollEnabled", defaultBoolean = true)
  override fun setScrollEnabled(view: LuggGoogleMapView, value: Boolean) {
    view.setScrollEnabled(value)
  }

  @ReactProp(name = "rotateEnabled", defaultBoolean = true)
  override fun setRotateEnabled(view: LuggGoogleMapView, value: Boolean) {
    view.setRotateEnabled(value)
  }

  @ReactProp(name = "pitchEnabled", defaultBoolean = true)
  override fun setPitchEnabled(view: LuggGoogleMapView, value: Boolean) {
    view.setPitchEnabled(value)
  }

  @ReactProp(name = "userLocationEnabled", defaultBoolean = false)
  override fun setUserLocationEnabled(view: LuggGoogleMapView, value: Boolean) {
    view.setUserLocationEnabled(value)
  }

  @ReactProp(name = "minZoom")
  override fun setMinZoom(view: LuggGoogleMapView, value: Double) {
    view.setMinZoom(value)
  }

  @ReactProp(name = "maxZoom")
  override fun setMaxZoom(view: LuggGoogleMapView, value: Double) {
    view.setMaxZoom(value)
  }

  @ReactProp(name = "padding")
  override fun setPadding(view: LuggGoogleMapView, value: ReadableMap?) {
    value?.let {
      val top = if (it.hasKey("top")) it.getDouble("top").toFloat().dpToPx().toInt() else 0
      val left = if (it.hasKey("left")) it.getDouble("left").toFloat().dpToPx().toInt() else 0
      val bottom = if (it.hasKey("bottom")) it.getDouble("bottom").toFloat().dpToPx().toInt() else 0
      val right = if (it.hasKey("right")) it.getDouble("right").toFloat().dpToPx().toInt() else 0
      view.setMapPadding(top, left, bottom, right)
    }
  }

  override fun onDropViewInstance(view: LuggGoogleMapView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun moveCamera(
    view: LuggGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Double,
    duration: Double
  ) {
    view.moveCamera(latitude, longitude, zoom, duration.toInt())
  }

  override fun fitCoordinates(view: LuggGoogleMapView, coordinates: ReadableArray?, padding: Double, duration: Double) {
    val coords = mutableListOf<LatLng>()
    coordinates?.let {
      for (i in 0 until it.size()) {
        val coord = it.getMap(i)
        val lat = coord?.getDouble("latitude") ?: 0.0
        val lng = coord?.getDouble("longitude") ?: 0.0
        coords.add(LatLng(lat, lng))
      }
    }
    view.fitCoordinates(coords, padding.toInt(), duration.toInt())
  }

  companion object {
    const val NAME = "LuggGoogleMapView"
  }
}
