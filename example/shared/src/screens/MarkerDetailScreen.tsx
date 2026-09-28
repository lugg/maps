import { useState } from 'react';
import { Platform, StyleSheet, View, useWindowDimensions } from 'react-native';
import { MapProvider, MapView, Marker, type MapProviderType } from '@lugg/maps';

import { Button, ThemedText } from '../components';
import { INITIAL_MARKERS } from '../markers';
import { CIRCLE_CENTER } from '../mapData';
import { sizes, useTheme } from '../theme';
import {
  PLACES,
  PlaceConstellation,
  PlaceMarkers,
  fittedCamera,
  placeCoordinates,
} from './StaticMapsScreen';

interface MarkerDetailScreenProps {
  name: string;
  bottomInset?: number;
}

const CARD_HEIGHT = 200;

const formatCoordinate = (value: number) => value.toFixed(4);

export const MarkerDetailScreen = ({
  name,
  bottomInset = 0,
}: MarkerDetailScreenProps) => {
  const { colors } = useTheme();
  const { width, height } = useWindowDimensions();
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const [provider, setProvider] = useState<MapProviderType>(
    Platform.OS === 'ios' ? 'apple' : 'google'
  );

  const cardBottom = bottomInset + sizes.lg;
  const edgeInsets = {
    top: 0,
    left: 0,
    right: 0,
    bottom: cardBottom + CARD_HEIGHT,
  };

  const marker = INITIAL_MARKERS.find((m) => m.name === name);
  const place = PLACES.find((p) => p.name === name);

  const coordinate = marker?.coordinate ?? place?.coordinate ?? CIRCLE_CENTER;
  const title = marker?.title ?? place?.name ?? name;
  const description =
    marker?.description ?? place?.description ?? 'Marker detail screen';
  const camera = place
    ? fittedCamera(
        placeCoordinates(place),
        provider,
        { width, height },
        sizes.xl,
        edgeInsets
      )
    : { coordinate, zoom: 15 };

  return (
    <View style={styles.container}>
      <MapProvider apiKey={apiKey}>
        <MapView
          key={provider}
          provider={provider}
          style={StyleSheet.absoluteFill}
          staticMode
          staticKey={name}
          initialCoordinate={camera.coordinate}
          initialZoom={camera.zoom}
          edgeInsets={edgeInsets}
        >
          {place ? (
            <>
              <PlaceMarkers place={place} />
              <PlaceConstellation place={place} />
            </>
          ) : (
            <Marker coordinate={coordinate} />
          )}
        </MapView>
      </MapProvider>
      <Button
        style={{
          ...styles.providerButton,
          bottom: edgeInsets.bottom + sizes.lg,
        }}
        title={provider === 'google' ? 'Apple Maps' : 'Google Maps'}
        disabled={Platform.OS !== 'ios'}
        onPress={() =>
          setProvider((p) => (p === 'google' ? 'apple' : 'google'))
        }
      />
      <View
        style={[
          styles.overlay,
          {
            bottom: cardBottom,
            backgroundColor: colors.backgroundElevated,
            shadowColor: colors.shadow,
          },
        ]}
        pointerEvents="none"
      >
        <ThemedText variant="title">{title}</ThemedText>
        <ThemedText variant="caption">{description}</ThemedText>
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <ThemedText variant="caption" style={styles.coordinate}>
          {formatCoordinate(coordinate.latitude)},{' '}
          {formatCoordinate(coordinate.longitude)}
        </ThemedText>
        <ThemedText variant="caption" style={styles.hint}>
          Go back and press the same marker again
        </ThemedText>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  providerButton: {
    position: 'absolute',
    right: sizes.lg,
  },
  overlay: {
    position: 'absolute',
    left: sizes.lg,
    right: sizes.lg,
    height: CARD_HEIGHT,
    padding: sizes.xl,
    gap: sizes.sm,
    borderRadius: sizes.radiusLg,
    shadowOffset: sizes.shadowOffset,
    shadowOpacity: sizes.shadowOpacity,
    shadowRadius: sizes.shadowRadius,
    elevation: sizes.elevation,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    marginVertical: sizes.xs,
  },
  coordinate: {
    fontVariant: ['tabular-nums'],
  },
  hint: {
    fontSize: sizes.fontSm,
    marginTop: 'auto',
  },
});
