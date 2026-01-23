import {
  Children,
  Component,
  isValidElement,
  useEffect,
  useRef,
  type CSSProperties,
  type ReactElement,
  type ReactNode,
} from 'react';
import type { NativeSyntheticEvent, ViewStyle } from 'react-native';
import { View } from 'react-native';
import { Map, useMap } from '@vis.gl/react-google-maps';
import { Marker } from './components/Marker.web';
import { Polyline } from './components/Polyline.web';

import type {
  MapViewProps,
  MapViewRef,
  MoveCameraOptions,
  FitCoordinatesOptions,
  CameraEventPayload,
} from './MapView.types';
import type { Coordinate } from './types';

// Map-specific component types that render inside the Google Map
const MAP_COMPONENT_TYPES = new Set([Marker, Polyline]);

const isMapComponent = (child: ReactElement): boolean =>
  MAP_COMPONENT_TYPES.has(child.type as typeof Marker | typeof Polyline);

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

interface MapControllerProps {
  onMapReady: (map: google.maps.Map) => void;
  onCameraMove?: (event: NativeSyntheticEvent<CameraEventPayload>) => void;
  onCameraIdle?: (event: NativeSyntheticEvent<CameraEventPayload>) => void;
  onReady?: () => void;
  userLocationEnabled?: boolean;
}

function MapController({
  onMapReady,
  onCameraMove,
  onCameraIdle,
  onReady,
  userLocationEnabled,
}: MapControllerProps) {
  const map = useMap();
  const readyFired = useRef(false);
  const userLocationMarker =
    useRef<google.maps.marker.AdvancedMarkerElement | null>(null);

  useEffect(() => {
    if (!map) return;
    onMapReady(map);

    if (!readyFired.current) {
      readyFired.current = true;
      onReady?.();
    }
  }, [map, onMapReady, onReady]);

  useEffect(() => {
    if (!map || !userLocationEnabled) {
      if (userLocationMarker.current) {
        userLocationMarker.current.map = null;
        userLocationMarker.current = null;
      }
      return;
    }

    let watchId: number | null = null;

    const updateLocation = (position: GeolocationPosition) => {
      const { latitude, longitude } = position.coords;
      const pos = { lat: latitude, lng: longitude };

      if (!userLocationMarker.current) {
        const dot = document.createElement('div');
        dot.style.width = '16px';
        dot.style.height = '16px';
        dot.style.backgroundColor = '#4285F4';
        dot.style.border = '2px solid white';
        dot.style.borderRadius = '50%';
        dot.style.boxShadow = '0 1px 4px rgba(0,0,0,0.3)';

        userLocationMarker.current =
          new google.maps.marker.AdvancedMarkerElement({
            map,
            position: pos,
            content: dot,
          });
      } else {
        userLocationMarker.current.position = pos;
      }
    };

    navigator.geolocation.getCurrentPosition(updateLocation, () => {});
    watchId = navigator.geolocation.watchPosition(updateLocation, () => {});

    return () => {
      if (watchId !== null) {
        navigator.geolocation.clearWatch(watchId);
      }
      if (userLocationMarker.current) {
        userLocationMarker.current.map = null;
        userLocationMarker.current = null;
      }
    };
  }, [map, userLocationEnabled]);

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

    const dragStartListener = map.addListener('dragstart', () => {
      isDragging = true;
    });

    const dragEndListener = map.addListener('dragend', () => {
      isDragging = false;
    });

    const centerListener = map.addListener('center_changed', () => {
      onCameraMove?.(createSyntheticEvent(createPayload(isDragging)));
    });

    const idleListener = map.addListener('idle', () => {
      onCameraIdle?.(createSyntheticEvent(createPayload(false)));
    });

    return () => {
      google.maps.event.removeListener(dragStartListener);
      google.maps.event.removeListener(dragEndListener);
      google.maps.event.removeListener(centerListener);
      google.maps.event.removeListener(idleListener);
    };
  }, [map, onCameraMove, onCameraIdle]);

  return null;
}

export class MapView extends Component<MapViewProps> implements MapViewRef {
  static defaultProps: Partial<MapViewProps> = {
    provider: 'google',
    mapId: 'DEMO_MAP_ID',
    initialZoom: 10,
    zoomEnabled: true,
    scrollEnabled: true,
    rotateEnabled: true,
    pitchEnabled: true,
  };

  private mapInstance: google.maps.Map | null = null;

  private handleMapReady = (map: google.maps.Map) => {
    this.mapInstance = map;
  };

  moveCamera(coordinate: Coordinate, options: MoveCameraOptions) {
    const map = this.mapInstance;
    if (!map) return;

    const { zoom, duration = -1 } = options;
    const center = { lat: coordinate.latitude, lng: coordinate.longitude };

    if (duration > 0) {
      map.panTo(center);
      map.setZoom(zoom);
    } else {
      map.setCenter(center);
      map.setZoom(zoom);
    }
  }

  fitCoordinates(coordinates: Coordinate[], options?: FitCoordinatesOptions) {
    const map = this.mapInstance;
    const first = coordinates[0];
    if (!map || !first) return;

    const { padding, duration = -1 } = options ?? {};

    if (coordinates.length === 1) {
      const zoom = this.props.initialZoom ?? 10;
      this.moveCamera(first, { zoom, duration });
      return;
    }

    const bounds = new google.maps.LatLngBounds();
    coordinates.forEach((coord) => {
      bounds.extend({ lat: coord.latitude, lng: coord.longitude });
    });

    map.fitBounds(bounds, {
      top: padding?.top ?? 0,
      left: padding?.left ?? 0,
      bottom: padding?.bottom ?? 0,
      right: padding?.right ?? 0,
    });
  }

  render() {
    const {
      mapId,
      initialCoordinate,
      initialZoom,
      minZoom,
      maxZoom,
      zoomEnabled,
      scrollEnabled,
      pitchEnabled,
      padding,
      userLocationEnabled,
      onCameraMove,
      onCameraIdle,
      onReady,
      children,
      style,
    } = this.props;

    const gestureHandling =
      scrollEnabled === false && zoomEnabled === false
        ? 'none'
        : scrollEnabled === false
        ? 'none'
        : 'auto';

    const defaultCenter = initialCoordinate
      ? { lat: initialCoordinate.latitude, lng: initialCoordinate.longitude }
      : undefined;

    // Separate map children (Marker, Polyline) from overlay children (regular Views)
    const mapChildren: ReactNode[] = [];
    const overlayChildren: ReactNode[] = [];

    Children.forEach(children, (child) => {
      if (!isValidElement(child)) return;
      if (isMapComponent(child)) {
        mapChildren.push(child);
      } else {
        overlayChildren.push(child);
      }
    });

    const mapContainerStyle: ViewStyle = {
      position: 'absolute',
      top: padding?.top ?? 0,
      left: padding?.left ?? 0,
      right: padding?.right ?? 0,
      bottom: padding?.bottom ?? 0,
    };

    const mapStyle: CSSProperties = {
      width: '100%',
      height: '100%',
    };

    return (
      <View style={style}>
        <View style={mapContainerStyle}>
          <Map
            mapId={mapId}
            defaultCenter={defaultCenter}
            defaultZoom={initialZoom}
            minZoom={minZoom}
            maxZoom={maxZoom}
            gestureHandling={gestureHandling}
            disableDefaultUI
            tilt={pitchEnabled === false ? 0 : undefined}
            style={mapStyle}
          >
            <MapController
              onMapReady={this.handleMapReady}
              onCameraMove={onCameraMove}
              onCameraIdle={onCameraIdle}
              onReady={onReady}
              userLocationEnabled={userLocationEnabled}
            />
            {mapChildren}
          </Map>
        </View>
        {overlayChildren}
      </View>
    );
  }
}
