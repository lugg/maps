import type { ReactNode } from 'react';

/**
 * MapProvider props
 */
export interface MapProviderProps {
  /**
   * Google Maps API key
   * @platform web
   */
  apiKey?: string;
  /**
   * Map children
   */
  children: ReactNode;
}
