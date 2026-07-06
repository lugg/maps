import { useState } from 'react';
import { FlatList, Platform, Pressable, StyleSheet, View } from 'react-native';
import {
  MapProvider,
  MapView,
  Marker,
  type Coordinate,
  type MapProviderType,
} from '@lugg/maps';

import { Button, ThemedText } from '../components';
import { sizes, useTheme } from '../theme';

export interface StaticPlace {
  id: string;
  name: string;
  description: string;
  coordinate: Coordinate;
}

const PLACES: StaticPlace[] = [
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

interface StaticMapsScreenProps {
  onSelect?: (place: StaticPlace) => void;
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
          style={StyleSheet.absoluteFill}
          provider={provider}
          initialCoordinate={place.coordinate}
          initialZoom={14}
        >
          <Marker coordinate={place.coordinate} />
        </MapView>
      </View>
      <View style={styles.cardContent}>
        <ThemedText variant="title" style={styles.cardTitle}>
          {place.name}
        </ThemedText>
        <ThemedText variant="caption">{place.description}</ThemedText>
      </View>
    </Pressable>
  );
};

export const StaticMapsScreen = ({ onSelect }: StaticMapsScreenProps) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const { colors } = useTheme();

  const [provider, setProvider] = useState<MapProviderType>(
    Platform.OS === 'ios' ? 'apple' : 'google'
  );

  return (
    <MapProvider apiKey={apiKey}>
      <FlatList
        style={{ backgroundColor: colors.background }}
        contentContainerStyle={styles.list}
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
});
