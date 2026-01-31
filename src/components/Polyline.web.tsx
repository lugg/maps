import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { PolylineProps, PolylineEasing } from './Polyline';

const DEFAULT_DURATION = 2150;

function applyEasing(t: number, easing: PolylineEasing = 'linear'): number {
  switch (easing) {
    case 'easeIn':
      return t * t;
    case 'easeOut':
      return t * (2 - t);
    case 'easeInOut':
      return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
    default:
      return t;
  }
}

function interpolateColor(color1: string, color2: string, t: number): string {
  const hex = (c: string) => parseInt(c, 16);
  const r1 = hex(color1.slice(1, 3));
  const g1 = hex(color1.slice(3, 5));
  const b1 = hex(color1.slice(5, 7));
  const r2 = hex(color2.slice(1, 3));
  const g2 = hex(color2.slice(3, 5));
  const b2 = hex(color2.slice(5, 7));

  const r = Math.round(r1 + (r2 - r1) * t);
  const g = Math.round(g1 + (g2 - g1) * t);
  const b = Math.round(b1 + (b2 - b1) * t);

  return `#${r.toString(16).padStart(2, '0')}${g
    .toString(16)
    .padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
}

function getGradientColor(colors: string[], position: number): string {
  if (colors.length === 0) return '#000000';
  if (colors.length === 1 || position <= 0) return colors[0]!;
  if (position >= 1) return colors[colors.length - 1]!;

  const scaledPos = position * (colors.length - 1);
  const index = Math.floor(scaledPos);
  const t = scaledPos - index;

  return interpolateColor(colors[index]!, colors[index + 1]!, t);
}

export function Polyline({
  coordinates,
  strokeColors,
  strokeWidth = 1,
  animated,
  animatedOptions,
  zIndex,
}: PolylineProps) {
  const resolvedZIndex = zIndex ?? (animated ? 1 : 0);
  const { map, isDragging } = useMapContext();
  const polylinesRef = useRef<google.maps.Polyline[]>([]);
  const animationRef = useRef<number>(0);
  const isPausedRef = useRef(false);

  const colors = useMemo(
    () =>
      strokeColors && strokeColors.length > 0
        ? (strokeColors as string[])
        : ['#000000'],
    [strokeColors]
  );

  const hasGradient = colors.length > 1;

  // Refs for animation loop access
  const propsRef = useRef({
    map,
    colors,
    strokeWidth,
    hasGradient,
    zIndex: resolvedZIndex,
  });
  const [mapReady, setMapReady] = useState(!!map);

  useEffect(() => {
    propsRef.current = {
      map,
      colors,
      strokeWidth,
      hasGradient,
      zIndex: resolvedZIndex,
    };
    if (map && !mapReady) setMapReady(true);
  }, [map, colors, strokeWidth, hasGradient, resolvedZIndex, mapReady]);

  const updatePath = useCallback((path: google.maps.LatLngLiteral[]) => {
    const {
      map: currentMap,
      colors: currentColors,
      strokeWidth: currentStrokeWidth,
      hasGradient: currentHasGradient,
      zIndex: currentZIndex,
    } = propsRef.current;
    if (!currentMap || path.length < 2) return;

    const neededSegments = currentHasGradient ? path.length - 1 : 1;
    const existing = polylinesRef.current;

    // Update or create segments
    for (let i = 0; i < neededSegments; i++) {
      const segmentPath = currentHasGradient ? [path[i]!, path[i + 1]!] : path;
      const color = currentHasGradient
        ? getGradientColor(currentColors, i / (path.length - 1))
        : currentColors[0]!;

      const segment = existing[i];
      if (segment) {
        segment.setPath(segmentPath);
        segment.setOptions({ strokeColor: color });
      } else {
        existing.push(
          new google.maps.Polyline({
            path: segmentPath,
            strokeColor: color,
            strokeWeight: currentStrokeWidth,
            strokeOpacity: 1,
            zIndex: currentZIndex,
            map: currentMap,
          })
        );
      }
    }

    // Remove extra segments
    for (let i = neededSegments; i < existing.length; i++) {
      existing[i]?.setMap(null);
    }
    existing.length = neededSegments;
  }, []);

  // Cleanup on unmount
  useEffect(() => {
    const polylines = polylinesRef.current;
    return () => {
      cancelAnimationFrame(animationRef.current);
      polylines.forEach((p) => p.setMap(null));
    };
  }, []);

  // Pause/resume animation during drag
  useEffect(() => {
    isPausedRef.current = isDragging;
  }, [isDragging]);

  // Main effect
  useEffect(() => {
    if (!propsRef.current.map || coordinates.length === 0) return;

    const fullPath = coordinates.map((c) => ({
      lat: c.latitude,
      lng: c.longitude,
    }));

    cancelAnimationFrame(animationRef.current);

    if (!animated) {
      updatePath(fullPath);
      return;
    }

    const duration = animatedOptions?.duration ?? DEFAULT_DURATION;
    const easing = animatedOptions?.easing ?? 'linear';
    const trailLength = Math.max(0.01, Math.min(1, animatedOptions?.trailLength ?? 1));
    const delay = animatedOptions?.delay ?? 0;

    const totalPoints = fullPath.length;
    const useTrailMode = trailLength < 1;
    const cycleDuration = useTrailMode ? duration : duration * 2;

    let startTime: number | null = null;
    let delayRemaining = delay;

    const animate = (time: number) => {
      if (isPausedRef.current) {
        startTime = null;
        animationRef.current = requestAnimationFrame(animate);
        return;
      }

      if (startTime === null) {
        startTime = time;
      }

      const elapsed = time - startTime;

      if (delayRemaining > 0) {
        if (elapsed < delayRemaining) {
          animationRef.current = requestAnimationFrame(animate);
          return;
        }
        startTime = time - (elapsed - delayRemaining);
        delayRemaining = 0;
      }

      const rawProgress = ((time - startTime) % cycleDuration) / duration;
      const maxProgress = useTrailMode ? 1 : 2;
      const clampedProgress = Math.min(rawProgress, maxProgress);
      const easedProgress = applyEasing(clampedProgress / maxProgress, easing) * maxProgress;

      let startIdx: number;
      let endIdx: number;

      if (useTrailMode) {
        endIdx = easedProgress * totalPoints;
        startIdx = Math.max(0, endIdx - trailLength * totalPoints);
      } else {
        startIdx = easedProgress <= 1 ? 0 : (easedProgress - 1) * totalPoints;
        endIdx = easedProgress <= 1 ? easedProgress * totalPoints : totalPoints;
      }

      if (rawProgress >= maxProgress) {
        delayRemaining = delay;
        startTime = time;
      }

      const partialPath: google.maps.LatLngLiteral[] = [];
      const startFloor = Math.floor(startIdx);
      const endFloor = Math.floor(endIdx);

      // Start point (interpolated)
      if (startFloor < totalPoints) {
        const frac = startIdx - startFloor;
        const from = fullPath[startFloor]!;
        const to = fullPath[Math.min(startFloor + 1, totalPoints - 1)]!;
        partialPath.push(
          frac > 0
            ? {
                lat: from.lat + (to.lat - from.lat) * frac,
                lng: from.lng + (to.lng - from.lng) * frac,
              }
            : from
        );
      }

      // Middle points
      for (
        let i = startFloor + 1;
        i <= Math.min(endFloor, totalPoints - 1);
        i++
      ) {
        partialPath.push(fullPath[i]!);
      }

      // End point (interpolated)
      if (endFloor < totalPoints - 1) {
        const frac = endIdx - endFloor;
        const from = fullPath[endFloor]!;
        const to = fullPath[endFloor + 1]!;
        if (frac > 0) {
          partialPath.push({
            lat: from.lat + (to.lat - from.lat) * frac,
            lng: from.lng + (to.lng - from.lng) * frac,
          });
        }
      }

      updatePath(partialPath);
      animationRef.current = requestAnimationFrame(animate);
    };

    animationRef.current = requestAnimationFrame(animate);

    return () => cancelAnimationFrame(animationRef.current);
  }, [coordinates, animated, animatedOptions, hasGradient, updatePath, mapReady]);

  return null;
}
