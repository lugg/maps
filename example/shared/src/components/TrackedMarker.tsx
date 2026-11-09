import { useEffect, useMemo, useState } from 'react';
import { Platform } from 'react-native';
import {
  Marker,
  pathPositionAt,
  type Coordinate,
  type MarkerPath,
} from '@lugg/maps';
import { getRhumbLineBearing } from 'geolib';

import { PickupIcon } from './PickupIcon';

const ANCHOR = { x: 0.5, y: 0.5 };
// A GPS fix arrives this often
const FIX_INTERVAL = 3000;
// The tracked vehicle's real pace: milliseconds per route segment
const SEGMENT_DURATION = 6000;
// About 10 m of GPS noise
const NOISE_DEGREES = 0.0001;

interface TrackedMarkerProps {
  route: Coordinate[];
}

/**
 * Live tracking: each GPS fix becomes a short path from where the marker is to
 * the fix, so the marker glides there natively until the next fix arrives.
 */
export const TrackedMarker = ({ route }: TrackedMarkerProps) => {
  // Where the vehicle really is, sampled with noise to simulate fixes
  const actual = useMemo<MarkerPath | null>(
    () =>
      route.length < 2
        ? null
        : {
            coordinates: route,
            times: route.map((_, i) => i * SEGMENT_DURATION),
            startTime: Date.now(),
            loop: true,
          },
    [route]
  );
  const [path, setPath] = useState<MarkerPath | null>(null);

  useEffect(() => {
    if (!actual) return;
    let current: MarkerPath | null = null;

    const receiveFix = () => {
      const now = Date.now();
      const sample = pathPositionAt(actual, now)!.coordinate;
      const fix = {
        latitude: sample.latitude + (Math.random() - 0.5) * NOISE_DEGREES,
        longitude: sample.longitude + (Math.random() - 0.5) * NOISE_DEGREES,
      };
      const from = current ? pathPositionAt(current, now) : null;
      // A fix reports the course too, so turn to it rather than toward the
      // noisy fix
      const course = getRhumbLineBearing(
        sample,
        pathPositionAt(actual, now + 1000)!.coordinate
      );
      current = {
        coordinates: [from?.coordinate ?? fix, fix],
        times: [0, FIX_INTERVAL],
        rotations: [from?.rotation ?? course, course],
        startTime: now,
      };
      setPath(current);
    };

    receiveFix();
    const interval = setInterval(receiveFix, FIX_INTERVAL);
    return () => clearInterval(interval);
  }, [actual]);

  if (!path) return null;

  return (
    <Marker
      coordinate={path.coordinates[0]!}
      path={path}
      anchor={ANCHOR}
      rasterize={Platform.OS !== 'web'}
      zIndex={1}
    >
      <PickupIcon loaded />
    </Marker>
  );
};
