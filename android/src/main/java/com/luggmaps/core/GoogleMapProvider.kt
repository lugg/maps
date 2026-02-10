package com.luggmaps.core

import android.annotation.SuppressLint
import android.content.Context
import android.view.View
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.facebook.react.util.RNLog
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.GoogleMapOptions
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.model.AdvancedMarker
import com.google.android.gms.maps.model.AdvancedMarkerOptions
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapColorScheme
import com.google.android.gms.maps.model.PolylineOptions
import com.luggmaps.LuggMarkerView
import com.luggmaps.LuggMarkerViewDelegate
import com.luggmaps.LuggPolylineView
import com.luggmaps.LuggPolylineViewDelegate

class GoogleMapProvider(private val context: Context) :
  MapProvider,
  OnMapReadyCallback,
  LuggMarkerViewDelegate,
  LuggPolylineViewDelegate,
  GoogleMap.OnCameraMoveStartedListener,
  GoogleMap.OnCameraMoveListener,
  GoogleMap.OnCameraIdleListener {

  override var delegate: MapProviderDelegate? = null
  override val isMapReady: Boolean get() = _isMapReady

  var mapId: String = DEMO_MAP_ID

  private var mapView: MapView? = null
  private var googleMap: GoogleMap? = null
  private var _isMapReady = false
  private var isDragging = false
  private val pendingMarkerViews = mutableSetOf<LuggMarkerView>()
  private val pendingPolylineViews = mutableSetOf<LuggPolylineView>()
  private val polylineAnimators = mutableMapOf<LuggPolylineView, PolylineAnimator>()

  // Initial camera settings
  private var initialLatitude: Double = 0.0
  private var initialLongitude: Double = 0.0
  private var initialZoom: Float = 10f

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

  // region MapProvider

  override fun initializeMap(wrapperView: View, latitude: Double, longitude: Double, zoom: Float) {
    if (mapView != null) return

    initialLatitude = latitude
    initialLongitude = longitude
    initialZoom = zoom

    val options = GoogleMapOptions().mapId(mapId)
    mapView = MapView(context, options).also { view ->
      view.onCreate(null)
      view.onResume()
      view.getMapAsync(this)
      (wrapperView as android.view.ViewGroup).addView(view)
    }
  }

  override fun destroy() {
    pendingMarkerViews.clear()
    pendingPolylineViews.clear()
    polylineAnimators.values.forEach { it.destroy() }
    polylineAnimators.clear()
    googleMap?.clear()
    googleMap = null
    _isMapReady = false
    mapView?.onPause()
    mapView?.onDestroy()
    mapView = null
  }

  override fun onMapReady(map: GoogleMap) {
    googleMap = map
    _isMapReady = true

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

    delegate?.mapProviderDidReady()
  }

  // endregion

  // region Camera Listeners

  override fun onCameraMoveStarted(reason: Int) {
    isDragging = reason == GoogleMap.OnCameraMoveStartedListener.REASON_GESTURE
    if (isDragging) {
      polylineAnimators.values.forEach { it.pause() }
    }
  }

  override fun onCameraMove() {
    val map = googleMap ?: return
    val position = map.cameraPosition
    delegate?.mapProviderDidMoveCamera(position.target.latitude, position.target.longitude, position.zoom, isDragging)
  }

  override fun onCameraIdle() {
    val map = googleMap ?: return
    val position = map.cameraPosition
    delegate?.mapProviderDidIdleCamera(position.target.latitude, position.target.longitude, position.zoom, isDragging)
    if (isDragging) {
      polylineAnimators.values.forEach { it.resume() }
    }
    isDragging = false
  }

  // endregion

  // region Props

  override fun setZoomEnabled(enabled: Boolean) {
    zoomEnabled = enabled
    googleMap?.uiSettings?.isZoomGesturesEnabled = enabled
  }

  override fun setScrollEnabled(enabled: Boolean) {
    scrollEnabled = enabled
    googleMap?.uiSettings?.isScrollGesturesEnabled = enabled
  }

  override fun setRotateEnabled(enabled: Boolean) {
    rotateEnabled = enabled
    googleMap?.uiSettings?.isRotateGesturesEnabled = enabled
  }

  override fun setPitchEnabled(enabled: Boolean) {
    pitchEnabled = enabled
    googleMap?.uiSettings?.isTiltGesturesEnabled = enabled
  }

  @SuppressLint("MissingPermission")
  override fun setUserLocationEnabled(enabled: Boolean) {
    userLocationEnabled = enabled
    val hasPermission =
      context.checkSelfPermission(
        android.Manifest.permission.ACCESS_FINE_LOCATION
      ) == android.content.pm.PackageManager.PERMISSION_GRANTED ||
        context.checkSelfPermission(android.Manifest.permission.ACCESS_COARSE_LOCATION) ==
        android.content.pm.PackageManager.PERMISSION_GRANTED
    googleMap?.isMyLocationEnabled = userLocationEnabled && hasPermission
  }

  override fun setTheme(value: String) {
    theme = value
    applyTheme()
  }

  override fun setMinZoom(zoom: Double) {
    minZoom = if (zoom > 0) zoom.toFloat() else null
    googleMap?.let { map ->
      minZoom?.let { map.setMinZoomPreference(it) } ?: map.resetMinMaxZoomPreference()
    }
  }

  override fun setMaxZoom(zoom: Double) {
    maxZoom = if (zoom > 0) zoom.toFloat() else null
    googleMap?.let { map ->
      maxZoom?.let { map.setMaxZoomPreference(it) } ?: map.resetMinMaxZoomPreference()
    }
  }

  override fun setMapPadding(top: Int, left: Int, bottom: Int, right: Int) {
    paddingTop = top
    paddingLeft = left
    paddingBottom = bottom
    paddingRight = right
    applyPadding()
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

  // region PolylineViewDelegate

  override fun polylineViewDidUpdate(polylineView: LuggPolylineView) {
    syncPolylineView(polylineView)
  }

  // endregion

  // region Marker Management

  override fun addMarkerView(markerView: LuggMarkerView) {
    markerView.delegate = this
    syncMarkerView(markerView)
  }

  override fun removeMarkerView(markerView: LuggMarkerView) {
    markerView.marker?.remove()
    markerView.marker = null
  }

  private fun syncMarkerView(markerView: LuggMarkerView) {
    if (googleMap == null) {
      pendingMarkerViews.add(markerView)
      return
    }

    if (markerView.marker == null) {
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
    val map = googleMap ?: return

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

  override fun addPolylineView(polylineView: LuggPolylineView) {
    polylineView.delegate = this
    syncPolylineView(polylineView)
  }

  override fun removePolylineView(polylineView: LuggPolylineView) {
    polylineAnimators[polylineView]?.destroy()
    polylineAnimators.remove(polylineView)
    polylineView.polyline?.remove()
    polylineView.polyline = null
  }

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

  // region Lifecycle

  override fun pauseAnimations() {
    polylineAnimators.values.forEach { it.pause() }
  }

  override fun resumeAnimations() {
    polylineAnimators.values.forEach { it.resume() }
  }

  // endregion

  // region Commands

  override fun moveCamera(latitude: Double, longitude: Double, zoom: Double, duration: Int) {
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

  override fun fitCoordinates(
    coordinates: List<Any>,
    paddingTop: Int,
    paddingLeft: Int,
    paddingBottom: Int,
    paddingRight: Int,
    duration: Int
  ) {
    val map = googleMap ?: return
    if (coordinates.isEmpty()) return

    val latLngs = coordinates.filterIsInstance<LatLng>()
    if (latLngs.isEmpty()) return

    val boundsBuilder = com.google.android.gms.maps.model.LatLngBounds.Builder()
    latLngs.forEach { boundsBuilder.include(it) }
    val bounds = boundsBuilder.build()

    val top = paddingTop.toFloat().dpToPx().toInt()
    val left = paddingLeft.toFloat().dpToPx().toInt()
    val bottom = paddingBottom.toFloat().dpToPx().toInt()
    val right = paddingRight.toFloat().dpToPx().toInt()

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

    map.setPadding(this.paddingLeft, this.paddingTop, this.paddingRight, this.paddingBottom)
  }

  // endregion

  // region Private

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

  companion object {
    const val DEMO_MAP_ID = "DEMO_MAP_ID"
  }
}
