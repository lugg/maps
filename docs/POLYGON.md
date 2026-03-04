# Polygon

Polygon component for drawing filled shapes on the map.

## Usage

```tsx
import { MapView, Polygon } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* Simple polygon */}
  <Polygon
    coordinates={[
      { latitude: 37.784, longitude: -122.428 },
      { latitude: 37.784, longitude: -122.422 },
      { latitude: 37.779, longitude: -122.422 },
      { latitude: 37.779, longitude: -122.428 },
    ]}
    fillColor="rgba(66, 133, 244, 0.3)"
    strokeColor="#4285F4"
    strokeWidth={2}
    onPress={() => console.log('Polygon pressed')}
  />

  {/* Polygon with a hole */}
  <Polygon
    coordinates={[
      { latitude: 37.790, longitude: -122.435 },
      { latitude: 37.790, longitude: -122.420 },
      { latitude: 37.775, longitude: -122.420 },
      { latitude: 37.775, longitude: -122.435 },
    ]}
    holes={[
      [
        { latitude: 37.787, longitude: -122.432 },
        { latitude: 37.787, longitude: -122.423 },
        { latitude: 37.778, longitude: -122.423 },
        { latitude: 37.778, longitude: -122.432 },
      ],
    ]}
    fillColor="rgba(244, 67, 54, 0.3)"
    strokeColor="#F44336"
    strokeWidth={2}
  />
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `coordinates` | `Coordinate[]` | **required** | Array of coordinates forming the polygon boundary |
| `holes` | `Coordinate[][]` | - | Array of coordinate arrays representing interior holes |
| `fillColor` | `ColorValue` | - | Fill color of the polygon |
| `strokeColor` | `ColorValue` | - | Stroke (outline) color |
| `strokeWidth` | `number` | - | Stroke width in points |
| `zIndex` | `number` | - | Z-index for layering |
| `onPress` | `() => void` | - | Called when the polygon is tapped |
