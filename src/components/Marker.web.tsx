import { AdvancedMarker } from '@vis.gl/react-google-maps';
import type { MarkerProps } from './Marker';

const toWebAnchor = (value: number) => `-${value * 100}%`;

export function Marker({
  coordinate,
  title,
  anchor,
  zIndex,
  rotate,
  scale,
  children,
}: MarkerProps) {
  const transforms: string[] = [];
  if (rotate) transforms.push(`rotate(${rotate}deg)`);
  if (scale && scale !== 1) transforms.push(`scale(${scale})`);

  return (
    <AdvancedMarker
      position={{ lat: coordinate.latitude, lng: coordinate.longitude }}
      title={title}
      zIndex={zIndex}
      anchorLeft={anchor ? toWebAnchor(anchor.x) : undefined}
      anchorTop={anchor ? toWebAnchor(anchor.y) : undefined}
      style={
        transforms.length > 0 ? { transform: transforms.join(' ') } : undefined
      }
    >
      {children}
    </AdvancedMarker>
  );
}
