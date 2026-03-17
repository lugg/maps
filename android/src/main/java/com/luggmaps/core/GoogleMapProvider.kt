package com.luggmaps.core

import android.annotation.SuppressLint
import android.content.Context
import android.view.View
import android.widget.ImageView
import androidx.core.graphics.createBitmap
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.GoogleMapOptions
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.model.AdvancedMarker
import com.google.android.gms.maps.model.AdvancedMarkerOptions
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapColorScheme
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.Polygon
import com.google.android.gms.maps.model.PolygonOptions
import com.google.android.gms.maps.model.PolylineOptions
import com.luggmaps.LuggCalloutView
import com.luggmaps.LuggMapWrapperView
import com.luggmaps.LuggMarkerView
import com.luggmaps.LuggMarkerViewDelegate
import com.luggmaps.LuggPolygonView
import com.luggmaps.LuggPolygonViewDelegate
import com.luggmaps.LuggPolylineView
import com.luggmaps.LuggPolylineViewDelegate

class GoogleMapProvider(private val context: Context) :
  MapProvider,
  OnMapReadyCallback,
  LuggMarkerViewDelegate,
  LuggPolylineViewDelegate,
  LuggPolygonViewDelegate,
  GoogleMap.OnCameraMoveStartedListener,
  GoogleMap.OnCameraMoveListener,
  GoogleMap.OnCameraIdleListener,
  GoogleMap.OnMapClickListener,
  GoogleMap.OnMapLongClickListener,
  GoogleMap.OnPolygonClickListener,
  GoogleMap.OnMarkerClickListener,
  GoogleMap.OnMarkerDragListener,
  GoogleMap.InfoWindowAdapter {

  override var delegate: MapProviderDelegate? = null
  override val isMapReady: Boolean get() = _isMapReady

  var mapId: String = DEMO_MAP_ID

  private var wrapperView: LuggMapWrapperView? = null
  private var mapView: MapView? = null
  private var googleMap: GoogleMap? = null
  private var _isMapReady = false
  private var isDragging = false
  private val pendingMarkerViews = mutableSetOf<LuggMarkerView>()
  private val pendingPolylineViews = mutableSetOf<LuggPolylineView>()
  private val pendingPolygonViews = mutableSetOf<LuggPolygonView>()
  private val polylineAnimators = mutableMapOf<LuggPolylineView, PolylineAnimator>()
  private val polygonToViewMap = mutableMapOf<Polygon, LuggPolygonView>()
  private val markerToViewMap = mutableMapOf<Marker, LuggMarkerView>()
  private val liveMarkerViews = mutableSetOf<LuggMarkerView>()
  private var activeNonBubbledMarker: Marker? = null
  private var tapLocation: LatLng? = null

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
  private var userLocationButtonEnabled: Boolean = false

  // Zoom limits
  private var minZoom: Float? = null
  private var maxZoom: Float? = null

  // Theme
  private var theme: String = "system"

  // Edge Insets
  private var edgeInsets: EdgeInsets = EdgeInsets()

  // region MapProvider

  override fun initializeMap(wrapperView: View, latitude: Double, longitude: Double, zoom: Float) {
    if (mapView != null) return

    initialLatitude = latitude
    initialLongitude = longitude
    initialZoom = zoom

    val wrapper = wrapperView as LuggMapWrapperView
    this.wrapperView = wrapper

    val options = GoogleMapOptions().mapId(mapId)
    mapView = MapView(context, options).also { view ->
      view.onCreate(null)
      view.onResume()
      view.getMapAsync(this)
      wrapper.addView(view)
    }
  }

  override fun destroy() {
    dismissNonBubbledCallout()
    for (markerView in liveMarkerViews) {
      markerView.onUpdate = null
    }
    liveMarkerViews.clear()
    pendingMarkerViews.clear()
    pendingPolylineViews.clear()
    pendingPolygonViews.clear()
    polylineAnimators.values.forEach { it.destroy() }
    polylineAnimators.clear()
    polygonToViewMap.clear()
    markerToViewMap.clear()
    wrapperView?.touchEventHandler = null
    wrapperView = null
    googleMap?.setOnCameraMoveStartedListener(null)
    googleMap?.setOnCameraMoveListener(null)
    googleMap?.setOnCameraIdleListener(null)
    googleMap?.setOnMapClickListener(null)
    googleMap?.setOnMapLongClickListener(null)
    googleMap?.setOnPolygonClickListener(null)
    googleMap?.setOnMarkerClickListener(null)
    googleMap?.setOnMarkerDragListener(null)
    googleMap?.setInfoWindowAdapter(null)
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
    map.setOnMapClickListener(this)
    map.setOnMapLongClickListener(this)
    map.setOnPolygonClickListener(this)
    map.setOnMarkerClickListener(this)
    map.setOnMarkerDragListener(this)
    map.setInfoWindowAdapter(this)

    wrapperView?.touchEventHandler = { event ->
      if (event.action == android.view.MotionEvent.ACTION_DOWN) {
        tapLocation = map.projection.fromScreenLocation(android.graphics.Point(event.x.toInt(), event.y.toInt()))
      }
    }

    applyUiSettings()
    applyZoomLimits()
    applyEdgeInsets()
    applyTheme()
    applyUserLocation()
    processPendingMarkers()
    processPendingPolylines()
    processPendingPolygons()

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
    positionLiveMarkers()
    positionNonBubbledCallout()
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

  override fun onMapClick(latLng: LatLng) {
    dismissNonBubbledCallout()
    val map = googleMap ?: return
    val point = map.projection.toScreenLocation(latLng)
    delegate?.mapProviderDidPress(latLng.latitude, latLng.longitude, point.x.toFloat(), point.y.toFloat())
  }

  override fun onMapLongClick(latLng: LatLng) {
    val map = googleMap ?: return
    val point = map.projection.toScreenLocation(latLng)
    delegate?.mapProviderDidLongPress(latLng.latitude, latLng.longitude, point.x.toFloat(), point.y.toFloat())
  }

  override fun onPolygonClick(polygon: Polygon) {
    val polygonView = polygonToViewMap[polygon]
    if (polygonView?.tappable == true) {
      polygonView.emitPressEvent()
    } else {
      onMapClick(tapLocation ?: return)
    }
  }

  override fun onMarkerClick(marker: Marker): Boolean {
    dismissNonBubbledCallout()

    markerToViewMap[marker]?.let { view ->
      val point = googleMap?.projection?.toScreenLocation(marker.position)
      view.emitPressEvent(point?.x?.toFloat() ?: 0f, point?.y?.toFloat() ?: 0f)

      val calloutView = view.calloutView
      if (calloutView != null && !calloutView.bubbled && calloutView.hasCustomContent) {
        googleMap?.animateCamera(CameraUpdateFactory.newLatLng(marker.position))
        showNonBubbledCallout(marker, calloutView)
        return true
      }
    }
    return false
  }

  override fun onMarkerDragStart(marker: Marker) {
    markerToViewMap[marker]?.let { view ->
      view.isDragging = true
      view.setCoordinate(marker.position.latitude, marker.position.longitude)
      val point = googleMap?.projection?.toScreenLocation(marker.position)
      view.emitDragStartEvent(point?.x?.toFloat() ?: 0f, point?.y?.toFloat() ?: 0f)
      if (!view.rasterize) positionLiveMarker(view)
    }
  }

  override fun onMarkerDrag(marker: Marker) {
    markerToViewMap[marker]?.let { view ->
      view.setCoordinate(marker.position.latitude, marker.position.longitude)
      val point = googleMap?.projection?.toScreenLocation(marker.position)
      view.emitDragChangeEvent(point?.x?.toFloat() ?: 0f, point?.y?.toFloat() ?: 0f)
      if (!view.rasterize) positionLiveMarker(view)
    }
  }

  override fun onMarkerDragEnd(marker: Marker) {
    markerToViewMap[marker]?.let { view ->
      view.isDragging = false
      view.setCoordinate(marker.position.latitude, marker.position.longitude)
      val point = googleMap?.projection?.toScreenLocation(marker.position)
      view.emitDragEndEvent(point?.x?.toFloat() ?: 0f, point?.y?.toFloat() ?: 0f)
      if (!view.rasterize) positionLiveMarker(view)
    }
  }

  override fun getInfoWindow(marker: Marker): View? {
    // Non-bubbled callouts are rendered as live views, not info windows
    return null
  }

  override fun getInfoContents(marker: Marker): View? {
    val markerView = markerToViewMap[marker] ?: return null
    val calloutView = markerView.calloutView ?: return null
    if (!calloutView.hasCustomContent || !calloutView.bubbled) return null

    val bitmap = calloutView.createContentBitmap() ?: return null
    return ImageView(context).apply { setImageBitmap(bitmap) }
  }

  private fun showNonBubbledCallout(marker: Marker, calloutView: LuggCalloutView) {
    val wrapper = wrapperView ?: return
    val contentView = calloutView.contentView

    calloutView.onUpdate = {
      layoutNonBubbledCallout()
      positionNonBubbledCallout()
    }

    dismissInfoWindows()
    wrapper.addView(contentView)
    activeNonBubbledMarker = marker
    layoutNonBubbledCallout()
    positionNonBubbledCallout()
  }

  private fun dismissInfoWindows() {
    for ((marker, _) in markerToViewMap) {
      if (marker.isInfoWindowShown) {
        marker.hideInfoWindow()
      }
    }
  }

  private fun dismissNonBubbledCallout() {
    val marker = activeNonBubbledMarker ?: return
    val markerView = markerToViewMap[marker] ?: return
    val calloutView = markerView.calloutView ?: return
    val contentView = calloutView.contentView

    calloutView.onUpdate = null
    (contentView.parent as? android.view.ViewGroup)?.removeView(contentView)
    activeNonBubbledMarker = null
  }

  private fun layoutNonBubbledCallout() {
    val marker = activeNonBubbledMarker ?: return
    val markerView = markerToViewMap[marker] ?: return
    val calloutView = markerView.calloutView ?: return
    val contentView = calloutView.contentView

    var contentWidth = 0
    var contentHeight = 0
    for (i in 0 until contentView.childCount) {
      val child = contentView.getChildAt(i)
      val childRight = child.left + child.width
      val childBottom = child.top + child.height
      if (childRight > contentWidth) contentWidth = childRight
      if (childBottom > contentHeight) contentHeight = childBottom
    }

    contentView.measure(
      View.MeasureSpec.makeMeasureSpec(contentWidth, View.MeasureSpec.EXACTLY),
      View.MeasureSpec.makeMeasureSpec(contentHeight, View.MeasureSpec.EXACTLY)
    )
    contentView.layout(0, 0, contentWidth, contentHeight)
  }

  private fun positionNonBubbledCallout() {
    val marker = activeNonBubbledMarker ?: return
    val markerView = markerToViewMap[marker] ?: return
    val calloutView = markerView.calloutView ?: return
    val contentView = calloutView.contentView
    val map = googleMap ?: return

    val point = map.projection.toScreenLocation(marker.position)
    contentView.translationX = point.x - contentView.width * calloutView.anchorX
    contentView.translationY = point.y - contentView.height * calloutView.anchorY
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

  override fun setUserLocationButtonEnabled(enabled: Boolean) {
    userLocationButtonEnabled = enabled
    googleMap?.uiSettings?.isMyLocationButtonEnabled = enabled
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

  override fun setEdgeInsets(edgeInsets: EdgeInsets) {
    val oldInsets = this.edgeInsets
    this.edgeInsets = edgeInsets
    applyEdgeInsets()

    val map = googleMap
    if (map != null && oldInsets != edgeInsets) {
      mapView?.post {
        setEdgeInsets(edgeInsets, 0)
      }
    }
  }

  override fun setEdgeInsets(edgeInsets: EdgeInsets, duration: Int) {
    val map = googleMap
    val oldInsets = this.edgeInsets
    this.edgeInsets = edgeInsets

    if (map != null && oldInsets != edgeInsets) {
      val cameraUpdate = CameraUpdateFactory.newCameraPosition(map.cameraPosition)
      applyEdgeInsets()
      when {
        duration < 0 -> map.animateCamera(cameraUpdate)
        duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
        else -> map.moveCamera(cameraUpdate)
      }
    } else {
      applyEdgeInsets()
    }
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

  // region PolygonViewDelegate

  override fun polygonViewDidUpdate(polygonView: LuggPolygonView) {
    syncPolygonView(polygonView)
  }

  // endregion

  // region Marker Management

  override fun addMarkerView(markerView: LuggMarkerView) {
    markerView.delegate = this
    syncMarkerView(markerView)
  }

  override fun removeMarkerView(markerView: LuggMarkerView) {
    removeLiveMarker(markerView)
    markerView.marker?.let { markerToViewMap.remove(it) }
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
      if (!markerView.isDragging) {
        position = LatLng(markerView.latitude, markerView.longitude)
      }
      title = markerView.title
      snippet = markerView.description
      setAnchor(markerView.anchorX, markerView.anchorY)
      zIndex = markerView.zIndex
      rotation = markerView.rotate
      isDraggable = markerView.draggable
    }

    if (markerView.hasCustomView) {
      if (markerView.scaleChanged) {
        markerView.applyScaleToMarker()
        markerView.clearScaleChanged()
      }
      if (!markerView.rasterize) {
        positionLiveMarker(markerView)
      }
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
    marker.isDraggable = markerView.draggable

    markerView.marker = marker
    markerToViewMap[marker] = markerView

    if (markerView.hasCustomView) {
      if (markerView.rasterize) {
        markerView.applyIconToMarker()
      } else {
        showLiveMarker(markerView)
      }
    }
  }

  // Workaround: AdvancedMarker.iconView is buggy on Android, so we manually add the custom
  // content view to the wrapper and position it via screen projection instead. The underlying
  // marker uses a transparent bitmap matching the content size so taps still trigger onMarkerClick.
  private fun showLiveMarker(markerView: LuggMarkerView) {
    val wrapper = wrapperView ?: return

    markerView.onUpdate = {
      updateLiveMarkerHitArea(markerView)
      positionLiveMarker(markerView)
    }

    val contentView = markerView.contentView
    contentView.pointerEvents = com.facebook.react.uimanager.PointerEvents.NONE
    (contentView.parent as? android.view.ViewGroup)?.removeView(contentView)
    wrapper.addView(contentView)
    liveMarkerViews.add(markerView)
    markerView.layoutContentView()
    updateLiveMarkerHitArea(markerView)
    positionLiveMarker(markerView)
  }

  private fun updateLiveMarkerHitArea(markerView: LuggMarkerView) {
    val marker = markerView.marker ?: return
    val contentView = markerView.contentView
    val w = contentView.width.coerceAtLeast(1)
    val h = contentView.height.coerceAtLeast(1)
    marker.setIcon(BitmapDescriptorFactory.fromBitmap(createBitmap(w, h)))
  }

  private fun removeLiveMarker(markerView: LuggMarkerView) {
    markerView.onUpdate = null
    val contentView = markerView.contentView
    (contentView.parent as? android.view.ViewGroup)?.removeView(contentView)
    liveMarkerViews.remove(markerView)
  }

  private fun positionLiveMarkers() {
    for (markerView in liveMarkerViews) {
      positionLiveMarker(markerView)
    }
  }

  private fun positionLiveMarker(markerView: LuggMarkerView) {
    val map = googleMap ?: return
    val contentView = markerView.contentView
    val point = map.projection.toScreenLocation(LatLng(markerView.latitude, markerView.longitude))
    contentView.translationX = point.x - contentView.width * markerView.anchorX
    contentView.translationY = point.y - contentView.height * markerView.anchorY
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

  // region Polygon Management

  override fun addPolygonView(polygonView: LuggPolygonView) {
    polygonView.delegate = this
    syncPolygonView(polygonView)
  }

  override fun removePolygonView(polygonView: LuggPolygonView) {
    polygonView.polygon?.let { polygonToViewMap.remove(it) }
    polygonView.polygon?.remove()
    polygonView.polygon = null
  }

  private fun syncPolygonView(polygonView: LuggPolygonView) {
    if (googleMap == null) {
      pendingPolygonViews.add(polygonView)
      return
    }

    if (polygonView.polygon == null) {
      addPolygonViewToMap(polygonView)
      return
    }

    polygonView.polygon?.apply {
      points = polygonView.coordinates
      holes = polygonView.holes
      fillColor = polygonView.fillColor
      strokeColor = polygonView.strokeColor
      strokeWidth = polygonView.strokeWidth.dpToPx()
      zIndex = polygonView.zIndex
      isClickable = true
    }
  }

  private fun processPendingPolygons() {
    if (googleMap == null) return
    pendingPolygonViews.forEach { addPolygonViewToMap(it) }
    pendingPolygonViews.clear()
  }

  private fun addPolygonViewToMap(polygonView: LuggPolygonView) {
    val map = googleMap ?: return

    val options = PolygonOptions()
      .addAll(polygonView.coordinates)
      .fillColor(polygonView.fillColor)
      .strokeColor(polygonView.strokeColor)
      .strokeWidth(polygonView.strokeWidth.dpToPx())
      .zIndex(polygonView.zIndex)
      .clickable(true)

    for (hole in polygonView.holes) {
      options.addHole(hole)
    }

    val polygon = map.addPolygon(options)
    polygonView.polygon = polygon
    polygonToViewMap[polygon] = polygonView
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
    edgeInsetsTop: Int,
    edgeInsetsLeft: Int,
    edgeInsetsBottom: Int,
    edgeInsetsRight: Int,
    duration: Int
  ) {
    val map = googleMap ?: return
    if (coordinates.isEmpty()) return

    val latLngs = coordinates.filterIsInstance<LatLng>()
    if (latLngs.isEmpty()) return

    val boundsBuilder = com.google.android.gms.maps.model.LatLngBounds.Builder()
    latLngs.forEach { boundsBuilder.include(it) }
    val bounds = boundsBuilder.build()

    val top = edgeInsetsTop.toFloat().dpToPx().toInt()
    val left = edgeInsetsLeft.toFloat().dpToPx().toInt()
    val bottom = edgeInsetsBottom.toFloat().dpToPx().toInt()
    val right = edgeInsetsRight.toFloat().dpToPx().toInt()

    map.setPadding(
      edgeInsets.left + left,
      edgeInsets.top + top,
      edgeInsets.right + right,
      edgeInsets.bottom + bottom
    )

    val cameraUpdate = CameraUpdateFactory.newLatLngBounds(bounds, 0)

    when {
      duration < 0 -> map.animateCamera(cameraUpdate)
      duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
      else -> map.moveCamera(cameraUpdate)
    }

    map.setPadding(edgeInsets.left, edgeInsets.top, edgeInsets.right, edgeInsets.bottom)
  }

  // endregion

  // region Private

  private fun applyUiSettings() {
    googleMap?.uiSettings?.apply {
      isZoomGesturesEnabled = zoomEnabled
      isScrollGesturesEnabled = scrollEnabled
      isRotateGesturesEnabled = rotateEnabled
      isTiltGesturesEnabled = pitchEnabled
      isMyLocationButtonEnabled = userLocationButtonEnabled
    }
  }

  private fun applyZoomLimits() {
    googleMap?.apply {
      minZoom?.let { setMinZoomPreference(it) }
      maxZoom?.let { setMaxZoomPreference(it) }
    }
  }

  private fun applyEdgeInsets() {
    googleMap?.setPadding(edgeInsets.left, edgeInsets.top, edgeInsets.right, edgeInsets.bottom)
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
    googleMap?.uiSettings?.isMyLocationButtonEnabled = userLocationButtonEnabled
  }

  // endregion

  companion object {
    const val DEMO_MAP_ID = "DEMO_MAP_ID"
  }
}
