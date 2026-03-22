export { Button } from './Button';
export { ThemedText } from './ThemedText';
export { Map } from './Map';
export type { MapRef } from './Map';
export { MarkerIcon } from './MarkerIcon';
export { MarkerText } from './MarkerText';
export { MarkerImage } from './MarkerImage';
export { CrewMarker } from './CrewMarker';
export { PickupIcon } from './PickupIcon';
export { MapTypeButton } from './MapTypeButton';

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
