import { useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { PolygonProps } from './Polygon';

export function Polygon({
  coordinates,
  strokeColor = '#000000',
  strokeWidth = 1,
  fillColor = 'rgba(0, 0, 0, 0.3)',
  zIndex = 0,
}: PolygonProps) {
  const { map } = useMapContext();
  const polygonRef = useRef<google.maps.Polygon | null>(null);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      polygonRef.current?.setMap(null);
      polygonRef.current = null;
    };
  }, []);

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
      polygonRef.current = new google.maps.Polygon({
        paths: path,
        strokeColor: strokeColor as string,
        strokeWeight: strokeWidth,
        strokeOpacity: 1,
        fillColor: fillColor as string,
        fillOpacity: 1,
        zIndex,
        map,
      });
    }
  }, [map, coordinates, strokeColor, strokeWidth, fillColor, zIndex]);

  return null;
}
