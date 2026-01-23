import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type { Double } from 'react-native/Libraries/Types/CodegenTypes';

export interface Coordinate {
  latitude: Double;
  longitude: Double;
}

export interface Point {
  x: Double;
  y: Double;
}

export interface NativeProps extends ViewProps {
  name?: string;
  coordinate: Coordinate;
  title?: string;
  description?: string;
  anchor?: Point;
}

export default codegenNativeComponent<NativeProps>(
  'LuggMarkerView'
) as HostComponent<NativeProps>;
