import {
  forwardRef,
  useEffect,
  useId,
  useImperativeHandle,
  useRef,
  useState,
  type CSSProperties,
} from 'react';
import type { NativeSyntheticEvent, ViewStyle } from 'react-native';
import { View, StyleSheet } from 'react-native';
import { Map, useMap } from '@vis.gl/react-google-maps';
import { Marker } from './components/Marker.web';
import { MapIdContext } from './MapProvider.web';

import type {
  MapViewProps,
  MapViewRef,
  MoveCameraOptions,
  FitCoordinatesOptions,
  CameraEventPayload,
} from './MapView.types';
import type { Coordinate } from './types';

const createSyntheticEvent = <T,>(nativeEvent: T): NativeSyntheticEvent<T> =>
  ({
    nativeEvent,
    currentTarget: null,
    target: null,
    bubbles: false,
    cancelable: false,
    defaultPrevented: false,
    eventPhase: 0,
    isTrusted: true,
    preventDefault: () => {},
    stopPropagation: () => {},
    isDefaultPrevented: () => false,
    isPropagationStopped: () => false,
    persist: () => {},
    timeStamp: Date.now(),
    type: '',
  } as unknown as NativeSyntheticEvent<T>);

const userLocationDotStyle: CSSProperties = {
  width: 16,
  height: 16,
  backgroundColor: '#4285F4',
  border: '2px solid white',
  borderRadius: '50%',
  boxShadow: '0 1px 4px rgba(0,0,0,0.3)',
};

function UserLocationMarker({ enabled }: { enabled?: boolean }) {
  const [coordinate, setCoordinate] = useState<Coordinate | null>(null);

  useEffect(() => {
    if (!enabled) {
      setCoordinate(null);
      return;
    }

    let watchId: number | null = null;

    const updateLocation = (position: GeolocationPosition) => {
      setCoordinate({
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
      });
    };

    navigator.geolocation.getCurrentPosition(updateLocation, () => {});
    watchId = navigator.geolocation.watchPosition(updateLocation, () => {});

    return () => {
      if (watchId !== null) {
        navigator.geolocation.clearWatch(watchId);
      }
    };
  }, [enabled]);

  if (!coordinate) return null;

  return (
    <Marker coordinate={coordinate} anchor={{ x: 0.5, y: 0.5 }}>
      <div style={userLocationDotStyle} />
    </Marker>
  );
}

export const MapView = forwardRef<MapViewRef, MapViewProps>(function MapView(
  props,
  ref
) {
  const {
    mapId = google.maps.Map.DEMO_MAP_ID,
    initialCoordinate,
    initialZoom = 10,
    minZoom,
    maxZoom,
    zoomEnabled = true,
    scrollEnabled = true,
    pitchEnabled = true,
    padding,
    userLocationEnabled,
    onCameraMove,
    onCameraIdle,
    onReady,
    children,
    style,
  } = props;

  const id = useId();
  const map = useMap(id);
  const readyFired = useRef(false);

  useImperativeHandle(
    ref,
    () => ({
      moveCamera(coordinate: Coordinate, options: MoveCameraOptions) {
        if (!map) return;

        const { zoom, duration = -1 } = options;
        const center = { lat: coordinate.latitude, lng: coordinate.longitude };

        if (duration === 0) {
          map.moveCamera({ center, zoom });
        } else {
          const currentZoom = map.getZoom();
          const zoomChanged = zoom !== undefined && zoom !== currentZoom;

          if (zoomChanged) {
            map.setZoom(zoom);
          }
          map.panTo(center);
        }
      },

      fitCoordinates(
        coordinates: Coordinate[],
        options?: FitCoordinatesOptions
      ) {
        const first = coordinates[0];
        if (!map || !first) return;

        const { padding: fitPadding, duration = -1 } = options ?? {};

        if (coordinates.length === 1) {
          this.moveCamera(first, { zoom: initialZoom, duration });
          return;
        }

        const bounds = new google.maps.LatLngBounds();
        coordinates.forEach((coord) => {
          bounds.extend({ lat: coord.latitude, lng: coord.longitude });
        });

        map.fitBounds(bounds, {
          top: fitPadding?.top ?? 0,
          left: fitPadding?.left ?? 0,
          bottom: fitPadding?.bottom ?? 0,
          right: fitPadding?.right ?? 0,
        });
      },
    }),
    [map, initialZoom]
  );

  useEffect(() => {
    if (map && !readyFired.current) {
      readyFired.current = true;
      onReady?.();
    }
  }, [map, onReady]);

  useEffect(() => {
    if (!map) return;

    const createPayload = (gesture: boolean): CameraEventPayload => {
      const center = map.getCenter();
      return {
        coordinate: {
          latitude: center?.lat() ?? 0,
          longitude: center?.lng() ?? 0,
        },
        zoom: map.getZoom() ?? 0,
        gesture,
      };
    };

    let isDragging = false;
    let wasGesture = false;

    const dragStartListener = map.addListener('dragstart', () => {
      isDragging = true;
      wasGesture = true;
    });

    const dragEndListener = map.addListener('dragend', () => {
      isDragging = false;
    });

    const centerListener = map.addListener('center_changed', () => {
      onCameraMove?.(createSyntheticEvent(createPayload(isDragging)));
    });

    const idleListener = map.addListener('idle', () => {
      onCameraIdle?.(createSyntheticEvent(createPayload(wasGesture)));
      wasGesture = false;
    });

    return () => {
      google.maps.event.removeListener(dragStartListener);
      google.maps.event.removeListener(dragEndListener);
      google.maps.event.removeListener(centerListener);
      google.maps.event.removeListener(idleListener);
    };
  }, [map, onCameraMove, onCameraIdle]);

  const gestureHandling =
    scrollEnabled === false && zoomEnabled === false
      ? 'none'
      : scrollEnabled === false
      ? 'cooperative'
      : 'auto';

  const defaultCenter = initialCoordinate
    ? { lat: initialCoordinate.latitude, lng: initialCoordinate.longitude }
    : undefined;

  const paddingStyle: ViewStyle = {
    paddingTop: padding?.top ?? 0,
    paddingLeft: padding?.left ?? 0,
    paddingRight: padding?.right ?? 0,
    paddingBottom: padding?.bottom ?? 0,
  };

  return (
    <MapIdContext.Provider value={id}>
      <View style={style}>
        <View style={[StyleSheet.absoluteFill, paddingStyle]}>
          <Map
            id={id}
            mapId={mapId}
            defaultCenter={defaultCenter}
            defaultZoom={initialZoom}
            minZoom={minZoom}
            maxZoom={maxZoom}
            gestureHandling={gestureHandling}
            disableDefaultUI
            isFractionalZoomEnabled
            tilt={pitchEnabled === false ? 0 : undefined}
          >
            <UserLocationMarker enabled={userLocationEnabled} />
            {children}
          </Map>
        </View>
      </View>
    </MapIdContext.Provider>
  );
});
