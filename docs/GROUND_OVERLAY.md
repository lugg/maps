# GroundOverlay

Overlay an image on the map within geographic bounds.

## Usage

```tsx
import { MapView, GroundOverlay } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* Image from URL */}
  <GroundOverlay
    image={{ uri: 'https://example.com/overlay.png' }}
    bounds={{
      northeast: { latitude: 37.790, longitude: -122.420 },
      southwest: { latitude: 37.775, longitude: -122.435 },
    }}
    opacity={0.8}
    onPress={() => console.log('Overlay pressed')}
  />

  {/* Local image */}
  <GroundOverlay
    image={require('./assets/floor-plan.png')}
    bounds={{
      northeast: { latitude: 37.784, longitude: -122.425 },
      southwest: { latitude: 37.780, longitude: -122.430 },
    }}
  />
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `image` | `ImageSourcePropType` | **required** | Image to overlay (`require()` or `{ uri }`) |
| `bounds` | `GroundOverlayBounds` | **required** | Geographic bounds for the overlay |
| `opacity` | `number` | `1` | Opacity of the overlay (0-1) |
| `bearing` | `number` | `0` | Rotation in degrees clockwise from north (Google Maps only) |
| `zIndex` | `number` | - | Z-index for layering |
| `onPress` | `() => void` | - | Called when the overlay is tapped |

## Types

```ts
interface GroundOverlayBounds {
  northeast: Coordinate;
  southwest: Coordinate;
}
```

## Platform Notes

- **Apple Maps**: Uses a custom `MKOverlayRenderer` to draw the image. `bearing` is not supported.
- **Google Maps**: Uses `GMSGroundOverlay` (iOS) / `GroundOverlay` (Android). Supports `bearing`.
- **Web**: Uses `google.maps.GroundOverlay`.
