import { createContext, useContext } from 'react';
import { APIProvider } from '@vis.gl/react-google-maps';
import type { MapProviderProps } from './MapProvider.types';

export const MapIdContext = createContext<string | null>(null);

export const useMapId = () => useContext(MapIdContext);

export function MapProvider({ apiKey = '', children }: MapProviderProps) {
  return <APIProvider apiKey={apiKey}>{children}</APIProvider>;
}
