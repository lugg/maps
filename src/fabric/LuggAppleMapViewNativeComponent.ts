import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  Double,
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

export interface NativeProps extends ViewProps {
  initialCoordinate?: Coordinate;
  initialZoom?: Double;
  zoomEnabled?: boolean;
  scrollEnabled?: boolean;
  rotateEnabled?: boolean;
  pitchEnabled?: boolean;
  padding?: EdgeInsets;
  onCameraMove?: DirectEventHandler<CameraMoveEvent>;
  onCameraIdle?: DirectEventHandler<CameraIdleEvent>;
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
    padding: Double,
    duration: Double
  ) => void;
}

export const Commands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['moveCamera', 'fitCoordinates'],
});

export default codegenNativeComponent<NativeProps>(
  'LuggAppleMapView'
) as ComponentType;
