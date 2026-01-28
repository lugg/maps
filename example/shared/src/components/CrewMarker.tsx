import { useEffect, useMemo, useState } from 'react';
import {
  Image,
  Platform,
  StyleSheet,
  View,
  type ImageSourcePropType,
} from 'react-native';
import { Marker, type Coordinate } from '@lugg/maps';
import Animated, {
  Extrapolation,
  interpolate,
  type SharedValue,
  useAnimatedProps,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { getDistance, getRhumbLineBearing } from 'geolib';

const AnimatedMarker = Animated.createAnimatedComponent(Marker);

export interface VehicleImages {
  driving: ImageSourcePropType;
  loaded: ImageSourcePropType;
}

const CONTAINER_SIZE = 156;
const TRUCK_SIZE = 96;
const DEFAULT_ANCHOR = { x: 0.5, y: 0.5 };
const ANIMATION_DURATION = 5000;
const SKIP_ANIMATION_DISTANCE = 500;

interface CrewMarkerProps {
  location?: Coordinate;
  directions: Coordinate[];
  loaded?: boolean;
  latitudeDelta?: number;
  images: VehicleImages;
}

const findClosestPointOnLine = (
  point: Coordinate,
  start: Coordinate,
  end: Coordinate
): Coordinate => {
  const lineLength = getDistance(start, end);
  if (lineLength === 0) return start;

  const t =
    ((point.longitude - start.longitude) * (end.longitude - start.longitude) +
      (point.latitude - start.latitude) * (end.latitude - start.latitude)) /
    ((end.longitude - start.longitude) ** 2 +
      (end.latitude - start.latitude) ** 2);

  const clampedT = Math.max(0, Math.min(1, t));

  return {
    latitude: start.latitude + clampedT * (end.latitude - start.latitude),
    longitude: start.longitude + clampedT * (end.longitude - start.longitude),
  };
};

const getBearing = (directions: Coordinate[], currentBearing = 0) => {
  if (directions.length < 2) return 0;

  const truckPosition = directions[0]!;
  let closestSegment: [Coordinate, Coordinate] = [
    directions[0]!,
    directions[1]!,
  ];
  let minDistance = Number.POSITIVE_INFINITY;

  for (let i = 0; i < directions.length - 1; i++) {
    const start = directions[i]!;
    const distance = getDistance(truckPosition, start);

    if (distance < minDistance) {
      minDistance = distance;
      closestSegment = [start, directions[i + 1]!];
    }
  }

  let newBearing = getRhumbLineBearing(closestSegment[0], closestSegment[1]);

  if (newBearing - currentBearing > 180) {
    newBearing -= 360;
  } else if (newBearing - currentBearing < -180) {
    newBearing += 360;
  }

  return newBearing;
};

const getZIndex = (coordinates?: Coordinate) => {
  if (!coordinates) return 10;
  return Math.round((90 - coordinates.latitude) * 10000);
};

const useAnimatedCoordinates = (latitude: number, longitude: number) => {
  const latitudeAnimated = useSharedValue(latitude);
  const longitudeAnimated = useSharedValue(longitude);
  const prevLat = useSharedValue(latitude);
  const prevLng = useSharedValue(longitude);

  const animatedCoordinates = useAnimatedProps(() => ({
    coordinate: {
      latitude: latitudeAnimated.value,
      longitude: longitudeAnimated.value,
    },
  }));

  useEffect(() => {
    const distance = getDistance(
      { latitude: prevLat.value, longitude: prevLng.value },
      { latitude, longitude }
    );

    if (distance > SKIP_ANIMATION_DISTANCE) {
      latitudeAnimated.value = latitude;
      longitudeAnimated.value = longitude;
    } else {
      latitudeAnimated.value = withTiming(latitude, {
        duration: ANIMATION_DURATION,
      });
      longitudeAnimated.value = withTiming(longitude, {
        duration: ANIMATION_DURATION,
      });
    }

    prevLat.value = latitude;
    prevLng.value = longitude;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [latitude, longitude]);

  return animatedCoordinates;
};

interface VehicleIconProps {
  bearing: SharedValue<number>;
  loaded: boolean;
  latitudeDelta: number;
  images: VehicleImages;
}

const VehicleIcon = ({
  bearing,
  loaded,
  latitudeDelta,
  images,
}: VehicleIconProps) => {
  const vehicleImage = loaded ? images.loaded : images.driving;
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { rotate: `${bearing.value * 360}deg` },
      { scale: scale.value },
    ],
  }));

  useEffect(() => {
    if (latitudeDelta > 0.003) {
      scale.value = withTiming(
        interpolate(
          latitudeDelta,
          [0.003, 0.02],
          [1, 0.6],
          Extrapolation.CLAMP
        ),
        { duration: 300 }
      );
    } else {
      scale.value = withTiming(1, { duration: 300 });
    }
  }, [latitudeDelta, scale]);

  return (
    <View style={styles.root}>
      <Animated.View style={[animatedStyle, styles.truckContainer]}>
        <Image
          source={vehicleImage}
          style={styles.image}
          resizeMode="contain"
        />
      </Animated.View>
    </View>
  );
};

export function CrewMarker({
  location,
  directions,
  loaded = false,
  latitudeDelta = 0.01,
  images,
}: CrewMarkerProps) {
  const [truckAngle, setTruckAngle] = useState(0);
  const truckAngleAnimation = useSharedValue(
    getBearing(directions, truckAngle) / 360
  );
  const [lastKnownLocation, setLastKnownLocation] = useState(location);

  useEffect(() => {
    if (location) setLastKnownLocation(location);
  }, [location]);

  const projectedPosition = useMemo(() => {
    if (!location || directions.length < 2) return lastKnownLocation;

    let closestPoint = location;
    let minDistance = Number.POSITIVE_INFINITY;

    for (let i = 0; i < directions.length - 1; i++) {
      const start = directions[i]!;
      const end = directions[i + 1]!;
      const projectedPoint = findClosestPointOnLine(location, start, end);
      const distance = getDistance(location, projectedPoint);

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = projectedPoint;
      }
    }

    return closestPoint;
  }, [location, directions, lastKnownLocation]);

  useEffect(() => {
    const newBearing = getBearing(directions, truckAngle);
    setTruckAngle(newBearing);
    truckAngleAnimation.value = withTiming(newBearing / 360, {
      duration: ANIMATION_DURATION,
    });
  }, [directions, truckAngle, truckAngleAnimation]);

  const latitude = projectedPosition?.latitude ?? 0;
  const longitude = projectedPosition?.longitude ?? 0;
  const animatedCoordinates = useAnimatedCoordinates(latitude, longitude);

  if (!projectedPosition) return null;

  return (
    <AnimatedMarker
      anchor={DEFAULT_ANCHOR}
      coordinate={{ latitude, longitude }}
      zIndex={getZIndex(projectedPosition)}
      animatedProps={animatedCoordinates}
    >
      <VehicleIcon
        bearing={truckAngleAnimation}
        loaded={loaded}
        latitudeDelta={latitudeDelta}
        images={images}
      />
    </AnimatedMarker>
  );
}

const styles = StyleSheet.create({
  root: {
    width: CONTAINER_SIZE,
    height: CONTAINER_SIZE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  truckContainer: {
    width: TRUCK_SIZE,
    height: TRUCK_SIZE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  image: {
    width: 45,
    height: 80,
    ...(Platform.OS !== 'web' && {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.12,
      shadowRadius: 8,
    }),
  },
});
