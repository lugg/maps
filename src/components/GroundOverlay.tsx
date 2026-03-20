import React from 'react';
import { Image, StyleSheet } from 'react-native';
import LuggGroundOverlayViewNativeComponent from '../fabric/LuggGroundOverlayViewNativeComponent';
import type { GroundOverlayProps } from './GroundOverlay.types';

export type {
  GroundOverlayProps,
  GroundOverlayBounds,
} from './GroundOverlay.types';

export class GroundOverlay extends React.PureComponent<GroundOverlayProps> {
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
    const { image, bounds, opacity, bearing, zIndex, onPress } = this.props;
    const resolved = Image.resolveAssetSource(image);

    return (
      <LuggGroundOverlayViewNativeComponent
        style={this.getStyle(zIndex)}
        image={resolved?.uri ?? ''}
        bounds={bounds}
        opacity={opacity}
        bearing={bearing}
        tappable={!!onPress}
        onGroundOverlayPress={onPress}
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
