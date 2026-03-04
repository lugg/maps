import React from 'react';
import { StyleSheet } from 'react-native';
import LuggPolygonViewNativeComponent from '../fabric/LuggPolygonViewNativeComponent';
import type { PolygonProps } from './Polygon.types';

export type { PolygonProps } from './Polygon.types';

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
      holes,
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
        holes={holes}
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
