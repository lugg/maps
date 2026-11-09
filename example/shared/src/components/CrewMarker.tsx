import { useEffect, useMemo, useRef } from 'react';
import { Platform } from 'react-native';
import {
  Marker,
  pathPositionAt,
  type Coordinate,
  type MarkerPath,
} from '@lugg/maps';
import Animated, {
  Easing,
  useAnimatedProps,
  useDerivedValue,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { getRhumbLineBearing } from 'geolib';

import { PickupIcon } from './PickupIcon';

const AnimatedMarker = Animated.createAnimatedComponent(Marker);

const DEFAULT_ANCHOR = { x: 0.5, y: 0.5 };
const SEGMENT_DURATION = 2000;
// How long the truck takes to turn onto the next segment
const TURN_DURATION = 300;

/**
 * `path` hands the route to native code as keyframes. `reanimated` animates
 * the marker from Reanimated every frame, the way apps do without `path`.
 */
export type CrewMotion = 'path' | 'reanimated';

interface CrewMarkerProps {
  route: Coordinate[];
  loaded?: boolean;
  speed?: number;
  zoom?: number;
  motion?: CrewMotion;
  /** Fraction of the route to start at, so a fleet can spread out */
  phase?: number;
  onSegment?: (index: number) => void;
}

const getBearing = (from: Coordinate, to: Coordinate, currentBearing = 0) => {
  // getRhumbLineBearing returns 0° = North, 90° = East, etc.
  let newBearing = getRhumbLineBearing(from, to);

  // Normalize bearing difference to avoid spinning the wrong way
  while (newBearing - currentBearing > 180) {
    newBearing -= 360;
  }
  while (newBearing - currentBearing < -180) {
    newBearing += 360;
  }

  return newBearing;
};

const BASE_ZOOM = 14;
const MIN_SCALE = 0.5;
const MAX_SCALE = 1.5;
const SCALE_MIN_ZOOM = 10;
const SCALE_MAX_ZOOM = 18;

const getScaleForZoom = (zoom: number) => {
  'worklet';
  if (zoom <= SCALE_MIN_ZOOM) return MIN_SCALE;
  if (zoom >= SCALE_MAX_ZOOM) return MAX_SCALE;
  const t = (zoom - SCALE_MIN_ZOOM) / (SCALE_MAX_ZOOM - SCALE_MIN_ZOOM);
  return MIN_SCALE + t * (MAX_SCALE - MIN_SCALE);
};

const useZoomScale = (zoom: number) => {
  const scale = useSharedValue(getScaleForZoom(zoom));
  useEffect(() => {
    scale.value = withTiming(getScaleForZoom(zoom), { duration: 200 });
  }, [zoom, scale]);
  return scale;
};

// Two keyframes per segment: the start, and a point TURN_DURATION in where the
// truck has turned onto the segment's bearing. Native code interpolates the
// rest, so JS only runs for `onSegment`, once per segment.
const createCrewPath = (
  route: Coordinate[],
  speed: number,
  phase: number
): MarkerPath | null => {
  if (route.length < 2) return null;

  const segment = SEGMENT_DURATION / speed;
  const turn = Math.min(TURN_DURATION, segment / 2) / segment;
  const coordinates: Coordinate[] = [];
  const times: number[] = [];
  const rotations: number[] = [];
  let bearing = getRhumbLineBearing(route[0]!, route[1]!);

  for (let i = 0; i < route.length - 1; i++) {
    const from = route[i]!;
    const to = route[i + 1]!;
    const next = getRhumbLineBearing(from, to);
    coordinates.push(from, {
      latitude: from.latitude + (to.latitude - from.latitude) * turn,
      longitude: from.longitude + (to.longitude - from.longitude) * turn,
    });
    times.push(i * segment, (i + turn) * segment);
    rotations.push(bearing, next);
    bearing = next;
  }
  coordinates.push(route[route.length - 1]!);
  times.push((route.length - 1) * segment);
  rotations.push(bearing);

  const lap = times[times.length - 1]!;
  return {
    coordinates,
    times,
    rotations,
    startTime: Date.now() - phase * lap,
    loop: true,
  };
};

export const CrewMarker = ({ motion = 'path', ...props }: CrewMarkerProps) =>
  motion === 'path' ? (
    <PathCrewMarker {...props} />
  ) : (
    <ReanimatedCrewMarker {...props} />
  );

const PathCrewMarker = ({
  route,
  loaded = false,
  speed = 1,
  zoom = BASE_ZOOM,
  phase = 0,
  onSegment,
}: Omit<CrewMarkerProps, 'motion'>) => {
  const onSegmentRef = useRef(onSegment);
  onSegmentRef.current = onSegment;
  const scaleValue = useZoomScale(zoom);
  const path = useMemo(
    () => createCrewPath(route, speed, phase),
    [route, speed, phase]
  );

  const animatedProps = useAnimatedProps(() => ({
    scale: scaleValue.value,
  }));

  // The path is a function of the clock, so a timer at each segment boundary
  // is enough to report progress
  const hasOnSegment = !!onSegment;
  useEffect(() => {
    if (!path || !hasOnSegment) return;
    const segment = SEGMENT_DURATION / speed;
    let timer: ReturnType<typeof setTimeout>;
    const tick = () => {
      const now = Date.now();
      const position = pathPositionAt(path, now);
      if (position) onSegmentRef.current?.(Math.floor(position.index / 2));
      timer = setTimeout(
        tick,
        segment - ((now - path.startTime) % segment) + 1
      );
    };
    tick();
    return () => clearTimeout(timer);
  }, [path, speed, hasOnSegment]);

  if (!path || !route[0]) return null;

  return (
    <AnimatedMarker
      coordinate={route[0]}
      path={path}
      anchor={DEFAULT_ANCHOR}
      rasterize={Platform.OS !== 'web'}
      animatedProps={animatedProps}
    >
      <PickupIcon loaded={loaded} />
    </AnimatedMarker>
  );
};

const ReanimatedCrewMarker = ({
  route,
  loaded = false,
  speed = 1,
  zoom = BASE_ZOOM,
  phase = 0,
  onSegment,
}: Omit<CrewMarkerProps, 'motion'>) => {
  const onSegmentRef = useRef(onSegment);
  onSegmentRef.current = onSegment;
  const latitude = useSharedValue(route[0]?.latitude ?? 0);
  const longitude = useSharedValue(route[0]?.longitude ?? 0);
  const bearingValue = useSharedValue(0);
  const scaleValue = useZoomScale(zoom);
  const currentBearingRef = useRef(0);
  const segmentIndexRef = useRef(0);
  const animationRef = useRef<NodeJS.Timeout | null>(null);

  const zIndex = useDerivedValue(() => {
    return Math.round((90 - latitude.value) * 10000);
  });

  const animatedProps = useAnimatedProps(() => ({
    coordinate: {
      latitude: latitude.value,
      longitude: longitude.value,
    },
    zIndex: zIndex.value,
    rotate: bearingValue.value,
    scale: scaleValue.value,
  }));

  const zoomRef = useRef(zoom);
  zoomRef.current = zoom;

  useEffect(() => {
    if (route.length < 2) return;

    const startIndex = Math.min(
      route.length - 2,
      Math.floor(phase * (route.length - 1))
    );
    segmentIndexRef.current = startIndex;
    latitude.value = route[startIndex]!.latitude;
    longitude.value = route[startIndex]!.longitude;

    const animateSegment = (index: number) => {
      if (index >= route.length - 1) {
        segmentIndexRef.current = 0;
        animateSegment(0);
        return;
      }

      onSegmentRef.current?.(index);

      const from = route[index]!;
      const to = route[index + 1]!;

      const newBearing = getBearing(from, to, currentBearingRef.current);
      currentBearingRef.current = newBearing;
      bearingValue.value = withTiming(newBearing, {
        duration: 300,
        easing: Easing.out(Easing.ease),
      });

      const duration = SEGMENT_DURATION / speed;

      latitude.value = withTiming(to.latitude, { duration });
      longitude.value = withTiming(to.longitude, { duration });

      animationRef.current = setTimeout(() => {
        segmentIndexRef.current = index + 1;
        animateSegment(index + 1);
      }, duration);
    };

    animateSegment(startIndex);

    return () => {
      if (animationRef.current) {
        clearTimeout(animationRef.current);
      }
    };
  }, [route, speed, phase, bearingValue, latitude, longitude]);

  if (!route[0]) return null;

  return (
    <AnimatedMarker
      coordinate={route[0]}
      anchor={DEFAULT_ANCHOR}
      rasterize={Platform.OS !== 'web'}
      animatedProps={animatedProps}
    >
      <PickupIcon loaded={loaded} />
    </AnimatedMarker>
  );
};
