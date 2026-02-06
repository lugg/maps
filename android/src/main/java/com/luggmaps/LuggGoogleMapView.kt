package com.luggmaps

import android.annotation.SuppressLint
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
import com.google.android.gms.maps.model.MapColorScheme
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
  fun onCameraIdle(
    view: LuggGoogleMapView,
    latitude: Double,
    longitude: Double,
    zoom: Float,
    gesture: Boolean
  )
  fun onReady(view: LuggGoogleMapView)
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
  private val pendingMarkerViews = mutableSetOf<LuggMarkerView>()
  private val pendingPolylineViews = mutableSetOf<LuggPolylineView>()
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
  private var userLocationEnabled: Boolean = false

  // Zoom limits
  private var minZoom: Float? = null
  private var maxZoom: Float? = null

  // Theme
  private var theme: String = "system"

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
      mapWrapperView?.addView(view)
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
    applyZoomLimits()
    applyPadding()
    applyTheme()
    applyUserLocation()
    processPendingMarkers()
    processPendingPolylines()

    eventDelegate?.onReady(this)
  }

  override fun onCameraMoveStarted(reason: Int) {
    isDragging = reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE
    if (isDragging) {
      polylineAnimators.values.forEach { it.pause() }
    }
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
    if (isDragging) {
      polylineAnimators.values.forEach { it.resume() }
    }
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

  private fun applyZoomLimits() {
    googleMap?.apply {
      minZoom?.let { setMinZoomPreference(it) }
      maxZoom?.let { setMaxZoomPreference(it) }
    }
  }

  private fun applyPadding() {
    googleMap?.setPadding(paddingLeft, paddingTop, paddingRight, paddingBottom)
  }

  private fun applyTheme() {
    val colorScheme = when (theme) {
      "dark" -> MapColorScheme.DARK
      "light" -> MapColorScheme.LIGHT
      else -> MapColorScheme.FOLLOW_SYSTEM
    }
    googleMap?.setMapColorScheme(colorScheme)
  }

  @SuppressLint("MissingPermission")
  private fun applyUserLocation() {
    val hasPermission =
      context.checkSelfPermission(
        android.Manifest.permission.ACCESS_FINE_LOCATION
      ) == android.content.pm.PackageManager.PERMISSION_GRANTED ||
        context.checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) ==
        android.content.pm.PackageManager.PERMISSION_GRANTED
    googleMap?.isMyLocationEnabled = userLocationEnabled && hasPermission
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
      pendingMarkerViews.add(markerView)
      return
    }

    if (markerView.hasCustomView) {
      markerView.updateIcon { addMarkerViewToMap(markerView) }
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
      pendingMarkerViews.add(markerView)
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
      zIndex = markerView.zIndex
      rotation = markerView.rotate
    }

    if (markerView.hasCustomView && markerView.scaleChanged) {
      markerView.applyScaleToMarker()
      markerView.clearScaleChanged()
    }
  }

  private fun processPendingMarkers() {
    if (googleMap == null) return

    pendingMarkerViews.forEach { addMarkerViewToMap(it) }
    pendingMarkerViews.clear()
  }

  private fun addMarkerViewToMap(markerView: LuggMarkerView) {
    val map = googleMap ?: run {
      RNLog.w(reactContext, "LuggMaps: addMarkerViewToMap called without a map")
      return
    }

    val position = LatLng(markerView.latitude, markerView.longitude)

    val options = AdvancedMarkerOptions()
      .position(position)
      .title(markerView.title)
      .snippet(markerView.description)

    val marker = map.addMarker(options) as AdvancedMarker
    marker.setAnchor(markerView.anchorX, markerView.anchorY)
    marker.zIndex = markerView.zIndex
    marker.rotation = markerView.rotate

    markerView.marker = marker
    markerView.applyIconToMarker()
  }

  // endregion

  // region Polyline Management

  private fun syncPolylineView(polylineView: LuggPolylineView) {
    if (googleMap == null) {
      pendingPolylineViews.add(polylineView)
      return
    }

    if (polylineView.polyline == null) {
      addPolylineViewToMap(polylineView)
      return
    }

    polylineView.polyline?.width = polylineView.strokeWidth.dpToPx()
    polylineView.polyline?.zIndex = polylineView.zIndex

    polylineAnimators[polylineView]?.apply {
      coordinates = polylineView.coordinates
      strokeColors = polylineView.strokeColors
      strokeWidth = polylineView.strokeWidth.dpToPx()
      animatedOptions = polylineView.animatedOptions
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
      .zIndex(polylineView.zIndex)

    val polyline = map.addPolyline(options)
    polylineView.polyline = polyline

    val animator = PolylineAnimator().apply {
      this.polyline = polyline
      coordinates = polylineView.coordinates
      strokeColors = polylineView.strokeColors
      strokeWidth = polylineView.strokeWidth.dpToPx()
      animatedOptions = polylineView.animatedOptions
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
      RNLog.w(reactContext, "LuggMaps: mapId cannot be changed after map is initialized")
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

  fun setUserLocationEnabled(enabled: Boolean) {
    userLocationEnabled = enabled
    applyUserLocation()
  }

  fun setMinZoom(zoom: Double) {
    minZoom = if (zoom > 0) zoom.toFloat() else null
    googleMap?.let { map ->
      minZoom?.let { map.setMinZoomPreference(it) } ?: map.resetMinMaxZoomPreference()
    }
  }

  fun setMaxZoom(zoom: Double) {
    maxZoom = if (zoom > 0) zoom.toFloat() else null
    googleMap?.let { map ->
      maxZoom?.let { map.setMaxZoomPreference(it) } ?: map.resetMinMaxZoomPreference()
    }
  }

  fun setTheme(value: String) {
    theme = value
    applyTheme()
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
    val targetZoom = if (zoom > 0) zoom.toFloat() else map.cameraPosition.zoom
    val cameraUpdate = CameraUpdateFactory.newLatLngZoom(position, targetZoom)
    when {
      duration < 0 -> map.animateCamera(cameraUpdate)
      duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
      else -> map.moveCamera(cameraUpdate)
    }
  }

  fun fitCoordinates(
    coordinates: List<LatLng>,
    paddingTop: Int,
    paddingLeft: Int,
    paddingBottom: Int,
    paddingRight: Int,
    duration: Int
  ) {
    val map = googleMap ?: return
    if (coordinates.isEmpty()) return

    val boundsBuilder = com.google.android.gms.maps.model.LatLngBounds.Builder()
    coordinates.forEach { boundsBuilder.include(it) }
    val bounds = boundsBuilder.build()

    val top = paddingTop.toFloat().dpToPx().toInt()
    val left = paddingLeft.toFloat().dpToPx().toInt()
    val bottom = paddingBottom.toFloat().dpToPx().toInt()
    val right = paddingRight.toFloat().dpToPx().toInt()

    // Set padding before camera update, then restore after
    map.setPadding(
      this.paddingLeft + left,
      this.paddingTop + top,
      this.paddingRight + right,
      this.paddingBottom + bottom
    )

    val cameraUpdate = CameraUpdateFactory.newLatLngBounds(bounds, 0)

    when {
      duration < 0 -> map.animateCamera(cameraUpdate)
      duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
      else -> map.moveCamera(cameraUpdate)
    }

    // Restore base padding
    map.setPadding(this.paddingLeft, this.paddingTop, this.paddingRight, this.paddingBottom)
  }

  // endregion

  companion object {
    private const val TAG = "Lugg"
    const val DEMO_MAP_ID = "DEMO_MAP_ID"
  }
}
