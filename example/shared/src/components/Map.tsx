import { forwardRef, useMemo, useState } from 'react';
import {
  Alert,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  MapView,
  Marker,
  GeoJson,
  Polygon,
  Circle,
  GroundOverlay,
  type MapViewProps,
  type MapCameraEvent,
  type MarkerPressEvent,
  type MarkerDragEvent,
  type GeoJSON,
} from '@lugg/maps';
import Animated, {
  useAnimatedStyle,
  type SharedValue,
} from 'react-native-reanimated';

import { CrewMarker } from './CrewMarker';
import { MarkerIcon } from './MarkerIcon';
import { MarkerText } from './MarkerText';
import { MarkerImage } from './MarkerImage';
import { Button } from './Button';
import type { MarkerData } from './index';
import { Route, smoothCoordinates } from './Route';
import { SAMPLE_GEOJSON } from '../geojson';

interface MapProps extends MapViewProps {
  markers: MarkerData[];
  geojson?: GeoJSON | null;
  animatedPosition?: SharedValue<number>;
  onPolygonPress?: () => void;
  onCirclePress?: () => void;
  onGroundOverlayPress?: () => void;
  onMarkerPress?: (event: MarkerPressEvent, marker: MarkerData) => void;
  onMarkerDragStart?: (event: MarkerDragEvent, marker: MarkerData) => void;
  onMarkerDragChange?: (event: MarkerDragEvent, marker: MarkerData) => void;
  onMarkerDragEnd?: (event: MarkerDragEvent, marker: MarkerData) => void;
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

const HOLE_RADIUS = 0.0015;
const CIRCLE_HOLES = [
  Array.from({ length: 36 }, (_, i) => {
    const angle = (i * 10 * Math.PI) / 180;
    return {
      latitude: CIRCLE_CENTER.latitude + HOLE_RADIUS * Math.cos(angle),
      longitude:
        CIRCLE_CENTER.longitude +
        (HOLE_RADIUS * Math.sin(angle)) /
          Math.cos((CIRCLE_CENTER.latitude * Math.PI) / 180),
    };
  }),
];

const SELECTED_SCALE = 1.5;

const renderMarker = (
  marker: MarkerData,
  selectedId: string | null,
  onPress?: (event: MarkerPressEvent, marker: MarkerData) => void,
  onDragStart?: (event: MarkerDragEvent, marker: MarkerData) => void,
  onDragChange?: (event: MarkerDragEvent, marker: MarkerData) => void,
  onDragEnd?: (event: MarkerDragEvent, marker: MarkerData) => void
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
  const scale = id === selectedId ? SELECTED_SCALE : 1;

  const handlePress = onPress
    ? (e: MarkerPressEvent) => onPress(e, marker)
    : undefined;
  const handleDragStart = onDragStart
    ? (e: MarkerDragEvent) => onDragStart(e, marker)
    : undefined;
  const handleDragChange = onDragChange
    ? (e: MarkerDragEvent) => onDragChange(e, marker)
    : undefined;
  const handleDragEnd = onDragEnd
    ? (e: MarkerDragEvent) => onDragEnd(e, marker)
    : undefined;

  const calloutEl = (label: string, desc: string) => (
    <View style={styles.callout}>
      <Text style={styles.calloutTitle}>{label}</Text>
      <Text style={styles.calloutDescription}>{desc}</Text>
    </View>
  );

  switch (type) {
    case 'icon':
      return (
        <MarkerIcon
          key={id}
          name={name}
          coordinate={coordinate}
          scale={scale}
          draggable
          onPress={handlePress}
          onDragStart={handleDragStart}
          onDragChange={handleDragChange}
          onDragEnd={handleDragEnd}
          callout={calloutEl(
            'Icon Marker Callout',
            'A draggable pin-style marker with a custom icon representation on the map'
          )}
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
          scale={scale}
          draggable
          onPress={handlePress}
          onDragStart={handleDragStart}
          onDragChange={handleDragChange}
          onDragEnd={handleDragEnd}
          callout={calloutEl(
            `Text Badge Marker ${text}`,
            'Displays a colored text badge that can be dragged around the map'
          )}
        />
      );
    case 'image':
      return (
        <MarkerImage
          key={id}
          name={name}
          coordinate={coordinate}
          source={{ uri: imageUrl }}
          scale={scale}
          draggable
          onPress={handlePress}
          onDragStart={handleDragStart}
          onDragChange={handleDragChange}
          onDragEnd={handleDragEnd}
          callout={calloutEl(
            'Remote Image Marker',
            'An avatar marker rendered from a remote image source URL'
          )}
        />
      );
    case 'custom':
      return (
        <Marker
          key={id}
          name={name}
          coordinate={coordinate}
          anchor={anchor}
          scale={scale}
          draggable
          onPress={handlePress}
          onDragStart={handleDragStart}
          onDragChange={handleDragChange}
          onDragEnd={handleDragEnd}
          callout={
            <View style={styles.customCallout}>
              <View>
                <Text style={styles.calloutTitle}>
                  Custom Interactive Marker
                </Text>
                <Text style={styles.calloutDescription}>
                  A non-bubbled custom callout with interactive button support
                </Text>
              </View>
              <Button title="Press me" onPress={() => Alert.alert('pressed')} />
            </View>
          }
          calloutOptions={{ bubbled: false }}
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
          scale={scale}
          draggable
          onPress={handlePress}
          onDragStart={handleDragStart}
          onDragChange={handleDragChange}
          onDragEnd={handleDragEnd}
          callout={title ? undefined : calloutEl('Basic Marker', name ?? '')}
        />
      );
  }
};

export const Map = forwardRef<MapView, MapProps>(
  (
    {
      markers,
      geojson,
      edgeInsets,
      animatedPosition,
      onCameraIdle,
      onCameraMove,
      onPress,
      onLongPress,
      onPolygonPress,
      onCirclePress,
      onGroundOverlayPress,
      onMarkerPress,
      onMarkerDragStart,
      onMarkerDragChange,
      onMarkerDragEnd,
      ...props
    },
    ref
  ) => {
    const { height: screenHeight } = useWindowDimensions();
    const [zoom, setZoom] = useState(INITIAL_ZOOM);
    const [selectedMarkerId, setSelectedMarkerId] = useState<string | null>(
      null
    );
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

    const handleMarkerPress = (e: MarkerPressEvent, marker: MarkerData) => {
      setSelectedMarkerId((prev) => (prev === marker.id ? null : marker.id));
      onMarkerPress?.(e, marker);
    };

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
          {markers.map((m) =>
            renderMarker(
              m,
              selectedMarkerId,
              handleMarkerPress,
              onMarkerDragStart,
              onMarkerDragChange,
              onMarkerDragEnd
            )
          )}
          <Route coordinates={smoothedRoute} />
          <CrewMarker route={smoothedRoute} zoom={zoom} />
          <Polygon
            coordinates={CIRCLE_COORDS}
            holes={CIRCLE_HOLES}
            fillColor="rgba(66, 133, 244, 0.15)"
            strokeColor="#4285F4"
            strokeWidth={2}
            onPress={onPolygonPress}
          />
          <Circle
            center={{ latitude: 37.78, longitude: -122.427 }}
            radius={300}
            fillColor="rgba(244, 67, 54, 0.3)"
            strokeColor="#F44336"
            strokeWidth={2}
            onPress={onCirclePress}
          />
          <MarkerText
            name="inline-marker"
            coordinate={{ latitude: 37.782, longitude: -122.425 }}
            text="LO"
            color="#34A853"
          />
          <GeoJson geojson={SAMPLE_GEOJSON} />
          <GroundOverlay
            image={{
              uri: 'https://picsum.photos/320/240',
            }}
            bounds={{
              southwest: { latitude: 37.7765, longitude: -122.435 },
              northeast: { latitude: 37.7805, longitude: -122.43 },
            }}
            opacity={0.6}
            onPress={onGroundOverlayPress}
          />
          {geojson && (
            <GeoJson
              geojson={geojson}
              renderPolygon={(polygonProps) => (
                <Polygon
                  key={`geojson-${polygonProps.coordinates[0]?.latitude}`}
                  {...polygonProps}
                  fillColor="rgba(66, 133, 244, 0.2)"
                  strokeColor="#4285F4"
                  strokeWidth={1}
                />
              )}
            />
          )}
        </MapView>
        <Animated.View style={[styles.centerPin, centerPinStyle]}>
          <View style={styles.centerPinDot} />
        </Animated.View>
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
    alignItems: 'center',
    justifyContent: 'center',
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(66, 133, 244, 0.2)',
    borderWidth: 2,
    borderColor: 'white',
    pointerEvents: 'none',
  },
  centerPinDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#4285F4',
  },
  customMarker: {
    height: 30,
    width: 30,
    borderRadius: 15,
  },
  callout: {
    minWidth: 140,
  },
  customCallout: {
    width: 250,
    padding: 10,
    backgroundColor: 'white',
    borderRadius: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 4,
    gap: 12,
  },
  calloutTitle: {
    fontWeight: 'bold',
    fontSize: 14,
    marginBottom: 2,
  },
  calloutDescription: {
    fontSize: 12,
    color: '#666',
  },
});
