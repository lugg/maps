import React from 'react';
import { Platform, StyleSheet } from 'react-native';
import LuggMapViewNativeComponent, {
  Commands,
} from './fabric/LuggMapViewNativeComponent';
import LuggMapWrapperViewNativeComponent from './fabric/LuggMapWrapperViewNativeComponent';
import type {
  MapViewProps,
  MapViewRef,
  MoveCameraOptions,
  FitCoordinatesOptions,
  SetEdgeInsetsOptions,
} from './MapView.types';
import type { Coordinate, EdgeInsets } from './types';

export class MapView
  extends React.Component<MapViewProps>
  implements MapViewRef
{
  static defaultProps: Partial<MapViewProps> = {
    provider: Platform.OS === 'ios' ? 'apple' : 'google',
    mapType: 'standard',
    initialZoom: 10,
    zoomEnabled: true,
    scrollEnabled: true,
    rotateEnabled: true,
    pitchEnabled: true,
    poiEnabled: true,
    theme: 'system',
  };

  private nativeRef = React.createRef<any>();

  moveCamera(coordinate: Coordinate, options?: MoveCameraOptions) {
    const ref = this.nativeRef.current;
    if (!ref) return;

    const { zoom = 0, duration = -1 } = options ?? {};
    Commands.moveCamera(
      ref,
      coordinate.latitude,
      coordinate.longitude,
      zoom,
      duration
    );
  }

  fitCoordinates(coordinates: Coordinate[], options?: FitCoordinatesOptions) {
    const ref = this.nativeRef.current;
    const first = coordinates[0];
    if (!ref || !first) return;

    const { padding, duration = -1 } = options ?? {};
    const { top = 0, left = 0, bottom = 0, right = 0 } = padding ?? {};

    if (coordinates.length === 1) {
      const zoom = this.props.initialZoom ?? 10;
      this.moveCamera(first, { zoom, duration });
      return;
    }

    Commands.fitCoordinates(
      ref,
      coordinates,
      top,
      left,
      bottom,
      right,
      duration
    );
  }

  setEdgeInsets(edgeInsets: EdgeInsets, options?: SetEdgeInsetsOptions) {
    const ref = this.nativeRef.current;
    if (!ref) return;

    const { top = 0, left = 0, bottom = 0, right = 0 } = edgeInsets;
    const { duration = -1 } = options ?? {};
    Commands.setEdgeInsets(ref, top, left, bottom, right, duration);
  }

  render() {
    const {
      provider,
      mapType,
      mapId,
      initialCoordinate,
      initialZoom,
      minZoom,
      maxZoom,
      zoomEnabled,
      scrollEnabled,
      rotateEnabled,
      pitchEnabled,
      edgeInsets,
      userLocationEnabled,
      userLocationButtonEnabled,
      poiEnabled,
      poiFilter,
      theme,
      insetAdjustment,
      onPress,
      onLongPress,
      onCameraMove,
      onCameraIdle,
      onReady,
      children,
      ...rest
    } = this.props;

    return (
      <LuggMapViewNativeComponent
        ref={this.nativeRef}
        {...rest}
        provider={provider}
        mapType={mapType}
        mapId={mapId}
        initialCoordinate={initialCoordinate}
        initialZoom={initialZoom}
        minZoom={minZoom}
        maxZoom={maxZoom}
        zoomEnabled={zoomEnabled}
        scrollEnabled={scrollEnabled}
        rotateEnabled={rotateEnabled}
        pitchEnabled={pitchEnabled}
        edgeInsets={edgeInsets}
        userLocationEnabled={userLocationEnabled}
        userLocationButtonEnabled={userLocationButtonEnabled}
        poiEnabled={poiEnabled}
        poiFilterMode={poiFilter?.mode}
        poiFilterCategories={poiFilter?.categories}
        theme={theme}
        insetAdjustment={insetAdjustment}
        onMapPress={onPress}
        onMapLongPress={onLongPress}
        onCameraMove={onCameraMove}
        onCameraIdle={onCameraIdle}
        onReady={onReady}
      >
        <LuggMapWrapperViewNativeComponent style={StyleSheet.absoluteFill} />
        {children}
      </LuggMapViewNativeComponent>
    );
  }
}
