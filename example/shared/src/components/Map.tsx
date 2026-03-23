import {
  forwardRef,
  useCallback,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  Alert,
  Platform,
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
  type MapViewRef,
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
import { ThemedText } from './ThemedText';
import type { MarkerData } from './index';
import { Route, smoothCoordinates } from './Route';
import { SAMPLE_GEOJSON } from '../geojson';
import { sizes, useTheme } from '../theme';
import {
  INITIAL_ZOOM,
  CIRCLE_CENTER,
  CIRCLE_COORDS,
  CIRCLE_HOLES,
} from '../mapData';

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

const CustomCallout = () => {
  const { colors } = useTheme();
  return (
    <View
      style={[styles.customCallout, { backgroundColor: colors.background }]}
    >
      <View>
        <ThemedText style={styles.calloutTitle}>
          Custom Interactive Marker
        </ThemedText>
        <ThemedText variant="caption" style={styles.calloutDescription}>
          A non-bubbled custom callout with interactive button support
        </ThemedText>
      </View>
      <Button title="Press me" onPress={() => Alert.alert('pressed')} />
    </View>
  );
};

const SELECTED_SCALE = 1.5;

const CalloutContent = ({
  title,
  description,
  themed,
}: {
  title: string;
  description: string;
  themed?: boolean;
}) => {
  const Label = themed ? ThemedText : Text;
  return (
    <View style={styles.callout}>
      <Label style={styles.calloutTitle}>{title}</Label>
      <Label style={styles.calloutDescription}>{description}</Label>
    </View>
  );
};

const renderMarker = (
  marker: MarkerData,
  selectedId: string | null,
  onPress?: (event: MarkerPressEvent, marker: MarkerData) => void,
  onDragStart?: (event: MarkerDragEvent, marker: MarkerData) => void,
  onDragChange?: (event: MarkerDragEvent, marker: MarkerData) => void,
  onDragEnd?: (event: MarkerDragEvent, marker: MarkerData) => void,
  refCallback?: (id: string, ref: Marker | null) => void,
  themedCallout?: boolean
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
  const markerRef = refCallback
    ? (r: Marker | null) => refCallback(id, r)
    : undefined;

  const shared = {
    name,
    coordinate,
    scale,
    draggable: true as const,
    onPress: handlePress,
    onDragStart: handleDragStart,
    onDragChange: handleDragChange,
    onDragEnd: handleDragEnd,
  };

  switch (type) {
    case 'icon':
      return (
        <MarkerIcon
          key={id}
          ref={markerRef}
          {...shared}
          callout={
            <CalloutContent
              themed={themedCallout}
              title="Icon Marker Callout"
              description="A draggable pin-style marker with a custom icon representation on the map"
            />
          }
        />
      );
    case 'text':
      return (
        <MarkerText
          key={id}
          ref={markerRef}
          {...shared}
          text={text ?? 'X'}
          color={color}
          callout={
            <CalloutContent
              themed={themedCallout}
              title={`Text Badge Marker ${text}`}
              description="Displays a colored text badge that can be dragged around the map"
            />
          }
        />
      );
    case 'image':
      return (
        <MarkerImage
          key={id}
          ref={markerRef}
          {...shared}
          source={{ uri: imageUrl }}
          callout={
            <CalloutContent
              themed={themedCallout}
              title="Remote Image Marker"
              description="An avatar marker rendered from a remote image source URL"
            />
          }
        />
      );
    case 'custom':
      return (
        <Marker
          key={id}
          ref={markerRef}
          {...shared}
          anchor={anchor}
          callout={<CustomCallout />}
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
          ref={markerRef}
          {...shared}
          title={title}
          description={description}
          callout={
            title ? undefined : (
              <CalloutContent
                themed={themedCallout}
                title="Basic Marker"
                description={name ?? ''}
              />
            )
          }
        />
      );
  }
};

export interface MapRef extends MapViewRef {
  showMarkerCallout(markerId: string): void;
  hideMarkerCallout(markerId: string): void;
}

export const Map = forwardRef<MapRef, MapProps>(
  (
    {
      markers,
      geojson,
      provider,
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
    const mapRef = useRef<MapView>(null);
    const markerRefsMap = useRef(new globalThis.Map<string, Marker>());
    const [zoom, setZoom] = useState(INITIAL_ZOOM);
    const [selectedMarkerId, setSelectedMarkerId] = useState<string | null>(
      null
    );

    const handleMarkerRef = useCallback((id: string, r: Marker | null) => {
      if (r) {
        markerRefsMap.current.set(id, r);
      } else {
        markerRefsMap.current.delete(id);
      }
    }, []);

    useImperativeHandle(
      ref,
      () => ({
        moveCamera: (...args) => mapRef.current?.moveCamera(...args),
        fitCoordinates: (...args) => mapRef.current?.fitCoordinates(...args),
        setEdgeInsets: (...args) => mapRef.current?.setEdgeInsets(...args),
        showMarkerCallout: (markerId) =>
          markerRefsMap.current.get(markerId)?.showCallout(),
        hideMarkerCallout: (markerId) =>
          markerRefsMap.current.get(markerId)?.hideCallout(),
      }),
      []
    );

    const smoothedRoute = useMemo(
      () => smoothCoordinates(markers.map((m) => m.coordinate)),
      [markers]
    );

    const centerPinStyle = useAnimatedStyle(() => {
      const bottom = animatedPosition
        ? screenHeight - animatedPosition.value
        : 0;
      return { transform: [{ translateY: -bottom / 2 }] };
    });

    const handleMarkerPress = (e: MarkerPressEvent, marker: MarkerData) => {
      setSelectedMarkerId((prev) => (prev === marker.id ? null : marker.id));
      onMarkerPress?.(e, marker);
    };

    const handleCameraIdle = (e: MapCameraEvent) => {
      setZoom(e.nativeEvent.zoom);
      onCameraIdle?.(e);
    };

    return (
      <View style={styles.container}>
        <MapView
          ref={mapRef}
          style={StyleSheet.absoluteFill}
          provider={provider}
          initialCoordinate={CIRCLE_CENTER}
          initialZoom={INITIAL_ZOOM}
          userLocationEnabled
          edgeInsets={edgeInsets}
          onPress={onPress}
          onLongPress={onLongPress}
          onCameraMove={onCameraMove}
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
              onMarkerDragEnd,
              handleMarkerRef,
              provider === 'apple' || Platform.OS === 'android'
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
            image={{ uri: 'https://picsum.photos/320/240' }}
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
    borderRadius: sizes.radiusFull,
    backgroundColor: 'rgba(66, 133, 244, 0.2)',
    borderWidth: 2,
    borderColor: 'white',
    pointerEvents: 'none',
  },
  centerPinDot: {
    width: sizes.sm,
    height: sizes.sm,
    borderRadius: sizes.radiusFull,
    backgroundColor: '#4285F4',
  },
  customMarker: {
    height: 30,
    width: 30,
    borderRadius: sizes.radiusFull,
  },
  callout: {
    minWidth: 140,
  },
  customCallout: {
    width: 250,
    padding: sizes.radiusLg,
    borderRadius: sizes.radiusLg,
    shadowColor: '#000',
    shadowOffset: sizes.shadowOffset,
    shadowOpacity: 0.2,
    shadowRadius: sizes.shadowRadius,
    elevation: sizes.elevation,
    gap: sizes.md,
  },
  calloutTitle: {
    fontWeight: 'bold',
    fontSize: sizes.fontBase,
    marginBottom: 2,
  },
  calloutDescription: {
    fontSize: sizes.fontSm,
    color: '#666',
  },
});
