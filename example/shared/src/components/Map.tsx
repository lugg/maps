import { forwardRef, useMemo, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import {
  MapView,
  Marker,
  type MapViewProps,
  type CameraEventPayload,
} from '@lugg/maps';
import type { NativeSyntheticEvent } from 'react-native';

import { MarkerIcon } from './MarkerIcon';
import { MarkerText } from './MarkerText';
import { MarkerImage } from './MarkerImage';
import { CrewMarker } from './CrewMarker';
import type { MarkerData } from './index';
import { Route, smoothCoordinates } from './Route';

interface MapProps extends MapViewProps {
  markers: MarkerData[];
}

const renderMarker = (marker: MarkerData) => {
  const {
    id,
    name,
    coordinate,
    type,
    anchor,
    title,
    description,
    text,
    color,
    imageUrl,
  } = marker;

  switch (type) {
    case 'icon':
      return <MarkerIcon key={id} name={name} coordinate={coordinate} />;
    case 'text':
      return (
        <MarkerText
          key={id}
          name={name}
          coordinate={coordinate}
          text={text ?? 'X'}
          color={color}
        />
      );
    case 'image':
      return (
        <MarkerImage
          key={id}
          name={name}
          coordinate={coordinate}
          source={{ uri: imageUrl }}
        />
      );
    case 'custom':
      return (
        <Marker key={id} name={name} coordinate={coordinate} anchor={anchor}>
          <View style={[styles.customMarker, { backgroundColor: color }]} />
        </Marker>
      );
    default:
      return (
        <Marker
          key={id}
          name={name}
          coordinate={coordinate}
          title={title}
          description={description}
        />
      );
  }
};

const INITIAL_ZOOM = 14;

export const Map = forwardRef<MapView, MapProps>(
  ({ markers, padding, onCameraIdle, onCameraMove, ...props }, ref) => {
    const [zoom, setZoom] = useState(INITIAL_ZOOM);
    const polylineCoordinates = useMemo(
      () => markers.map((m) => m.coordinate),
      [markers]
    );
    const smoothedRoute = useMemo(
      () => smoothCoordinates(polylineCoordinates),
      [polylineCoordinates]
    );
    const bottomOffset = padding?.bottom ?? 0;

    const handleCameraMove = (e: NativeSyntheticEvent<CameraEventPayload>) => {
      onCameraMove?.(e);
    };

    const handleCameraIdle = (e: NativeSyntheticEvent<CameraEventPayload>) => {
      setZoom(e.nativeEvent.zoom);
      onCameraIdle?.(e);
    };

    return (
      <View style={styles.container}>
        <MapView
          ref={ref}
          style={StyleSheet.absoluteFill}
          mapId="6939261d95ee48fd57332474"
          initialCoordinate={{ latitude: 37.78, longitude: -122.43 }}
          initialZoom={INITIAL_ZOOM}
          padding={padding}
          onCameraMove={handleCameraMove}
          onCameraIdle={handleCameraIdle}
          {...props}
        >
          {markers.map(renderMarker)}
          <Route coordinates={smoothedRoute} />
          <CrewMarker route={smoothedRoute} zoom={zoom} />
          <MarkerText
            name="inline-marker"
            coordinate={{ latitude: 37.782, longitude: -122.425 }}
            text="LO"
            color="#34A853"
          />
        </MapView>
        <View
          style={[
            styles.centerPin,
            { transform: [{ translateY: -bottomOffset / 2 }] },
          ]}
        />
      </View>
    );
  }
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  map: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  centerPin: {
    backgroundColor: 'blue',
    height: 20,
    width: 20,
    borderRadius: 10,
  },
  customMarker: {
    backgroundColor: 'gray',
    height: 30,
    width: 30,
    borderRadius: 15,
  },
});
