import { APIProvider } from '@vis.gl/react-google-maps';
import type { MapProviderProps } from './MapProvider.types';

export function MapProvider({ apiKey = '', children }: MapProviderProps) {
  return <APIProvider apiKey={apiKey}>{children}</APIProvider>;
}
