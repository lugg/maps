import React from 'react';
import type { ColorValue } from 'react-native';
import { StyleSheet } from 'react-native';
import LuggPolylineViewNativeComponent from '../fabric/LuggPolylineViewNativeComponent';
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

export class Polyline extends React.PureComponent<PolylineProps> {
  private getStyle(zIndex: number | undefined) {
    if (zIndex == null) return styles.polyline;
    if (zIndex !== this._cachedZIndex) {
      this._cachedZIndex = zIndex;
      this._cachedStyle = [{ zIndex }, styles.polyline];
    }
    return this._cachedStyle!;
  }

  private _cachedZIndex: number | undefined;
  private _cachedStyle: any;

  render() {
    const {
      coordinates,
      strokeColors,
      strokeWidth,
      animated = false,
      animatedOptions,
      zIndex,
    } = this.props;

    return (
      <LuggPolylineViewNativeComponent
        style={this.getStyle(zIndex)}
        coordinates={coordinates}
        strokeColors={strokeColors}
        strokeWidth={strokeWidth}
        animated={animated}
        animatedOptions={animatedOptions}
      />
    );
  }
}

const styles = StyleSheet.create({
  polyline: {
    position: 'absolute',
    pointerEvents: 'none',
  },
});
