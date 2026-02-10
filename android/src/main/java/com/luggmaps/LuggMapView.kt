package com.luggmaps

import android.annotation.SuppressLint
import android.view.View
import android.view.View.VISIBLE
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.model.LatLng
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

  // Cached initial props
  private var mapId: String = GoogleMapProvider.DEMO_MAP_ID
  private var initialLatitude: Double = 37.78
  private var initialLongitude: Double = -122.43
  private var initialZoom: Float = 14f

  // region View Lifecycle

  override fun addView(child: View?, index: Int) {
    super.addView(child, index)
    when (child) {
      is LuggMapWrapperView -> mapWrapperView = child
      is LuggMarkerView -> provider?.addMarkerView(child)
      is LuggPolylineView -> provider?.addPolylineView(child)
    }
  }

  override fun removeViewAt(index: Int) {
    val view = getChildAt(index)
    when (view) {
      is LuggMarkerView -> provider?.removeMarkerView(view)
      is LuggPolylineView -> provider?.removePolylineView(view)
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

    google.initializeMap(mapWrapperView!!, initialLatitude, initialLongitude, initialZoom)

    // Flush children mounted before provider was created
    for (i in 0 until childCount) {
      when (val child = getChildAt(i)) {
        is LuggMarkerView -> google.addMarkerView(child)
        is LuggPolylineView -> google.addPolylineView(child)
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
    provider?.setZoomEnabled(enabled)
  }

  fun setScrollEnabled(enabled: Boolean) {
    provider?.setScrollEnabled(enabled)
  }

  fun setRotateEnabled(enabled: Boolean) {
    provider?.setRotateEnabled(enabled)
  }

  fun setPitchEnabled(enabled: Boolean) {
    provider?.setPitchEnabled(enabled)
  }

  fun setUserLocationEnabled(enabled: Boolean) {
    provider?.setUserLocationEnabled(enabled)
  }

  fun setMinZoom(zoom: Double) {
    provider?.setMinZoom(zoom)
  }

  fun setMaxZoom(zoom: Double) {
    provider?.setMaxZoom(zoom)
  }

  fun setTheme(value: String) {
    provider?.setTheme(value)
  }

  fun setMapPadding(top: Int, left: Int, bottom: Int, right: Int) {
    provider?.setMapPadding(top, left, bottom, right)
  }

  // endregion

  // region Commands

  fun moveCamera(latitude: Double, longitude: Double, zoom: Double, duration: Int) {
    provider?.moveCamera(latitude, longitude, zoom, duration)
  }

  fun fitCoordinates(
    coordinates: List<LatLng>,
    paddingTop: Int,
    paddingLeft: Int,
    paddingBottom: Int,
    paddingRight: Int,
    duration: Int
  ) {
    provider?.fitCoordinates(coordinates, paddingTop, paddingLeft, paddingBottom, paddingRight, duration)
  }

  // endregion
}
