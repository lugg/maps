import React, { memo, useMemo, type ReactElement } from 'react';
import type {
  Feature,
  FeatureCollection,
  GeoJSON,
  Geometry,
  Position,
} from './GeoJson.types';
import type { Coordinate } from '../types';
import type { GeoJsonProps } from './GeoJson.types';
import { Marker } from './Marker';
import type { MarkerProps } from './Marker.types';
import { Polygon } from './Polygon';
import type { PolygonProps } from './Polygon.types';
import { Polyline } from './Polyline';
import type { PolylineProps } from './Polyline.types';

export type { GeoJsonProps } from './GeoJson.types';

const toCoordinate = (position: Position): Coordinate => ({
  latitude: position[1],
  longitude: position[0],
});

const toCoordinates = (positions: Position[]): Coordinate[] =>
  positions.map(toCoordinate);

const normalizeFeatures = (geojson: GeoJSON): Feature[] => {
  switch (geojson.type) {
    case 'FeatureCollection':
      return (geojson as FeatureCollection).features;
    case 'Feature':
      return [geojson as Feature];
    default:
      return [
        { type: 'Feature', geometry: geojson as Geometry, properties: null },
      ];
  }
};

const renderGeometry = (
  geometry: Geometry,
  feature: Feature,
  props: GeoJsonProps,
  keyPrefix: string
): ReactElement[] => {
  const elements: ReactElement[] = [];

  switch (geometry.type) {
    case 'Point': {
      const markerProps: MarkerProps = {
        coordinate: toCoordinate(geometry.coordinates),
        title: feature.properties?.title,
        description: feature.properties?.description,
        zIndex: props.zIndex,
      };
      elements.push(
        props.renderMarker ? (
          props.renderMarker(markerProps, feature) ?? (
            <React.Fragment key={keyPrefix} />
          )
        ) : (
          <Marker key={keyPrefix} {...markerProps} />
        )
      );
      break;
    }
    case 'MultiPoint': {
      for (let i = 0; i < geometry.coordinates.length; i++) {
        const markerProps: MarkerProps = {
          coordinate: toCoordinate(geometry.coordinates[i]!),
          title: feature.properties?.title,
          description: feature.properties?.description,
          zIndex: props.zIndex,
        };
        const key = `${keyPrefix}-${i}`;
        elements.push(
          props.renderMarker ? (
            props.renderMarker(markerProps, feature) ?? (
              <React.Fragment key={key} />
            )
          ) : (
            <Marker key={key} {...markerProps} />
          )
        );
      }
      break;
    }
    case 'LineString': {
      const p = feature.properties;
      const polylineProps: PolylineProps = {
        coordinates: toCoordinates(geometry.coordinates),
        strokeColors: p?.stroke ? [p.stroke] : undefined,
        strokeWidth: p?.['stroke-width'],
        zIndex: props.zIndex,
      };
      elements.push(
        props.renderPolyline ? (
          props.renderPolyline(polylineProps, feature) ?? (
            <React.Fragment key={keyPrefix} />
          )
        ) : (
          <Polyline key={keyPrefix} {...polylineProps} />
        )
      );
      break;
    }
    case 'MultiLineString': {
      const p = feature.properties;
      for (let i = 0; i < geometry.coordinates.length; i++) {
        const polylineProps: PolylineProps = {
          coordinates: toCoordinates(geometry.coordinates[i]!),
          strokeColors: p?.stroke ? [p.stroke] : undefined,
          strokeWidth: p?.['stroke-width'],
          zIndex: props.zIndex,
        };
        const key = `${keyPrefix}-${i}`;
        elements.push(
          props.renderPolyline ? (
            props.renderPolyline(polylineProps, feature) ?? (
              <React.Fragment key={key} />
            )
          ) : (
            <Polyline key={key} {...polylineProps} />
          )
        );
      }
      break;
    }
    case 'Polygon': {
      const outer = toCoordinates(geometry.coordinates[0]!);
      const holes =
        geometry.coordinates.length > 1
          ? geometry.coordinates.slice(1).map(toCoordinates)
          : undefined;
      const p = feature.properties;
      const polygonProps: PolygonProps = {
        coordinates: outer,
        holes,
        fillColor: p?.fill,
        strokeColor: p?.stroke,
        strokeWidth: p?.['stroke-width'],
        zIndex: props.zIndex,
      };
      elements.push(
        props.renderPolygon ? (
          props.renderPolygon(polygonProps, feature) ?? (
            <React.Fragment key={keyPrefix} />
          )
        ) : (
          <Polygon key={keyPrefix} {...polygonProps} />
        )
      );
      break;
    }
    case 'MultiPolygon': {
      const p = feature.properties;
      for (let i = 0; i < geometry.coordinates.length; i++) {
        const rings = geometry.coordinates[i]!;
        const outer = toCoordinates(rings[0]!);
        const holes =
          rings.length > 1 ? rings.slice(1).map(toCoordinates) : undefined;
        const polygonProps: PolygonProps = {
          coordinates: outer,
          holes,
          fillColor: p?.fill,
          strokeColor: p?.stroke,
          strokeWidth: p?.['stroke-width'],
          zIndex: props.zIndex,
        };
        const key = `${keyPrefix}-${i}`;
        elements.push(
          props.renderPolygon ? (
            props.renderPolygon(polygonProps, feature) ?? (
              <React.Fragment key={key} />
            )
          ) : (
            <Polygon key={key} {...polygonProps} />
          )
        );
      }
      break;
    }
    case 'GeometryCollection': {
      for (let i = 0; i < geometry.geometries.length; i++) {
        elements.push(
          ...renderGeometry(
            geometry.geometries[i]!,
            feature,
            props,
            `${keyPrefix}-${i}`
          )
        );
      }
      break;
    }
  }

  return elements;
};

export const GeoJson = memo((props: GeoJsonProps) => {
  const { geojson } = props;

  const elements = useMemo(() => {
    const features = normalizeFeatures(geojson);
    const result: ReactElement[] = [];

    for (let i = 0; i < features.length; i++) {
      const feature = features[i]!;
      if (!feature.geometry) continue;

      const key = feature.id != null ? String(feature.id) : String(i);
      result.push(...renderGeometry(feature.geometry, feature, props, key));
    }

    return result;
  }, [geojson, props]);

  return <>{elements}</>;
});
