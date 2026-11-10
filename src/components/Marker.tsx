import React, { isValidElement } from 'react';
import { StyleSheet } from 'react-native';
import LuggMarkerViewNativeComponent, {
  Commands,
} from '../fabric/LuggMarkerViewNativeComponent';
import LuggCalloutViewNativeComponent from '../fabric/LuggCalloutViewNativeComponent';
import type { MarkerProps, MarkerRef } from './Marker.types';
import type { Point } from '../types';
import {
  MarkerMotion,
  PathProgress,
  type NativeMarkerPath,
} from './markerPath';

export type {
  CalloutOptions,
  MarkerRef,
  MarkerProps,
  MarkerPressEvent,
  MarkerDragEvent,
  MarkerPath,
  MarkerPathProgressEvent,
} from './Marker.types';

const DEFAULT_ANCHOR: Point = { x: 0.5, y: 1 };

export class Marker
  extends React.PureComponent<MarkerProps>
  implements MarkerRef
{
  private nativeRef = React.createRef<any>();
  private motion = new MarkerMotion();
  private progress = new PathProgress();
  private nativePath?: NativeMarkerPath;

  componentDidMount() {
    this.updateProgress();
  }

  componentDidUpdate() {
    this.updateProgress();
  }

  componentWillUnmount() {
    this.progress.stop();
  }

  private updateProgress() {
    this.progress.update(
      this.nativePath,
      this.props.onPathProgress ? this.emitProgress : undefined
    );
  }

  private emitProgress = (index: number) =>
    this.props.onPathProgress?.({ nativeEvent: { index } });

  showCallout() {
    const ref = this.nativeRef.current;
    if (!ref) return;
    Commands.showCallout(ref);
  }

  hideCallout() {
    const ref = this.nativeRef.current;
    if (!ref) return;
    Commands.hideCallout(ref);
  }

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
      centerOnPress = true,
      draggable = false,
      onPress,
      onDragStart,
      onDragChange,
      onDragEnd,
      callout,
      calloutOptions,
      children,
    } = this.props;

    const calloutContent = callout
      ? isValidElement(callout)
        ? callout
        : React.createElement(callout)
      : null;
    const path = this.motion.resolve(this.props);
    this.nativePath = path;
    const calloutBubbled = calloutOptions?.bubbled ?? true;
    const calloutOffset = calloutOptions?.offset;

    return (
      <LuggMarkerViewNativeComponent
        ref={this.nativeRef}
        style={this.getStyle(zIndex)}
        name={name}
        coordinate={coordinate}
        title={title}
        description={description}
        anchor={anchor ?? DEFAULT_ANCHOR}
        rotate={rotate}
        scale={scale}
        rasterize={rasterize}
        centerOnPress={centerOnPress}
        draggable={draggable}
        pathCoordinates={path?.coordinates}
        pathTimes={path?.times}
        pathRotations={path?.rotations}
        pathStartTime={path?.startTime}
        pathLoop={path?.loop}
        onMarkerPress={onPress}
        onMarkerDragStart={onDragStart}
        onMarkerDragChange={onDragChange}
        onMarkerDragEnd={onDragEnd}
      >
        {children}
        {calloutContent && (
          <LuggCalloutViewNativeComponent
            style={calloutStyles.callout}
            bubbled={calloutBubbled}
            offset={calloutOffset}
          >
            {calloutContent}
          </LuggCalloutViewNativeComponent>
        )}
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

const calloutStyles = StyleSheet.create({
  callout: {
    position: 'absolute',
    pointerEvents: 'box-none',
  },
});
