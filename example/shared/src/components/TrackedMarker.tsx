import { useEffect, useState } from 'react';
import { Platform } from 'react-native';
import { Marker, type Coordinate } from '@lugg/maps';
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

interface Fix {
  coordinate: Coordinate;
  course: number;
}

// Simulates a GPS fix: where the vehicle is on its route, with noise, and its
// course
const sampleFix = (route: Coordinate[], elapsed: number): Fix => {
  const progress = (elapsed / SEGMENT_DURATION) % (route.length - 1);
  const index = Math.floor(progress);
  const from = route[index]!;
  const to = route[index + 1]!;
  const f = progress - index;
  return {
    coordinate: {
      latitude:
        from.latitude +
        (to.latitude - from.latitude) * f +
        (Math.random() - 0.5) * NOISE_DEGREES,
      longitude:
        from.longitude +
        (to.longitude - from.longitude) * f +
        (Math.random() - 0.5) * NOISE_DEGREES,
    },
    course: getRhumbLineBearing(from, to),
  };
};

/**
 * Live tracking: each GPS fix is the marker's new `coordinate`, and
 * `transitionDuration` glides it there natively until the next fix arrives.
 */
export const TrackedMarker = ({ route }: TrackedMarkerProps) => {
  const [fix, setFix] = useState<Fix | null>(null);

  useEffect(() => {
    if (route.length < 2) return;
    const start = Date.now();
    const receiveFix = () => setFix(sampleFix(route, Date.now() - start));
    receiveFix();
    const interval = setInterval(receiveFix, FIX_INTERVAL);
    return () => clearInterval(interval);
  }, [route]);

  if (!fix) return null;

  return (
    <Marker
      coordinate={fix.coordinate}
      rotate={fix.course}
      transitionDuration={FIX_INTERVAL}
      anchor={ANCHOR}
      rasterize={Platform.OS !== 'web'}
      zIndex={1}
    >
      <PickupIcon loaded />
    </Marker>
  );
};
