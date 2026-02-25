import React from 'react';
import type { ColorValue } from 'react-native';
import { StyleSheet } from 'react-native';
import LuggPolygonViewNativeComponent from '../fabric/LuggPolygonViewNativeComponent';
import type { Coordinate } from '../types';

export interface PolygonProps {
  /**
   * Array of coordinates forming the polygon boundary
   */
  coordinates: Coordinate[];
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

export class Polygon extends React.PureComponent<PolygonProps> {
  private _cachedZIndex: number | undefined;
  private _cachedStyle: any;

  private getStyle(zIndex: number | undefined) {
    if (zIndex == null) return styles.polygon;
    if (zIndex !== this._cachedZIndex) {
      this._cachedZIndex = zIndex;
      this._cachedStyle = [{ zIndex }, styles.polygon];
    }
    return this._cachedStyle!;
  }

  render() {
    const {
      coordinates,
      strokeColor,
      strokeWidth,
      fillColor,
      zIndex,
      onPress,
    } = this.props;

    return (
      <LuggPolygonViewNativeComponent
        style={this.getStyle(zIndex)}
        coordinates={coordinates}
        strokeColor={strokeColor}
        strokeWidth={strokeWidth}
        fillColor={fillColor}
        tappable={!!onPress}
        onPolygonPress={onPress}
      />
    );
  }
}

const styles = StyleSheet.create({
  polygon: {
    position: 'absolute',
    pointerEvents: 'none',
  },
});
