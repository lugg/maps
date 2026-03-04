import { useCallback, useEffect, useRef } from 'react';
import { AdvancedMarker } from '@vis.gl/react-google-maps';
import { useMapContext } from '../MapProvider.web';
import type { MarkerProps } from './Marker.types';

const toWebAnchor = (value: number) => `-${value * 100}%`;

const createEvent = (
  e: google.maps.MapMouseEvent,
  coordinate: MarkerProps['coordinate']
) =>
  ({
    nativeEvent: {
      coordinate: {
        latitude: e.latLng?.lat() ?? coordinate.latitude,
        longitude: e.latLng?.lng() ?? coordinate.longitude,
      },
      point: {
        x: (e.domEvent as MouseEvent)?.clientX ?? 0,
        y: (e.domEvent as MouseEvent)?.clientY ?? 0,
      },
    },
  } as any);

export const Marker = ({
  coordinate,
  title,
  anchor,
  zIndex,
  rotate,
  scale,
  draggable,
  onPress,
  onDragStart,
  onDragChange,
  onDragEnd,
  children,
}: MarkerProps) => {
  const { moveCamera } = useMapContext();
  const dragPositionRef = useRef<google.maps.LatLngLiteral | null>(null);

  const transforms: string[] = [];
  if (rotate) transforms.push(`rotate(${rotate}deg)`);
  if (scale && scale !== 1) transforms.push(`scale(${scale})`);

  const handleClick = useCallback(
    (e: google.maps.MapMouseEvent) => {
      const pos = dragPositionRef.current;
      const coord = pos
        ? { latitude: pos.lat, longitude: pos.lng }
        : coordinate;
      moveCamera(coord);
      onPress?.(createEvent(e, coordinate));
    },
    [moveCamera, onPress, coordinate]
  );

  const handleDragStart = useCallback(
    (e: google.maps.MapMouseEvent) => {
      const latLng = e.latLng;
      if (latLng) {
        dragPositionRef.current = { lat: latLng.lat(), lng: latLng.lng() };
      }
      onDragStart?.(createEvent(e, coordinate));
    },
    [onDragStart, coordinate]
  );

  const handleDrag = useCallback(
    (e: google.maps.MapMouseEvent) => {
      const latLng = e.latLng;
      if (latLng) {
        dragPositionRef.current = { lat: latLng.lat(), lng: latLng.lng() };
      }
      onDragChange?.(createEvent(e, coordinate));
    },
    [onDragChange, coordinate]
  );

  const handleDragEnd = useCallback(
    (e: google.maps.MapMouseEvent) => {
      const latLng = e.latLng;
      if (latLng) {
        dragPositionRef.current = { lat: latLng.lat(), lng: latLng.lng() };
      }
      onDragEnd?.(createEvent(e, coordinate));
    },
    [onDragEnd, coordinate]
  );

  useEffect(() => {
    dragPositionRef.current = null;
  }, [coordinate.latitude, coordinate.longitude]);

  const position = dragPositionRef.current ?? {
    lat: coordinate.latitude,
    lng: coordinate.longitude,
  };

  return (
    <AdvancedMarker
      position={position}
      title={title}
      zIndex={zIndex}
      anchorLeft={anchor ? toWebAnchor(anchor.x) : undefined}
      anchorTop={anchor ? toWebAnchor(anchor.y) : undefined}
      clickable
      draggable={draggable}
      onClick={handleClick}
      onDragStart={handleDragStart}
      onDrag={handleDrag}
      onDragEnd={handleDragEnd}
      style={
        transforms.length > 0 ? { transform: transforms.join(' ') } : undefined
      }
    >
      {children}
    </AdvancedMarker>
  );
};
