import type { ReactNode } from 'react';
import type { NativeSyntheticEvent, ViewProps } from 'react-native';
import type { MapProvider, Coordinate, EdgeInsets } from './types';

/**
 * Options for moving the camera
 * @default duration -1
 */
export interface MoveCameraOptions {
  zoom?: number;
  duration?: number;
}

/**
 * Options for fitting coordinates in view
 * @default duration -1
 */
export interface FitCoordinatesOptions {
  padding?: EdgeInsets;
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
}

/**
 * Camera event payload
 */
export interface CameraEventPayload {
  coordinate: Coordinate;
  zoom: number;
  gesture: boolean;
}

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
   * Map content padding
   */
  padding?: EdgeInsets;
  /**
   * Show current user location on the map.
   * Requires location permission to be granted, otherwise silently ignored.
   * @default false
   */
  userLocationEnabled?: boolean;
  /**
   * Called when camera moves
   */
  onCameraMove?: (event: NativeSyntheticEvent<CameraEventPayload>) => void;
  /**
   * Called when camera stops moving
   */
  onCameraIdle?: (event: NativeSyntheticEvent<CameraEventPayload>) => void;
  /**
   * Called when map is loaded and ready
   */
  onReady?: () => void;
  /**
   * Map children (markers, polylines, etc.)
   */
  children?: ReactNode;
}
