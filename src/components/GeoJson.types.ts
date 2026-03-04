import type { ReactElement } from 'react';
import type { ColorValue } from 'react-native';
import type { Feature, GeoJSON } from '../geojson.types';
import type { MarkerProps } from './Marker.types';
import type { PolygonProps } from './Polygon.types';
import type { PolylineProps } from './Polyline.types';

export interface GeoJsonProps {
  geojson: GeoJSON;
  strokeColor?: ColorValue;
  strokeWidth?: number;
  fillColor?: ColorValue;
  zIndex?: number;
  renderMarker?: (props: MarkerProps, feature: Feature) => ReactElement | null;
  renderPolyline?: (
    props: PolylineProps,
    feature: Feature
  ) => ReactElement | null;
  renderPolygon?: (
    props: PolygonProps,
    feature: Feature
  ) => ReactElement | null;
}
