import type { ReactElement } from 'react';
import type { MarkerProps } from './Marker.types';
import type { PolygonProps } from './Polygon.types';
import type { PolylineProps } from './Polyline.types';

/**
 * GeoJSON types per RFC 7946
 * Note: GeoJSON positions use [longitude, latitude] order
 */

export type Position =
  | [longitude: number, latitude: number]
  | [longitude: number, latitude: number, altitude: number];

export interface Point {
  type: 'Point';
  coordinates: Position;
}

export interface MultiPoint {
  type: 'MultiPoint';
  coordinates: Position[];
}

export interface LineString {
  type: 'LineString';
  coordinates: Position[];
}

export interface MultiLineString {
  type: 'MultiLineString';
  coordinates: Position[][];
}

export interface Polygon {
  type: 'Polygon';
  coordinates: Position[][];
}

export interface MultiPolygon {
  type: 'MultiPolygon';
  coordinates: Position[][][];
}

export interface GeometryCollection {
  type: 'GeometryCollection';
  geometries: Geometry[];
}

export type Geometry =
  | Point
  | MultiPoint
  | LineString
  | MultiLineString
  | Polygon
  | MultiPolygon
  | GeometryCollection;

export interface Feature<G extends Geometry = Geometry> {
  type: 'Feature';
  id?: string | number;
  geometry: G;
  properties: Record<string, any> | null;
}

export interface FeatureCollection<G extends Geometry = Geometry> {
  type: 'FeatureCollection';
  features: Feature<G>[];
}

export type GeoJSON = Geometry | Feature | FeatureCollection;

export interface GeoJsonProps {
  /**
   * GeoJSON data to render.
   * Accepts a `FeatureCollection`, `Feature`, or bare `Geometry`.
   */
  geojson: GeoJSON;
  /**
   * Z-index for all rendered features.
   */
  zIndex?: number;
  /**
   * Custom render function for `Point`/`MultiPoint` features.
   * @param props - Default `MarkerProps` derived from the geometry.
   * @param feature - The source GeoJSON `Feature`.
   */
  renderMarker?: (props: MarkerProps, feature: Feature) => ReactElement | null;
  /**
   * Custom render function for `LineString`/`MultiLineString` features.
   * @param props - Default `PolylineProps` derived from the geometry.
   * @param feature - The source GeoJSON `Feature`.
   */
  renderPolyline?: (
    props: PolylineProps,
    feature: Feature
  ) => ReactElement | null;
  /**
   * Custom render function for `Polygon`/`MultiPolygon` features.
   * @param props - Default `PolygonProps` derived from the geometry.
   * @param feature - The source GeoJSON `Feature`.
   */
  renderPolygon?: (
    props: PolygonProps,
    feature: Feature
  ) => ReactElement | null;
}
