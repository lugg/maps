import type { ColorValue } from 'react-native';
import type { Coordinate } from '../types';

export interface PolygonProps {
  /**
   * Array of coordinates forming the polygon boundary
   */
  coordinates: Coordinate[];
  /**
   * Array of coordinate arrays representing interior holes
   */
  holes?: Coordinate[][];
  /**
   * Stroke (outline) color
   */
  strokeColor?: ColorValue;
  /**
   * Stroke width in points
   */
  strokeWidth?: number;
  /**
   * Fill color of the polygon
   */
  fillColor?: ColorValue;
  /**
   * Z-index for layering
   */
  zIndex?: number;
  /**
   * Called when the polygon is tapped
   */
  onPress?: () => void;
}
