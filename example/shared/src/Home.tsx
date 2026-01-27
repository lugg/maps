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
  type CameraEventPayload,
} from '@lugg/maps';
import {
  TrueSheet,
  TrueSheetProvider,
  type PositionChangeEvent,
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
  const [provider, setProvider] = useState<MapProviderType>('google');
  const [showMap, setShowMap] = useState(true);
  const [markers, setMarkers] = useState(INITIAL_MARKERS);
  const [sheetHeight, setSheetHeight] = useState(0);
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

  const handleSheetPositionChange = useCallback(
    (event: PositionChangeEvent) => {
      setSheetHeight(screenHeight - event.nativeEvent.position);
    },
    [screenHeight]
  );

  const handleMapReady = useCallback(() => {
    sheetRef.current?.present();
  }, []);

  const addMarker = () => {
    if (!cameraPosition) return;

    const type = randomFrom(MARKER_TYPES);
    const id = Date.now().toString();

    setMarkers((prev) => [
      ...prev,
      {
        id,
        name: `marker-${id}`,
        coordinate: cameraPosition.coordinate,
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
      zoom: 14,
    });
  };

  const fitAllMarkers = () => {
    const coordinates = markers.map((m) => m.coordinate);
    mapRef.current?.fitCoordinates(coordinates);
  };

  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  return (
    <TrueSheetProvider>
      <MapProvider apiKey={apiKey}>
        <View style={styles.container}>
          {showMap && (
            <Map
              ref={mapRef}
              provider={provider}
              markers={markers}
              padding={{
                top: 0,
                left: 40,
                right: 40,
                bottom: sheetHeight,
              }}
              userLocationEnabled={locationPermission}
              onReady={handleMapReady}
              onCameraMove={handleCameraMove}
              onCameraIdle={handleCameraIdle}
            />
          )}

          <TrueSheet
            ref={sheetRef}
            detents={['auto', 1]}
            dimmed={false}
            backgroundBlur="system-material-light"
            dismissible={false}
            grabber
            onPositionChange={handleSheetPositionChange}
          >
            {cameraPosition && (
              <Text style={styles.positionText}>
                {cameraPosition.coordinate.latitude.toFixed(5)},{' '}
                {cameraPosition.coordinate.longitude.toFixed(5)} (z
                {cameraPosition.zoom.toFixed(1)})
                {isIdle
                  ? ` (idle${cameraPosition.gesture ? ', gesture' : ''})`
                  : cameraPosition.gesture
                  ? ' (gesture)'
                  : ''}
              </Text>
            )}
            <View style={styles.sheetContent}>
              <Button title="Add Marker" onPress={addMarker} />
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
          </TrueSheet>
        </View>
      </MapProvider>
    </TrueSheetProvider>
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
