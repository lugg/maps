import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent, CodegenTypes } from 'react-native';

export interface Point {
  x: CodegenTypes.Double;
  y: CodegenTypes.Double;
}

export interface NativeProps extends ViewProps {
  bubbled?: CodegenTypes.WithDefault<boolean, true>;
  offset?: Point;
}

export default codegenNativeComponent<NativeProps>(
  'LuggCalloutView'
) as HostComponent<NativeProps>;
