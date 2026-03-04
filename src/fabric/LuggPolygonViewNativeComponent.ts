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
  coordinates: ReadonlyArray<Coordinate>;
  holes?: ReadonlyArray<ReadonlyArray<Coordinate>>;
  strokeColor?: ColorValue;
  strokeWidth?: Double;
  fillColor?: ColorValue;
  tappable?: boolean;
  onPolygonPress?: DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggPolygonView'
) as HostComponent<NativeProps>;
