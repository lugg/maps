# TileOverlay

Display custom map tile layers on top of the base map.

## Usage

```tsx
import { MapView, TileOverlay } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* OpenStreetMap tiles */}
  <TileOverlay
    urlTemplate="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    opacity={0.7}
  />

  {/* Custom tile server with bounds */}
  <TileOverlay
    urlTemplate="https://tiles.example.com/{z}/{x}/{y}.png"
    tileSize={512}
    opacity={0.5}
    zIndex={1}
    bounds={{
      southwest: { latitude: 37.77, longitude: -122.44 },
      northeast: { latitude: 37.79, longitude: -122.42 },
    }}
  />
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `urlTemplate` | `string` | **required** | URL template with `{x}`, `{y}`, `{z}` placeholders |
| `tileSize` | `number` | `256` | Size of each tile in pixels |
| `opacity` | `number` | `1` | Opacity of the tile layer (0-1) |
| `bounds` | `TileOverlayBounds` | - | Restrict tiles to a geographic region |
| `zIndex` | `number` | - | Z-index for layering |
| `onPress` | `() => void` | - | Called when the tile overlay is tapped |

## Platform Notes

- **Apple Maps**: Uses `MKTileOverlay` with `MKTileOverlayRenderer`.
- **Google Maps**: Uses `GMSURLTileLayer` (iOS) / `UrlTileProvider` (Android).
- **Web**: Uses `google.maps.ImageMapType`.
- **`onPress`**: Not natively supported by map SDKs. Behavior may vary by platform.
