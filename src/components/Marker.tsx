import React from 'react';
import type { ReactNode } from 'react';
import { StyleSheet } from 'react-native';
import LuggMarkerViewNativeComponent from '../fabric/LuggMarkerViewNativeComponent';
import type { Coordinate, Point } from '../types';

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
   * Rasterize custom marker view to bitmap for better performance.
   * Set to false if you need live view updates (e.g., animations).
   * @default true
   */
  rasterize?: boolean;
  /**
   * Custom marker view
   */
  children?: ReactNode;
}

export class Marker extends React.Component<MarkerProps> {
  render() {
    const {
      name,
      coordinate,
      title,
      description,
      anchor,
      zIndex,
      rasterize = true,
      children,
    } = this.props;

    return (
      <LuggMarkerViewNativeComponent
        style={[{ zIndex }, styles.marker]}
        name={name}
        coordinate={coordinate}
        title={title}
        description={description}
        anchor={anchor}
        rasterize={rasterize}
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
