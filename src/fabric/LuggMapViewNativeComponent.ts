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

export interface ReadyEvent {}

export interface NativeProps extends ViewProps {
  provider?: WithDefault<'google' | 'apple', 'google'>;
  mapId?: string;
  initialCoordinate?: Coordinate;
  initialZoom?: Double;
  minZoom?: Double;
  maxZoom?: Double;
  zoomEnabled?: boolean;
  scrollEnabled?: boolean;
  rotateEnabled?: boolean;
  pitchEnabled?: boolean;
  padding?: EdgeInsets;
  userLocationEnabled?: boolean;
  theme?: WithDefault<'light' | 'dark' | 'system', 'system'>;
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
    paddingTop: Double,
    paddingLeft: Double,
    paddingBottom: Double,
    paddingRight: Double,
    duration: Double
  ) => void;
}

export const Commands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['moveCamera', 'fitCoordinates'],
});

export default codegenNativeComponent<NativeProps>(
  'LuggMapView'
) as ComponentType;
