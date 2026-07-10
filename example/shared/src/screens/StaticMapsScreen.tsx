import { useState } from 'react';
import {
  FlatList,
  Platform,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  MapProvider,
  MapView,
  Marker,
  Polyline,
  type Coordinate,
  type MapProviderType,
} from '@lugg/maps';

import {
  Button,
  MarkerIcon,
  MarkerImage,
  MarkerText,
  ThemedText,
} from '../components';
import { sizes, useTheme } from '../theme';

type StaticMarkerType = 'default' | 'icon' | 'text' | 'image' | 'multiple';

const MARKER_TYPES: StaticMarkerType[] = [
  'default',
  'icon',
  'text',
  'image',
  'multiple',
];

export interface StaticPlace {
  id: string;
  name: string;
  description: string;
  coordinate: Coordinate;
  markerType: StaticMarkerType;
  markerText: string;
  imageUrl: string;
}

const BASE_PLACES: Omit<
  StaticPlace,
  'markerType' | 'markerText' | 'imageUrl'
>[] = [
  {
    id: 'golden-gate-bridge',
    name: 'Golden Gate Bridge',
    description: 'Iconic suspension bridge over the Golden Gate strait',
    coordinate: { latitude: 37.8199, longitude: -122.4783 },
  },
  {
    id: 'alcatraz',
    name: 'Alcatraz Island',
    description: 'Historic island prison in San Francisco Bay',
    coordinate: { latitude: 37.827, longitude: -122.423 },
  },
  {
    id: 'ferry-building',
    name: 'Ferry Building',
    description: 'Marketplace and transit hub on the Embarcadero',
    coordinate: { latitude: 37.7955, longitude: -122.3937 },
  },
  {
    id: 'golden-gate-park',
    name: 'Golden Gate Park',
    description: 'Large urban park with gardens and museums',
    coordinate: { latitude: 37.7694, longitude: -122.4862 },
  },
  {
    id: 'coit-tower',
    name: 'Coit Tower',
    description: 'Art deco tower on Telegraph Hill',
    coordinate: { latitude: 37.8024, longitude: -122.4058 },
  },
  {
    id: 'twin-peaks',
    name: 'Twin Peaks',
    description: 'Hills with panoramic views of the city',
    coordinate: { latitude: 37.7544, longitude: -122.4477 },
  },
];

// Large list for performance testing - cycles the base places with
// shifted coordinates so every map renders a unique region, and cycles
// marker use-cases so snapshots cover default, custom, and live markers
export const PLACES: StaticPlace[] = Array.from({ length: 100 }, (_, i) => {
  const base = BASE_PLACES[i % BASE_PLACES.length]!;
  const shift = Math.floor(i / BASE_PLACES.length) * 0.015;
  return {
    ...base,
    id: `${base.id}-${i}`,
    name: `${i + 1}. ${base.name}`,
    coordinate: {
      latitude: base.coordinate.latitude + shift,
      longitude: base.coordinate.longitude - shift,
    },
    markerType: MARKER_TYPES[i % MARKER_TYPES.length]!,
    markerText: `${i + 1}`,
    imageUrl: `https://i.pravatar.cc/100?img=${(i % 70) + 1}`,
  };
});

const seedFromId = (id: string) =>
  id.split('').reduce((acc, ch) => acc + ch.charCodeAt(0), 0);

// Deterministic pseudo-random scatter of 2-4 points, stable across
// re-renders so static snapshots stay valid. Clustered west of the
// coordinate so it doesn't overlap the center markers
const constellationPoints = (
  coordinate: Coordinate,
  seed: number
): Coordinate[] => {
  const count = 2 + (seed % 3);
  return Array.from({ length: count }, (_, i) => {
    const angle = seed + i * 2.4;
    const radius = 0.002 + ((seed + i) % 4) * 0.001;
    return {
      latitude: coordinate.latitude + Math.sin(angle) * radius * 0.8,
      longitude: coordinate.longitude - 0.009 + Math.cos(angle) * radius * 1.2,
    };
  });
};

// Extra markers shown for the 'multiple' use-case, offset from the center
const multipleMarkerCoordinates = (coordinate: Coordinate): Coordinate[] => [
  {
    latitude: coordinate.latitude + 0.003,
    longitude: coordinate.longitude - 0.004,
  },
  {
    latitude: coordinate.latitude - 0.002,
    longitude: coordinate.longitude + 0.004,
  },
];

// Every coordinate rendered on a place's map (markers + constellation),
// used to fit the camera around the content
const placeCoordinates = (place: StaticPlace): Coordinate[] => {
  const coordinates = [
    place.coordinate,
    ...constellationPoints(place.coordinate, seedFromId(place.id)),
  ];
  if (place.markerType === 'multiple') {
    coordinates.push(...multipleMarkerCoordinates(place.coordinate));
  }
  return coordinates;
};

const mercatorX = (longitude: number) => (longitude + 180) / 360;
const mercatorY = (latitude: number) =>
  (1 - Math.asinh(Math.tan((latitude * Math.PI) / 180)) / Math.PI) / 2;

// Camera that fits the coordinates in the given view size, derived up
// front so static maps center their content without imperative commands.
// Matches the native static framing: Google shows the world 256 * 2^zoom
// points wide; Apple fits a square span rect to the view's short side
// (see LuggStaticFittedMapRect)
const fittedCamera = (
  coordinates: Coordinate[],
  provider: MapProviderType,
  size: { width: number; height: number },
  padding: number
): { coordinate: Coordinate; zoom: number } => {
  const xs = coordinates.map((c) => mercatorX(c.longitude));
  const ys = coordinates.map((c) => mercatorY(c.latitude));
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);

  const centerY = (minY + maxY) / 2;
  const coordinate = {
    latitude:
      (Math.atan(Math.sinh(Math.PI * (1 - 2 * centerY))) * 180) / Math.PI,
    longitude: ((minX + maxX) / 2) * 360 - 180,
  };

  // World fraction per view point at which the bounds fit the padded view
  const scale = Math.max(
    (maxX - minX) / Math.max(size.width - padding * 2, 1),
    (maxY - minY) / Math.max(size.height - padding * 2, 1)
  );

  const zoom =
    provider === 'apple'
      ? 0.5 +
        Math.log2(
          1 /
            (scale *
              Math.min(size.width, size.height) *
              Math.cos((coordinate.latitude * Math.PI) / 180))
        )
      : Math.log2(1 / (256 * scale));

  return { coordinate, zoom };
};

const PlaceConstellation = ({ place }: { place: StaticPlace }) => {
  const points = constellationPoints(place.coordinate, seedFromId(place.id));
  return (
    <>
      <Polyline
        coordinates={points}
        strokeWidth={3}
        strokeColors={['#007aff']}
      />
      {points.map((point, index) => (
        <Marker key={index} coordinate={point} anchor={{ x: 0.5, y: 0.5 }}>
          <View style={styles.dot} />
        </Marker>
      ))}
    </>
  );
};

const PlaceMarkers = ({ place }: { place: StaticPlace }) => {
  const { coordinate, markerType, markerText, imageUrl } = place;

  switch (markerType) {
    case 'icon':
      return <MarkerIcon coordinate={coordinate} />;
    case 'text':
      return <MarkerText coordinate={coordinate} text={markerText} />;
    case 'image':
      return <MarkerImage coordinate={coordinate} source={{ uri: imageUrl }} />;
    case 'multiple': {
      const [textCoordinate, iconCoordinate] =
        multipleMarkerCoordinates(coordinate);
      return (
        <>
          <Marker coordinate={coordinate} />
          <MarkerText coordinate={textCoordinate!} text={markerText} />
          <MarkerIcon coordinate={iconCoordinate!} />
        </>
      );
    }
    default:
      return <Marker coordinate={coordinate} />;
  }
};

interface StaticMapsScreenProps {
  onSelect?: (place: StaticPlace) => void;
  topInset?: number;
}

const PlaceCard = ({
  place,
  provider,
  onSelect,
}: {
  place: StaticPlace;
  provider: MapProviderType;
  onSelect?: (place: StaticPlace) => void;
}) => {
  const { colors } = useTheme();
  const { width } = useWindowDimensions();

  const camera = fittedCamera(
    placeCoordinates(place),
    provider,
    { width: width - sizes.lg * 2, height: MAP_HEIGHT },
    16
  );

  return (
    <Pressable
      style={({ pressed }) => [
        styles.card,
        { backgroundColor: colors.background, borderColor: colors.border },
        pressed && styles.cardPressed,
      ]}
      onPress={() => onSelect?.(place)}
    >
      <View style={styles.map} pointerEvents="none">
        <MapView
          key={provider}
          staticMode
          staticKey={place.id}
          style={StyleSheet.absoluteFill}
          provider={provider}
          initialCoordinate={camera.coordinate}
          initialZoom={camera.zoom}
        >
          <PlaceMarkers place={place} />
          <PlaceConstellation place={place} />
        </MapView>
      </View>
      <View style={styles.cardContent}>
        <ThemedText variant="title" style={styles.cardTitle}>
          {place.name}
        </ThemedText>
        <ThemedText variant="caption">{place.description}</ThemedText>
        <ThemedText variant="caption">Marker: {place.markerType}</ThemedText>
      </View>
    </Pressable>
  );
};

export const StaticMapsScreen = ({
  onSelect,
  topInset = 0,
}: StaticMapsScreenProps) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const { colors } = useTheme();

  const [provider, setProvider] = useState<MapProviderType>(
    Platform.OS === 'ios' ? 'apple' : 'google'
  );

  return (
    <MapProvider apiKey={apiKey}>
      <FlatList
        style={{ backgroundColor: colors.background }}
        contentContainerStyle={[
          styles.list,
          { paddingTop: sizes.lg + topInset },
        ]}
        scrollIndicatorInsets={{ top: topInset }}
        data={PLACES}
        keyExtractor={(place) => place.id}
        ListHeaderComponent={
          <Button
            title={provider === 'google' ? 'Apple Maps' : 'Google Maps'}
            disabled={Platform.OS !== 'ios'}
            onPress={() =>
              setProvider((p) => (p === 'google' ? 'apple' : 'google'))
            }
          />
        }
        renderItem={({ item }) => (
          <PlaceCard place={item} provider={provider} onSelect={onSelect} />
        )}
      />
    </MapProvider>
  );
};

const MAP_HEIGHT = 140;

const styles = StyleSheet.create({
  list: {
    padding: sizes.lg,
    gap: sizes.lg,
  },
  card: {
    borderRadius: sizes.radiusLg,
    borderWidth: StyleSheet.hairlineWidth,
    overflow: 'hidden',
  },
  cardPressed: {
    opacity: 0.7,
  },
  map: {
    height: MAP_HEIGHT,
  },
  cardContent: {
    padding: sizes.lg,
    gap: sizes.xs,
  },
  cardTitle: {
    fontSize: sizes.fontLg,
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#007aff',
    borderWidth: 2,
    borderColor: 'white',
  },
});
