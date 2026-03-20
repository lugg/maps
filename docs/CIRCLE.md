# Circle

Circle component for drawing circular overlays on the map.

## Usage

```tsx
import { MapView, Circle } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  <Circle
    center={{ latitude: 37.78, longitude: -122.43 }}
    radius={500}
    fillColor="rgba(66, 133, 244, 0.3)"
    strokeColor="#4285F4"
    strokeWidth={2}
    onPress={() => console.log('Circle pressed')}
  />
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `center` | `Coordinate` | **required** | Center coordinate of the circle |
| `radius` | `number` | **required** | Radius in meters |
| `fillColor` | `ColorValue` | - | Fill color of the circle |
| `strokeColor` | `ColorValue` | - | Stroke (outline) color |
| `strokeWidth` | `number` | - | Stroke width in points |
| `zIndex` | `number` | - | Z-index for layering |
| `onPress` | `() => void` | - | Called when the circle is tapped |
