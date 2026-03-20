import { useCallback, useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { CircleProps } from './Circle.types';

export const Circle = ({
  center,
  radius,
  strokeColor = '#000000',
  strokeWidth = 1,
  fillColor = 'rgba(0, 0, 0, 0.3)',
  zIndex = 0,
  onPress,
}: CircleProps) => {
  const { map } = useMapContext();
  const circleRef = useRef<google.maps.Circle | null>(null);
  const listenersRef = useRef<google.maps.MapsEventListener[]>([]);

  const handleClick = useCallback(() => {
    onPress?.();
  }, [onPress]);

  useEffect(() => {
    return () => {
      listenersRef.current.forEach((l) => l.remove());
      listenersRef.current = [];
      circleRef.current?.setMap(null);
      circleRef.current = null;
    };
  }, []);

  useEffect(() => {
    const circle = circleRef.current;
    if (!circle) return;

    listenersRef.current.forEach((l) => l.remove());
    listenersRef.current = [];

    if (onPress) {
      listenersRef.current.push(circle.addListener('click', handleClick));
    }
    circle.set('clickable', !!onPress);
  }, [onPress, handleClick]);

  useEffect(() => {
    if (!map) {
      circleRef.current?.setMap(null);
      return;
    }

    const googleCenter = { lat: center.latitude, lng: center.longitude };

    if (circleRef.current) {
      circleRef.current.setCenter(googleCenter);
      circleRef.current.setRadius(radius);
      circleRef.current.setOptions({
        strokeColor: strokeColor as string,
        strokeWeight: strokeWidth,
        fillColor: fillColor as string,
        zIndex,
      });
    } else {
      const circle = new google.maps.Circle({
        center: googleCenter,
        radius,
        strokeColor: strokeColor as string,
        strokeWeight: strokeWidth,
        strokeOpacity: 1,
        fillColor: fillColor as string,
        fillOpacity: 1,
        zIndex,
        clickable: !!onPress,
        map,
      });
      circleRef.current = circle;

      if (onPress) {
        listenersRef.current.push(circle.addListener('click', handleClick));
      }
    }
  }, [
    map,
    center,
    radius,
    strokeColor,
    strokeWidth,
    fillColor,
    zIndex,
    onPress,
    handleClick,
  ]);

  return null;
};
