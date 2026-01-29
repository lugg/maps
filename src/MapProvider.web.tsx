import { createContext, useContext } from 'react';
import { APIProvider } from '@vis.gl/react-google-maps';
import type { MapProviderProps } from './MapProvider.types';

export const MapContext = createContext<{
  map: google.maps.Map | null;
  isDragging: boolean;
}>({ map: null, isDragging: false });

export const useMapContext = () => useContext(MapContext);

export function MapProvider({ apiKey = '', children }: MapProviderProps) {
  return <APIProvider apiKey={apiKey}>{children}</APIProvider>;
}
