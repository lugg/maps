export { Button } from './Button';
export { Map } from './Map';
export { MarkerIcon } from './MarkerIcon';
export { MarkerText } from './MarkerText';
export { MarkerImage } from './MarkerImage';
export { CrewMarker, type VehicleImages } from './CrewMarker';

export type MarkerData = {
  id: string;
  name: string;
  coordinate: { latitude: number; longitude: number };
  type: 'basic' | 'icon' | 'text' | 'image' | 'custom';
  title?: string;
  description?: string;
  anchor?: { x: number; y: number };
  text?: string;
  color?: string;
  imageUrl?: string;
};
