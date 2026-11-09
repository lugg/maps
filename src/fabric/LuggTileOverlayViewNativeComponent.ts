import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent, CodegenTypes } from 'react-native';

export interface Coordinate {
  latitude: CodegenTypes.Double;
  longitude: CodegenTypes.Double;
}

export interface Bounds {
  northeast: Coordinate;
  southwest: Coordinate;
}

export interface NativeProps extends ViewProps {
  urlTemplate: string;
  tileSize?: CodegenTypes.Int32;
  opacity?: CodegenTypes.Double;
  bounds?: Bounds;
  tappable?: boolean;
  onTileOverlayPress?: CodegenTypes.DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggTileOverlayView'
) as HostComponent<NativeProps>;
