package com.luggmaps.core

import android.view.View
import com.luggmaps.LuggMarkerView
import com.luggmaps.LuggPolylineView

interface MapProviderDelegate {
  fun mapProviderDidReady()
  fun mapProviderDidMoveCamera(latitude: Double, longitude: Double, zoom: Float, gesture: Boolean)
  fun mapProviderDidIdleCamera(latitude: Double, longitude: Double, zoom: Float, gesture: Boolean)
}

interface MapProvider {
  var delegate: MapProviderDelegate?
  val isMapReady: Boolean

  fun initializeMap(wrapperView: View, latitude: Double, longitude: Double, zoom: Float)
  fun destroy()

  // Props
  fun setZoomEnabled(enabled: Boolean)
  fun setScrollEnabled(enabled: Boolean)
  fun setRotateEnabled(enabled: Boolean)
  fun setPitchEnabled(enabled: Boolean)
  fun setUserLocationEnabled(enabled: Boolean)
  fun setTheme(value: String)
  fun setMinZoom(zoom: Double)
  fun setMaxZoom(zoom: Double)
  fun setMapPadding(top: Int, left: Int, bottom: Int, right: Int)

  // Children
  fun addMarkerView(markerView: LuggMarkerView)
  fun removeMarkerView(markerView: LuggMarkerView)
  fun addPolylineView(polylineView: LuggPolylineView)
  fun removePolylineView(polylineView: LuggPolylineView)

  // Lifecycle
  fun pauseAnimations()
  fun resumeAnimations()

  // Commands
  fun moveCamera(latitude: Double, longitude: Double, zoom: Double, duration: Int)
  fun fitCoordinates(
    coordinates: List<Any>,
    paddingTop: Int,
    paddingLeft: Int,
    paddingBottom: Int,
    paddingRight: Int,
    duration: Int
  )
}
