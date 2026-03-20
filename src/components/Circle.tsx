import React from 'react';
import { StyleSheet } from 'react-native';
import LuggCircleViewNativeComponent from '../fabric/LuggCircleViewNativeComponent';
import type { CircleProps } from './Circle.types';

export type { CircleProps } from './Circle.types';

export class Circle extends React.PureComponent<CircleProps> {
  private _cachedZIndex: number | undefined;
  private _cachedStyle: any;

  private getStyle(zIndex: number | undefined) {
    if (zIndex == null) return styles.circle;
    if (zIndex !== this._cachedZIndex) {
      this._cachedZIndex = zIndex;
      this._cachedStyle = [{ zIndex }, styles.circle];
    }
    return this._cachedStyle!;
  }

  render() {
    const { center, radius, strokeColor, strokeWidth, fillColor, zIndex, onPress } =
      this.props;

    return (
      <LuggCircleViewNativeComponent
        style={this.getStyle(zIndex)}
        center={center}
        radius={radius}
        strokeColor={strokeColor}
        strokeWidth={strokeWidth}
        fillColor={fillColor}
        tappable={!!onPress}
        onCirclePress={onPress}
      />
    );
  }
}

const styles = StyleSheet.create({
  circle: {
    position: 'absolute',
    pointerEvents: 'none',
  },
});
