import React from 'react';
import { StyleSheet } from 'react-native';
import LuggTileOverlayViewNativeComponent from '../fabric/LuggTileOverlayViewNativeComponent';
import type { TileOverlayProps } from './TileOverlay.types';

export type { TileOverlayProps } from './TileOverlay.types';

export class TileOverlay extends React.PureComponent<TileOverlayProps> {
  private _cachedZIndex: number | undefined;
  private _cachedStyle: any;

  private getStyle(zIndex: number | undefined) {
    if (zIndex == null) return styles.overlay;
    if (zIndex !== this._cachedZIndex) {
      this._cachedZIndex = zIndex;
      this._cachedStyle = [{ zIndex }, styles.overlay];
    }
    return this._cachedStyle!;
  }

  render() {
    const { urlTemplate, tileSize, opacity, bounds, zIndex, onPress } =
      this.props;

    return (
      <LuggTileOverlayViewNativeComponent
        style={this.getStyle(zIndex)}
        urlTemplate={urlTemplate}
        tileSize={tileSize}
        opacity={opacity}
        bounds={bounds}
        tappable={!!onPress}
        onTileOverlayPress={onPress}
      />
    );
  }
}

const styles = StyleSheet.create({
  overlay: {
    position: 'absolute',
    pointerEvents: 'none',
  },
});
