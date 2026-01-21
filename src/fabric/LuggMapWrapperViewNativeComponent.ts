import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';

export interface NativeProps extends ViewProps {}

export default codegenNativeComponent<NativeProps>(
  'LuggMapWrapperView'
) as HostComponent<NativeProps>;
