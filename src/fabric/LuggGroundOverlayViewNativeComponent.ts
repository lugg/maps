import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  Double,
  DirectEventHandler,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface Coordinate {
  latitude: Double;
  longitude: Double;
}

export interface Bounds {
  northeast: Coordinate;
  southwest: Coordinate;
}

export interface NativeProps extends ViewProps {
  image: string;
  bounds: Bounds;
  opacity?: Double;
  bearing?: Double;
  tappable?: boolean;
  onGroundOverlayPress?: DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggGroundOverlayView'
) as HostComponent<NativeProps>;
