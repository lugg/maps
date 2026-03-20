import type { ImageSourcePropType } from 'react-native';
import type { Coordinate } from '../types';

export interface GroundOverlayBounds {
  northeast: Coordinate;
  southwest: Coordinate;
}

export interface GroundOverlayProps {
  /**
   * Image to overlay on the map
   */
  image: ImageSourcePropType;
  /**
   * Geographic bounds for the overlay
   */
  bounds: GroundOverlayBounds;
  /**
   * Opacity of the overlay (0-1)
   */
  opacity?: number;
  /**
   * Bearing (rotation) in degrees clockwise from north.
   * Only supported on Google Maps.
   * @platform google
   */
  bearing?: number;
  /**
   * Z-index for layering
   */
  zIndex?: number;
  /**
   * Called when the overlay is tapped
   */
  onPress?: () => void;
}
