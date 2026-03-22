import { useRef, useState, useCallback } from 'react';
import type { Coordinate } from '@lugg/maps';
import { randomFrom, randomLetter } from '../utils';
import {
  MARKER_COLORS,
  AVATAR_URLS,
  MARKER_TYPES,
  INITIAL_MARKERS,
} from '../markers';

export const useMarkers = () => {
  const [markers, setMarkers] = useState(INITIAL_MARKERS);
  const lastCoordinate = useRef<Coordinate>({
    latitude: 37.78,
    longitude: -122.43,
  });

  const updateLastCoordinate = useCallback((coordinate: Coordinate) => {
    lastCoordinate.current = coordinate;
  }, []);

  const addMarker = useCallback(
    (coordinate: Coordinate = lastCoordinate.current) => {
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
    },
    []
  );

  const removeRandom = useCallback(() => {
    setMarkers((prev) =>
      prev.filter((_, i) => i !== Math.floor(Math.random() * prev.length))
    );
  }, []);

  const clear = useCallback(() => setMarkers([]), []);

  return {
    markers,
    addMarker,
    removeRandom,
    clear,
    updateLastCoordinate,
  };
};
