package com.luggmaps.core

import android.animation.ValueAnimator
import android.graphics.Color
import android.location.Location
import android.view.animation.LinearInterpolator
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Polyline
import com.google.android.gms.maps.model.StrokeStyle
import com.google.android.gms.maps.model.StyleSpan
import kotlin.math.floor
import kotlin.math.min

class PolylineAnimator {
  var polyline: Polyline? = null
  var coordinates: List<LatLng> = emptyList()
  var strokeColors: List<Int> = listOf(Color.BLACK)
  var strokeWidth: Float = 1f

  var animated: Boolean = false
    set(value) {
      if (field == value) return
      field = value
      if (value) {
        startAnimation()
      } else {
        stopAnimation()
        update()
      }
    }

  private var animator: ValueAnimator? = null
  private var animationProgress: Float = 0f
  private var cumulativeDistances: FloatArray = floatArrayOf()
  private var totalLength: Float = 0f

  fun update() {
    if (animated) return

    val poly = polyline ?: return
    if (coordinates.size < 2) return

    poly.points = coordinates

    if (strokeColors.size > 1) {
      poly.setSpans(createGradientSpans())
    } else {
      poly.color = strokeColors.firstOrNull() ?: Color.BLACK
    }
  }

  private fun startAnimation() {
    if (animator != null) return

    computeCumulativeDistances()

    animator = ValueAnimator.ofFloat(0f, 2.15f).apply {
      duration = 2150
      repeatCount = ValueAnimator.INFINITE
      interpolator = LinearInterpolator()
      addUpdateListener { animation ->
        animationProgress = animation.animatedValue as Float
        updateAnimatedPolyline()
      }
      start()
    }
  }

  private fun computeCumulativeDistances() {
    if (coordinates.size < 2) {
      cumulativeDistances = floatArrayOf(0f)
      totalLength = 0f
      return
    }

    val distances = FloatArray(coordinates.size)
    distances[0] = 0f
    var total = 0f

    for (i in 1 until coordinates.size) {
      val prev = coordinates[i - 1]
      val curr = coordinates[i]
      val results = FloatArray(1)
      Location.distanceBetween(prev.latitude, prev.longitude, curr.latitude, curr.longitude, results)
      total += results[0]
      distances[i] = total
    }

    cumulativeDistances = distances
    totalLength = total
  }

  private fun indexForDistance(distance: Float): Int {
    for (i in 1 until cumulativeDistances.size) {
      if (cumulativeDistances[i] >= distance) {
        return i - 1
      }
    }
    return (cumulativeDistances.size - 2).coerceAtLeast(0)
  }

  private fun coordinateAtDistance(distance: Float): LatLng {
    if (distance <= 0f) return coordinates.first()
    if (distance >= totalLength) return coordinates.last()

    val idx = indexForDistance(distance)
    val segStart = cumulativeDistances[idx]
    val segEnd = cumulativeDistances[idx + 1]
    val segLength = segEnd - segStart

    val t = if (segLength > 0) (distance - segStart) / segLength else 0f
    val c1 = coordinates[idx]
    val c2 = coordinates[idx + 1]

    return LatLng(
      c1.latitude + (c2.latitude - c1.latitude) * t,
      c1.longitude + (c2.longitude - c1.longitude) * t
    )
  }

  private fun stopAnimation() {
    animator?.cancel()
    animator = null
  }

  private fun updateAnimatedPolyline() {
    val poly = polyline ?: return
    if (coordinates.size < 2 || totalLength <= 0f) {
      poly.points = coordinates
      return
    }

    val progress = min(animationProgress, 2f)

    val headDist: Float
    val tailDist: Float

    if (progress <= 1f) {
      tailDist = 0f
      headDist = progress * totalLength
    } else {
      val shrinkProgress = progress - 1f
      tailDist = shrinkProgress * totalLength
      headDist = totalLength
    }

    if (headDist <= tailDist) {
      poly.setSpans(emptyList())
      poly.points = listOf(coordinates.firstOrNull() ?: LatLng(0.0, 0.0))
      return
    }

    val visibleLength = headDist - tailDist
    val startIndex = indexForDistance(tailDist)
    val endIndex = indexForDistance(headDist)

    val points = mutableListOf<LatLng>()
    val spans = mutableListOf<StyleSpan>()

    points.add(coordinateAtDistance(tailDist))

    for (i in (startIndex + 1)..endIndex) {
      points.add(coordinates[i])
    }

    val endCoord = coordinateAtDistance(headDist)
    val lastAdded = points.lastOrNull()
    if (lastAdded == null || endCoord.latitude != lastAdded.latitude || endCoord.longitude != lastAdded.longitude) {
      points.add(endCoord)
    }

    for (i in 0 until (points.size - 1)) {
      val segMidDist = tailDist + visibleLength * (i + 0.5f) / (points.size - 1)
      val gradientPos = (segMidDist - tailDist) / visibleLength
      val color = colorAtGradientPosition(gradientPos)
      spans.add(StyleSpan(StrokeStyle.colorBuilder(color).build()))
    }

    poly.points = points
    if (spans.isNotEmpty()) {
      poly.setSpans(spans)
    }
  }

  private fun createGradientSpans(): List<StyleSpan> {
    val segmentCount = coordinates.size - 1
    return (0 until segmentCount).map { i ->
      val position = i.toFloat() / segmentCount
      val color = colorAtGradientPosition(position)
      StyleSpan(StrokeStyle.colorBuilder(color).build())
    }
  }

  private fun colorAtGradientPosition(position: Float): Int {
    if (strokeColors.isEmpty()) return Color.BLACK
    if (strokeColors.size == 1) return strokeColors[0]

    val pos = position.coerceIn(0f, 1f)
    val scaledPos = pos * (strokeColors.size - 1)
    val index = floor(scaledPos).toInt()
    val t = scaledPos - index

    if (index >= strokeColors.size - 1) return strokeColors.last()

    val c1 = strokeColors[index]
    val c2 = strokeColors[index + 1]

    val r = ((Color.red(c1) + (Color.red(c2) - Color.red(c1)) * t).toInt())
    val g = ((Color.green(c1) + (Color.green(c2) - Color.green(c1)) * t).toInt())
    val b = ((Color.blue(c1) + (Color.blue(c2) - Color.blue(c1)) * t).toInt())
    val a = ((Color.alpha(c1) + (Color.alpha(c2) - Color.alpha(c1)) * t).toInt())

    return Color.argb(a, r, g, b)
  }

  fun destroy() {
    stopAnimation()
    polyline = null
  }
}
