import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  Double,
  WithDefault,
  DirectEventHandler,
} from 'react-native/Libraries/Types/CodegenTypes';

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
  rotate?: WithDefault<Double, 0>;
  scale?: WithDefault<Double, 1>;
  rasterize?: WithDefault<boolean, true>;
  onMarkerPress?: DirectEventHandler<{
    coordinate: {
      latitude: Double;
      longitude: Double;
    };
    point: {
      x: Double;
      y: Double;
    };
  }>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggMarkerView'
) as HostComponent<NativeProps>;
