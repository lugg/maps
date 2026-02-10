import {
  forwardRef,
  useCallback,
  useEffect,
  useId,
  useImperativeHandle,
  useRef,
  useState,
  type CSSProperties,
} from 'react';
import type { NativeSyntheticEvent } from 'react-native';
import { View } from 'react-native';
import {
  ColorScheme,
  Map,
  useMap,
  type MapCameraChangedEvent,
  type MapEvent,
} from '@vis.gl/react-google-maps';
import { Marker } from './components/Marker.web';
import { MapContext } from './MapProvider.web';

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
    edgeInsets,
    userLocationEnabled,
    theme = 'system',
    onCameraMove,
    onCameraIdle,
    onReady,
    children,
    style,
  } = props;

  const id = useId();
  const map = useMap(id);
  const containerRef = useRef<View>(null);
  const readyFired = useRef(false);
  const [isDragging, setIsDragging] = useState(false);
  const wasGesture = useRef(false);
  const prevEdgeInsets = useRef(edgeInsets);

  const offsetCenter = useCallback(
    (
      coord: Coordinate,
      zoom: number,
      edgeInsetsOverride?: typeof edgeInsets,
      reverse = false
    ) => {
      const p = edgeInsetsOverride ?? edgeInsets;
      const div = map?.getDiv();
      if (!p || !div) {
        return { lat: coord.latitude, lng: coord.longitude };
      }

      const dir = reverse ? -1 : 1;
      const scale = 256 * Math.pow(2, zoom);
      const offsetX = (dir * ((p.right ?? 0) - (p.left ?? 0))) / 2;
      const offsetY = (dir * ((p.bottom ?? 0) - (p.top ?? 0))) / 2;

      const latRad = (coord.latitude * Math.PI) / 180;
      const x = ((coord.longitude + 180) / 360) * scale + offsetX;
      const y =
        ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) /
          2) *
          scale +
        offsetY;

      const lng = (x / scale) * 360 - 180;
      const lat =
        (Math.atan(Math.sinh(Math.PI * (1 - (2 * y) / scale))) * 180) / Math.PI;

      return { lat, lng };
    },
    [map, edgeInsets]
  );

  useImperativeHandle(
    ref,
    () => ({
      moveCamera(coordinate: Coordinate, options?: MoveCameraOptions) {
        if (!map) return;

        const { zoom = 0, duration = -1 } = options ?? {};
        const targetZoom = zoom || map.getZoom() || initialZoom;
        const center = offsetCenter(coordinate, targetZoom, undefined, false);

        if (duration === 0) {
          map.moveCamera({ center, zoom: targetZoom });
        } else {
          const currentZoom = map.getZoom();
          const zoomChanged = zoom !== 0 && zoom !== currentZoom;

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

        const { edgeInsets: fitEdgeInsets, duration = -1 } = options ?? {};

        if (coordinates.length === 1) {
          this.moveCamera(first, { zoom: initialZoom, duration });
          return;
        }

        const bounds = new google.maps.LatLngBounds();
        coordinates.forEach((coord) => {
          bounds.extend({ lat: coord.latitude, lng: coord.longitude });
        });

        map.fitBounds(bounds, {
          top: (edgeInsets?.top ?? 0) + (fitEdgeInsets?.top ?? 0),
          left: (edgeInsets?.left ?? 0) + (fitEdgeInsets?.left ?? 0),
          bottom: (edgeInsets?.bottom ?? 0) + (fitEdgeInsets?.bottom ?? 0),
          right: (edgeInsets?.right ?? 0) + (fitEdgeInsets?.right ?? 0),
        });
      },
    }),
    [map, initialZoom, edgeInsets, offsetCenter]
  );

  useEffect(() => {
    if (map && !readyFired.current) {
      readyFired.current = true;
      onReady?.();
    }
  }, [map, onReady]);

  useEffect(() => {
    if (!map || !edgeInsets) return;

    const prev = prevEdgeInsets.current;
    const changed =
      prev?.top !== edgeInsets.top ||
      prev?.left !== edgeInsets.left ||
      prev?.bottom !== edgeInsets.bottom ||
      prev?.right !== edgeInsets.right;

    if (changed) {
      const center = map.getCenter();
      const zoom = map.getZoom() ?? initialZoom;
      if (center) {
        const logicalCenter = offsetCenter(
          { latitude: center.lat(), longitude: center.lng() },
          zoom,
          prev,
          true
        );
        const newCenter = offsetCenter(
          { latitude: logicalCenter.lat, longitude: logicalCenter.lng },
          zoom,
          edgeInsets,
          false
        );
        map.panTo(newCenter);
      }
      prevEdgeInsets.current = edgeInsets;
    }
  }, [map, edgeInsets, initialZoom, offsetCenter]);

  const handleDragStart = () => {
    setIsDragging(true);
    wasGesture.current = true;
  };

  const handleDragEnd = () => {
    setIsDragging(false);
  };

  const handleCameraChanged = (event: MapCameraChangedEvent) => {
    const logicalCenter = offsetCenter(
      { latitude: event.detail.center.lat, longitude: event.detail.center.lng },
      event.detail.zoom,
      undefined,
      true
    );
    const payload: CameraEventPayload = {
      coordinate: {
        latitude: logicalCenter.lat,
        longitude: logicalCenter.lng,
      },
      zoom: event.detail.zoom,
      gesture: isDragging,
    };
    onCameraMove?.(createSyntheticEvent(payload));
  };

  const handleIdle = (event: MapEvent) => {
    const center = event.map.getCenter();
    const zoom = event.map.getZoom() ?? 0;
    const logicalCenter = offsetCenter(
      { latitude: center?.lat() ?? 0, longitude: center?.lng() ?? 0 },
      zoom,
      undefined,
      true
    );
    const payload: CameraEventPayload = {
      coordinate: {
        latitude: logicalCenter.lat,
        longitude: logicalCenter.lng,
      },
      zoom,
      gesture: wasGesture.current,
    };
    onCameraIdle?.(createSyntheticEvent(payload));
    wasGesture.current = false;
  };

  const gestureHandling =
    scrollEnabled === false && zoomEnabled === false
      ? 'none'
      : scrollEnabled === false
      ? 'cooperative'
      : 'auto';

  const colorScheme =
    theme === 'dark'
      ? ColorScheme.DARK
      : theme === 'light'
      ? ColorScheme.LIGHT
      : ColorScheme.FOLLOW_SYSTEM;

  const defaultCenter = initialCoordinate
    ? { lat: initialCoordinate.latitude, lng: initialCoordinate.longitude }
    : undefined;

  return (
    <MapContext.Provider value={{ map, isDragging }}>
      <View ref={containerRef} style={style}>
        <Map
          id={id}
          mapId={mapId}
          defaultCenter={defaultCenter}
          defaultZoom={initialZoom}
          minZoom={minZoom}
          maxZoom={maxZoom}
          gestureHandling={gestureHandling}
          colorScheme={colorScheme}
          disableDefaultUI
          isFractionalZoomEnabled
          tilt={pitchEnabled === false ? 0 : undefined}
          onDragstart={handleDragStart}
          onDragend={handleDragEnd}
          onCameraChanged={handleCameraChanged}
          onIdle={handleIdle}
        >
          <UserLocationMarker enabled={userLocationEnabled} />
          {children}
        </Map>
      </View>
    </MapContext.Provider>
  );
});
