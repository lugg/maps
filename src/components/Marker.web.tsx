import { AdvancedMarker } from '@vis.gl/react-google-maps';
import type { MarkerProps } from './Marker';

const toWebAnchor = (value: number) => `-${value * 100}%`;

export function Marker({
  coordinate,
  title,
  anchor,
  zIndex,
  rotate,
  children,
}: MarkerProps) {
  return (
    <AdvancedMarker
      position={{ lat: coordinate.latitude, lng: coordinate.longitude }}
      title={title}
      zIndex={zIndex}
      anchorLeft={anchor ? toWebAnchor(anchor.x) : undefined}
      anchorTop={anchor ? toWebAnchor(anchor.y) : undefined}
      style={rotate ? { transform: `rotate(${rotate}deg)` } : undefined}
    >
      {children}
    </AdvancedMarker>
  );
}
