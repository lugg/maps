import { forwardRef } from 'react';
import Svg, { Path, Circle } from 'react-native-svg';
import { Marker, type MarkerProps } from '@lugg/maps';

interface MarkerIconProps extends MarkerProps {}

export const MarkerIcon = forwardRef<Marker, MarkerIconProps>(
  ({ anchor = { x: 0.5, y: 1 }, ...rest }, ref) => {
    return (
      <Marker ref={ref} anchor={anchor} {...rest}>
        <Svg width={32} height={40} viewBox="0 0 32 40" fill="none">
          <Path
            d="M16 0C7.164 0 0 7.164 0 16c0 12 16 24 16 24s16-12 16-24c0-8.836-7.164-16-16-16z"
            fill="#EA4335"
          />
          <Circle cx={16} cy={16} r={6} fill="white" />
        </Svg>
      </Marker>
    );
  }
);
