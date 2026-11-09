import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type { ViewProps, HostComponent, CodegenTypes } from 'react-native';

export interface Coordinate {
  latitude: CodegenTypes.Double;
  longitude: CodegenTypes.Double;
}

export interface EdgeInsets {
  top: CodegenTypes.Double;
  left: CodegenTypes.Double;
  bottom: CodegenTypes.Double;
  right: CodegenTypes.Double;
}

export interface CameraMoveEvent {
  coordinate: {
    latitude: CodegenTypes.Double;
    longitude: CodegenTypes.Double;
  };
  zoom: CodegenTypes.Double;
  gesture: boolean;
}

export interface CameraIdleEvent {
  coordinate: {
    latitude: CodegenTypes.Double;
    longitude: CodegenTypes.Double;
  };
  zoom: CodegenTypes.Double;
  gesture: boolean;
}

export interface PressEvent {
  coordinate: {
    latitude: CodegenTypes.Double;
    longitude: CodegenTypes.Double;
  };
  point: {
    x: CodegenTypes.Double;
    y: CodegenTypes.Double;
  };
}

export interface LongPressEvent {
  coordinate: {
    latitude: CodegenTypes.Double;
    longitude: CodegenTypes.Double;
  };
  point: {
    x: CodegenTypes.Double;
    y: CodegenTypes.Double;
  };
}

export interface ReadyEvent {}

export interface NativeProps extends ViewProps {
  provider?: CodegenTypes.WithDefault<'google' | 'apple', 'google'>;
  mapType?: CodegenTypes.WithDefault<
    'standard' | 'satellite' | 'terrain' | 'hybrid' | 'muted-standard',
    'standard'
  >;
  mapId?: string;
  initialCoordinate?: Coordinate;
  initialZoom?: CodegenTypes.Double;
  minZoom?: CodegenTypes.Double;
  maxZoom?: CodegenTypes.Double;
  zoomEnabled?: CodegenTypes.WithDefault<boolean, true>;
  scrollEnabled?: CodegenTypes.WithDefault<boolean, true>;
  rotateEnabled?: CodegenTypes.WithDefault<boolean, true>;
  pitchEnabled?: CodegenTypes.WithDefault<boolean, true>;
  compassEnabled?: CodegenTypes.WithDefault<boolean, true>;
  staticMode?: boolean;
  staticKey?: string;
  edgeInsets?: EdgeInsets;
  userLocationEnabled?: boolean;
  userLocationButtonEnabled?: boolean;
  poiEnabled?: boolean;
  poiFilterMode?: CodegenTypes.WithDefault<
    'including' | 'excluding',
    'including'
  >;
  poiFilterCategories?: ReadonlyArray<string>;
  theme?: CodegenTypes.WithDefault<'system' | 'light' | 'dark', 'system'>;
  insetAdjustment?: CodegenTypes.WithDefault<'never' | 'automatic', 'never'>;
  idleFrameRate?: CodegenTypes.WithDefault<
    'maximum' | 'conservative' | 'powerSave',
    'maximum'
  >;
  onMapPress?: CodegenTypes.DirectEventHandler<PressEvent>;
  onMapLongPress?: CodegenTypes.DirectEventHandler<LongPressEvent>;
  onCameraMove?: CodegenTypes.DirectEventHandler<CameraMoveEvent>;
  onCameraIdle?: CodegenTypes.DirectEventHandler<CameraIdleEvent>;
  onReady?: CodegenTypes.DirectEventHandler<ReadyEvent>;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  moveCamera: (
    viewRef: React.ElementRef<ComponentType>,
    latitude: CodegenTypes.Double,
    longitude: CodegenTypes.Double,
    zoom: CodegenTypes.Double,
    duration: CodegenTypes.Double
  ) => void;
  fitCoordinates: (
    viewRef: React.ElementRef<ComponentType>,
    coordinates: Coordinate[],
    edgeInsetsTop: CodegenTypes.Double,
    edgeInsetsLeft: CodegenTypes.Double,
    edgeInsetsBottom: CodegenTypes.Double,
    edgeInsetsRight: CodegenTypes.Double,
    duration: CodegenTypes.Double
  ) => void;
  setEdgeInsets: (
    viewRef: React.ElementRef<ComponentType>,
    top: CodegenTypes.Double,
    left: CodegenTypes.Double,
    bottom: CodegenTypes.Double,
    right: CodegenTypes.Double,
    duration: CodegenTypes.Double
  ) => void;
  reload: (viewRef: React.ElementRef<ComponentType>) => void;
}

export const Commands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    'moveCamera',
    'fitCoordinates',
    'setEdgeInsets',
    'reload',
  ],
});

export default codegenNativeComponent<NativeProps>(
  'LuggMapView'
) as ComponentType;
