import { StyleSheet, View } from 'react-native';
import { MapProvider, MapView, Marker } from '@lugg/maps';

import { ThemedText } from '../components';
import { INITIAL_MARKERS } from '../markers';
import { CIRCLE_CENTER } from '../mapData';
import { sizes, useTheme } from '../theme';
import { PLACES } from './StaticMapsScreen';

interface MarkerDetailScreenProps {
  name: string;
}

const CARD_HEIGHT = 200;
const CARD_BOTTOM = sizes.xl * 3;

const formatCoordinate = (value: number) => value.toFixed(4);

export const MarkerDetailScreen = ({ name }: MarkerDetailScreenProps) => {
  const { colors } = useTheme();
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  const marker = INITIAL_MARKERS.find((m) => m.name === name);
  const place = PLACES.find((p) => p.name === name);

  const coordinate = marker?.coordinate ?? place?.coordinate ?? CIRCLE_CENTER;
  const title = marker?.title ?? place?.name ?? name;
  const description =
    marker?.description ?? place?.description ?? 'Marker detail screen';

  return (
    <View style={styles.container}>
      <MapProvider apiKey={apiKey}>
        <MapView
          style={StyleSheet.absoluteFill}
          staticMode
          staticKey={name}
          initialCoordinate={coordinate}
          initialZoom={15}
          edgeInsets={{
            top: 0,
            left: 0,
            right: 0,
            bottom: CARD_BOTTOM + CARD_HEIGHT,
          }}
        >
          <Marker coordinate={coordinate} />
        </MapView>
      </MapProvider>
      <View
        style={[
          styles.overlay,
          {
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
  overlay: {
    position: 'absolute',
    left: sizes.lg,
    right: sizes.lg,
    bottom: CARD_BOTTOM,
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
