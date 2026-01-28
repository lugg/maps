import { useEffect, useRef, useState } from 'react';
import {
  Image,
  Platform,
  StyleSheet,
  type ImageSourcePropType,
} from 'react-native';
import { Marker, type Coordinate } from '@lugg/maps';
import Animated, {
  Easing,
  type SharedValue,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { getRhumbLineBearing } from 'geolib';

export interface VehicleImages {
  driving: ImageSourcePropType;
  loaded: ImageSourcePropType;
}

const IMAGE_WIDTH = 45;
const IMAGE_HEIGHT = 80;
// Container must be square and large enough to fit rotated image (diagonal)
const CONTAINER_SIZE = Math.ceil(
  Math.sqrt(IMAGE_WIDTH * IMAGE_WIDTH + IMAGE_HEIGHT * IMAGE_HEIGHT)
);
const DEFAULT_ANCHOR = { x: 0.5, y: 0.4 };
const SEGMENT_DURATION = 2000;

interface CrewMarkerProps {
  route: Coordinate[];
  loaded?: boolean;
  images: VehicleImages;
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

const getZIndex = (coordinate?: Coordinate) => {
  if (!coordinate) return 10;
  return Math.round((90 - coordinate.latitude) * 10000);
};

interface VehicleIconProps {
  bearing: SharedValue<number>;
  loaded: boolean;
  images: VehicleImages;
}

const VehicleIcon = ({ bearing, loaded, images }: VehicleIconProps) => {
  const vehicleImage = loaded ? images.loaded : images.driving;

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: `${bearing.value}deg` }],
  }));

  return (
    <Animated.View style={[styles.root, animatedStyle]}>
      <Image source={vehicleImage} style={styles.image} resizeMode="contain" />
    </Animated.View>
  );
};

const BASE_ZOOM = 14;

export function CrewMarker({
  route,
  loaded = false,
  images,
  speed = 1,
  zoom = BASE_ZOOM,
}: CrewMarkerProps) {
  const [currentPosition, setCurrentPosition] = useState<Coordinate | null>(
    route[0] ?? null
  );
  const bearingValue = useSharedValue(0);
  const animationRef = useRef<NodeJS.Timeout | null>(null);
  const currentBearingRef = useRef(0);
  const segmentIndexRef = useRef(0);

  useEffect(() => {
    if (route.length < 2) return;

    // Reset to start
    segmentIndexRef.current = 0;
    setCurrentPosition(route[0]!);

    const animateSegment = (index: number) => {
      if (index >= route.length - 1) {
        // Loop back to start
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
      const steps = 60;
      const stepDuration = duration / steps;
      let step = 0;

      const animate = () => {
        step++;
        const progress = step / steps;

        const lat = from.latitude + (to.latitude - from.latitude) * progress;
        const lng = from.longitude + (to.longitude - from.longitude) * progress;
        setCurrentPosition({ latitude: lat, longitude: lng });

        if (progress >= 1) {
          segmentIndexRef.current = index + 1;
          animateSegment(index + 1);
          return;
        }

        animationRef.current = setTimeout(animate, stepDuration);
      };

      animationRef.current = setTimeout(animate, stepDuration);
    };

    animateSegment(0);

    return () => {
      if (animationRef.current) {
        clearTimeout(animationRef.current);
      }
    };
  }, [route, speed, zoom, bearingValue]);

  if (!currentPosition) return null;

  return (
    <Marker
      anchor={DEFAULT_ANCHOR}
      coordinate={currentPosition}
      zIndex={getZIndex(currentPosition)}
      rasterize={false}
    >
      <VehicleIcon bearing={bearingValue} loaded={loaded} images={images} />
    </Marker>
  );
}

const styles = StyleSheet.create({
  root: {
    width: CONTAINER_SIZE,
    height: CONTAINER_SIZE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  image: {
    width: IMAGE_WIDTH,
    height: IMAGE_HEIGHT,
    ...(Platform.OS !== 'web' && {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.12,
      shadowRadius: 8,
    }),
  },
});
