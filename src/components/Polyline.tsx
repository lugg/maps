import React from 'react';
import type { ColorValue } from 'react-native';
import { StyleSheet } from 'react-native';
import LuggPolylineViewNativeComponent from '../fabric/LuggPolylineViewNativeComponent';
import type { Coordinate } from '../types';

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
   * Z-index for layering polylines
   */
  zIndex?: number;
}

export class Polyline extends React.Component<PolylineProps> {
  render() {
    const {
      coordinates,
      strokeColors,
      strokeWidth,
      animated = false,
      zIndex,
    } = this.props;

    return (
      <LuggPolylineViewNativeComponent
        style={[{ zIndex }, styles.polyline]}
        coordinates={coordinates}
        strokeColors={strokeColors}
        strokeWidth={strokeWidth}
        animated={animated}
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
