/**
 * Map provider type
 */
export type MapProvider = 'google' | 'apple';

/**
 * Geographic coordinate with latitude and longitude
 */
export interface Coordinate {
  latitude: number;
  longitude: number;
}

/**
 * 2D point representing x and y positions
 */
export interface Point {
  x: number;
  y: number;
}

/**
 * Edge insets for padding
 */
export interface EdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}

/**
 * Map type
 */
export type MapType =
  | 'standard'
  | 'satellite'
  | 'terrain'
  | 'hybrid'
  | 'muted-standard';

/**
 * Map theme
 */
export type MapTheme = 'light' | 'dark' | 'system';

/**
 * Press event payload
 */
export interface PressEventPayload {
  coordinate: Coordinate;
  point: Point;
}
