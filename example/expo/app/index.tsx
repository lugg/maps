import { useCallback } from 'react';
import { useRouter } from 'expo-router';
import type { MarkerPressEvent } from '@lugg/maps';
import { HomeScreen, type MarkerData } from '@lugg/shared-example';

export default function MapScreen() {
  const router = useRouter();

  const handleMarkerPress = useCallback(
    (_e: MarkerPressEvent, marker: MarkerData) => {
      router.push({ pathname: '/detail', params: { name: marker.name } });
    },
    [router]
  );

  return <HomeScreen onMarkerPress={handleMarkerPress} />;
}
