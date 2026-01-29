# Marker

Map marker component.

## Usage

```tsx
import { MapView, Marker } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* Basic marker */}
  <Marker
    coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
    title="San Francisco"
    description="California, USA"
  />

  {/* Custom marker view */}
  <Marker
    coordinate={{ latitude: 37.8049, longitude: -122.4094 }}
    anchor={{ x: 0.5, y: 1 }}
  >
    <View style={styles.customMarker}>
      <Text>Custom</Text>
    </View>
  </Marker>
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `coordinate` | `Coordinate` | **required** | Marker position |
| `title` | `string` | - | Callout title |
| `description` | `string` | - | Callout description |
| `anchor` | `Point` | - | Anchor point for custom views |
| `zIndex` | `number` | - | Z-index for marker ordering. Higher values render on top |
| `rotate` | `number` | `0` | Rotation angle in degrees clockwise from north |
| `scale` | `number` | `1` | Scale factor for the marker |
| `rasterize` | `boolean` | `true` | Rasterize custom marker view to bitmap (iOS/Android only) |
| `children` | `ReactNode` | - | Custom marker view |

## Custom Markers

Use the `children` prop to render a custom marker view. The `anchor` prop controls the point that is placed at the coordinate.

```tsx
<Marker
  coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
  anchor={{ x: 0.5, y: 1 }} // bottom center
>
  <View style={{ backgroundColor: 'red', padding: 8, borderRadius: 4 }}>
    <Text style={{ color: 'white' }}>Custom</Text>
  </View>
</Marker>
```

### Anchor Point

- `{ x: 0, y: 0 }` - top left
- `{ x: 0.5, y: 0 }` - top center
- `{ x: 1, y: 0 }` - top right
- `{ x: 0.5, y: 0.5 }` - center
- `{ x: 0.5, y: 1 }` - bottom center (default for pins)
