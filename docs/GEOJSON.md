# GeoJson

Renders [GeoJSON](https://geojson.org/) data on the map using Marker, Polyline, and Polygon components.

## Usage

```tsx
import { MapView, GeoJson } from '@lugg/maps';

const geojson = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [-122.4194, 37.7749],
      },
      properties: { title: 'San Francisco' },
    },
    {
      type: 'Feature',
      geometry: {
        type: 'Polygon',
        coordinates: [[
          [-122.428, 37.784],
          [-122.422, 37.784],
          [-122.422, 37.779],
          [-122.428, 37.779],
          [-122.428, 37.784],
        ]],
      },
      properties: { fill: 'rgba(66, 133, 244, 0.3)', stroke: '#4285F4' },
    },
  ],
};

<MapView style={{ flex: 1 }}>
  <GeoJson geojson={geojson} />
</MapView>
```

### Custom Rendering

Use render callbacks to customize how features are rendered:

```tsx
<GeoJson
  geojson={data}
  renderMarker={(props, feature) => (
    <Marker {...props} title={feature.properties?.name}>
      <CustomPin />
    </Marker>
  )}
  renderPolygon={(props, feature) => (
    <Polygon {...props} fillColor={feature.properties?.color} />
  )}
/>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `geojson` | `GeoJSON` | **required** | GeoJSON object (FeatureCollection, Feature, or Geometry) |
| `strokeColor` | `ColorValue` | - | Default stroke color for polylines and polygons |
| `strokeWidth` | `number` | - | Default stroke width |
| `fillColor` | `ColorValue` | - | Default fill color for polygons |
| `zIndex` | `number` | - | Z-index for all rendered components |
| `renderMarker` | `(props, feature) => ReactElement` | - | Custom marker renderer |
| `renderPolyline` | `(props, feature) => ReactElement` | - | Custom polyline renderer |
| `renderPolygon` | `(props, feature) => ReactElement` | - | Custom polygon renderer |

## Geometry Mapping

| GeoJSON Type | Renders As |
|---|---|
| Point | `<Marker>` |
| MultiPoint | Multiple `<Marker>` |
| LineString | `<Polyline>` |
| MultiLineString | Multiple `<Polyline>` |
| Polygon | `<Polygon>` (with holes) |
| MultiPolygon | Multiple `<Polygon>` |
| GeometryCollection | Recursive rendering |

## Feature Properties (simplestyle-spec)

Per-feature styling via `feature.properties` overrides component-level props:

| Property | Maps To |
|---|---|
| `title` | Marker `title` |
| `description` | Marker `description` |
| `stroke` | Polyline `strokeColors[0]` / Polygon `strokeColor` |
| `stroke-width` | Polyline/Polygon `strokeWidth` |
| `fill` | Polygon `fillColor` |

Precedence: render callback > feature properties > component props.
