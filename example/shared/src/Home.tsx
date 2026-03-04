import { useRef, useState, useCallback } from 'react';
import {
  StyleSheet,
  View,
  Text,
  Platform,
  useWindowDimensions,
} from 'react-native';
import {
  MapView,
  MapProvider,
  type MapProviderType,
  type MapCameraEvent,
  type MapPressEvent,
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

import { Button, Map } from './components';
import { randomFrom, randomLetter } from './utils';
import {
  MARKER_COLORS,
  AVATAR_URLS,
  MARKER_TYPES,
  INITIAL_MARKERS,
} from './markers';
import { useLocationPermission } from './useLocationPermission';

const bottomEdgeInsets = (bottom: number) => ({
  top: 0,
  left: 0,
  bottom,
  right: 0,
});

export function Home() {
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
}

function HomeContent() {
  const mapRef = useRef<MapView>(null);
  const sheetRef = useRef<TrueSheet>(null);
  const { height: screenHeight } = useWindowDimensions();
  const locationPermission = useLocationPermission();
  const { animatedPosition } = useReanimatedTrueSheet();
  const [provider, setProvider] = useState<MapProviderType>('apple');
  const [showMap, setShowMap] = useState(true);
  const [markers, setMarkers] = useState(INITIAL_MARKERS);
  const [statusText, setStatusText] = useState('Loading...');
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
      setStatusText(`${label}: ${lat}, ${lng} (${px}, ${py})`);
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
      setStatusText(pos + suffix);
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

  return (
    <View style={styles.container}>
      {showMap && (
        <Map
          key={provider}
          ref={mapRef}
          provider={provider}
          markers={markers}
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
            setStatusText('Polygon pressed');
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
        <Text style={styles.statusText}>{statusText}</Text>
        <View style={styles.sheetContent}>
          <Button title="Add Marker" onPress={() => addMarker()} />
          <Button
            title={`Remove Marker (${markers.length})`}
            onPress={removeRandomMarker}
            disabled={markers.length === 0}
          />
          <Button
            title="Clear Markers"
            onPress={() => setMarkers([])}
            disabled={markers.length === 0}
          />
          <Button title="Move Camera" onPress={moveToRandomMarker} />
          <Button
            title="Fit Markers"
            onPress={fitAllMarkers}
            disabled={markers.length === 0}
          />
          <Button
            title={showMap ? 'Hide Map' : 'Show Map'}
            onPress={() => setShowMap((prev) => !prev)}
          />
          <Button
            title={provider === 'google' ? 'Apple Maps' : 'Google Maps'}
            disabled={Platform.OS !== 'ios'}
            onPress={() =>
              setProvider((p) => (p === 'google' ? 'apple' : 'google'))
            }
          />
        </View>
      </ReanimatedTrueSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  statusText: {
    fontSize: 14,
    color: '#666',
  },
  sheet: {
    padding: 24,
    gap: 12,
  },
  sheetContent: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
});
