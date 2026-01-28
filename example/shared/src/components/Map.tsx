import { forwardRef, useEffect, useMemo, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { MapView, Marker, type MapViewProps } from '@lugg/maps';

import { MarkerIcon } from './MarkerIcon';
import { MarkerText } from './MarkerText';
import { MarkerImage } from './MarkerImage';
import { CrewMarker, type VehicleImages } from './CrewMarker';
import type { MarkerData } from './index';
import { Route } from './Route';

interface MapProps extends MapViewProps {
  markers: MarkerData[];
  vehicleImages: VehicleImages;
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

export const Map = forwardRef<MapView, MapProps>(
  ({ markers, padding, vehicleImages, ...props }, ref) => {
    const polylineCoordinates = useMemo(
      () => markers.map((m) => m.coordinate),
      [markers]
    );
    const bottomOffset = padding?.bottom ?? 0;

    const [crewLocation, setCrewLocation] = useState(polylineCoordinates[0]);
    const [routeIndex, setRouteIndex] = useState(0);

    useEffect(() => {
      if (polylineCoordinates.length === 0) return;

      const interval = setInterval(() => {
        setRouteIndex((prev) => {
          const next = (prev + 1) % polylineCoordinates.length;
          setCrewLocation(polylineCoordinates[next]);
          return next;
        });
      }, 5000);
      return () => clearInterval(interval);
    }, [polylineCoordinates]);

    return (
      <View style={styles.container}>
        <MapView
          ref={ref}
          style={StyleSheet.absoluteFill}
          mapId="6939261d95ee48fd57332474"
          initialCoordinate={{ latitude: 37.78, longitude: -122.43 }}
          initialZoom={14}
          padding={padding}
          {...props}
        >
          {markers.map(renderMarker)}
          <Route markerCoordinates={polylineCoordinates} />
          <CrewMarker
            location={crewLocation}
            directions={polylineCoordinates.slice(routeIndex)}
            loaded={routeIndex > 2}
            images={vehicleImages}
          />
          <Marker
            name="inline-marker"
            coordinate={{ latitude: 37.782, longitude: -122.425 }}
            zIndex={10}
          >
            <View style={styles.customMarker} />
          </Marker>
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
