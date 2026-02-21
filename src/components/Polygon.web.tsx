import { useCallback, useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { PolygonProps } from './Polygon';

export function Polygon({
  coordinates,
  strokeColor = '#000000',
  strokeWidth = 1,
  fillColor = 'rgba(0, 0, 0, 0.3)',
  zIndex = 0,
  onPress,
}: PolygonProps) {
  const { map } = useMapContext();
  const polygonRef = useRef<google.maps.Polygon | null>(null);
  const listenerRef = useRef<google.maps.MapsEventListener | null>(null);

  const handleClick = useCallback(() => {
    onPress?.();
  }, [onPress]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      listenerRef.current?.remove();
      listenerRef.current = null;
      polygonRef.current?.setMap(null);
      polygonRef.current = null;
    };
  }, []);

  // Sync click listener
  useEffect(() => {
    const polygon = polygonRef.current;
    if (!polygon) return;

    listenerRef.current?.remove();
    listenerRef.current = onPress
      ? polygon.addListener('click', handleClick)
      : null;
    polygon.set('clickable', !!onPress);
  }, [onPress, handleClick]);

  // Sync polygon with props
  useEffect(() => {
    if (!map || coordinates.length === 0) {
      polygonRef.current?.setMap(null);
      return;
    }

    const path = coordinates.map((c) => ({
      lat: c.latitude,
      lng: c.longitude,
    }));

    if (polygonRef.current) {
      polygonRef.current.setPath(path);
      polygonRef.current.setOptions({
        strokeColor: strokeColor as string,
        strokeWeight: strokeWidth,
        fillColor: fillColor as string,
        zIndex,
      });
    } else {
      const polygon = new google.maps.Polygon({
        paths: path,
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
        listenerRef.current = polygon.addListener('click', handleClick);
      }
    }
  }, [
    map,
    coordinates,
    strokeColor,
    strokeWidth,
    fillColor,
    zIndex,
    onPress,
    handleClick,
  ]);

  return null;
}
