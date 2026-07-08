import { useState } from 'react';
import { FlatList, Platform, Pressable, StyleSheet, View } from 'react-native';
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
    case 'multiple':
      return (
        <>
          <Marker coordinate={coordinate} />
          <MarkerText
            coordinate={{
              latitude: coordinate.latitude + 0.003,
              longitude: coordinate.longitude - 0.004,
            }}
            text={markerText}
          />
          <MarkerIcon
            coordinate={{
              latitude: coordinate.latitude - 0.002,
              longitude: coordinate.longitude + 0.004,
            }}
          />
        </>
      );
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
          initialCoordinate={place.coordinate}
          initialZoom={14}
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
    height: 140,
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
