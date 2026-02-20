package com.luggmaps

import android.annotation.SuppressLint
import android.view.View
import android.view.View.VISIBLE
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.util.RNLog
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.LatLng
import com.luggmaps.core.EdgeInsets
import com.luggmaps.core.GoogleMapProvider
import com.luggmaps.core.MapProvider
import com.luggmaps.core.MapProviderDelegate

interface LuggMapViewEventDelegate {
  fun onCameraMove(
    view: LuggMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  )
  fun onCameraIdle(
    view: LuggMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  )
  fun onReady(view: LuggMapView)
}

@SuppressLint("ViewConstructor")
class LuggMapView(private val reactContext: ThemedReactContext) :
  ReactViewGroup(reactContext),
  MapProviderDelegate {

  var eventDelegate: LuggMapViewEventDelegate? = null
  private var provider: MapProvider? = null
  private var mapWrapperView: LuggMapWrapperView? = null

  // Cached props (applied during initializeProvider)
  private var mapId: String = GoogleMapProvider.DEMO_MAP_ID
  private var initialLatitude: Double = 37.78
  private var initialLongitude: Double = -122.43
  private var initialZoom: Float = 14f
  private var theme: String = "system"
  private var zoomEnabled: Boolean = true
  private var scrollEnabled: Boolean = true
  private var rotateEnabled: Boolean = true
  private var pitchEnabled: Boolean = true
  private var userLocationEnabled: Boolean = false
  private var userLocationButtonEnabled: Boolean = false
  private var minZoom: Double? = null
  private var maxZoom: Double? = null
  private var edgeInsets: EdgeInsets = EdgeInsets()

  // region View Lifecycle

  override fun addView(child: View?, index: Int) {
    super.addView(child, index)
    when (child) {
      is LuggMapWrapperView -> mapWrapperView = child
      is LuggMarkerView -> provider?.addMarkerView(child)
      is LuggPolylineView -> provider?.addPolylineView(child)
      is LuggPolygonView -> provider?.addPolygonView(child)
    }
  }

  override fun removeViewAt(index: Int) {
    val view = getChildAt(index)
    when (view) {
      is LuggMarkerView -> provider?.removeMarkerView(view)
      is LuggPolylineView -> provider?.removePolylineView(view)
      is LuggPolygonView -> provider?.removePolygonView(view)
    }
    super.removeViewAt(index)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    if (provider == null && mapWrapperView != null) {
      initializeProvider()
    }
  }

  override fun onWindowVisibilityChanged(visibility: Int) {
    super.onWindowVisibilityChanged(visibility)
    if (visibility == VISIBLE) {
      provider?.resumeAnimations()
    } else {
      provider?.pauseAnimations()
    }
  }

  fun onDropViewInstance() {
    provider?.destroy()
    provider = null
    mapWrapperView = null
  }

  // endregion

  // region Provider Initialization

  private fun initializeProvider() {
    if (provider != null || mapWrapperView == null) return

    val google = GoogleMapProvider(context)
    google.mapId = mapId
    google.delegate = this
    provider = google

    applyProps()

    google.initializeMap(mapWrapperView!!, initialLatitude, initialLongitude, initialZoom)

    // Flush children mounted before provider was created
    for (i in 0 until childCount) {
      when (val child = getChildAt(i)) {
        is LuggMarkerView -> google.addMarkerView(child)
        is LuggPolylineView -> google.addPolylineView(child)
        is LuggPolygonView -> google.addPolygonView(child)
      }
    }
  }

  // endregion

  // region MapProviderDelegate

  override fun mapProviderDidReady() {
    eventDelegate?.onReady(this)
  }

  override fun mapProviderDidMoveCamera(latitude: Double, longitude: Double, zoom: Float, gesture: Boolean) {
    eventDelegate?.onCameraMove(this, latitude, longitude, zoom, gesture)
  }

  override fun mapProviderDidIdleCamera(latitude: Double, longitude: Double, zoom: Float, gesture: Boolean) {
    eventDelegate?.onCameraIdle(this, latitude, longitude, zoom, gesture)
  }

  // endregion

  // region Property Setters

  private fun applyProps() {
    provider?.setZoomEnabled(zoomEnabled)
    provider?.setScrollEnabled(scrollEnabled)
    provider?.setRotateEnabled(rotateEnabled)
    provider?.setPitchEnabled(pitchEnabled)
    provider?.setUserLocationEnabled(userLocationEnabled)
    provider?.setUserLocationButtonEnabled(userLocationButtonEnabled)
    provider?.setTheme(theme)
    minZoom?.let { provider?.setMinZoom(it) }
    maxZoom?.let { provider?.setMaxZoom(it) }
    provider?.setEdgeInsets(edgeInsets)
  }

  fun setProvider(value: String?) {
    if (value != null && value != "google") {
      RNLog.w(reactContext, "LuggMapView: Only Google Maps is supported on Android")
    }
  }

  fun setMapId(value: String?) {
    if (value.isNullOrEmpty()) return
    mapId = value
  }

  fun setInitialCoordinate(latitude: Double, longitude: Double) {
    initialLatitude = latitude
    initialLongitude = longitude
  }

  fun setInitialZoom(zoom: Double) {
    initialZoom = zoom.toFloat()
  }

  fun setZoomEnabled(enabled: Boolean) {
    if (zoomEnabled == enabled) return
    zoomEnabled = enabled
    provider?.setZoomEnabled(enabled)
  }

  fun setScrollEnabled(enabled: Boolean) {
    if (scrollEnabled == enabled) return
    scrollEnabled = enabled
    provider?.setScrollEnabled(enabled)
  }

  fun setRotateEnabled(enabled: Boolean) {
    if (rotateEnabled == enabled) return
    rotateEnabled = enabled
    provider?.setRotateEnabled(enabled)
  }

  fun setPitchEnabled(enabled: Boolean) {
    if (pitchEnabled == enabled) return
    pitchEnabled = enabled
    provider?.setPitchEnabled(enabled)
  }

  fun setUserLocationEnabled(enabled: Boolean) {
    if (userLocationEnabled == enabled) return
    userLocationEnabled = enabled
    provider?.setUserLocationEnabled(enabled)
  }

  fun setUserLocationButtonEnabled(enabled: Boolean) {
    if (userLocationButtonEnabled == enabled) return
    userLocationButtonEnabled = enabled
    provider?.setUserLocationButtonEnabled(enabled)
  }

  fun setMinZoom(zoom: Double) {
    if (minZoom == zoom) return
    minZoom = zoom
    provider?.setMinZoom(zoom)
  }

  fun setMaxZoom(zoom: Double) {
    if (maxZoom == zoom) return
    maxZoom = zoom
    provider?.setMaxZoom(zoom)
  }

  fun setTheme(value: String) {
    if (theme == value) return
    theme = value
    provider?.setTheme(value)
  }

  fun setEdgeInsets(
    top: Int,
    left: Int,
    bottom: Int,
    right: Int,
    duration: Int = 0
  ) {
    val newEdgeInsets = EdgeInsets(top, left, bottom, right)
    if (edgeInsets == newEdgeInsets) return
    edgeInsets = newEdgeInsets
    provider?.setEdgeInsets(edgeInsets, duration)
  }

  // endregion

  // region Commands

  fun moveCamera(latitude: Double, longitude: Double, zoom: Double, duration: Int) {
    provider?.moveCamera(latitude, longitude, zoom, duration)
  }

  fun fitCoordinates(
    coordinates: List<LatLng>,
    edgeInsetsTop: Int,
    edgeInsetsLeft: Int,
    edgeInsetsBottom: Int,
    edgeInsetsRight: Int,
    duration: Int
  ) {
    provider?.fitCoordinates(coordinates, edgeInsetsTop, edgeInsetsLeft, edgeInsetsBottom, edgeInsetsRight, duration)
  }

  // endregion
}
