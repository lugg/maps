# MapView

Main map component.

## Usage

```tsx
import { MapView } from '@lugg/maps';

<MapView
  style={{ flex: 1 }}
  provider="google"
  initialCoordinate={{ latitude: 37.7749, longitude: -122.4194 }}
  initialZoom={12}
  onCameraMove={(e) => console.log(e.nativeEvent)}
  onCameraIdle={(e) => console.log(e.nativeEvent)}
>
  {/* Markers, Polylines, etc. */}
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `provider` | `'google' \| 'apple'` | `'apple'` (iOS), `'google'` (Android) | Map provider |
| `mapId` | `string` | - | Map style ID (Google) or configuration name (Apple) |
| `initialCoordinate` | `Coordinate` | - | Initial camera coordinate |
| `initialZoom` | `number` | `10` | Initial zoom level |
| `zoomEnabled` | `boolean` | `true` | Enable zoom gestures |
| `scrollEnabled` | `boolean` | `true` | Enable scroll/pan gestures |
| `rotateEnabled` | `boolean` | `true` | Enable rotation gestures |
| `pitchEnabled` | `boolean` | `true` | Enable pitch/tilt gestures |
| `edgeInsets` | `EdgeInsets` | - | Map content edge insets |
| `userLocationEnabled` | `boolean` | `false` | Show current user location on the map |
| `userLocationButtonEnabled` | `boolean` | `false` | Show native my-location button (Android only) |
| `theme` | `'light' \| 'dark' \| 'system'` | `'system'` | Map color theme |
| `onCameraMove` | `(event) => void` | - | Called when camera moves |
| `onCameraIdle` | `(event) => void` | - | Called when camera stops moving |

## Ref Methods

```tsx
import { useRef } from 'react';
import { MapView, MapViewRef } from '@lugg/maps';

const mapRef = useRef<MapViewRef>(null);

// Move camera to coordinate
mapRef.current?.moveCamera(
  { latitude: 37.7749, longitude: -122.4194 },
  { zoom: 15, duration: 500 }
);

// Fit coordinates in view
mapRef.current?.fitCoordinates(
  [
    { latitude: 37.7749, longitude: -122.4194 },
    { latitude: 37.8049, longitude: -122.4094 },
  ],
  { padding: { top: 50, left: 50, bottom: 50, right: 50 }, duration: 500 }
);

// Set edge insets with animation
mapRef.current?.setEdgeInsets(
  { top: 0, left: 0, bottom: 200, right: 0 },
  { duration: 300 }
);
```

### moveCamera

Move the camera to a coordinate with optional zoom and animation duration.

```ts
moveCamera(coordinate: Coordinate, options: MoveCameraOptions): void

interface MoveCameraOptions {
  zoom: number;
  duration?: number; // milliseconds, -1 for default
}
```

### fitCoordinates

Fit multiple coordinates in the visible map area.

```ts
fitCoordinates(coordinates: Coordinate[], options?: FitCoordinatesOptions): void

interface FitCoordinatesOptions {
  padding?: EdgeInsets;
  duration?: number; // milliseconds, -1 for default
}
```

### setEdgeInsets

Programmatically update the map's edge insets with optional animation.

```ts
setEdgeInsets(edgeInsets: EdgeInsets, options?: SetEdgeInsetsOptions): void

interface SetEdgeInsetsOptions {
  duration?: number; // milliseconds, -1 for default animation, 0 for instant
}
```

## Events

### onCameraMove

Called continuously while the camera is moving.

```ts
interface CameraMoveEvent {
  coordinate: Coordinate;
  zoom: number;
  dragging: boolean; // true if user is dragging
}
```

### onCameraIdle

Called when the camera stops moving.

```ts
interface CameraIdleEvent {
  coordinate: Coordinate;
  zoom: number;
}
```
