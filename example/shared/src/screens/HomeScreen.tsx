import { useRef, useState, useCallback } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  MapProvider,
  type MapProviderType,
  type MapType,
  type MapCameraEvent,
  type MapPressEvent,
  type MarkerPressEvent,
  type MarkerDragEvent,
  type GeoJSON,
} from '@lugg/maps';
import {
  TrueSheetProvider,
  type DetentChangeEvent,
} from '@lodev09/react-native-true-sheet';
import { ReanimatedTrueSheetProvider } from '@lodev09/react-native-true-sheet/reanimated';

import { Map, type MapRef, type MarkerData, MapTypeButton } from '../components';
import { useLocationPermission, useMarkers } from '../hooks';
import { randomFrom } from '../utils';
import {
  ControlSheet,
  type ControlSheetRef,
  MapTypeSheet,
  type MapTypeSheetRef,
  GeoJsonSheet,
  type GeoJsonSheetRef,
} from '../sheets';

const bottomEdgeInsets = (bottom: number) => ({
  top: 0,
  left: 0,
  bottom,
  right: 0,
});

interface HomeProps {
  onMarkerPress?: (e: MarkerPressEvent, marker: MarkerData) => void;
}

export const HomeScreen = ({ onMarkerPress }: HomeProps) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  return (
    <TrueSheetProvider>
      <ReanimatedTrueSheetProvider>
        <MapProvider apiKey={apiKey}>
          <HomeContent onMarkerPress={onMarkerPress} />
        </MapProvider>
      </ReanimatedTrueSheetProvider>
    </TrueSheetProvider>
  );
};

const HomeContent = ({ onMarkerPress: onMarkerPressProp }: HomeProps) => {
  const mapRef = useRef<MapRef>(null);
  const controlSheetRef = useRef<ControlSheetRef>(null);
  const mapTypeSheetRef = useRef<MapTypeSheetRef>(null);
  const geojsonSheetRef = useRef<GeoJsonSheetRef>(null);
  const { height: screenHeight } = useWindowDimensions();
  const locationPermission = useLocationPermission();
  const { markers, addMarker, removeRandom, clear, updateLastCoordinate } =
    useMarkers();

  const [provider, setProvider] = useState<MapProviderType>('apple');
  const [mapType, setMapType] = useState<MapType>('standard');
  const [showMap, setShowMap] = useState(true);
  const [status, setStatus] = useState({ text: 'Loading...', error: false });
  const [geojson, setGeojson] = useState<GeoJSON | null>(null);
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
    const position = controlSheetRef.current?.animatedPosition;
    if (!position) return;
    const bottom = screenHeight - position.value;
    if (bottom > 0) {
      mapRef.current?.setEdgeInsets(bottomEdgeInsets(bottom));
    }
  }, [screenHeight]);

  const handleSheetEvent = useCallback(
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
      updateLastCoordinate(coordinate);
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
    [updateLastCoordinate]
  );

  const setStatusText = useCallback((text: string, error = false) => {
    setStatus({ text, error });
  }, []);

  const handleOverlayPress = useCallback(
    (label: string) => {
      lockStatus();
      setStatus({ text: `${label} pressed`, error: false });
    },
    [lockStatus]
  );

  const moveToRandomMarker = () => {
    if (markers.length === 0) return;
    const marker = randomFrom(markers);
    mapRef.current?.moveCamera(marker.coordinate);
    mapRef.current?.showMarkerCallout(marker.id);
  };

  const fitAllMarkers = () => {
    mapRef.current?.fitCoordinates(
      markers.map((m) => m.coordinate),
      { padding: { top: 60, left: 40, right: 40, bottom: 40 } }
    );
  };

  const handlePress = useCallback(
    (e: MapPressEvent) => formatPressEvent(e, 'Press'),
    [formatPressEvent]
  );

  const handleLongPress = useCallback(
    (e: MapPressEvent) => {
      formatPressEvent(e, 'Long press');
      addMarker(e.nativeEvent.coordinate);
    },
    [formatPressEvent, addMarker]
  );

  const handleCameraMove = useCallback(
    (e: MapCameraEvent) => formatCameraEvent(e, false),
    [formatCameraEvent]
  );

  const handleCameraIdle = useCallback(
    (e: MapCameraEvent) => formatCameraEvent(e, true),
    [formatCameraEvent]
  );

  const handleMarkerPress = useCallback(
    (e: MarkerPressEvent, m: MarkerData) => {
      formatPressEvent(e, `Marker(${m.name})`);
      if (m.type === 'navigate') {
        onMarkerPressProp?.(e, m);
      }
    },
    [formatPressEvent, onMarkerPressProp]
  );

  const handleMarkerDragStart = useCallback(
    (e: MarkerDragEvent, m: MarkerData) =>
      formatPressEvent(e, `Drag start(${m.name})`),
    [formatPressEvent]
  );

  const handleMarkerDragChange = useCallback(
    (e: MarkerDragEvent, m: MarkerData) =>
      formatPressEvent(e, `Dragging(${m.name})`),
    [formatPressEvent]
  );

  const handleMarkerDragEnd = useCallback(
    (e: MarkerDragEvent, m: MarkerData) =>
      formatPressEvent(e, `Drag end(${m.name})`),
    [formatPressEvent]
  );

  const handlePolygonPress = useCallback(
    () => handleOverlayPress('Polygon'),
    [handleOverlayPress]
  );

  const handleCirclePress = useCallback(
    () => handleOverlayPress('Circle'),
    [handleOverlayPress]
  );

  const handleGroundOverlayPress = useCallback(
    () => handleOverlayPress('Ground overlay'),
    [handleOverlayPress]
  );

  return (
    <View style={styles.container}>
      {showMap && (
        <Map
          key={provider}
          ref={mapRef}
          provider={provider}
          mapType={mapType}
          markers={markers}
          geojson={geojson}
          animatedPosition={controlSheetRef.current?.animatedPosition}
          userLocationEnabled={locationPermission}
          onReady={handleMapReady}
          onPress={handlePress}
          onLongPress={handleLongPress}
          onCameraMove={handleCameraMove}
          onCameraIdle={handleCameraIdle}
          onMarkerPress={handleMarkerPress}
          onMarkerDragStart={handleMarkerDragStart}
          onMarkerDragChange={handleMarkerDragChange}
          onMarkerDragEnd={handleMarkerDragEnd}
          onPolygonPress={handlePolygonPress}
          onCirclePress={handleCirclePress}
          onGroundOverlayPress={handleGroundOverlayPress}
        />
      )}

      <MapTypeButton onPress={() => mapTypeSheetRef.current?.present()} />

      <ControlSheet
        ref={controlSheetRef}
        status={status}
        markerCount={markers.length}
        showMap={showMap}
        provider={provider}
        hasGeojson={!!geojson}
        onAddMarker={() => addMarker()}
        onRemoveMarker={removeRandom}
        onClearMarkers={clear}
        onMoveCamera={moveToRandomMarker}
        onFitMarkers={fitAllMarkers}
        onToggleMap={() => setShowMap((prev) => !prev)}
        onToggleProvider={() =>
          setProvider((p) => (p === 'google' ? 'apple' : 'google'))
        }
        onLoadGeojson={() => geojsonSheetRef.current?.present()}
        onDidPresent={handleSheetEvent}
        onDetentChange={handleSheetEvent}
      />

      <MapTypeSheet
        ref={mapTypeSheetRef}
        mapType={mapType}
        onSelect={setMapType}
      />

      <GeoJsonSheet
        ref={geojsonSheetRef}
        geojson={geojson}
        onLoad={(data) => setGeojson(data)}
        onClear={() => setGeojson(null)}
        onStatus={(text, error) => {
          lockStatus();
          setStatusText(text, error);
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1 },
});
