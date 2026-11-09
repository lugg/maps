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
  image: string;
  bounds: Bounds;
  opacity?: CodegenTypes.Double;
  bearing?: CodegenTypes.Double;
  tappable?: boolean;
  onGroundOverlayPress?: CodegenTypes.DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggGroundOverlayView'
) as HostComponent<NativeProps>;
