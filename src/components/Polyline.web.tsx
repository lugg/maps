import React from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import type { PolylineProps } from './Polyline';

function PolylineImpl({
  coordinates,
  strokeColors,
  strokeWidth,
}: PolylineProps) {
  const map = useMap();

  React.useEffect(() => {
    if (!map || coordinates.length === 0) return;

    const path = coordinates.map((coord) => ({
      lat: coord.latitude,
      lng: coord.longitude,
    }));

    const strokeColor =
      strokeColors && strokeColors.length > 0
        ? (strokeColors[0] as string)
        : '#000000';

    const polyline = new google.maps.Polyline({
      path,
      strokeColor,
      strokeWeight: strokeWidth ?? 3,
      strokeOpacity: 1,
      map,
    });

    return () => {
      polyline.setMap(null);
    };
  }, [map, coordinates, strokeColors, strokeWidth]);

  return null;
}

export class Polyline extends React.Component<PolylineProps> {
  render() {
    return <PolylineImpl {...this.props} />;
  }
}
