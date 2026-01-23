import React from 'react';
import { AdvancedMarker } from '@vis.gl/react-google-maps';
import type { MarkerProps } from './Marker';

export class Marker extends React.Component<MarkerProps> {
  render() {
    const { coordinate, title, anchor, zIndex, children } = this.props;

    const position = {
      lat: coordinate.latitude,
      lng: coordinate.longitude,
    };

    const style: React.CSSProperties | undefined = anchor
      ? {
          transform: `translate(${(anchor.x - 0.5) * -100}%, ${
            (anchor.y - 0.5) * -100
          }%)`,
        }
      : undefined;

    return (
      <AdvancedMarker position={position} title={title} zIndex={zIndex}>
        {children ? <div style={style}>{children}</div> : null}
      </AdvancedMarker>
    );
  }
}
