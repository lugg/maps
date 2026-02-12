import { forwardRef, useMemo, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import {
  MapView,
  type MapViewProps,
  type CameraEventPayload,
} from '@lugg/maps';
import type { NativeSyntheticEvent } from 'react-native';
import Animated, {
  useAnimatedProps,
  useAnimatedStyle,
  type SharedValue,
} from 'react-native-reanimated';

import { renderMarker } from '../renderMarker';
import { CrewMarker } from './CrewMarker';
import { MarkerText } from './MarkerText';
import type { MarkerData } from './index';
import { Route, smoothCoordinates } from './Route';

interface AnimatedMapProps extends Omit<MapViewProps, 'edgeInsets'> {
  markers: MarkerData[];
  edgeInsetsBottom?: SharedValue<number>;
}

const AnimatedMapView = Animated.createAnimatedComponent(MapView);

const INITIAL_ZOOM = 14;

export const AnimatedMap = forwardRef<MapView, AnimatedMapProps>(
  ({ markers, edgeInsetsBottom, onCameraIdle, onCameraMove, ...props }, ref) => {
    const [zoom, setZoom] = useState(INITIAL_ZOOM);
    const polylineCoordinates = useMemo(
      () => markers.map((m) => m.coordinate),
      [markers]
    );
    const smoothedRoute = useMemo(
      () => smoothCoordinates(polylineCoordinates),
      [polylineCoordinates]
    );

    const animatedProps = useAnimatedProps(() => {
      const bottom = edgeInsetsBottom?.value ?? 0;
      console.log('[AnimatedMap] edgeInsets bottom:', bottom);
      return {
        edgeInsets: {
          top: 0,
          left: 0,
          bottom,
          right: 0,
        },
      };
    });

    const centerPinStyle = useAnimatedStyle(() => ({
      transform: [{ translateY: -(edgeInsetsBottom?.value ?? 0) / 2 }],
    }));

    const handleCameraMove = (e: NativeSyntheticEvent<CameraEventPayload>) => {
      onCameraMove?.(e);
    };

    const handleCameraIdle = (e: NativeSyntheticEvent<CameraEventPayload>) => {
      setZoom(e.nativeEvent.zoom);
      onCameraIdle?.(e);
    };

    return (
      <View style={styles.container}>
        <AnimatedMapView
          ref={ref}
          style={StyleSheet.absoluteFill}
          initialCoordinate={{ latitude: 37.78, longitude: -122.43 }}
          initialZoom={INITIAL_ZOOM}
          userLocationEnabled
          animatedProps={animatedProps}
          onCameraMove={handleCameraMove}
          onCameraIdle={handleCameraIdle}
          {...props}
        >
          {markers.map(renderMarker)}
          <Route coordinates={smoothedRoute} />
          <CrewMarker route={smoothedRoute} zoom={zoom} />
          <MarkerText
            name="inline-marker"
            coordinate={{ latitude: 37.782, longitude: -122.425 }}
            text="LO"
            color="#34A853"
          />
        </AnimatedMapView>
        <Animated.View style={[styles.centerPin, centerPinStyle]} />
      </View>
    );
  }
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  centerPin: {
    backgroundColor: 'blue',
    height: 20,
    width: 20,
    borderRadius: 10,
  },
});
