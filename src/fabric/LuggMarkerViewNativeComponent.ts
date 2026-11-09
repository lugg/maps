import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type { ViewProps, HostComponent, CodegenTypes } from 'react-native';

export interface Coordinate {
  latitude: CodegenTypes.Double;
  longitude: CodegenTypes.Double;
}

export interface Point {
  x: CodegenTypes.Double;
  y: CodegenTypes.Double;
}

export interface NativeProps extends ViewProps {
  name?: string;
  coordinate: Coordinate;
  title?: string;
  description?: string;
  anchor?: Point;
  rotate?: CodegenTypes.WithDefault<CodegenTypes.Double, 0>;
  scale?: CodegenTypes.WithDefault<CodegenTypes.Double, 1>;
  rasterize?: CodegenTypes.WithDefault<boolean, true>;
  centerOnPress?: CodegenTypes.WithDefault<boolean, true>;
  draggable?: CodegenTypes.WithDefault<boolean, false>;
  pathCoordinates?: ReadonlyArray<Coordinate>;
  pathTimes?: ReadonlyArray<CodegenTypes.Double>;
  pathRotations?: ReadonlyArray<CodegenTypes.Double>;
  pathStartTime?: CodegenTypes.Double;
  pathLoop?: CodegenTypes.WithDefault<boolean, false>;
  onMarkerPress?: CodegenTypes.DirectEventHandler<{
    coordinate: {
      latitude: CodegenTypes.Double;
      longitude: CodegenTypes.Double;
    };
    point: {
      x: CodegenTypes.Double;
      y: CodegenTypes.Double;
    };
  }>;
  onMarkerDragStart?: CodegenTypes.DirectEventHandler<{
    coordinate: {
      latitude: CodegenTypes.Double;
      longitude: CodegenTypes.Double;
    };
    point: {
      x: CodegenTypes.Double;
      y: CodegenTypes.Double;
    };
  }>;
  onMarkerDragChange?: CodegenTypes.DirectEventHandler<{
    coordinate: {
      latitude: CodegenTypes.Double;
      longitude: CodegenTypes.Double;
    };
    point: {
      x: CodegenTypes.Double;
      y: CodegenTypes.Double;
    };
  }>;
  onMarkerDragEnd?: CodegenTypes.DirectEventHandler<{
    coordinate: {
      latitude: CodegenTypes.Double;
      longitude: CodegenTypes.Double;
    };
    point: {
      x: CodegenTypes.Double;
      y: CodegenTypes.Double;
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
