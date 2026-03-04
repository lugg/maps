import type { MapProviderProps } from './MapProvider.types';

/**
 * Provider component for map configuration.
 * On web, wraps children with Google Maps APIProvider.
 * On native, passes children through.
 */
export const MapProvider = ({ children }: MapProviderProps) => children;
