import React from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import type { PolylineProps } from './Polyline';

const ANIMATION_DURATION = 1500;

/**
 * Interpolate between two hex colors
 */
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

/**
 * Get color at position along gradient
 */
function getGradientColor(colors: string[], position: number): string {
  if (colors.length === 0) return '#000000';
  if (colors.length === 1 || position <= 0) return colors[0]!;
  if (position >= 1) return colors[colors.length - 1]!;

  const scaledPos = position * (colors.length - 1);
  const index = Math.floor(scaledPos);
  const t = scaledPos - index;

  return interpolateColor(colors[index]!, colors[index + 1]!, t);
}

function PolylineImpl({
  coordinates,
  strokeColors,
  strokeWidth,
  animated,
}: PolylineProps) {
  const map = useMap();
  const polylinesRef = React.useRef<google.maps.Polyline[]>([]);
  const animationRef = React.useRef<number | null>(null);

  const colors = React.useMemo(
    () =>
      strokeColors && strokeColors.length > 0
        ? (strokeColors as string[])
        : ['#000000'],
    [strokeColors]
  );

  const hasGradient = colors.length > 1;

  const clearPolylines = React.useCallback(() => {
    polylinesRef.current.forEach((p) => p.setMap(null));
    polylinesRef.current = [];
  }, []);

  // Create/update gradient segments
  const createGradientSegments = React.useCallback(
    (path: google.maps.LatLngLiteral[]) => {
      if (!map || path.length < 2) return;

      clearPolylines();

      for (let i = 0; i < path.length - 1; i++) {
        const position = i / (path.length - 1);
        const color = getGradientColor(colors, position);

        const segment = new google.maps.Polyline({
          path: [path[i]!, path[i + 1]!],
          strokeColor: color,
          strokeWeight: strokeWidth ?? 1,
          strokeOpacity: 1,
          map,
        });

        polylinesRef.current.push(segment);
      }
    },
    [map, colors, strokeWidth, clearPolylines]
  );

  // Single polyline for solid color
  const singlePolylineRef = React.useRef<google.maps.Polyline | null>(null);

  React.useEffect(() => {
    if (!map) return;

    if (!hasGradient && !singlePolylineRef.current) {
      singlePolylineRef.current = new google.maps.Polyline({
        strokeColor: colors[0],
        strokeWeight: strokeWidth ?? 1,
        strokeOpacity: 1,
        map,
      });
    }

    return () => {
      clearPolylines();
      singlePolylineRef.current?.setMap(null);
      singlePolylineRef.current = null;
    };
  }, [map, hasGradient, colors, strokeWidth, clearPolylines]);

  React.useEffect(() => {
    if (!map || coordinates.length === 0) return;

    const fullPath = coordinates.map((coord) => ({
      lat: coord.latitude,
      lng: coord.longitude,
    }));

    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current);
      animationRef.current = null;
    }

    if (!animated) {
      if (hasGradient) {
        createGradientSegments(fullPath);
      } else {
        singlePolylineRef.current?.setPath(fullPath);
      }
      return;
    }

    // Animate (snake effect with looping)
    const totalPoints = fullPath.length;
    const cycleDuration = ANIMATION_DURATION * 2;

    const animate = (currentTime: number) => {
      const elapsed = currentTime % cycleDuration;
      const progress = elapsed / ANIMATION_DURATION;

      let startIndex: number;
      let endIndex: number;

      if (progress <= 1) {
        startIndex = 0;
        endIndex = progress * totalPoints;
      } else {
        const tailProgress = progress - 1;
        startIndex = tailProgress * totalPoints;
        endIndex = totalPoints;
      }

      const startFloor = Math.floor(startIndex);
      const endFloor = Math.floor(endIndex);
      const partialPath: google.maps.LatLngLiteral[] = [];

      if (startFloor < totalPoints) {
        const startFrac = startIndex - startFloor;
        const fromPoint = fullPath[startFloor];
        const toPoint = fullPath[Math.min(startFloor + 1, totalPoints - 1)];

        if (fromPoint && toPoint && startFrac > 0) {
          partialPath.push({
            lat: fromPoint.lat + (toPoint.lat - fromPoint.lat) * startFrac,
            lng: fromPoint.lng + (toPoint.lng - fromPoint.lng) * startFrac,
          });
        } else if (fromPoint) {
          partialPath.push(fromPoint);
        }
      }

      for (
        let i = startFloor + 1;
        i <= Math.min(endFloor, totalPoints - 1);
        i++
      ) {
        const point = fullPath[i];
        if (point) partialPath.push(point);
      }

      if (endFloor < totalPoints - 1) {
        const endFrac = endIndex - endFloor;
        const fromPoint = fullPath[endFloor];
        const toPoint = fullPath[endFloor + 1];

        if (fromPoint && toPoint && endFrac > 0) {
          partialPath.push({
            lat: fromPoint.lat + (toPoint.lat - fromPoint.lat) * endFrac,
            lng: fromPoint.lng + (toPoint.lng - fromPoint.lng) * endFrac,
          });
        }
      }

      if (hasGradient) {
        createGradientSegments(partialPath);
      } else {
        singlePolylineRef.current?.setPath(partialPath);
      }

      animationRef.current = requestAnimationFrame(animate);
    };

    animationRef.current = requestAnimationFrame(animate);

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
        animationRef.current = null;
      }
    };
  }, [coordinates, animated, hasGradient, createGradientSegments, map]);

  return null;
}

export class Polyline extends React.Component<PolylineProps> {
  render() {
    return <PolylineImpl {...this.props} />;
  }
}
