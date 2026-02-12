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
  const [cameraPosition, setCameraPosition] = useState<CameraEventPayload>();
  const [isIdle, setIsIdle] = useState(true);

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

  const handleCameraEvent = useCallback(
    (event: { nativeEvent: CameraEventPayload }, idle: boolean) => {
      setCameraPosition(event.nativeEvent);
      setIsIdle(idle);
    },
    []
  );

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
          onCameraMove={(e) => handleCameraEvent(e, false)}
          onCameraIdle={(e) => handleCameraEvent(e, true)}
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
        <Text style={styles.positionText}>
          {cameraPosition ? (
            <>
              {cameraPosition.coordinate.latitude.toFixed(5)},{' '}
              {cameraPosition.coordinate.longitude.toFixed(5)} (z
              {cameraPosition.zoom.toFixed(1)})
              {isIdle
                ? ` (idle${cameraPosition.gesture ? ', gesture' : ''})`
                : cameraPosition.gesture
                ? ' (gesture)'
                : ''}
            </>
          ) : (
            'Loading...'
          )}
        </Text>
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
      </ReanimatedTrueSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  positionText: {
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
