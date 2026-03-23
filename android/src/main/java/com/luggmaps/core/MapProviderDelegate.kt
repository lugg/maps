package com.luggmaps.core

import android.view.View
import com.luggmaps.LuggCircleView
import com.luggmaps.LuggGroundOverlayView
import com.luggmaps.LuggMarkerView
import com.luggmaps.LuggPolygonView
import com.luggmaps.LuggPolylineView
import com.luggmaps.LuggTileOverlayView

data class EdgeInsets(val top: Int = 0, val left: Int = 0, val bottom: Int = 0, val right: Int = 0)

interface MapProviderDelegate {
  fun mapProviderDidReady()
  fun mapProviderDidMoveCamera(latitude: Double, longitude: Double, zoom: Float, gesture: Boolean)
  fun mapProviderDidIdleCamera(latitude: Double, longitude: Double, zoom: Float, gesture: Boolean)
  fun mapProviderDidPress(latitude: Double, longitude: Double, x: Float, y: Float)
  fun mapProviderDidLongPress(latitude: Double, longitude: Double, x: Float, y: Float)
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
  fun setUserLocationButtonEnabled(enabled: Boolean)
  fun setMapType(value: String)
  fun setTheme(value: String)
  fun setMinZoom(zoom: Double)
  fun setMaxZoom(zoom: Double)
  fun setEdgeInsets(edgeInsets: EdgeInsets)
  fun setEdgeInsets(edgeInsets: EdgeInsets, duration: Int)
  fun setInsetAdjustment(value: String)
  fun setPoiEnabled(enabled: Boolean)
  fun setPoiFilterMode(mode: String)
  fun setPoiFilterCategories(categories: List<String>)

  // Children
  fun addMarkerView(markerView: LuggMarkerView)
  fun removeMarkerView(markerView: LuggMarkerView)
  fun addPolylineView(polylineView: LuggPolylineView)
  fun removePolylineView(polylineView: LuggPolylineView)
  fun addPolygonView(polygonView: LuggPolygonView)
  fun removePolygonView(polygonView: LuggPolygonView)
  fun addCircleView(circleView: LuggCircleView)
  fun removeCircleView(circleView: LuggCircleView)
  fun addGroundOverlayView(groundOverlayView: LuggGroundOverlayView)
  fun removeGroundOverlayView(groundOverlayView: LuggGroundOverlayView)
  fun addTileOverlayView(tileOverlayView: LuggTileOverlayView)
  fun removeTileOverlayView(tileOverlayView: LuggTileOverlayView)

  // Lifecycle
  fun pauseAnimations()
  fun resumeAnimations()

  // Commands
  fun moveCamera(latitude: Double, longitude: Double, zoom: Double, duration: Int)
  fun fitCoordinates(
    coordinates: List<Any>,
    edgeInsetsTop: Int,
    edgeInsetsLeft: Int,
    edgeInsetsBottom: Int,
    edgeInsetsRight: Int,
    duration: Int
  )
}
