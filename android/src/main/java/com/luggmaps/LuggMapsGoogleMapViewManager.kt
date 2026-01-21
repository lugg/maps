package com.luggmaps

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LuggMapsGoogleMapViewManagerDelegate
import com.facebook.react.viewmanagers.LuggMapsGoogleMapViewManagerInterface
import com.google.android.gms.maps.model.LatLng
import com.luggmaps.events.CameraIdleEvent
import com.luggmaps.events.CameraMoveEvent

@ReactModule(name = LuggMapsGoogleMapViewManager.NAME)
class LuggMapsGoogleMapViewManager :
  ViewGroupManager<LuggMapsGoogleMapView>(),
  LuggMapsGoogleMapViewManagerInterface<LuggMapsGoogleMapView>,
  LuggMapsGoogleMapViewEventDelegate {
  private val delegate: ViewManagerDelegate<LuggMapsGoogleMapView> = LuggMapsGoogleMapViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LuggMapsGoogleMapView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): LuggMapsGoogleMapView {
    val view = LuggMapsGoogleMapView(context)
    view.eventDelegate = this
    return view
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> =
    mapOf(
      "topCameraMove" to mapOf("registrationName" to "onCameraMove"),
      "topCameraIdle" to mapOf("registrationName" to "onCameraIdle")
    )

  override fun onCameraMove(
    view: LuggMapsGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  ) {
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(
      view.context as ThemedReactContext,
      view.id
    )
    eventDispatcher?.dispatchEvent(CameraMoveEvent(UIManagerHelper.getSurfaceId(view), view.id, latitude, longitude, zoom, gesture))
  }

  override fun onCameraIdle(view: LuggMapsGoogleMapView, latitude: Double, longitude: Double, zoom: Float, gesture: Boolean) {
    val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(
      view.context as ThemedReactContext,
      view.id
    )
    eventDispatcher?.dispatchEvent(CameraIdleEvent(UIManagerHelper.getSurfaceId(view), view.id, latitude, longitude, zoom, gesture))
  }

  @ReactProp(name = "mapId")
  override fun setMapId(view: LuggMapsGoogleMapView, value: String?) {
    view.setMapId(value)
  }

  @ReactProp(name = "initialCoordinate")
  override fun setInitialCoordinate(view: LuggMapsGoogleMapView, value: ReadableMap?) {
    value?.let {
      val latitude = if (it.hasKey("latitude")) it.getDouble("latitude") else 0.0
      val longitude = if (it.hasKey("longitude")) it.getDouble("longitude") else 0.0
      view.setInitialCoordinate(latitude, longitude)
    }
  }

  @ReactProp(name = "initialZoom", defaultDouble = 10.0)
  override fun setInitialZoom(view: LuggMapsGoogleMapView, value: Double) {
    view.setInitialZoom(value)
  }

  @ReactProp(name = "zoomEnabled", defaultBoolean = true)
  override fun setZoomEnabled(view: LuggMapsGoogleMapView, value: Boolean) {
    view.setZoomEnabled(value)
  }

  @ReactProp(name = "scrollEnabled", defaultBoolean = true)
  override fun setScrollEnabled(view: LuggMapsGoogleMapView, value: Boolean) {
    view.setScrollEnabled(value)
  }

  @ReactProp(name = "rotateEnabled", defaultBoolean = true)
  override fun setRotateEnabled(view: LuggMapsGoogleMapView, value: Boolean) {
    view.setRotateEnabled(value)
  }

  @ReactProp(name = "pitchEnabled", defaultBoolean = true)
  override fun setPitchEnabled(view: LuggMapsGoogleMapView, value: Boolean) {
    view.setPitchEnabled(value)
  }

  @ReactProp(name = "padding")
  override fun setPadding(view: LuggMapsGoogleMapView, value: ReadableMap?) {
    value?.let {
      val top = if (it.hasKey("top")) it.getDouble("top").toFloat().dpToPx().toInt() else 0
      val left = if (it.hasKey("left")) it.getDouble("left").toFloat().dpToPx().toInt() else 0
      val bottom = if (it.hasKey("bottom")) it.getDouble("bottom").toFloat().dpToPx().toInt() else 0
      val right = if (it.hasKey("right")) it.getDouble("right").toFloat().dpToPx().toInt() else 0
      view.setMapPadding(top, left, bottom, right)
    }
  }

  override fun onDropViewInstance(view: LuggMapsGoogleMapView) {
    super.onDropViewInstance(view)
    view.onDropViewInstance()
  }

  override fun moveCamera(
    view: LuggMapsGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Double,
    duration: Double
  ) {
    view.moveCamera(latitude, longitude, zoom, duration.toInt())
  }

  override fun fitCoordinates(view: LuggMapsGoogleMapView, coordinates: ReadableArray?, padding: Double, duration: Double) {
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
    const val NAME = "LuggMapsGoogleMapView"
  }
}
