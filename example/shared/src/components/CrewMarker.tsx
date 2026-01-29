import { useEffect, useRef } from 'react';
import { Marker, type Coordinate } from '@lugg/maps';
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

interface CrewMarkerProps {
  route: Coordinate[];
  loaded?: boolean;
  speed?: number;
  zoom?: number;
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

export function CrewMarker({
  route,
  loaded = false,
  speed = 1,
  zoom = BASE_ZOOM,
}: CrewMarkerProps) {
  const latitude = useSharedValue(route[0]?.latitude ?? 0);
  const longitude = useSharedValue(route[0]?.longitude ?? 0);
  const bearingValue = useSharedValue(0);
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
  }));

  useEffect(() => {
    if (route.length < 2) return;

    // Reset to start
    segmentIndexRef.current = 0;
    latitude.value = route[0]!.latitude;
    longitude.value = route[0]!.longitude;

    const animateSegment = (index: number) => {
      if (index >= route.length - 1) {
        segmentIndexRef.current = 0;
        animateSegment(0);
        return;
      }

      const from = route[index]!;
      const to = route[index + 1]!;

      const newBearing = getBearing(from, to, currentBearingRef.current);
      currentBearingRef.current = newBearing;
      bearingValue.value = withTiming(newBearing, {
        duration: 300,
        easing: Easing.out(Easing.ease),
      });

      const zoomScale = Math.pow(2, zoom - BASE_ZOOM);
      const duration = (SEGMENT_DURATION / speed) * zoomScale;

      latitude.value = withTiming(to.latitude, { duration });
      longitude.value = withTiming(to.longitude, { duration });

      animationRef.current = setTimeout(() => {
        segmentIndexRef.current = index + 1;
        animateSegment(index + 1);
      }, duration);
    };

    animateSegment(0);

    return () => {
      if (animationRef.current) {
        clearTimeout(animationRef.current);
      }
    };
  }, [route, speed, zoom, bearingValue, latitude, longitude]);

  if (!route[0]) return null;

  return (
    <AnimatedMarker
      coordinate={route[0]}
      anchor={DEFAULT_ANCHOR}
      animatedProps={animatedProps}
    >
      <PickupIcon loaded={loaded} />
    </AnimatedMarker>
  );
}
