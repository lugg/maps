import { createContext, useContext } from 'react';
import { APIProvider } from '@vis.gl/react-google-maps';
import type { MapProviderProps } from './MapProvider.types';

export const MapContext = createContext<{
  map: google.maps.Map | null;
  isDragging: boolean;
  moveCamera: (coordinate: { latitude: number; longitude: number }) => void;
}>({ map: null, isDragging: false, moveCamera: () => {} });

export const useMapContext = () => useContext(MapContext);

export const MapProvider = ({ apiKey = '', children }: MapProviderProps) => (
  <APIProvider apiKey={apiKey}>{children}</APIProvider>
);
