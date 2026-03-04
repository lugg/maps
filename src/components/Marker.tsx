import React from 'react';
import { StyleSheet } from 'react-native';
import LuggMarkerViewNativeComponent from '../fabric/LuggMarkerViewNativeComponent';
import type { MarkerProps } from './Marker.types';

export type {
  MarkerProps,
  MarkerPressEvent,
  MarkerDragEvent,
} from './Marker.types';

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
      draggable = false,
      onPress,
      onDragStart,
      onDragChange,
      onDragEnd,
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
        draggable={draggable}
        onMarkerPress={onPress}
        onMarkerDragStart={onDragStart}
        onMarkerDragChange={onDragChange}
        onMarkerDragEnd={onDragEnd}
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
