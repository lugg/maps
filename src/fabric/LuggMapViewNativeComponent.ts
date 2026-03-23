import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  Double,
  WithDefault,
  DirectEventHandler,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface Coordinate {
  latitude: Double;
  longitude: Double;
}

export interface EdgeInsets {
  top: Double;
  left: Double;
  bottom: Double;
  right: Double;
}

export interface CameraMoveEvent {
  coordinate: {
    latitude: Double;
    longitude: Double;
  };
  zoom: Double;
  gesture: boolean;
}

export interface CameraIdleEvent {
  coordinate: {
    latitude: Double;
    longitude: Double;
  };
  zoom: Double;
  gesture: boolean;
}

export interface PressEvent {
  coordinate: {
    latitude: Double;
    longitude: Double;
  };
  point: {
    x: Double;
    y: Double;
  };
}

export interface LongPressEvent {
  coordinate: {
    latitude: Double;
    longitude: Double;
  };
  point: {
    x: Double;
    y: Double;
  };
}

export interface ReadyEvent {}

export interface NativeProps extends ViewProps {
  provider?: WithDefault<'google' | 'apple', 'google'>;
  mapType?: WithDefault<
    'standard' | 'satellite' | 'terrain' | 'hybrid' | 'muted-standard',
    'standard'
  >;
  mapId?: string;
  initialCoordinate?: Coordinate;
  initialZoom?: Double;
  minZoom?: Double;
  maxZoom?: Double;
  zoomEnabled?: boolean;
  scrollEnabled?: boolean;
  rotateEnabled?: boolean;
  pitchEnabled?: boolean;
  edgeInsets?: EdgeInsets;
  userLocationEnabled?: boolean;
  userLocationButtonEnabled?: boolean;
  poiEnabled?: boolean;
  poiFilterMode?: WithDefault<'including' | 'excluding', 'including'>;
  poiFilterCategories?: ReadonlyArray<string>;
  theme?: WithDefault<'light' | 'dark' | 'system', 'system'>;
  onMapPress?: DirectEventHandler<PressEvent>;
  onMapLongPress?: DirectEventHandler<LongPressEvent>;
  onCameraMove?: DirectEventHandler<CameraMoveEvent>;
  onCameraIdle?: DirectEventHandler<CameraIdleEvent>;
  onReady?: DirectEventHandler<ReadyEvent>;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  moveCamera: (
    viewRef: React.ElementRef<ComponentType>,
    latitude: Double,
    longitude: Double,
    zoom: Double,
    duration: Double
  ) => void;
  fitCoordinates: (
    viewRef: React.ElementRef<ComponentType>,
    coordinates: Coordinate[],
    edgeInsetsTop: Double,
    edgeInsetsLeft: Double,
    edgeInsetsBottom: Double,
    edgeInsetsRight: Double,
    duration: Double
  ) => void;
  setEdgeInsets: (
    viewRef: React.ElementRef<ComponentType>,
    top: Double,
    left: Double,
    bottom: Double,
    right: Double,
    duration: Double
  ) => void;
}

export const Commands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['moveCamera', 'fitCoordinates', 'setEdgeInsets'],
});

export default codegenNativeComponent<NativeProps>(
  'LuggMapView'
) as ComponentType;
