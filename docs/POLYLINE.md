# Polyline

Polyline component for drawing lines on the map.

## Usage

```tsx
import { MapView, Polyline } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* Simple polyline */}
  <Polyline
    coordinates={[
      { latitude: 37.7749, longitude: -122.4194 },
      { latitude: 37.7849, longitude: -122.4094 },
      { latitude: 37.7949, longitude: -122.3994 },
    ]}
    strokeWidth={3}
  />

  {/* Gradient polyline */}
  <Polyline
    coordinates={[
      { latitude: 37.8049, longitude: -122.4194 },
      { latitude: 37.8149, longitude: -122.4094 },
      { latitude: 37.8249, longitude: -122.3994 },
    ]}
    strokeWidth={5}
    strokeColors={['#ff0000', '#00ff00', '#0000ff']}
  />
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `coordinates` | `Coordinate[]` | **required** | Array of coordinates |
| `strokeWidth` | `number` | - | Line width in points |
| `strokeColors` | `ColorValue[]` | - | Gradient colors along the line |
| `animated` | `boolean` | `false` | Animate the polyline with a snake effect |
| `animatedOptions` | `PolylineAnimatedOptions` | - | Animation configuration options |
| `zIndex` | `number` | - | Z-index for layering polylines |

## Animated Options

```ts
interface PolylineAnimatedOptions {
  duration?: number;   // milliseconds, default 2150
  easing?: 'linear' | 'easeIn' | 'easeOut' | 'easeInOut'; // default 'linear'
  trailLength?: number; // 0-1, default 1.0 (full snake effect)
  delay?: number;       // milliseconds, default 0
}
```

```tsx
<Polyline
  coordinates={coordinates}
  strokeWidth={4}
  animated
  animatedOptions={{ duration: 3000, easing: 'easeOut', trailLength: 0.5 }}
/>
```

## Gradient Colors

The `strokeColors` prop accepts an array of colors that will be applied as a gradient along the polyline. The colors are distributed evenly across the segments.

```tsx
<Polyline
  coordinates={coordinates}
  strokeWidth={4}
  strokeColors={['#ff0000', '#ffff00', '#00ff00']} // red -> yellow -> green
/>
```
