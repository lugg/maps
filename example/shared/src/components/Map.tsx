import { forwardRef } from 'react';
import { StyleSheet, View } from 'react-native';
import { MapView, Marker, type MapViewProps } from '@lugg/maps';

import { MarkerIcon } from './MarkerIcon';
import { MarkerText } from './MarkerText';
import { MarkerImage } from './MarkerImage';
import type { MarkerData } from './index';
import { Route } from './Route';

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
          anchor={anchor}
        />
      );
  }
};

export const Map = forwardRef<MapView, MapProps>(
  ({ markers, ...props }, ref) => {
    const polylineCoordinates = markers.map((m) => m.coordinate);

    return (
      <MapView
        ref={ref}
        style={styles.map}
        mapId="6939261d95ee48fd57332474"
        initialCoordinate={{ latitude: 37.78, longitude: -122.43 }}
        initialZoom={14}
        {...props}
      >
        {markers.map(renderMarker)}
        <Route markerCoordinates={polylineCoordinates} />
        <Marker
          name="inline-marker"
          coordinate={{ latitude: 37.782, longitude: -122.425 }}
        >
          <View style={styles.customMarker} />
        </Marker>
        <View style={styles.centerPin} />
      </MapView>
    );
  }
);

const styles = StyleSheet.create({
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
