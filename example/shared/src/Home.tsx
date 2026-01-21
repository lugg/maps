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
  type MapProvider,
  type EdgeInsets,
  type CameraEventPayload,
} from '@lugg/maps';
import {
  TrueSheet,
  type DidPresentEvent,
} from '@lodev09/react-native-true-sheet';

import { Button, Map } from './components';
import { randomFrom, randomLetter } from './utils';
import {
  MARKER_COLORS,
  AVATAR_URLS,
  MARKER_TYPES,
  INITIAL_MARKERS,
} from './markers';
import { useLocationPermission } from './useLocationPermission';

export function Home() {
  const mapRef = useRef<MapView>(null);
  const sheetRef = useRef<TrueSheet>(null);
  const { height: screenHeight } = useWindowDimensions();
  const locationPermission = useLocationPermission();
  const [provider, setProvider] = useState<MapProvider>('google');
  const [showMap, setShowMap] = useState(true);
  const [markers, setMarkers] = useState(INITIAL_MARKERS);
  const [mapPadding, setMapPadding] = useState<EdgeInsets>();
  const [cameraPosition, setCameraPosition] = useState<CameraEventPayload>();
  const [isIdle, setIsIdle] = useState(true);

  const handleCameraMove = useCallback(
    (event: { nativeEvent: CameraEventPayload }) => {
      setCameraPosition(event.nativeEvent);
      setIsIdle(false);
    },
    []
  );

  const handleCameraIdle = useCallback(
    (event: { nativeEvent: CameraEventPayload }) => {
      setCameraPosition(event.nativeEvent);
      setIsIdle(true);
    },
    []
  );

  const handleSheetPresent = useCallback(
    (event: DidPresentEvent) => {
      const sheetHeight = screenHeight - event.nativeEvent.position;
      setMapPadding({ top: 0, left: 0, bottom: sheetHeight, right: 0 });
    },
    [screenHeight]
  );

  const handleMapReady = useCallback(() => {
    sheetRef.current?.present();
  }, []);

  const addRandomMarker = () => {
    const type = randomFrom(MARKER_TYPES);
    const id = Date.now().toString();

    setMarkers((prev) => [
      ...prev,
      {
        id,
        name: `marker-${id}`,
        coordinate: {
          latitude: 37.77 + Math.random() * 0.03,
          longitude: -122.45 + Math.random() * 0.05,
        },
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
    mapRef.current?.moveCamera(marker.coordinate, {
      zoom: 12 + Math.random() * 4,
    });
  };

  const fitAllMarkers = () => {
    const coordinates = markers.map((m) => m.coordinate);
    mapRef.current?.fitCoordinates(coordinates, { padding: 40 });
  };

  return (
    <View style={styles.container}>
      {showMap && (
        <Map
          ref={mapRef}
          provider={provider}
          markers={markers}
          padding={mapPadding}
          userLocationEnabled={locationPermission}
          onReady={handleMapReady}
          onCameraMove={handleCameraMove}
          onCameraIdle={handleCameraIdle}
        />
      )}

      <TrueSheet
        ref={sheetRef}
        detents={['auto']}
        dimmed={false}
        backgroundBlur="system-material-light"
        dismissible={false}
        grabber={false}
        onDidPresent={handleSheetPresent}
      >
        {cameraPosition && (
          <Text style={styles.positionText}>
            {cameraPosition.coordinate.latitude.toFixed(5)},{' '}
            {cameraPosition.coordinate.longitude.toFixed(5)} (z
            {cameraPosition.zoom.toFixed(1)})
            {isIdle ? ' (idle)' : cameraPosition.gesture ? ' (gesture)' : ''}
          </Text>
        )}
        <View style={styles.sheetContent}>
          <Button title="Add Marker" onPress={addRandomMarker} />
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
            disabled={Platform.OS === 'android'}
            onPress={() =>
              setProvider((p) => (p === 'google' ? 'apple' : 'google'))
            }
          />
        </View>
      </TrueSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  positionText: {
    paddingHorizontal: 16,
    paddingTop: 16,
    fontSize: 14,
    color: '#666',
  },
  sheetContent: {
    padding: 16,
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
});
