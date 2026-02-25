import { useCallback } from 'react';
import { AdvancedMarker } from '@vis.gl/react-google-maps';
import { useMapContext } from '../MapProvider.web';
import type { MarkerProps } from './Marker';

const toWebAnchor = (value: number) => `-${value * 100}%`;

export function Marker({
  coordinate,
  title,
  anchor,
  zIndex,
  rotate,
  scale,
  onPress,
  children,
}: MarkerProps) {
  const { moveCamera } = useMapContext();
  const transforms: string[] = [];
  if (rotate) transforms.push(`rotate(${rotate}deg)`);
  if (scale && scale !== 1) transforms.push(`scale(${scale})`);

  const handleClick = useCallback(
    (e: google.maps.MapMouseEvent) => {
      moveCamera(coordinate);

      if (!onPress) return;
      const latLng = e.latLng;
      const domEvent = e.domEvent as MouseEvent;
      onPress({
        nativeEvent: {
          coordinate: {
            latitude: latLng?.lat() ?? coordinate.latitude,
            longitude: latLng?.lng() ?? coordinate.longitude,
          },
          point: {
            x: domEvent?.clientX ?? 0,
            y: domEvent?.clientY ?? 0,
          },
        },
      } as any);
    },
    [moveCamera, onPress, coordinate]
  );

  return (
    <AdvancedMarker
      position={{ lat: coordinate.latitude, lng: coordinate.longitude }}
      title={title}
      zIndex={zIndex}
      anchorLeft={anchor ? toWebAnchor(anchor.x) : undefined}
      anchorTop={anchor ? toWebAnchor(anchor.y) : undefined}
      clickable
      onClick={handleClick}
      style={
        transforms.length > 0 ? { transform: transforms.join(' ') } : undefined
      }
    >
      {children}
    </AdvancedMarker>
  );
}
