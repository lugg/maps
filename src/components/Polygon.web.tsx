import { useCallback, useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { PolygonProps } from './Polygon';

export function Polygon({
  coordinates,
  holes,
  strokeColor = '#000000',
  strokeWidth = 1,
  fillColor = 'rgba(0, 0, 0, 0.3)',
  zIndex = 0,
  onPress,
}: PolygonProps) {
  const { map } = useMapContext();
  const polygonRef = useRef<google.maps.Polygon | null>(null);
  const listenersRef = useRef<google.maps.MapsEventListener[]>([]);

  const handleClick = useCallback(() => {
    onPress?.();
  }, [onPress]);

  const applyHighlight = useCallback(() => {
    const polygon = polygonRef.current;
    if (!polygon) return;
    polygon.setOptions({
      fillOpacity: 0.5,
      strokeOpacity: 0.5,
    });
  }, []);

  const restoreHighlight = useCallback(() => {
    const polygon = polygonRef.current;
    if (!polygon) return;
    polygon.setOptions({
      fillOpacity: 1,
      strokeOpacity: 1,
    });
  }, []);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      listenersRef.current.forEach((l) => l.remove());
      listenersRef.current = [];
      polygonRef.current?.setMap(null);
      polygonRef.current = null;
    };
  }, []);

  // Sync listeners
  useEffect(() => {
    const polygon = polygonRef.current;
    if (!polygon) return;

    listenersRef.current.forEach((l) => l.remove());
    listenersRef.current = [];

    if (onPress) {
      listenersRef.current.push(
        polygon.addListener('click', handleClick),
        polygon.addListener('mousedown', applyHighlight),
        polygon.addListener('mouseup', restoreHighlight),
        polygon.addListener('mouseout', restoreHighlight)
      );
    }
    polygon.set('clickable', !!onPress);
  }, [onPress, handleClick, applyHighlight, restoreHighlight]);

  // Sync polygon with props
  useEffect(() => {
    if (!map || coordinates.length === 0) {
      polygonRef.current?.setMap(null);
      return;
    }

    const outerPath = coordinates.map((c) => ({
      lat: c.latitude,
      lng: c.longitude,
    }));

    const paths = [
      outerPath,
      ...(holes ?? []).map((hole) =>
        [...hole].reverse().map((c) => ({ lat: c.latitude, lng: c.longitude }))
      ),
    ];

    if (polygonRef.current) {
      polygonRef.current.setPaths(paths);
      polygonRef.current.setOptions({
        strokeColor: strokeColor as string,
        strokeWeight: strokeWidth,
        fillColor: fillColor as string,
        zIndex,
      });
    } else {
      const polygon = new google.maps.Polygon({
        paths,
        strokeColor: strokeColor as string,
        strokeWeight: strokeWidth,
        strokeOpacity: 1,
        fillColor: fillColor as string,
        fillOpacity: 1,
        zIndex,
        clickable: !!onPress,
        map,
      });
      polygonRef.current = polygon;

      if (onPress) {
        listenersRef.current.push(
          polygon.addListener('click', handleClick),
          polygon.addListener('mousedown', applyHighlight),
          polygon.addListener('mouseup', restoreHighlight),
          polygon.addListener('mouseout', restoreHighlight)
        );
      }
    }
  }, [
    map,
    coordinates,
    holes,
    strokeColor,
    strokeWidth,
    fillColor,
    zIndex,
    onPress,
    handleClick,
    applyHighlight,
    restoreHighlight,
  ]);

  return null;
}
