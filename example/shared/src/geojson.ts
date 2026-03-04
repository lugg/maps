import type { GeoJSON } from '@lugg/maps';

export const SAMPLE_GEOJSON: GeoJSON = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [-122.42, 37.775],
            [-122.41, 37.775],
            [-122.41, 37.765],
            [-122.42, 37.765],
            [-122.42, 37.775],
          ],
        ],
      },
      properties: {
        title: 'GeoJSON Polygon',
        fill: 'rgba(255, 0, 0, 0.3)',
        stroke: '#FF0000',
        'stroke-width': 2,
      },
    },
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [-122.415, 37.77],
      },
      properties: { title: 'GeoJSON Point' },
    },
    {
      type: 'Feature',
      geometry: {
        type: 'MultiPoint',
        coordinates: [
          [-122.408, 37.772],
          [-122.405, 37.768],
        ],
      },
      properties: { title: 'GeoJSON MultiPoint' },
    },
    {
      type: 'Feature',
      geometry: {
        type: 'LineString',
        coordinates: [
          [-122.42, 37.762],
          [-122.415, 37.758],
          [-122.41, 37.76],
          [-122.405, 37.757],
        ],
      },
      properties: {
        title: 'GeoJSON LineString',
        stroke: '#FF0000',
        'stroke-width': 3,
      },
    },
    {
      type: 'Feature',
      geometry: {
        type: 'MultiLineString',
        coordinates: [
          [
            [-122.422, 37.758],
            [-122.418, 37.755],
          ],
          [
            [-122.416, 37.755],
            [-122.412, 37.752],
          ],
        ],
      },
      properties: {
        title: 'GeoJSON MultiLineString',
        stroke: '#FF9800',
        'stroke-width': 2,
      },
    },
  ],
};
