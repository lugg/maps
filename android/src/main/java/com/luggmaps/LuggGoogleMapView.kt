package com.luggmaps

import android.annotation.SuppressLint
import android.util.Log
import android.view.View
import android.view.ViewGroup
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.util.RNLog
import com.facebook.react.views.view.ReactViewGroup
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.GoogleMapOptions
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.model.AdvancedMarker
import com.google.android.gms.maps.model.AdvancedMarkerOptions
import com.google.android.gms.maps.model.AdvancedMarkerOptions.CollisionBehavior
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.PolylineOptions
import com.luggmaps.core.PolylineAnimator

interface LuggGoogleMapViewEventDelegate {
  fun onCameraMove(
    view: LuggGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  )
  fun onCameraIdle(view: LuggGoogleMapView, latitude: Double, longitude: Double, zoom: Float, gesture: Boolean)
}

@SuppressLint("ViewConstructor")
class LuggGoogleMapView(private val reactContext: ThemedReactContext) :
  ReactViewGroup(reactContext),
  OnMapReadyCallback,
  LuggMarkerViewDelegate,
  LuggPolylineViewDelegate,
  GoogleMap.OnCameraMoveStartedListener,
  GoogleMap.OnCameraMoveListener,
  GoogleMap.OnCameraIdleListener {

  var eventDelegate: LuggGoogleMapViewEventDelegate? = null
  private var mapView: MapView? = null
  private var mapWrapperView: LuggMapWrapperView? = null
  private var googleMap: GoogleMap? = null
  private var isMapReady = false
  private var isDragging = false
  private var mapId: String = DEMO_MAP_ID
  private val pendingMarkerViews = mutableListOf<LuggMarkerView>()
  private val pendingPolylineViews = mutableListOf<LuggPolylineView>()
  private val polylineAnimators = mutableMapOf<LuggPolylineView, PolylineAnimator>()

  // Initial camera settings
  private var initialLatitude: Double = 37.78
  private var initialLongitude: Double = -122.43
  private var initialZoom: Float = 14f

  // UI settings
  private var zoomEnabled: Boolean = true
  private var scrollEnabled: Boolean = true
  private var rotateEnabled: Boolean = true
  private var pitchEnabled: Boolean = true

  // Padding
  private var paddingTop: Int = 0
  private var paddingLeft: Int = 0
  private var paddingBottom: Int = 0
  private var paddingRight: Int = 0

  // region View Lifecycle

  override fun addView(child: View?, index: Int) {
    super.addView(child, index)
    when (child) {
      is LuggMapWrapperView -> mapWrapperView = child

      is LuggMarkerView -> {
        child.delegate = this
        syncMarkerView(child)
      }

      is LuggPolylineView -> {
        child.delegate = this
        syncPolylineView(child)
      }
    }
  }

  override fun removeViewAt(index: Int) {
    val view = getChildAt(index)
    if (view is LuggMarkerView) {
      Log.d(TAG, "removing markerView: ${view.name}")
      view.marker?.remove()
      view.marker = null
    } else if (view is LuggPolylineView) {
      polylineAnimators[view]?.destroy()
      polylineAnimators.remove(view)
      view.polyline?.remove()
      view.polyline = null
    }
    super.removeViewAt(index)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    if (mapView == null && mapWrapperView != null) {
      initializeMap()
    }
  }

  fun onDropViewInstance() {
    Log.d(TAG, "dropping mapView instance")
    pendingMarkerViews.clear()
    pendingPolylineViews.clear()
    polylineAnimators.values.forEach { it.destroy() }
    polylineAnimators.clear()
    googleMap?.clear()
    googleMap = null
    isMapReady = false
    mapView?.onPause()
    mapView?.onDestroy()
    mapView = null
    mapWrapperView = null
  }

  // endregion

  // region Map Initialization

  private fun initializeMap() {
    if (mapView != null || mapWrapperView == null) return

    val options = GoogleMapOptions().mapId(mapId)
    mapView = MapView(context, options).also { view ->
      view.onCreate(null)
      view.onResume()
      view.getMapAsync(this)
      mapWrapperView?.addView(
        view,
        LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
      )
    }
  }

  override fun onMapReady(map: GoogleMap) {
    googleMap = map
    isMapReady = true

    val position = LatLng(initialLatitude, initialLongitude)
    map.moveCamera(CameraUpdateFactory.newLatLngZoom(position, initialZoom))

    map.setOnCameraMoveStartedListener(this)
    map.setOnCameraMoveListener(this)
    map.setOnCameraIdleListener(this)

    applyUiSettings()
    applyPadding()
    processPendingMarkers()
    processPendingPolylines()
  }

  override fun onCameraMoveStarted(reason: Int) {
    isDragging = reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE
  }

  override fun onCameraMove() {
    val map = googleMap ?: return
    val position = map.cameraPosition
    eventDelegate?.onCameraMove(this, position.target.latitude, position.target.longitude, position.zoom, isDragging)
  }

  override fun onCameraIdle() {
    val map = googleMap ?: return
    val position = map.cameraPosition
    eventDelegate?.onCameraIdle(this, position.target.latitude, position.target.longitude, position.zoom, isDragging)
    isDragging = false
  }

  private fun applyUiSettings() {
    googleMap?.uiSettings?.apply {
      isZoomGesturesEnabled = zoomEnabled
      isScrollGesturesEnabled = scrollEnabled
      isRotateGesturesEnabled = rotateEnabled
      isTiltGesturesEnabled = pitchEnabled
    }
  }

  private fun applyPadding() {
    googleMap?.setPadding(paddingLeft, paddingTop, paddingRight, paddingBottom)
  }

  // endregion

  // region PolylineViewDelegate

  override fun polylineViewDidUpdate(polylineView: LuggPolylineView) {
    syncPolylineView(polylineView)
  }

  // endregion

  // region MarkerViewDelegate

  override fun markerViewDidLayout(markerView: LuggMarkerView) {
    if (googleMap == null) {
      if (!pendingMarkerViews.contains(markerView)) {
        pendingMarkerViews.add(markerView)
      }
      return
    }

    if (markerView.hasCustomView) {
      // Recreate marker with custom view
      markerView.marker?.remove()
      addMarkerViewToMap(markerView)
    } else {
      syncMarkerView(markerView)
    }
  }

  override fun markerViewDidUpdate(markerView: LuggMarkerView) {
    syncMarkerView(markerView)
  }

  // endregion

  // region Marker Management

  private fun syncMarkerView(markerView: LuggMarkerView) {
    if (googleMap == null) {
      if (!pendingMarkerViews.contains(markerView)) {
        pendingMarkerViews.add(markerView)
      }
      return
    }

    if (markerView.marker == null) {
      // Custom views need layout first before adding to map
      if (markerView.hasCustomView) return
      addMarkerViewToMap(markerView)
      return
    }

    markerView.marker?.apply {
      position = LatLng(markerView.latitude, markerView.longitude)
      title = markerView.title
      snippet = markerView.description
      setAnchor(markerView.anchorX, markerView.anchorY)
      if (!markerView.hasCustomView) {
        iconView = null
      }
    }
  }

  private fun processPendingMarkers() {
    if (googleMap == null) return

    Log.d(TAG, "processing pending markers ${pendingMarkerViews.size}")
    pendingMarkerViews.forEach { addMarkerViewToMap(it) }
    pendingMarkerViews.clear()
  }

  private fun addMarkerViewToMap(markerView: LuggMarkerView) {
    val map = googleMap ?: run {
      RNLog.w(reactContext, "Lugg: addMarkerViewToMap called without a map")
      return
    }

    val position = LatLng(markerView.latitude, markerView.longitude)
    val iconView = markerView.iconView

    (iconView.parent as? ViewGroup)?.removeView(iconView)

    val options = AdvancedMarkerOptions()
      .position(position)
      .title(markerView.title)
      .snippet(markerView.description)
      .collisionBehavior(CollisionBehavior.REQUIRED)

    Log.d(TAG, "adding marker: ${markerView.name} customview: ${markerView.hasCustomView}")
    if (markerView.hasCustomView) {
      options.iconView(iconView)
    }

    val marker = map.addMarker(options) as AdvancedMarker
    marker.setAnchor(markerView.anchorX, markerView.anchorY)

    markerView.marker = marker
  }

  // endregion

  // region Polyline Management

  private fun syncPolylineView(polylineView: LuggPolylineView) {
    if (googleMap == null) {
      if (!pendingPolylineViews.contains(polylineView)) {
        pendingPolylineViews.add(polylineView)
      }
      return
    }

    if (polylineView.polyline == null) {
      addPolylineViewToMap(polylineView)
      return
    }

    polylineView.polyline?.width = polylineView.strokeWidth.dpToPx()

    polylineAnimators[polylineView]?.apply {
      coordinates = polylineView.coordinates
      strokeColors = polylineView.strokeColors
      strokeWidth = polylineView.strokeWidth.dpToPx()
      animated = polylineView.animated
      update()
    }
  }

  private fun processPendingPolylines() {
    if (googleMap == null) return

    pendingPolylineViews.forEach { addPolylineViewToMap(it) }
    pendingPolylineViews.clear()
  }

  private fun addPolylineViewToMap(polylineView: LuggPolylineView) {
    val map = googleMap ?: return

    val options = PolylineOptions()
      .width(polylineView.strokeWidth.dpToPx())

    val polyline = map.addPolyline(options)
    polylineView.polyline = polyline

    val animator = PolylineAnimator().apply {
      this.polyline = polyline
      coordinates = polylineView.coordinates
      strokeColors = polylineView.strokeColors
      strokeWidth = polylineView.strokeWidth.dpToPx()
      animated = polylineView.animated
      update()
    }

    polylineAnimators[polylineView] = animator
  }

  // endregion

  // region Property Setters

  fun setMapId(value: String?) {
    if (value.isNullOrEmpty()) return

    if (mapView != null) {
      RNLog.w(reactContext, "Lugg: mapId cannot be changed after map is initialized")
      return
    }

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
    zoomEnabled = enabled
    googleMap?.uiSettings?.isZoomGesturesEnabled = enabled
  }

  fun setScrollEnabled(enabled: Boolean) {
    scrollEnabled = enabled
    googleMap?.uiSettings?.isScrollGesturesEnabled = enabled
  }

  fun setRotateEnabled(enabled: Boolean) {
    rotateEnabled = enabled
    googleMap?.uiSettings?.isRotateGesturesEnabled = enabled
  }

  fun setPitchEnabled(enabled: Boolean) {
    pitchEnabled = enabled
    googleMap?.uiSettings?.isTiltGesturesEnabled = enabled
  }

  fun setMapPadding(top: Int, left: Int, bottom: Int, right: Int) {
    paddingTop = top
    paddingLeft = left
    paddingBottom = bottom
    paddingRight = right
    applyPadding()
  }

  // endregion

  // region Commands

  fun moveCamera(latitude: Double, longitude: Double, zoom: Double, duration: Int) {
    val map = googleMap ?: return
    val position = LatLng(latitude, longitude)
    val cameraUpdate = CameraUpdateFactory.newLatLngZoom(position, zoom.toFloat())
    when {
      duration < 0 -> map.animateCamera(cameraUpdate)
      duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
      else -> map.moveCamera(cameraUpdate)
    }
  }

  fun fitCoordinates(coordinates: List<LatLng>, padding: Int, duration: Int) {
    val map = googleMap ?: return
    if (coordinates.isEmpty()) return

    val boundsBuilder = com.google.android.gms.maps.model.LatLngBounds.Builder()
    coordinates.forEach { boundsBuilder.include(it) }
    val bounds = boundsBuilder.build()

    val cameraUpdate = CameraUpdateFactory.newLatLngBounds(bounds, padding.toFloat().dpToPx().toInt())
    when {
      duration < 0 -> map.animateCamera(cameraUpdate)
      duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
      else -> map.moveCamera(cameraUpdate)
    }
  }

  // endregion

  companion object {
    private const val TAG = "Lugg"
    const val DEMO_MAP_ID = "DEMO_MAP_ID"
  }
}
