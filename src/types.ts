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
 * Point of interest category (Apple Maps)
 */
export type PoiCategory =
  | 'airport'
  | 'amusement-park'
  | 'aquarium'
  | 'atm'
  | 'bakery'
  | 'bank'
  | 'beach'
  | 'brewery'
  | 'cafe'
  | 'campground'
  | 'car-rental'
  | 'ev-charger'
  | 'fire-station'
  | 'fitness-center'
  | 'food-market'
  | 'gas-station'
  | 'hospital'
  | 'hotel'
  | 'laundry'
  | 'library'
  | 'marina'
  | 'movie-theater'
  | 'museum'
  | 'national-park'
  | 'nightlife'
  | 'park'
  | 'parking'
  | 'pharmacy'
  | 'police'
  | 'post-office'
  | 'public-transport'
  | 'restaurant'
  | 'restroom'
  | 'school'
  | 'stadium'
  | 'store'
  | 'theater'
  | 'university'
  | 'winery'
  | 'zoo';

/**
 * Point of interest filter
 */
export interface PoiFilter {
  /**
   * Filter mode
   * @default 'including'
   */
  mode?: 'including' | 'excluding';
  /**
   * POI categories to include or exclude
   */
  categories: PoiCategory[];
}

/**
 * Press event payload
 */
export interface PressEventPayload {
  coordinate: Coordinate;
  point: Point;
}
