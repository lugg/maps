import React from 'react';
import { AdvancedMarker } from '@vis.gl/react-google-maps';
import type { MarkerProps } from './Marker';

/**
 * Converts point to % anchor for web.
 * e.g. `0.5` to `-50%`
 */
const toWebAnchor = (value: number) => `-${value * 100}%`;

export class Marker extends React.Component<MarkerProps> {
  render() {
    const { coordinate, title, anchor, zIndex, children } = this.props;

    const position = {
      lat: coordinate.latitude,
      lng: coordinate.longitude,
    };

    return (
      <AdvancedMarker
        position={position}
        title={title}
        zIndex={zIndex}
        anchorLeft={anchor ? toWebAnchor(anchor.x) : undefined}
        anchorTop={anchor ? toWebAnchor(anchor.y) : undefined}
      >
        {children}
      </AdvancedMarker>
    );
  }
}
