import { codegenNativeComponent } from 'react-native';
import type { ViewProps, HostComponent } from 'react-native';
import type {
  Double,
  Int32,
  DirectEventHandler,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  urlTemplate: string;
  tileSize?: Int32;
  opacity?: Double;
  tappable?: boolean;
  onTileOverlayPress?: DirectEventHandler<null>;
}

export default codegenNativeComponent<NativeProps>(
  'LuggTileOverlayView'
) as HostComponent<NativeProps>;
