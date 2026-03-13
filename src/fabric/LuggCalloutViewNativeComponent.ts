import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  onCalloutPress?: DirectEventHandler<{}>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggCalloutView'
) as HostComponent<NativeProps>;
