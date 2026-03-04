import type { ColorValue } from 'react-native';
import type { Coordinate } from '../types';

export type PolylineEasing = 'linear' | 'easeIn' | 'easeOut' | 'easeInOut';

export interface PolylineAnimatedOptions {
  /**
   * Animation duration in milliseconds
   * @default 2150
   */
  duration?: number;
  /**
   * Easing function for the animation
   * @default 'linear'
   */
  easing?: PolylineEasing;
  /**
   * Portion of the line visible as trail (0-1)
   * 1.0 = full snake effect, 0.2 = short worm
   * @default 1.0
   */
  trailLength?: number;
  /**
   * Delay before animation starts in milliseconds
   * @default 0
   */
  delay?: number;
}

export interface PolylineProps {
  /**
   * Array of coordinates forming the polyline
   */
  coordinates: Coordinate[];
  /**
   * Gradient colors along the polyline
   */
  strokeColors?: ColorValue[];
  /**
   * Line width in points
   */
  strokeWidth?: number;
  /**
   * Animate the polyline with a snake effect
   */
  animated?: boolean;
  /**
   * Animation configuration options
   */
  animatedOptions?: PolylineAnimatedOptions;
  /**
   * Z-index for layering polylines
   */
  zIndex?: number;
}
