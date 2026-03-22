import { forwardRef, useRef, useImperativeHandle } from 'react';
import { StyleSheet } from 'react-native';
import { TrueSheet } from '@lodev09/react-native-true-sheet';
import type { MapType } from '@lugg/maps';

import { Button, ThemedText } from '../components';
import { sizes } from '../theme';

const MAP_TYPES: MapType[] = [
  'standard',
  'satellite',
  'terrain',
  'hybrid',
  'muted-standard',
];

interface MapTypeSheetProps {
  mapType: MapType;
  onSelect: (type: MapType) => void;
}

export interface MapTypeSheetRef {
  present: () => void;
}

export const MapTypeSheet = forwardRef<MapTypeSheetRef, MapTypeSheetProps>(
  ({ mapType, onSelect }, ref) => {
    const sheetRef = useRef<TrueSheet>(null);

    useImperativeHandle(ref, () => ({
      present: () => sheetRef.current?.present(),
    }));

    return (
      <TrueSheet ref={sheetRef} detents={['auto']} style={styles.sheet}>
        <ThemedText variant="title">Map Type</ThemedText>
        {MAP_TYPES.map((type) => (
          <Button
            key={type}
            title={type === mapType ? `${type} ✓` : type}
            onPress={() => {
              onSelect(type);
              sheetRef.current?.dismiss();
            }}
          />
        ))}
      </TrueSheet>
    );
  }
);

const styles = StyleSheet.create({
  sheet: {
    padding: sizes.xl,
    gap: sizes.md,
  },
});
