import { codegenNativeComponent } from 'react-native';
import type {
  ViewProps,
  HostComponent,
  ColorValue,
  CodegenTypes,
} from 'react-native';

export interface Coordinate {
  latitude: CodegenTypes.Double;
  longitude: CodegenTypes.Double;
}

export interface NativeProps extends ViewProps {
  center: Coordinate;
  radius?: CodegenTypes.Double;
  strokeColor?: ColorValue;
  strokeWidth?: CodegenTypes.Double;
  fillColor?: ColorValue;
  tappable?: boolean;
  onCirclePress?: CodegenTypes.DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggCircleView'
) as HostComponent<NativeProps>;
