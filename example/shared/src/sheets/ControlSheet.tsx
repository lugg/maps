import { forwardRef, useImperativeHandle, useRef } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
import type { MapProviderType } from '@lugg/maps';
import {
  ReanimatedTrueSheet,
  useReanimatedTrueSheet,
} from '@lodev09/react-native-true-sheet/reanimated';
import {
  TrueSheet,
  type DetentChangeEvent,
} from '@lodev09/react-native-true-sheet';

import { Button, ThemedText } from '../components';
import { sizes, useTheme } from '../theme';

interface StatusInfo {
  text: string;
  error: boolean;
}

interface ControlSheetProps {
  status: StatusInfo;
  markerCount: number;
  showMap: boolean;
  provider: MapProviderType;
  hasGeojson: boolean;
  onAddMarker: () => void;
  onRemoveMarker: () => void;
  onClearMarkers: () => void;
  onMoveCamera: () => void;
  onFitMarkers: () => void;
  onToggleMap: () => void;
  onToggleProvider: () => void;
  onLoadGeojson: () => void;
  onDidPresent?: (event: DetentChangeEvent) => void;
  onDetentChange?: (event: DetentChangeEvent) => void;
}

export interface ControlSheetRef {
  animatedPosition: ReturnType<
    typeof useReanimatedTrueSheet
  >['animatedPosition'];
}

export const ControlSheet = forwardRef<ControlSheetRef, ControlSheetProps>(
  (
    {
      status,
      markerCount,
      showMap,
      provider,
      hasGeojson,
      onAddMarker,
      onRemoveMarker,
      onClearMarkers,
      onMoveCamera,
      onFitMarkers,
      onToggleMap,
      onToggleProvider,
      onLoadGeojson,
      onDidPresent,
      onDetentChange,
    },
    ref
  ) => {
    const sheetRef = useRef<TrueSheet>(null);
    const { animatedPosition } = useReanimatedTrueSheet();

    useImperativeHandle(ref, () => ({ animatedPosition }));

    const { colors } = useTheme();

    return (
      <ReanimatedTrueSheet
        ref={sheetRef}
        detents={['auto', 0.5]}
        style={styles.sheet}
        dimmed={false}
        dismissible={false}
        initialDetentIndex={0}
        anchor="left"
        maxContentWidth={500}
        onDidPresent={onDidPresent}
        onDetentChange={onDetentChange}
      >
        <ThemedText
          style={[
            { color: colors.textSecondary },
            status.error && { color: colors.textError },
          ]}
        >
          {status.text}
        </ThemedText>
        <View style={styles.sheetContent}>
          <Button
            style={styles.sheetButton}
            title="Add Marker"
            onPress={onAddMarker}
          />
          <Button
            style={styles.sheetButton}
            title={`Remove Marker (${markerCount})`}
            onPress={onRemoveMarker}
            disabled={markerCount === 0}
          />
          <Button
            style={styles.sheetButton}
            title="Clear Markers"
            onPress={onClearMarkers}
            disabled={markerCount === 0}
          />
          <Button
            style={styles.sheetButton}
            title="Move Camera"
            onPress={onMoveCamera}
          />
          <Button
            style={styles.sheetButton}
            title="Fit Markers"
            onPress={onFitMarkers}
            disabled={markerCount === 0}
          />
          <Button
            style={styles.sheetButton}
            title={showMap ? 'Hide Map' : 'Show Map'}
            onPress={onToggleMap}
          />
          <Button
            style={styles.sheetButton}
            title={provider === 'google' ? 'Apple Maps' : 'Google Maps'}
            disabled={Platform.OS !== 'ios'}
            onPress={onToggleProvider}
          />
          <Button
            style={styles.sheetButton}
            title={hasGeojson ? 'GeoJSON (loaded)' : 'Load GeoJSON'}
            onPress={onLoadGeojson}
          />
        </View>
      </ReanimatedTrueSheet>
    );
  }
);

const styles = StyleSheet.create({
  sheet: {
    padding: sizes.xl,
    gap: sizes.md,
  },
  sheetContent: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: sizes.sm,
  },
  sheetButton: {
    flex: 1,
    minWidth: '45%',
  },
});
