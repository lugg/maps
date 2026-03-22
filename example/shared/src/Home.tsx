import { useRef, useState, useCallback } from 'react';
import {
  StyleSheet,
  View,
  TextInput,
  Platform,
  useColorScheme,
  useWindowDimensions,
} from 'react-native';
import {
  MapProvider,
  type MapProviderType,
  type MapCameraEvent,
  type MapPressEvent,
  type GeoJSON,
} from '@lugg/maps';
import {
  TrueSheet,
  TrueSheetProvider,
  type DetentChangeEvent,
} from '@lodev09/react-native-true-sheet';
import {
  ReanimatedTrueSheet,
  ReanimatedTrueSheetProvider,
  useReanimatedTrueSheet,
} from '@lodev09/react-native-true-sheet/reanimated';

import { Button, Map, type MapRef, ThemedText } from './components';
import { randomFrom, randomLetter } from './utils';
import {
  MARKER_COLORS,
  AVATAR_URLS,
  MARKER_TYPES,
  INITIAL_MARKERS,
} from './markers';
import { useLocationPermission } from './useLocationPermission';

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

const bottomEdgeInsets = (bottom: number) => ({
  top: 0,
  left: 0,
  bottom,
  right: 0,
});

export const Home = () => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  return (
    <TrueSheetProvider>
      <ReanimatedTrueSheetProvider>
        <MapProvider apiKey={apiKey}>
          <HomeContent />
        </MapProvider>
      </ReanimatedTrueSheetProvider>
    </TrueSheetProvider>
  );
};

const HomeContent = () => {
  const mapRef = useRef<MapRef>(null);
  const sheetRef = useRef<TrueSheet>(null);
  const geojsonSheetRef = useRef<TrueSheet>(null);
  const { height: screenHeight } = useWindowDimensions();
  const isDark = useColorScheme() === 'dark';
  const locationPermission = useLocationPermission();
  const { animatedPosition } = useReanimatedTrueSheet();
  const [provider, setProvider] = useState<MapProviderType>('apple');
  const [showMap, setShowMap] = useState(true);
  const [markers, setMarkers] = useState(INITIAL_MARKERS);
  const [status, setStatus] = useState({ text: 'Loading...', error: false });
  const [geojson, setGeojson] = useState<GeoJSON | null>(null);
  const [geojsonUrl, setGeojsonUrl] = useState('');
  const [loadingGeojson, setLoadingGeojson] = useState(false);
  const lastCoordinate = useRef({ latitude: 37.78, longitude: -122.43 });
  const statusLockRef = useRef(false);

  const lockStatus = useCallback(() => {
    statusLockRef.current = true;
    setTimeout(() => {
      statusLockRef.current = false;
    }, 1000);
  }, []);

  const getSheetBottom = useCallback(
    (event: DetentChangeEvent) => screenHeight - event.nativeEvent.position,
    [screenHeight]
  );

  const handleMapReady = useCallback(() => {
    const bottom = screenHeight - animatedPosition.value;
    if (bottom > 0) {
      mapRef.current?.setEdgeInsets(bottomEdgeInsets(bottom));
    }
  }, [screenHeight, animatedPosition]);

  const handleSheetPresent = useCallback(
    (event: DetentChangeEvent) => {
      const bottom = getSheetBottom(event);
      mapRef.current?.setEdgeInsets(bottomEdgeInsets(bottom));
    },
    [getSheetBottom]
  );

  const handleDetentChange = useCallback(
    (event: DetentChangeEvent) => {
      const bottom = getSheetBottom(event);
      mapRef.current?.setEdgeInsets(bottomEdgeInsets(bottom));
    },
    [getSheetBottom]
  );

  const formatPressEvent = useCallback(
    (event: MapPressEvent, label: string) => {
      lockStatus();
      const { coordinate, point } = event.nativeEvent;
      const lat = coordinate.latitude.toFixed(5);
      const lng = coordinate.longitude.toFixed(5);
      const px = point.x.toFixed(0);
      const py = point.y.toFixed(0);
      setStatus({
        text: `${label}: ${lat}, ${lng} (${px}, ${py})`,
        error: false,
      });
    },
    [lockStatus]
  );

  const formatCameraEvent = useCallback(
    (event: MapCameraEvent, idle: boolean) => {
      const { coordinate, zoom, gesture } = event.nativeEvent;
      lastCoordinate.current = coordinate;
      if (statusLockRef.current) return;
      const pos = `${coordinate.latitude.toFixed(
        5
      )}, ${coordinate.longitude.toFixed(5)} (z${zoom.toFixed(1)})`;
      const suffix = idle
        ? ` (idle${gesture ? ', gesture' : ''})`
        : gesture
        ? ' (gesture)'
        : '';
      setStatus({ text: pos + suffix, error: false });
    },
    []
  );

  const addMarker = (coordinate = lastCoordinate.current) => {
    const type = randomFrom(MARKER_TYPES);
    const id = Date.now().toString();

    setMarkers((prev) => [
      ...prev,
      {
        id,
        name: `marker-${id}`,
        coordinate,
        type,
        anchor: { x: 0.5, y: type === 'icon' ? 1 : 0.5 },
        text: randomLetter(),
        color: randomFrom(MARKER_COLORS),
        imageUrl: randomFrom(AVATAR_URLS),
      },
    ]);
  };

  const removeRandomMarker = () => {
    if (markers.length === 0) return;
    setMarkers((prev) =>
      prev.filter((_, i) => i !== Math.floor(Math.random() * prev.length))
    );
  };

  const moveToRandomMarker = () => {
    if (markers.length === 0) return;
    const marker = randomFrom(markers);
    mapRef.current?.moveCamera(marker.coordinate);
    mapRef.current?.showMarkerCallout(marker.id);
  };

  const fitAllMarkers = () => {
    const coordinates = markers.map((m) => m.coordinate);
    mapRef.current?.fitCoordinates(coordinates, {
      padding: {
        top: 60,
        left: 40,
        right: 40,
        bottom: 40,
      },
    });
  };

  const loadGeojson = async (url: string) => {
    if (!url.trim()) return;
    setLoadingGeojson(true);
    lockStatus();
    setStatus({ text: 'Loading GeoJSON...', error: false });
    try {
      const res = await fetch(url.trim());
      const data = await res.json();
      setGeojson(data);
      setStatus({ text: 'GeoJSON loaded', error: false });
      geojsonSheetRef.current?.dismiss();
    } catch (e: any) {
      setStatus({ text: `GeoJSON: ${e.message}`, error: true });
    } finally {
      setLoadingGeojson(false);
    }
  };

  return (
    <View style={styles.container}>
      {showMap && (
        <Map
          key={provider}
          ref={mapRef}
          provider={provider}
          markers={markers}
          geojson={geojson}
          animatedPosition={animatedPosition}
          userLocationEnabled={locationPermission}
          onReady={handleMapReady}
          onPress={(e) => formatPressEvent(e, 'Press')}
          onLongPress={(e) => {
            formatPressEvent(e, 'Long press');
            addMarker(e.nativeEvent.coordinate);
          }}
          onCameraMove={(e) => formatCameraEvent(e, false)}
          onCameraIdle={(e) => formatCameraEvent(e, true)}
          onMarkerPress={(e, m) => formatPressEvent(e, `Marker(${m.name})`)}
          onMarkerDragStart={(e, m) =>
            formatPressEvent(e, `Drag start(${m.name})`)
          }
          onMarkerDragChange={(e, m) =>
            formatPressEvent(e, `Dragging(${m.name})`)
          }
          onMarkerDragEnd={(e, m) => formatPressEvent(e, `Drag end(${m.name})`)}
          onPolygonPress={() => {
            lockStatus();
            setStatus({ text: 'Polygon pressed', error: false });
          }}
          onCirclePress={() => {
            lockStatus();
            setStatus({ text: 'Circle pressed', error: false });
          }}
          onGroundOverlayPress={() => {
            lockStatus();
            setStatus({ text: 'Ground overlay pressed', error: false });
          }}
        />
      )}

      <ReanimatedTrueSheet
        ref={sheetRef}
        detents={['auto', 0.5]}
        style={styles.sheet}
        dimmed={false}
        dismissible={false}
        initialDetentIndex={0}
        anchor="left"
        maxContentWidth={500}
        onDidPresent={handleSheetPresent}
        onDetentChange={handleDetentChange}
      >
        <ThemedText
          style={[styles.statusText, status.error && styles.statusError]}
        >
          {status.text}
        </ThemedText>
        <View style={styles.sheetContent}>
          <Button
            style={styles.sheetButton}
            title="Add Marker"
            onPress={() => addMarker()}
          />
          <Button
            style={styles.sheetButton}
            title={`Remove Marker (${markers.length})`}
            onPress={removeRandomMarker}
            disabled={markers.length === 0}
          />
          <Button
            style={styles.sheetButton}
            title="Clear Markers"
            onPress={() => setMarkers([])}
            disabled={markers.length === 0}
          />
          <Button
            style={styles.sheetButton}
            title="Move Camera"
            onPress={moveToRandomMarker}
          />
          <Button
            style={styles.sheetButton}
            title="Fit Markers"
            onPress={fitAllMarkers}
            disabled={markers.length === 0}
          />
          <Button
            style={styles.sheetButton}
            title={showMap ? 'Hide Map' : 'Show Map'}
            onPress={() => setShowMap((prev) => !prev)}
          />
          <Button
            style={styles.sheetButton}
            title={provider === 'google' ? 'Apple Maps' : 'Google Maps'}
            disabled={Platform.OS !== 'ios'}
            onPress={() =>
              setProvider((p) => (p === 'google' ? 'apple' : 'google'))
            }
          />
          <Button
            style={styles.sheetButton}
            title={geojson ? 'GeoJSON (loaded)' : 'Load GeoJSON'}
            onPress={() => geojsonSheetRef.current?.present()}
          />
        </View>
      </ReanimatedTrueSheet>

      <TrueSheet
        ref={geojsonSheetRef}
        detents={['auto']}
        style={styles.geojsonSheet}
      >
        <ThemedText variant="title">Load GeoJSON</ThemedText>
        <TextInput
          style={[styles.urlInput, isDark && styles.urlInputDark]}
          placeholder="Enter GeoJSON URL..."
          placeholderTextColor={isDark ? '#666' : '#999'}
          value={geojsonUrl}
          onChangeText={setGeojsonUrl}
          autoCapitalize="none"
          autoCorrect={false}
          keyboardType="url"
        />
        <Button
          title={loadingGeojson ? 'Loading...' : 'Fetch'}
          onPress={() => loadGeojson(geojsonUrl)}
          disabled={loadingGeojson || !geojsonUrl.trim()}
        />
        <ThemedText variant="caption">Presets</ThemedText>
        {GEOJSON_PRESETS.map((preset) => (
          <Button
            key={preset.name}
            title={preset.name}
            onPress={() => {
              setGeojsonUrl(preset.url);
              loadGeojson(preset.url);
            }}
            disabled={loadingGeojson}
          />
        ))}
        {geojson && (
          <Button
            title="Clear GeoJSON"
            onPress={() => {
              setGeojson(null);
              setGeojsonUrl('');
              geojsonSheetRef.current?.dismiss();
            }}
          />
        )}
      </TrueSheet>
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1 },
  statusText: {
    color: '#666',
  },
  statusError: {
    color: '#D32F2F',
  },
  sheet: {
    padding: 24,
    gap: 12,
  },
  sheetContent: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  sheetButton: {
    flex: 1,
    minWidth: '45%',
  },
  geojsonSheet: {
    padding: 24,
    gap: 12,
  },
  urlInput: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#DDD',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    backgroundColor: '#FFF',
    color: '#000',
  },
  urlInputDark: {
    backgroundColor: '#1C1C1E',
    borderColor: '#333',
    color: '#FFF',
  },
});
