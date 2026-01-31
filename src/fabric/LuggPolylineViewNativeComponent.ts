import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent, ColorValue } from 'react-native';
import type { Double } from 'react-native/Libraries/Types/CodegenTypes';

export interface Coordinate {
  latitude: Double;
  longitude: Double;
}

export interface AnimatedOptions {
  duration?: Double;
  easing?: string;
  trailLength?: Double;
  delay?: Double;
}

export interface NativeProps extends ViewProps {
  coordinates: ReadonlyArray<Coordinate>;
  strokeColors?: ReadonlyArray<ColorValue>;
  strokeWidth?: Double;
  animated?: boolean;
  animatedOptions?: AnimatedOptions;
}

export default codegenNativeComponent<NativeProps>(
  'LuggPolylineView'
) as HostComponent<NativeProps>;
