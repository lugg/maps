import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  Double,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface Point {
  x: Double;
  y: Double;
}

export interface NativeProps extends ViewProps {
  bubbled?: WithDefault<boolean, true>;
  anchor?: Point;
}

export default codegenNativeComponent<NativeProps>(
  'LuggCalloutView'
) as HostComponent<NativeProps>;
