import type { ColorValue } from 'react-native';
import type { Coordinate } from '../types';

export interface CircleProps {
  /**
   * Center coordinate of the circle
   */
  center: Coordinate;
  /**
   * Radius in meters
   */
  radius: number;
  /**
   * Stroke (outline) color
   */
  strokeColor?: ColorValue;
  /**
   * Stroke width in points
   */
  strokeWidth?: number;
  /**
   * Fill color of the circle
   */
  fillColor?: ColorValue;
  /**
   * Z-index for layering
   */
  zIndex?: number;
  /**
   * Called when the circle is tapped
   */
  onPress?: () => void;
}
