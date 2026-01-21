import React from 'react';
import { Platform, StyleSheet } from 'react-native';
import LuggGoogleMapViewNativeComponent, {
  Commands as GoogleMapCommands,
} from './fabric/LuggGoogleMapViewNativeComponent';
import LuggAppleMapViewNativeComponent, {
  Commands as AppleMapCommands,
} from './fabric/LuggAppleMapViewNativeComponent';
import LuggMapWrapperViewNativeComponent from './fabric/LuggMapWrapperViewNativeComponent';
import type {
  MapViewProps,
  MapViewRef,
  MoveCameraOptions,
  FitCoordinatesOptions,
} from './MapView.types';
import type { Coordinate } from './types';

export class MapView
  extends React.Component<MapViewProps>
  implements MapViewRef
{
  static defaultProps: Partial<MapViewProps> = {
    provider: Platform.OS === 'ios' ? 'apple' : 'google',
    initialZoom: 10,
    zoomEnabled: true,
    scrollEnabled: true,
    rotateEnabled: true,
    pitchEnabled: true,
  };

  private nativeRef = React.createRef<any>();

  private get nativeCommands() {
    const provider = this.props.provider ?? MapView.defaultProps.provider;
    const isApple = Platform.OS === 'ios' && provider === 'apple';
    return isApple ? AppleMapCommands : GoogleMapCommands;
  }

  moveCamera(coordinate: Coordinate, options: MoveCameraOptions) {
    const ref = this.nativeRef.current;
    if (!ref) return;

    const { zoom, duration = -1 } = options;
    this.nativeCommands.moveCamera(
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

    const { padding = 0, duration = -1 } = options ?? {};

    if (coordinates.length === 1) {
      const zoom = this.props.initialZoom ?? 10;
      this.moveCamera(first, { zoom, duration });
      return;
    }

    this.nativeCommands.fitCoordinates(ref, coordinates, padding, duration);
  }

  render() {
    const {
      provider,
      mapId,
      initialCoordinate,
      initialZoom,
      minZoom,
      maxZoom,
      zoomEnabled,
      scrollEnabled,
      rotateEnabled,
      pitchEnabled,
      padding,
      userLocationEnabled,
      onCameraMove,
      onCameraIdle,
      onReady,
      children,
      ...rest
    } = this.props;

    const NativeMapView =
      Platform.OS === 'ios' && provider === 'apple'
        ? LuggAppleMapViewNativeComponent
        : LuggGoogleMapViewNativeComponent;

    return (
      <NativeMapView
        ref={this.nativeRef}
        {...rest}
        mapId={mapId}
        initialCoordinate={initialCoordinate}
        initialZoom={initialZoom}
        minZoom={minZoom}
        maxZoom={maxZoom}
        zoomEnabled={zoomEnabled}
        scrollEnabled={scrollEnabled}
        rotateEnabled={rotateEnabled}
        pitchEnabled={pitchEnabled}
        padding={padding}
        userLocationEnabled={userLocationEnabled}
        onCameraMove={onCameraMove}
        onCameraIdle={onCameraIdle}
        onReady={onReady}
      >
        <LuggMapWrapperViewNativeComponent style={StyleSheet.absoluteFill} />
        {children}
      </NativeMapView>
    );
  }
}
