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
  coordinates: ReadonlyArray<Coordinate>;
  holes?: ReadonlyArray<ReadonlyArray<Coordinate>>;
  strokeColor?: ColorValue;
  strokeWidth?: CodegenTypes.Double;
  fillColor?: ColorValue;
  tappable?: boolean;
  onPolygonPress?: CodegenTypes.DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggPolygonView'
) as HostComponent<NativeProps>;
