import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent, ColorValue } from 'react-native';
import type {
  Double,
  DirectEventHandler,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface Coordinate {
  latitude: Double;
  longitude: Double;
}

export interface NativeProps extends ViewProps {
  center: Coordinate;
  radius?: Double;
  strokeColor?: ColorValue;
  strokeWidth?: Double;
  fillColor?: ColorValue;
  tappable?: boolean;
  onCirclePress?: DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggCircleView'
) as HostComponent<NativeProps>;
