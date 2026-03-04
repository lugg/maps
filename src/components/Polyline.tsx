import React from 'react';
import { StyleSheet } from 'react-native';
import LuggPolylineViewNativeComponent from '../fabric/LuggPolylineViewNativeComponent';
import type { PolylineProps } from './Polyline.types';

export type {
  PolylineProps,
  PolylineEasing,
  PolylineAnimatedOptions,
} from './Polyline.types';

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
