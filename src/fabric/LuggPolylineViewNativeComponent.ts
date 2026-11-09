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

export interface AnimatedOptions {
  duration?: CodegenTypes.Double;
  easing?: string;
  trailLength?: CodegenTypes.Double;
  delay?: CodegenTypes.Double;
}

export interface NativeProps extends ViewProps {
  coordinates: ReadonlyArray<Coordinate>;
  strokeColors?: ReadonlyArray<ColorValue>;
  strokeWidth?: CodegenTypes.Double;
  animated?: boolean;
  animatedOptions?: AnimatedOptions;
}

export default codegenNativeComponent<NativeProps>(
  'LuggPolylineView'
) as HostComponent<NativeProps>;
