import { useEffect, useMemo, useRef } from 'react';
import { Platform } from 'react-native';
import { Marker, type Coordinate, type MarkerPath } from '@lugg/maps';
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
  const scaleValue = useZoomScale(zoom);
  const animatedProps = useAnimatedProps(() => ({
    scale: scaleValue.value,
  }));
  const path = useMemo<MarkerPath | null>(() => {
    if (route.length < 2) return null;
    const duration = ((route.length - 1) * SEGMENT_DURATION) / speed;
    return {
      coordinates: route,
      duration,
      // Start partway round, so a fleet spreads out
      startTime: Date.now() - phase * duration,
      loop: true,
    };
  }, [route, speed, phase]);

  if (!path || !route[0]) return null;

  return (
    <AnimatedMarker
      coordinate={route[0]}
      path={path}
      rotateAlongPath
      onPathProgress={
        onSegment ? (e) => onSegment(e.nativeEvent.index) : undefined
      }
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
