import { forwardRef, useRef, useImperativeHandle, useState } from 'react';
import { StyleSheet, TextInput } from 'react-native';
import { TrueSheet } from '@lodev09/react-native-true-sheet';
import type { GeoJSON } from '@lugg/maps';

import { Button, ThemedText } from '../components';
import { sizes, useTheme } from '../theme';

const GEOJSON_PRESETS = [
  {
    name: 'California Counties',
    url: 'https://raw.githubusercontent.com/codeforgermany/click_that_hood/main/public/data/california-counties.geojson',
  },
  {
    name: 'San Francisco Neighborhoods',
    url: 'https://raw.githubusercontent.com/codeforgermany/click_that_hood/main/public/data/san-francisco.geojson',
  },
];

interface GeoJsonSheetProps {
  geojson: GeoJSON | null;
  onLoad: (data: GeoJSON) => void;
  onClear: () => void;
  onStatus: (text: string, error?: boolean) => void;
}

export interface GeoJsonSheetRef {
  present: () => void;
}

export const GeoJsonSheet = forwardRef<GeoJsonSheetRef, GeoJsonSheetProps>(
  ({ geojson, onLoad, onClear, onStatus }, ref) => {
    const sheetRef = useRef<TrueSheet>(null);
    const { colors } = useTheme();
    const [url, setUrl] = useState('');
    const [loading, setLoading] = useState(false);

    useImperativeHandle(ref, () => ({
      present: () => sheetRef.current?.present(),
    }));

    const load = async (targetUrl: string) => {
      if (!targetUrl.trim()) return;
      setLoading(true);
      onStatus('Loading GeoJSON...');
      try {
        const res = await fetch(targetUrl.trim());
        const data = await res.json();
        onLoad(data);
        onStatus('GeoJSON loaded');
        sheetRef.current?.dismiss();
      } catch (e: any) {
        onStatus(`GeoJSON: ${e.message}`, true);
      } finally {
        setLoading(false);
      }
    };

    return (
      <TrueSheet ref={sheetRef} detents={['auto']} style={styles.sheet}>
        <ThemedText variant="title">Load GeoJSON</ThemedText>
        <TextInput
          style={[
            styles.urlInput,
            {
              borderColor: colors.border,
              backgroundColor: colors.inputBackground,
              color: colors.inputText,
            },
          ]}
          placeholder="Enter GeoJSON URL..."
          placeholderTextColor={colors.placeholder}
          value={url}
          onChangeText={setUrl}
          autoCapitalize="none"
          autoCorrect={false}
          keyboardType="url"
        />
        <Button
          title={loading ? 'Loading...' : 'Fetch'}
          onPress={() => load(url)}
          disabled={loading || !url.trim()}
        />
        <ThemedText variant="caption">Presets</ThemedText>
        {GEOJSON_PRESETS.map((preset) => (
          <Button
            key={preset.name}
            title={preset.name}
            onPress={() => {
              setUrl(preset.url);
              load(preset.url);
            }}
            disabled={loading}
          />
        ))}
        {geojson && (
          <Button
            title="Clear GeoJSON"
            onPress={() => {
              onClear();
              setUrl('');
              sheetRef.current?.dismiss();
            }}
          />
        )}
      </TrueSheet>
    );
  }
);

const styles = StyleSheet.create({
  sheet: {
    padding: sizes.xl,
    gap: sizes.md,
  },
  urlInput: {
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: sizes.radiusMd,
    padding: sizes.md,
    fontSize: sizes.fontBase,
  },
});
