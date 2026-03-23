import type { ReactNode } from 'react';
import type { NativeSyntheticEvent, ViewProps } from 'react-native';
import type {
  MapProvider,
  Coordinate,
  EdgeInsets,
  PressEventPayload,
} from './types';

export type MapType =
  | 'standard'
  | 'satellite'
  | 'terrain'
  | 'hybrid'
  | 'muted-standard';

export type MapTheme = 'light' | 'dark' | 'system';

export type InsetAdjustment = 'automatic' | 'never';

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

export interface PoiFilter {
  /**
   * Filter mode
   * @default 'including'
   */
  mode?: 'including' | 'excluding';
  categories: PoiCategory[];
}

/**
 * Options for moving the camera
 */
export interface MoveCameraOptions {
  zoom?: number;
  duration?: number;
}

/**
 * Options for fitting coordinates in view
 */
export interface FitCoordinatesOptions {
  padding?: EdgeInsets;
  duration?: number;
}

/**
 * Options for setting edge insets
 */
export interface SetEdgeInsetsOptions {
  duration?: number;
}

/**
 * MapView ref methods
 */
export interface MapViewRef {
  moveCamera(coordinate: Coordinate, options?: MoveCameraOptions): void;
  fitCoordinates(
    coordinates: Coordinate[],
    options?: FitCoordinatesOptions
  ): void;
  setEdgeInsets(edgeInsets: EdgeInsets, options?: SetEdgeInsetsOptions): void;
}

/**
 * Camera event payload
 */
export interface CameraEventPayload {
  coordinate: Coordinate;
  zoom: number;
  gesture: boolean;
}

export type MapCameraEvent = NativeSyntheticEvent<CameraEventPayload>;
export type MapPressEvent = NativeSyntheticEvent<PressEventPayload>;

/**
 * MapView component props
 */
export interface MapViewProps extends ViewProps {
  /**
   * Map provider to use
   * @default 'apple' on iOS, 'google' on Android
   */
  provider?: MapProvider;
  /**
   * Map type to display
   * @default 'standard'
   */
  mapType?: MapType;
  /**
   * Map style ID (Google Maps) or configuration name (Apple Maps)
   */
  mapId?: string;
  /**
   * Initial camera coordinate
   */
  initialCoordinate?: Coordinate;
  /**
   * Initial zoom level
   * @default 10
   */
  initialZoom?: number;
  /**
   * Minimum zoom level
   */
  minZoom?: number;
  /**
   * Maximum zoom level
   */
  maxZoom?: number;
  /**
   * Enable zoom gestures
   * @default true
   */
  zoomEnabled?: boolean;
  /**
   * Enable scroll/pan gestures
   * @default true
   */
  scrollEnabled?: boolean;
  /**
   * Enable rotation gestures
   * @default true
   */
  rotateEnabled?: boolean;
  /**
   * Enable pitch/tilt gestures
   * @default true
   */
  pitchEnabled?: boolean;
  /**
   * Map content edge insets
   */
  edgeInsets?: EdgeInsets;
  /**
   * Show current user location on the map.
   * Requires location permission to be granted, otherwise silently ignored.
   * @default false
   */
  userLocationEnabled?: boolean;
  /**
   * Show native my-location button when userLocationEnabled is true (Android only).
   * @default false
   * @platform android
   */
  userLocationButtonEnabled?: boolean;
  /**
   * Show points of interest on the map (Apple Maps only).
   * When false, hides all POIs regardless of poiFilter.
   * @default true
   * @platform ios
   */
  poiEnabled?: boolean;
  /**
   * Filter POI categories to show or hide (Apple Maps only).
   * Only takes effect when poiEnabled is true.
   * @platform ios
   */
  poiFilter?: PoiFilter;
  /**
   * Map color theme
   * @default 'system'
   */
  theme?: MapTheme;
  /**
   * Safe area inset adjustment behavior
   * @default 'never'
   */
  insetAdjustment?: InsetAdjustment;
  /**
   * Called when the map is pressed
   */
  onPress?: (event: MapPressEvent) => void;
  /**
   * Called when the map is long pressed
   */
  onLongPress?: (event: MapPressEvent) => void;
  /**
   * Called when camera moves
   */
  onCameraMove?: (event: MapCameraEvent) => void;
  /**
   * Called when camera stops moving
   */
  onCameraIdle?: (event: MapCameraEvent) => void;
  /**
   * Called when map is loaded and ready
   */
  onReady?: () => void;
  /**
   * Map children (markers, polylines, etc.)
   */
  children?: ReactNode;
}
