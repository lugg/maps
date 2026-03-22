import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
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
  draggable?: WithDefault<boolean, false>;
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
  onMarkerDragStart?: DirectEventHandler<{
    coordinate: {
      latitude: Double;
      longitude: Double;
    };
    point: {
      x: Double;
      y: Double;
    };
  }>;
  onMarkerDragChange?: DirectEventHandler<{
    coordinate: {
      latitude: Double;
      longitude: Double;
    };
    point: {
      x: Double;
      y: Double;
    };
  }>;
  onMarkerDragEnd?: DirectEventHandler<{
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

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  showCallout: (viewRef: React.ElementRef<ComponentType>) => void;
  hideCallout: (viewRef: React.ElementRef<ComponentType>) => void;
}

export const Commands = codegenNativeCommands<NativeCommands>({
  supportedCommands: ['showCallout', 'hideCallout'],
});

export default codegenNativeComponent<NativeProps>(
  'LuggMarkerView'
) as ComponentType;
