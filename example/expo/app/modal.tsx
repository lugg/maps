import { useRef } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { MapProvider, MapView, Polyline } from '@lugg/maps';
import { Button, PLACES, PlaceMarkers } from '@lugg/shared-example';

// Golden Gate Bridge, Alcatraz, Coit Tower, Ferry Building, Twin Peaks,
// Golden Gate Park
const TOUR = [0, 1, 4, 2, 5, 3].map((i) => PLACES[i]!);
const TOUR_COORDINATES = TOUR.map((place) => place.coordinate);

// Cold start into `lugg-maps-expo://modal` to mount the home map underneath
export default function ModalScreen() {
  const router = useRouter();
  const mapRef = useRef<MapView>(null);
  const { top, bottom } = useSafeAreaInsets();
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  const handleReady = () => {
    mapRef.current?.fitCoordinates(TOUR_COORDINATES, {
      padding: { top: top + 48, left: 48, right: 48, bottom: bottom + 96 },
      duration: 0,
    });
  };

  return (
    <View style={styles.container}>
      <MapProvider apiKey={apiKey}>
        <MapView
          ref={mapRef}
          provider={Platform.OS === 'ios' ? 'apple' : 'google'}
          style={StyleSheet.absoluteFill}
          initialCoordinate={TOUR_COORDINATES[0]}
          initialZoom={12}
          onReady={handleReady}
        >
          <Polyline
            coordinates={TOUR_COORDINATES}
            strokeColors={['#B0B0B0']}
            strokeWidth={6}
          />
          <Polyline
            coordinates={TOUR_COORDINATES}
            strokeColors={['#0a4da0', '#4da6ff']}
            strokeWidth={6}
            animatedOptions={{
              easing: 'easeInOut',
              delay: 1200,
              duration: 1500,
            }}
            animated
          />
          {TOUR.map((place) => (
            <PlaceMarkers key={place.id} place={place} />
          ))}
        </MapView>
      </MapProvider>
      <Button
        title="Close"
        style={{ ...styles.close, bottom: bottom + 24 }}
        onPress={() => router.back()}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  close: {
    position: 'absolute',
    alignSelf: 'center',
  },
});
