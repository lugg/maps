import { forwardRef, useMemo, useState } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  MapView,
  Marker,
  Polygon,
  type MapViewProps,
  type MapCameraEvent,
  type MarkerPressEvent,
} from '@lugg/maps';
import Animated, {
  useAnimatedStyle,
  type SharedValue,
} from 'react-native-reanimated';

import { CrewMarker } from './CrewMarker';
import { MarkerIcon } from './MarkerIcon';
import { MarkerText } from './MarkerText';
import { MarkerImage } from './MarkerImage';
import type { MarkerData } from './index';
import { Route, smoothCoordinates } from './Route';

interface MapProps extends MapViewProps {
  markers: MarkerData[];
  animatedPosition?: SharedValue<number>;
  onPolygonPress?: () => void;
  onMarkerPress?: (event: MarkerPressEvent, marker: MarkerData) => void;
}

const INITIAL_ZOOM = 14;

const CIRCLE_CENTER = { latitude: 37.78, longitude: -122.43 };
const CIRCLE_RADIUS = 0.003;
const CIRCLE_COORDS = Array.from({ length: 36 }, (_, i) => {
  const angle = (i * 10 * Math.PI) / 180;
  return {
    latitude: CIRCLE_CENTER.latitude + CIRCLE_RADIUS * Math.cos(angle),
    longitude:
      CIRCLE_CENTER.longitude +
      (CIRCLE_RADIUS * Math.sin(angle)) /
        Math.cos((CIRCLE_CENTER.latitude * Math.PI) / 180),
  };
});

const renderMarker = (
  marker: MarkerData,
  onPress?: (event: MarkerPressEvent, marker: MarkerData) => void
) => {
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

  const handlePress = onPress
    ? (e: MarkerPressEvent) => onPress(e, marker)
    : undefined;

  switch (type) {
    case 'icon':
      return (
        <MarkerIcon
          key={id}
          name={name}
          coordinate={coordinate}
          onPress={handlePress}
        />
      );
    case 'text':
      return (
        <MarkerText
          key={id}
          name={name}
          coordinate={coordinate}
          text={text ?? 'X'}
          color={color}
          onPress={handlePress}
        />
      );
    case 'image':
      return (
        <MarkerImage
          key={id}
          name={name}
          coordinate={coordinate}
          source={{ uri: imageUrl }}
          onPress={handlePress}
        />
      );
    case 'custom':
      return (
        <Marker
          key={id}
          name={name}
          coordinate={coordinate}
          anchor={anchor}
          onPress={handlePress}
        >
          <View
            style={[styles.customMarker, { backgroundColor: color ?? 'gray' }]}
          />
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
          onPress={handlePress}
        />
      );
  }
};

export const Map = forwardRef<MapView, MapProps>(
  (
    {
      markers,
      edgeInsets,
      animatedPosition,
      onCameraIdle,
      onCameraMove,
      onPress,
      onLongPress,
      onPolygonPress,
      onMarkerPress,
      ...props
    },
    ref
  ) => {
    const { height: screenHeight } = useWindowDimensions();
    const [zoom, setZoom] = useState(INITIAL_ZOOM);
    const polylineCoordinates = useMemo(
      () => markers.map((m) => m.coordinate),
      [markers]
    );
    const smoothedRoute = useMemo(
      () => smoothCoordinates(polylineCoordinates),
      [polylineCoordinates]
    );

    const centerPinStyle = useAnimatedStyle(() => {
      const bottom = animatedPosition
        ? screenHeight - animatedPosition.value
        : 0;
      return {
        transform: [{ translateY: -bottom / 2 }],
      };
    });

    const handleCameraMove = (e: MapCameraEvent) => {
      onCameraMove?.(e);
    };

    const handleCameraIdle = (e: MapCameraEvent) => {
      setZoom(e.nativeEvent.zoom);
      onCameraIdle?.(e);
    };

    return (
      <View style={styles.container}>
        <MapView
          ref={ref}
          style={StyleSheet.absoluteFill}
          initialCoordinate={{ latitude: 37.78, longitude: -122.43 }}
          initialZoom={INITIAL_ZOOM}
          userLocationEnabled
          edgeInsets={edgeInsets}
          onPress={onPress}
          onLongPress={onLongPress}
          onCameraMove={handleCameraMove}
          onCameraIdle={handleCameraIdle}
          {...props}
        >
          {markers.map((m) => renderMarker(m, onMarkerPress))}
          <Route coordinates={smoothedRoute} />
          <CrewMarker route={smoothedRoute} zoom={zoom} />
          <Polygon
            coordinates={CIRCLE_COORDS}
            fillColor="rgba(66, 133, 244, 0.15)"
            strokeColor="#4285F4"
            strokeWidth={2}
            onPress={onPolygonPress}
          />
          <MarkerText
            name="inline-marker"
            coordinate={{ latitude: 37.782, longitude: -122.425 }}
            text="LO"
            color="#34A853"
          />
        </MapView>
        <Animated.View style={[styles.centerPin, centerPinStyle]} />
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
  centerPin: {
    backgroundColor: 'blue',
    height: 20,
    width: 20,
    borderRadius: 10,
  },
  customMarker: {
    height: 30,
    width: 30,
    borderRadius: 15,
  },
});
