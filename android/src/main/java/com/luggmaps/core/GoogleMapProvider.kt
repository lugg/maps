package com.luggmaps.core

import android.annotation.SuppressLint
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.res.Configuration
import android.view.View
import android.view.ViewTreeObserver
import android.widget.ImageView
import androidx.core.graphics.createBitmap
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.facebook.react.uimanager.PixelUtil.dpToPx
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.GoogleMapOptions
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.Circle
import com.google.android.gms.maps.model.CircleOptions
import com.google.android.gms.maps.model.GroundOverlay
import com.google.android.gms.maps.model.GroundOverlayOptions
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.android.gms.maps.model.MapColorScheme
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.maps.model.Polygon
import com.google.android.gms.maps.model.PolygonOptions
import com.google.android.gms.maps.model.PolylineOptions
import com.google.android.gms.maps.model.TileOverlayOptions
import com.google.android.gms.maps.model.UrlTileProvider
import com.luggmaps.LuggCalloutView
import com.luggmaps.LuggCircleView
import com.luggmaps.LuggCircleViewDelegate
import com.luggmaps.LuggGroundOverlayView
import com.luggmaps.LuggGroundOverlayViewDelegate
import com.luggmaps.LuggMapWrapperView
import com.luggmaps.LuggMarkerView
import com.luggmaps.LuggMarkerViewDelegate
import com.luggmaps.LuggPolygonView
import com.luggmaps.LuggPolygonViewDelegate
import com.luggmaps.LuggPolylineView
import com.luggmaps.LuggPolylineViewDelegate
import com.luggmaps.LuggTileOverlayView
import com.luggmaps.LuggTileOverlayViewDelegate
import com.luggmaps.extensions.findViewByTag
import java.net.URL
import kotlin.math.atan
import kotlin.math.ln
import kotlin.math.log2
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sinh

class GoogleMapProvider(private val context: Context) :
  MapProvider,
  OnMapReadyCallback,
  LuggMarkerViewDelegate,
  LuggPolylineViewDelegate,
  LuggPolygonViewDelegate,
  LuggCircleViewDelegate,
  LuggGroundOverlayViewDelegate,
  LuggTileOverlayViewDelegate,
  GoogleMap.OnCameraMoveStartedListener,
  GoogleMap.OnCameraMoveListener,
  GoogleMap.OnCameraIdleListener,
  GoogleMap.OnMapClickListener,
  GoogleMap.OnMapLongClickListener,
  GoogleMap.OnPolygonClickListener,
  GoogleMap.OnCircleClickListener,
  GoogleMap.OnGroundOverlayClickListener,
  GoogleMap.OnMarkerClickListener,
  GoogleMap.OnMarkerDragListener,
  GoogleMap.InfoWindowAdapter,
  ComponentCallbacks2 {

  override var delegate: MapProviderDelegate? = null
  override val isMapReady: Boolean get() = _isMapReady

  var mapId: String = DEMO_MAP_ID

  // Renders a non-interactive static map — lite mode when the view fits
  // the lite bitmap cap, a gesture-less full map otherwise. Creation-time only.
  var staticMode: Boolean = false

  private var wrapperView: LuggMapWrapperView? = null
  private var currentNightMode: Int = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
  private var mapView: MapView? = null
  private var googleMap: GoogleMap? = null
  private var _isMapReady = false
  private var isDragging = false
  private val pendingMarkerViews = mutableSetOf<LuggMarkerView>()
  private val pendingPolylineViews = mutableSetOf<LuggPolylineView>()
  private val pendingPolygonViews = mutableSetOf<LuggPolygonView>()
  private val pendingCircleViews = mutableSetOf<LuggCircleView>()
  private val pendingGroundOverlayViews = mutableSetOf<LuggGroundOverlayView>()
  private val pendingTileOverlayViews = mutableSetOf<LuggTileOverlayView>()
  private val polylineAnimators = mutableMapOf<LuggPolylineView, PolylineAnimator>()
  private val polygonToViewMap = mutableMapOf<Polygon, LuggPolygonView>()
  private val circleToViewMap = mutableMapOf<Circle, LuggCircleView>()
  private val groundOverlayToViewMap = mutableMapOf<GroundOverlay, LuggGroundOverlayView>()
  private val markerToViewMap = mutableMapOf<Marker, LuggMarkerView>()
  private val liveMarkerViews = mutableSetOf<LuggMarkerView>()
  private var staticProjectionReady = false
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
  private var compassEnabled: Boolean = true
  private var userLocationEnabled: Boolean = false
  private var userLocationButtonEnabled: Boolean = false

  // Zoom limits
  private var minZoom: Float? = null
  private var maxZoom: Float? = null

  // Theme
  private var theme: String = "system"

  // Edge Insets
  private var edgeInsets: EdgeInsets = EdgeInsets()

  // Inset adjustment
  private var insetAdjustment: String = "never"
  private var systemInsets: EdgeInsets = EdgeInsets()

  // The maps renderer adds and positions the watermark asynchronously; the
  // layout listener re-evaluates the translation on every layout pass
  private var watermarkLayoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
  private var watermarkView: View? = null
  private var watermarkTargetX = 0f
  private var watermarkTargetY = 0f

  // region MapProvider

  override fun initializeMap(wrapperView: View, latitude: Double, longitude: Double, zoom: Float) {
    if (mapView != null) return

    initialLatitude = latitude
    initialLongitude = longitude
    initialZoom = zoom

    val wrapper = wrapperView as LuggMapWrapperView
    wrapper.relayoutChildOnRequest = staticMode
    this.wrapperView = wrapper

    context.applicationContext.registerComponentCallbacks(this)

    // Static mode needs the view size to pick lite vs full map, so wait
    // for the first layout if it hasn't happened yet
    if (staticMode && (wrapper.width == 0 || wrapper.height == 0)) {
      wrapper.onLayoutReady = { createMapView() }
    } else {
      createMapView()
    }
  }

  private fun createMapView() {
    if (mapView != null) return
    val wrapper = wrapperView ?: return

    // Lite mode renders the map as a single bitmap capped at ~2048px per
    // dimension, centered in the view — bigger views get letterboxed. Fall
    // back to a full map (gestures disabled) when the view exceeds the cap
    val useLite = staticMode && maxOf(wrapper.width, wrapper.height) <= LITE_MODE_MAX_SIZE
    val options = GoogleMapOptions().liteMode(useLite)
    // Lite mode doesn't support map IDs (cloud-based styling); setting one
    // makes the static map render blank
    if (!useLite) options.mapId(mapId)
    mapView = MapView(context, options).also { view ->
      view.onCreate(null)
      view.onResume()
      view.getMapAsync(this)
      wrapper.addView(view)
    }
    wrapper.onLayoutReady = null
  }

  override fun destroy() {
    wrapperView?.onLayoutReady = null
    detachWindowInsetsListener()
    detachWatermarkLayoutListener()
    context.applicationContext.unregisterComponentCallbacks(this)
    dismissNonBubbledCallout()
    for (markerView in liveMarkerViews) {
      markerView.onUpdate = null
    }
    liveMarkerViews.clear()
    pendingMarkerViews.clear()
    pendingPolylineViews.clear()
    pendingPolygonViews.clear()
    pendingCircleViews.clear()
    pendingGroundOverlayViews.clear()
    pendingTileOverlayViews.clear()
    polylineAnimators.values.forEach { it.destroy() }
    polylineAnimators.clear()
    polygonToViewMap.clear()
    circleToViewMap.clear()
    groundOverlayToViewMap.clear()
    markerToViewMap.clear()
    wrapperView?.touchEventHandler = null
    wrapperView = null
    googleMap?.setOnCameraMoveStartedListener(null)
    googleMap?.setOnCameraMoveListener(null)
    googleMap?.setOnCameraIdleListener(null)
    googleMap?.setOnMapClickListener(null)
    googleMap?.setOnMapLongClickListener(null)
    googleMap?.setOnPolygonClickListener(null)
    googleMap?.setOnCircleClickListener(null)
    googleMap?.setOnGroundOverlayClickListener(null)
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

    if (staticMode) {
      // Tapping the map otherwise shows an "open in Google Maps" toolbar
      map.uiSettings.isMapToolbarEnabled = false
      // The projection is only valid once the map has rendered, and no
      // camera events fire afterwards to correct live marker positions
      map.setOnMapLoadedCallback {
        staticProjectionReady = true
        positionLiveMarkers()
      }
    }

    // Padding must be in place before the initial camera move: setPadding
    // never repositions the current camera, but camera updates after it are
    // relative to the padded center
    applyEdgeInsets()

    val position = if (staticMode) staticCameraTarget() else LatLng(initialLatitude, initialLongitude)
    map.moveCamera(CameraUpdateFactory.newLatLngZoom(position, initialZoom))

    map.setOnCameraMoveStartedListener(this)
    map.setOnCameraMoveListener(this)
    map.setOnCameraIdleListener(this)
    map.setOnMapClickListener(this)
    map.setOnMapLongClickListener(this)
    map.setOnPolygonClickListener(this)
    map.setOnCircleClickListener(this)
    map.setOnGroundOverlayClickListener(this)
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
    applyInsetAdjustment()
    applyTheme()
    applyUserLocation()
    processPendingMarkers()
    processPendingPolylines()
    processPendingPolygons()
    processPendingCircles()
    processPendingGroundOverlays()
    processPendingTileOverlays()

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

  override fun onCircleClick(circle: Circle) {
    val circleView = circleToViewMap[circle]
    if (circleView?.tappable == true) {
      circleView.emitPressEvent()
    } else {
      onMapClick(tapLocation ?: return)
    }
  }

  override fun onGroundOverlayClick(groundOverlay: GroundOverlay) {
    val view = groundOverlayToViewMap[groundOverlay]
    if (view?.tappable == true) {
      view.emitPressEvent()
    }
  }

  override fun onMarkerClick(marker: Marker): Boolean {
    dismissNonBubbledCallout()

    markerToViewMap[marker]?.let { view ->
      val point = googleMap?.projection?.toScreenLocation(marker.position)
      view.emitPressEvent(point?.x?.toFloat() ?: 0f, point?.y?.toFloat() ?: 0f)

      val calloutView = view.calloutView
      if (calloutView != null && !calloutView.bubbled && calloutView.hasCustomContent) {
        if (view.centerOnPress) {
          googleMap?.animateCamera(CameraUpdateFactory.newLatLng(marker.position))
        }
        showNonBubbledCallout(marker, calloutView)
        return true
      }

      if (!view.centerOnPress) {
        marker.showInfoWindow()
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
    contentView.translationX = point.x - contentView.width / 2f + calloutView.offsetX
    contentView.translationY = point.y - markerView.scaledContentHeight * markerView.anchorY - contentView.height + calloutView.offsetY
  }

  // endregion

  // region Props

  override fun setZoomEnabled(enabled: Boolean) {
    zoomEnabled = enabled
    if (staticMode) return
    googleMap?.uiSettings?.isZoomGesturesEnabled = enabled
  }

  override fun setScrollEnabled(enabled: Boolean) {
    scrollEnabled = enabled
    if (staticMode) return
    googleMap?.uiSettings?.isScrollGesturesEnabled = enabled
  }

  override fun setRotateEnabled(enabled: Boolean) {
    rotateEnabled = enabled
    if (staticMode) return
    googleMap?.uiSettings?.isRotateGesturesEnabled = enabled
  }

  override fun setPitchEnabled(enabled: Boolean) {
    pitchEnabled = enabled
    if (staticMode) return
    googleMap?.uiSettings?.isTiltGesturesEnabled = enabled
  }

  override fun setCompassEnabled(enabled: Boolean) {
    compassEnabled = enabled
    googleMap?.uiSettings?.isCompassEnabled = enabled
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

  override fun setMapType(value: String) {
    googleMap?.mapType = when (value) {
      "satellite" -> GoogleMap.MAP_TYPE_SATELLITE
      "terrain" -> GoogleMap.MAP_TYPE_TERRAIN
      "hybrid" -> GoogleMap.MAP_TYPE_HYBRID
      else -> GoogleMap.MAP_TYPE_NORMAL
    }
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
    if (staticMode) {
      setStaticEdgeInsets(edgeInsets)
      return
    }

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
    if (staticMode) {
      setStaticEdgeInsets(edgeInsets)
      return
    }

    val map = googleMap
    val oldInsets = this.edgeInsets
    this.edgeInsets = edgeInsets

    if (map != null && oldInsets != edgeInsets) {
      val cameraUpdate = CameraUpdateFactory.newCameraPosition(map.cameraPosition)
      applyEdgeInsets(duration)
      when {
        duration < 0 -> map.animateCamera(cameraUpdate)
        duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
        else -> map.moveCamera(cameraUpdate)
      }
    } else {
      applyEdgeInsets()
    }
  }

  override fun setInsetAdjustment(value: String) {
    insetAdjustment = value
    applyInsetAdjustment()
  }

  override fun setPoiEnabled(enabled: Boolean) {}

  override fun setPoiFilterMode(mode: String) {}

  override fun setPoiFilterCategories(categories: List<String>) {}

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

  override fun showCalloutForMarkerView(markerView: LuggMarkerView) {
    val marker = markerView.marker ?: return
    val calloutView = markerView.calloutView

    if (calloutView != null && calloutView.hasCustomContent) {
      dismissNonBubbledCallout()
      if (calloutView.bubbled) {
        marker.showInfoWindow()
      } else {
        showNonBubbledCallout(marker, calloutView)
      }
      return
    }

    if (!markerView.title.isNullOrEmpty()) {
      marker.showInfoWindow()
    }
  }

  override fun hideCalloutForMarkerView(markerView: LuggMarkerView) {
    dismissNonBubbledCallout()
    markerView.marker?.hideInfoWindow()
  }

  // endregion

  // region PolylineViewDelegate

  override fun polylineViewDidUpdate(polylineView: LuggPolylineView) {
    syncPolylineView(polylineView)
  }

  override fun polylineViewDidDrop(polylineView: LuggPolylineView) {
    teardownPolyline(polylineView)
  }

  // endregion

  // region PolygonViewDelegate

  override fun polygonViewDidUpdate(polygonView: LuggPolygonView) {
    syncPolygonView(polygonView)
  }

  // endregion

  // region CircleViewDelegate

  override fun circleViewDidUpdate(circleView: LuggCircleView) {
    syncCircleView(circleView)
  }

  // endregion

  // region GroundOverlayViewDelegate

  override fun groundOverlayViewDidUpdate(groundOverlayView: LuggGroundOverlayView) {
    syncGroundOverlayView(groundOverlayView)
  }

  // endregion

  // region TileOverlayViewDelegate

  override fun tileOverlayViewDidUpdate(tileOverlayView: LuggTileOverlayView) {
    syncTileOverlayView(tileOverlayView)
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
    val options = MarkerOptions()
      .position(position)
      .title(markerView.title)
      .snippet(markerView.description)

    val marker = map.addMarker(options) ?: return
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

  // Live marker: content view is added to the wrapper and positioned via screen projection.
  // The underlying marker uses a transparent bitmap matching the content size so taps still trigger onMarkerClick.
  private fun showLiveMarker(markerView: LuggMarkerView) {
    val wrapper = wrapperView ?: return

    markerView.onUpdate = {
      updateLiveMarkerHitArea(markerView)
      positionLiveMarker(markerView)
    }

    val contentView = markerView.contentView
    contentView.pointerEvents = com.facebook.react.uimanager.PointerEvents.NONE
    // Until the lite map's projection is valid, hide the marker instead of
    // flashing it at a wrong position; onMapLoaded positions and shows it
    contentView.visibility =
      if (staticMode && !staticProjectionReady) View.INVISIBLE else View.VISIBLE
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
    if (staticMode && !staticProjectionReady) return
    val contentView = markerView.contentView
    val point = map.projection.toScreenLocation(LatLng(markerView.latitude, markerView.longitude))
    contentView.translationX = point.x - contentView.width * markerView.anchorX
    contentView.translationY = point.y - contentView.height * markerView.anchorY
    contentView.visibility = View.VISIBLE
  }

  // endregion

  // region Polyline Management

  override fun addPolylineView(polylineView: LuggPolylineView) {
    polylineView.delegate = this
    syncPolylineView(polylineView)
  }

  override fun removePolylineView(polylineView: LuggPolylineView) {
    teardownPolyline(polylineView)
  }

  private fun teardownPolyline(polylineView: LuggPolylineView) {
    pendingPolylineViews.remove(polylineView)
    polylineAnimators.remove(polylineView)?.destroy()
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

    polylineAnimators[polylineView]?.apply {
      coordinates = polylineView.coordinates
      strokeColors = polylineView.strokeColors
      strokeWidth = polylineView.strokeWidth.dpToPx()
      zIndex = polylineView.zIndex
      animatedOptions = polylineView.animatedOptions
      animated = polylineView.animated && !staticMode
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

    polylineAnimators.remove(polylineView)?.destroy()

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
      zIndex = polylineView.zIndex
      animatedOptions = polylineView.animatedOptions
      // Static maps render once; show the full polyline instead of animating
      animated = polylineView.animated && !staticMode
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

  // region Circle Management

  override fun addCircleView(circleView: LuggCircleView) {
    circleView.delegate = this
    syncCircleView(circleView)
  }

  override fun removeCircleView(circleView: LuggCircleView) {
    circleView.circle?.let { circleToViewMap.remove(it) }
    circleView.circle?.remove()
    circleView.circle = null
  }

  private fun syncCircleView(circleView: LuggCircleView) {
    if (googleMap == null) {
      pendingCircleViews.add(circleView)
      return
    }

    if (circleView.circle == null) {
      addCircleViewToMap(circleView)
      return
    }

    circleView.circle?.apply {
      center = circleView.center
      radius = circleView.radius
      fillColor = circleView.fillColor
      strokeColor = circleView.strokeColor
      strokeWidth = circleView.strokeWidth.dpToPx()
      zIndex = circleView.zIndex
      isClickable = true
    }
  }

  private fun processPendingCircles() {
    if (googleMap == null) return
    pendingCircleViews.forEach { addCircleViewToMap(it) }
    pendingCircleViews.clear()
  }

  private fun addCircleViewToMap(circleView: LuggCircleView) {
    val map = googleMap ?: return

    val options = CircleOptions()
      .center(circleView.center)
      .radius(circleView.radius)
      .fillColor(circleView.fillColor)
      .strokeColor(circleView.strokeColor)
      .strokeWidth(circleView.strokeWidth.dpToPx())
      .zIndex(circleView.zIndex)
      .clickable(true)

    val circle = map.addCircle(options)
    circleView.circle = circle
    circleToViewMap[circle] = circleView
  }

  // endregion

  // region Ground Overlay Management

  override fun addGroundOverlayView(groundOverlayView: LuggGroundOverlayView) {
    groundOverlayView.delegate = this
    syncGroundOverlayView(groundOverlayView)
  }

  override fun removeGroundOverlayView(groundOverlayView: LuggGroundOverlayView) {
    groundOverlayView.delegate = null
    groundOverlayView.groundOverlay?.let { groundOverlayToViewMap.remove(it) }
    groundOverlayView.groundOverlay?.remove()
    groundOverlayView.groundOverlay = null
  }

  private fun syncGroundOverlayView(groundOverlayView: LuggGroundOverlayView) {
    if (googleMap == null) {
      pendingGroundOverlayViews.add(groundOverlayView)
      return
    }

    val imageUri = groundOverlayView.imageUri
    if (imageUri.isEmpty()) return

    // Remove old overlay
    groundOverlayView.groundOverlay?.let { groundOverlayToViewMap.remove(it) }
    groundOverlayView.groundOverlay?.remove()
    groundOverlayView.groundOverlay = null

    // Load image async and add overlay
    Thread {
      try {
        val connection = URL(imageUri).openConnection() as java.net.HttpURLConnection
        connection.instanceFollowRedirects = true
        connection.connect()
        val bitmap = android.graphics.BitmapFactory.decodeStream(connection.inputStream)
        connection.disconnect()
        if (bitmap != null) {
          mapView?.post {
            addGroundOverlayToMap(groundOverlayView, bitmap)
          }
        }
      } catch (_: Exception) {}
    }.start()
  }

  private fun addGroundOverlayToMap(groundOverlayView: LuggGroundOverlayView, bitmap: android.graphics.Bitmap) {
    val map = googleMap ?: return

    val bounds = LatLngBounds(groundOverlayView.southwest, groundOverlayView.northeast)
    val options = GroundOverlayOptions()
      .image(BitmapDescriptorFactory.fromBitmap(bitmap))
      .positionFromBounds(bounds)
      .transparency(1f - groundOverlayView.overlayOpacity)
      .bearing(groundOverlayView.bearing)
      .zIndex(groundOverlayView.zIndex)
      .clickable(groundOverlayView.tappable)

    val overlay = map.addGroundOverlay(options)
    if (overlay != null) {
      groundOverlayView.groundOverlay = overlay
      groundOverlayToViewMap[overlay] = groundOverlayView
    }
  }

  private fun processPendingGroundOverlays() {
    if (googleMap == null) return
    pendingGroundOverlayViews.forEach { syncGroundOverlayView(it) }
    pendingGroundOverlayViews.clear()
  }

  // endregion

  // region Tile Overlay Management

  override fun addTileOverlayView(tileOverlayView: LuggTileOverlayView) {
    tileOverlayView.delegate = this
    syncTileOverlayView(tileOverlayView)
  }

  override fun removeTileOverlayView(tileOverlayView: LuggTileOverlayView) {
    tileOverlayView.delegate = null
    tileOverlayView.tileOverlay?.remove()
    tileOverlayView.tileOverlay = null
  }

  private fun syncTileOverlayView(tileOverlayView: LuggTileOverlayView) {
    if (googleMap == null) {
      pendingTileOverlayViews.add(tileOverlayView)
      return
    }

    val urlTemplate = tileOverlayView.urlTemplate
    if (urlTemplate.isEmpty()) return

    // Remove old overlay
    tileOverlayView.tileOverlay?.remove()
    tileOverlayView.tileOverlay = null

    val tileSize = tileOverlayView.tileSize
    val hasBounds = tileOverlayView.hasBounds
    val swLat = tileOverlayView.boundsSwLat
    val swLng = tileOverlayView.boundsSwLng
    val neLat = tileOverlayView.boundsNeLat
    val neLng = tileOverlayView.boundsNeLng

    val tileProvider = object : UrlTileProvider(tileSize, tileSize) {
      override fun getTileUrl(x: Int, y: Int, zoom: Int): URL? {
        if (hasBounds) {
          val n = 2.0.pow(zoom.toDouble())
          val tileSWLat = Math.toDegrees(atan(sinh(Math.PI * (1 - 2.0 * (y + 1) / n))))
          val tileNELat = Math.toDegrees(atan(sinh(Math.PI * (1 - 2.0 * y / n))))
          val tileSWLng = x / n * 360.0 - 180.0
          val tileNELng = (x + 1) / n * 360.0 - 180.0

          if (tileNELat < swLat ||
            tileSWLat > neLat ||
            tileNELng < swLng ||
            tileSWLng > neLng
          ) {
            return null
          }
        }

        val url = urlTemplate
          .replace("{x}", x.toString())
          .replace("{y}", y.toString())
          .replace("{z}", zoom.toString())
        return try {
          URL(url)
        } catch (_: Exception) {
          null
        }
      }
    }

    val options = TileOverlayOptions()
      .tileProvider(tileProvider)
      .transparency(1f - tileOverlayView.overlayOpacity)
      .zIndex(tileOverlayView.zIndex)

    val overlay = googleMap?.addTileOverlay(options)
    tileOverlayView.tileOverlay = overlay
  }

  private fun processPendingTileOverlays() {
    if (googleMap == null) return
    pendingTileOverlayViews.forEach { syncTileOverlayView(it) }
    pendingTileOverlayViews.clear()
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
    if (staticMode) {
      // Static maps don't animate; re-center at the final camera
      initialLatitude = latitude
      initialLongitude = longitude
      if (zoom > 0) initialZoom = zoom.toFloat()
      val map = googleMap ?: return
      map.moveCamera(CameraUpdateFactory.newLatLngZoom(staticCameraTarget(), initialZoom))
      positionLiveMarkers()
      return
    }

    val map = googleMap ?: return
    val position = LatLng(latitude, longitude)
    val targetZoom = if (zoom > 0) zoom.toFloat() else map.cameraPosition.zoom
    val cameraPosition = CameraPosition.Builder(map.cameraPosition)
      .target(position)
      .zoom(targetZoom)
      .build()
    val cameraUpdate = CameraUpdateFactory.newCameraPosition(cameraPosition)
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

    val latLongs = coordinates.filterIsInstance<LatLng>()
    if (latLongs.isEmpty()) return

    val top = edgeInsetsTop.toFloat().dpToPx().toInt()
    val left = edgeInsetsLeft.toFloat().dpToPx().toInt()
    val bottom = edgeInsetsBottom.toFloat().dpToPx().toInt()
    val right = edgeInsetsRight.toFloat().dpToPx().toInt()

    if (staticMode) {
      fitStaticCoordinates(latLongs, top, left, bottom, right)
      return
    }

    val boundsBuilder = LatLngBounds.Builder()
    latLongs.forEach { boundsBuilder.include(it) }
    val bounds = boundsBuilder.build()

    val combined = combinedEdgeInsets()
    map.setPadding(
      combined.left + left,
      combined.top + top,
      combined.right + right,
      combined.bottom + bottom
    )

    val cameraUpdate = CameraUpdateFactory.newLatLngBounds(bounds, 0)

    when {
      duration < 0 -> map.animateCamera(cameraUpdate)
      duration > 0 -> map.animateCamera(cameraUpdate, duration, null)
      else -> map.moveCamera(cameraUpdate)
    }

    map.setPadding(combined.left, combined.top, combined.right, combined.bottom)
  }

  // endregion

  // region Private

  private fun applyUiSettings() {
    googleMap?.uiSettings?.apply {
      if (staticMode) {
        // The non-lite fallback is a full map; keep it behaving like a
        // static image (lite mode ignores gestures anyway)
        setAllGesturesEnabled(false)
        return
      }
      isZoomGesturesEnabled = zoomEnabled
      isScrollGesturesEnabled = scrollEnabled
      isRotateGesturesEnabled = rotateEnabled
      isTiltGesturesEnabled = pitchEnabled
      isCompassEnabled = compassEnabled
      isMyLocationButtonEnabled = userLocationButtonEnabled
    }
  }

  private fun applyZoomLimits() {
    googleMap?.apply {
      minZoom?.let { setMinZoomPreference(it) }
      maxZoom?.let { setMaxZoomPreference(it) }
    }
  }

  private fun applyInsetAdjustment() {
    if (insetAdjustment == "automatic") {
      attachWindowInsetsListener()
    } else {
      detachWindowInsetsListener()
      systemInsets = EdgeInsets()
    }
    applyEdgeInsets()
  }

  private fun combinedEdgeInsets(): EdgeInsets =
    if (insetAdjustment == "automatic") {
      EdgeInsets(
        edgeInsets.top + systemInsets.top,
        edgeInsets.left + systemInsets.left,
        edgeInsets.bottom + systemInsets.bottom,
        edgeInsets.right + systemInsets.right
      )
    } else {
      edgeInsets
    }

  private fun applyEdgeInsets(duration: Int = 0) {
    val combined = combinedEdgeInsets()
    // Lite mode misrenders padding: the static image is drawn only within
    // the padded viewport instead of the full view. The camera target shift
    // (staticCameraTarget) compensates for insets instead.
    if (!staticMode) {
      googleMap?.setPadding(combined.left, combined.top, combined.right, combined.bottom)
    }
    applyWatermarkTranslation(combined, duration)
  }

  // Insets are applied by shifting the camera target so the coordinate
  // centers in the inset viewport like a live map would (see
  // applyEdgeInsets for why padding can't be used)
  private fun setStaticEdgeInsets(edgeInsets: EdgeInsets) {
    val oldInsets = this.edgeInsets
    this.edgeInsets = edgeInsets
    applyEdgeInsets()

    val map = googleMap
    if (map != null && oldInsets != edgeInsets) {
      map.moveCamera(CameraUpdateFactory.newLatLngZoom(staticCameraTarget(), initialZoom))
      positionLiveMarkers()
    }
  }

  private fun staticCameraTarget(): LatLng {
    val offsetX = (edgeInsets.left - edgeInsets.right) / 2.0
    val offsetY = (edgeInsets.top - edgeInsets.bottom) / 2.0
    if (offsetX == 0.0 && offsetY == 0.0) return LatLng(initialLatitude, initialLongitude)

    val worldSize = mercatorWorldSize(initialZoom)
    return latLngFromMercator(
      mercatorX(initialLongitude) - offsetX / worldSize,
      mercatorY(initialLatitude) - offsetY / worldSize
    )
  }

  // A static camera can't fit with map padding (lite mode misrenders it);
  // compute the fitted camera in mercator space instead, shifting the
  // center for asymmetric padding like edge insets
  private fun fitStaticCoordinates(
    coordinates: List<LatLng>,
    top: Int,
    left: Int,
    bottom: Int,
    right: Int
  ) {
    val map = googleMap ?: return
    val wrapper = wrapperView ?: return
    if (wrapper.width == 0 || wrapper.height == 0) return

    var minX = Double.MAX_VALUE
    var minY = Double.MAX_VALUE
    var maxX = -Double.MAX_VALUE
    var maxY = -Double.MAX_VALUE
    for (coordinate in coordinates) {
      val x = mercatorX(coordinate.longitude)
      val y = mercatorY(coordinate.latitude)
      minX = minOf(minX, x)
      maxX = maxOf(maxX, x)
      minY = minOf(minY, y)
      maxY = maxOf(maxY, y)
    }

    val insets = combinedEdgeInsets()
    val availWidth = (wrapper.width - insets.left - insets.right - left - right).coerceAtLeast(1)
    val availHeight = (wrapper.height - insets.top - insets.bottom - top - bottom).coerceAtLeast(1)

    // World size in px at which the bounds fit the padded viewport;
    // infinite for coincident coordinates - keep the current zoom then
    val fitWorldSize = minOf(availWidth / (maxX - minX), availHeight / (maxY - minY))
    if (fitWorldSize.isFinite()) {
      initialZoom = log2(fitWorldSize / 256f.dpToPx())
        .toFloat()
        .coerceIn(map.minZoomLevel, map.maxZoomLevel)
    }

    val worldSize = mercatorWorldSize(initialZoom)
    val center = latLngFromMercator(
      (minX + maxX) / 2.0 - (left - right) / 2.0 / worldSize,
      (minY + maxY) / 2.0 - (top - bottom) / 2.0 / worldSize
    )
    initialLatitude = center.latitude
    initialLongitude = center.longitude

    map.moveCamera(CameraUpdateFactory.newLatLngZoom(staticCameraTarget(), initialZoom))
    positionLiveMarkers()
  }

  // Web mercator world space in [0, 1]
  private fun mercatorX(longitude: Double): Double = (longitude + 180.0) / 360.0

  private fun mercatorY(latitude: Double): Double {
    val sinLat = sin(Math.toRadians(latitude))
    return 0.5 - ln((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * Math.PI)
  }

  private fun latLngFromMercator(x: Double, y: Double): LatLng =
    LatLng(Math.toDegrees(atan(sinh(Math.PI * (1.0 - 2.0 * y)))), x * 360.0 - 180.0)

  // World size in px at the given zoom
  private fun mercatorWorldSize(zoom: Float): Double = 256f.dpToPx().toDouble() * 2.0.pow(zoom.toDouble())

  // Whether the renderer repositions the watermark for setPadding varies by
  // renderer version and by whether the watermark existed when padding was
  // set (and lite mode never applies padding). Measure where layout actually
  // placed it and translate only for the remainder.
  private fun applyWatermarkTranslation(insets: EdgeInsets, duration: Int = 0) {
    val view = mapView ?: return
    attachWatermarkLayoutListener()

    if (view.height == 0) return
    val watermark = view.findViewByTag("GoogleWatermark") ?: return

    // Layout position relative to the map view, excluding translation
    var left = 0
    var top = 0
    var current: View? = watermark
    while (current != null && current !== view) {
      left += current.left
      top += current.top
      current = current.parent as? View
    }
    if (current == null) return

    val bottomGap = view.height - (top + watermark.height)
    val targetY = if (bottomGap >= insets.bottom) 0f else -insets.bottom.toFloat()
    val targetX = if (left >= insets.left) 0f else insets.left.toFloat()

    // Skip when already applied (or animating) toward this target so layout
    // passes don't snap an in-flight animation
    if (watermark === watermarkView && targetX == watermarkTargetX && targetY == watermarkTargetY) {
      return
    }
    watermarkView = watermark
    watermarkTargetX = targetX
    watermarkTargetY = targetY

    if (duration > 0) {
      watermark.animate()
        .translationY(targetY)
        .translationX(targetX)
        .setDuration(duration.toLong())
        .start()
    } else if (duration < 0) {
      watermark.animate()
        .translationY(targetY)
        .translationX(targetX)
        .start()
    } else {
      watermark.translationY = targetY
      watermark.translationX = targetX
    }
  }

  private fun attachWatermarkLayoutListener() {
    if (watermarkLayoutListener != null) return
    val view = mapView ?: return

    val listener = ViewTreeObserver.OnGlobalLayoutListener {
      applyWatermarkTranslation(combinedEdgeInsets())
    }
    watermarkLayoutListener = listener
    view.viewTreeObserver.addOnGlobalLayoutListener(listener)
  }

  private fun detachWatermarkLayoutListener() {
    watermarkView = null
    val listener = watermarkLayoutListener ?: return
    watermarkLayoutListener = null
    mapView?.viewTreeObserver?.takeIf { it.isAlive }?.removeOnGlobalLayoutListener(listener)
  }

  private fun attachWindowInsetsListener() {
    val view = mapView ?: return
    ViewCompat.setOnApplyWindowInsetsListener(view) { _, windowInsets ->
      val insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars())
      systemInsets = EdgeInsets(insets.top, insets.left, insets.bottom, insets.right)
      applyEdgeInsets()
      windowInsets
    }
    ViewCompat.requestApplyInsets(view)
  }

  private fun detachWindowInsetsListener() {
    mapView?.let { ViewCompat.setOnApplyWindowInsetsListener(it, null) }
  }

  override fun onConfigurationChanged(newConfig: Configuration) {
    val newNightMode = newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK
    if (newNightMode != currentNightMode) {
      currentNightMode = newNightMode
      applyTheme()
    }
  }

  @Deprecated("Deprecated in Java")
  override fun onLowMemory() {}

  override fun onTrimMemory(level: Int) {}

  private fun applyTheme() {
    val colorScheme = when (theme) {
      "dark" -> MapColorScheme.DARK
      "light" -> MapColorScheme.LIGHT
      else -> MapColorScheme.FOLLOW_SYSTEM
    }
    googleMap?.mapColorScheme = colorScheme
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

    // Undocumented cap on the lite mode bitmap (2048 minus a 2px border,
    // measured empirically)
    private const val LITE_MODE_MAX_SIZE = 2046
  }
}
