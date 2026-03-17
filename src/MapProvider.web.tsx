import { createContext, useContext } from 'react';
import { APIProvider } from '@vis.gl/react-google-maps';
import type { MapProviderProps } from './MapProvider.types';

type CalloutCloseListener = () => void;

export const MapContext = createContext<{
  map: google.maps.Map | null;
  isDragging: boolean;
  moveCamera: (coordinate: { latitude: number; longitude: number }) => void;
  onCalloutClose: (listener: CalloutCloseListener) => () => void;
  closeCallouts: (except?: CalloutCloseListener) => void;
}>({
  map: null,
  isDragging: false,
  moveCamera: () => {},
  onCalloutClose: () => () => {},
  closeCallouts: () => {},
});

export const useMapContext = () => useContext(MapContext);

export const MapProvider = ({ apiKey = '', children }: MapProviderProps) => (
  <APIProvider apiKey={apiKey}>{children}</APIProvider>
);
