import React from 'react';
import type { ReactNode } from 'react';
import { StyleSheet, type NativeSyntheticEvent } from 'react-native';
import LuggMarkerViewNativeComponent from '../fabric/LuggMarkerViewNativeComponent';
import type { Coordinate, Point, PressEventPayload } from '../types';

export type MarkerPressEvent = NativeSyntheticEvent<PressEventPayload>;

export interface MarkerProps {
  /**
   * Name used for debugging purposes
   */
  name?: string;
  /**
   * Marker position
   */
  coordinate: Coordinate;
  /**
   * Callout title
   */
  title?: string;
  /**
   * Callout description
   */
  description?: string;
  /**
   * Anchor point for custom marker views
   */
  anchor?: Point;
  /**
   * Z-index for marker ordering. Higher values render on top.
   */
  zIndex?: number;
  /**
   * Rotation angle in degrees clockwise from north.
   * @default 0
   */
  rotate?: number;
  /**
   * Scale factor for the marker.
   * @default 1
   */
  scale?: number;
  /**
   * Rasterize custom marker view to bitmap for better performance.
   * Set to false if you need live view updates (e.g., animations).
   * @platform ios, android
   * @default true
   */
  rasterize?: boolean;
  /**
   * Called when the marker is pressed
   */
  onPress?: (event: MarkerPressEvent) => void;
  /**
   * Custom marker view
   */
  children?: ReactNode;
}

export class Marker extends React.PureComponent<MarkerProps> {
  private getStyle(zIndex: number | undefined) {
    if (zIndex == null) return styles.marker;
    if (zIndex !== this._cachedZIndex) {
      this._cachedZIndex = zIndex;
      this._cachedStyle = [{ zIndex }, styles.marker];
    }
    return this._cachedStyle!;
  }

  private _cachedZIndex: number | undefined;
  private _cachedStyle: any;

  render() {
    const {
      name,
      coordinate,
      title,
      description,
      anchor,
      zIndex,
      rotate = 0,
      scale = 1,
      rasterize = true,
      onPress,
      children,
    } = this.props;

    return (
      <LuggMarkerViewNativeComponent
        style={this.getStyle(zIndex)}
        name={name}
        coordinate={coordinate}
        title={title}
        description={description}
        anchor={anchor}
        rotate={rotate}
        scale={scale}
        rasterize={rasterize}
        onMarkerPress={onPress}
      >
        {children}
      </LuggMarkerViewNativeComponent>
    );
  }
}

const styles = StyleSheet.create({
  marker: {
    position: 'absolute',
    pointerEvents: 'box-none',
  },
});
