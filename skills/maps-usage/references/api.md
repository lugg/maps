# API Reference

Ref methods, events, and payload types for `@lugg/maps`.

## Table of Contents

- [Methods](#methods)
  - [MapViewRef](#mapviewref)
  - [MarkerRef](#markerref)
- [Events](#events)
  - [MapView events](#mapview-events)
  - [Marker events](#marker-events)
  - [Shape and overlay events](#shape-and-overlay-events)
- [Payload types](#payload-types)
- [Typing refs](#typing-refs)

---

## Methods

All methods are synchronous fire-and-forget (`void`). They no-op until the native view exists, so call them from `onReady` or a user action, not during the first render.

### MapViewRef

| Method | Signature | Description |
|--------|-----------|-------------|
| `moveCamera` | `(coordinate: Coordinate, options?: { zoom?: number; duration?: number }) => void` | Center on a coordinate. `zoom` omitted/`0` keeps the current zoom. Heading and pitch are preserved |
| `fitCoordinates` | `(coordinates: Coordinate[], options?: { padding?: EdgeInsets; duration?: number }) => void` | Fit all points in view. Resets heading to north. `padding` is added on top of the current `edgeInsets`. A single coordinate delegates to `moveCamera` at `initialZoom`. Empty array is a no-op |
| `setEdgeInsets` | `(edgeInsets: EdgeInsets, options?: { duration?: number }) => void` | Shift the viewport (logical center, attribution, controls). Camera events report the inset-adjusted center |
| `reload` | `() => void` | Rebuild the map at the current coordinate and zoom. Live map: heading/pitch reset, `onReady` fires again, children remain. Static map: re-renders the base map and drops the cached `staticKey` image (iOS) or recreates the lite map (Android). Preserves `mapType` and edge insets |

`duration` (ms): `-1` (default) = platform default animation, `0` = instant, `> 0` = custom. Static maps ignore it.

```ts
interface MoveCameraOptions { zoom?: number; duration?: number }
interface FitCoordinatesOptions { padding?: EdgeInsets; duration?: number }
interface SetEdgeInsetsOptions { duration?: number }
```

### MarkerRef

| Method | Signature | Description |
|--------|-----------|-------------|
| `showCallout` | `() => void` | Open the callout. No-op without `callout`, `title`, or `description` |
| `hideCallout` | `() => void` | Close the callout |

Only one callout is open per map; showing one closes the others.

---

## Events

All handlers receive a `NativeSyntheticEvent`; read data from `e.nativeEvent`.

### MapView events

| Prop | Type | Fires |
|------|------|-------|
| `onReady` | `() => void` | Map finished loading. Again after `reload()`. On web, once per map instance |
| `onPress` | `(e: MapPressEvent) => void` | Tap on empty map (not on a marker/shape). Disabled in `staticMode` |
| `onLongPress` | `(e: MapPressEvent) => void` | Long press. Web: 500 ms mousedown without drag |
| `onCameraMove` | `(e: MapCameraEvent) => void` | Every camera frame — gestures, animations, programmatic moves. Keep the handler cheap |
| `onCameraIdle` | `(e: MapCameraEvent) => void` | Camera settled. Use for state, fetching, and URL sync |

`gesture` in the camera payload: during `onCameraMove` it means the user is currently dragging; in `onCameraIdle` it means the finished movement was user-initiated (vs `moveCamera` / `fitCoordinates`).

### Marker events

| Prop | Type | Fires |
|------|------|-------|
| `onPress` | `(e: MarkerPressEvent) => void` | Marker tapped. Also centers the map (unless `centerOnPress={false}`) and toggles the callout if any |
| `onDragStart` | `(e: MarkerDragEvent) => void` | Drag began (`draggable` only) |
| `onDragChange` | `(e: MarkerDragEvent) => void` | Continuous during drag |
| `onDragEnd` | `(e: MarkerDragEvent) => void` | Drag finished — persist `e.nativeEvent.coordinate` to state here |

The marker's `coordinate` prop is not mutated by dragging; if you don't write it back on `onDragEnd`, the next re-render snaps the marker back.

### Shape and overlay events

| Component | Prop | Type | Notes |
|-----------|------|------|-------|
| `Polygon` | `onPress` | `() => void` | Hit-tested against the fill, holes excluded |
| `Circle` | `onPress` | `() => void` | |
| `GroundOverlay` | `onPress` | `() => void` | |
| `TileOverlay` | `onPress` | `() => void` | Web only |
| `Polyline` | — | | No press support |

Shape press handlers have no payload. Use the map's `onPress` coordinate if you need the tap location — it does **not** fire when a shape consumed the tap.

---

## Payload types

```ts
interface Coordinate { latitude: number; longitude: number }
interface Point { x: number; y: number } // view-relative pixels

interface PressEventPayload {
  coordinate: Coordinate;
  point: Point;
}

interface CameraEventPayload {
  coordinate: Coordinate; // logical center (edge insets applied)
  zoom: number;
  gesture: boolean;
}

type MapPressEvent = NativeSyntheticEvent<PressEventPayload>;
type MapCameraEvent = NativeSyntheticEvent<CameraEventPayload>;
type MarkerPressEvent = NativeSyntheticEvent<PressEventPayload>;
type MarkerDragEvent = NativeSyntheticEvent<PressEventPayload>;
```

---

## Typing refs

```tsx
import { useRef } from 'react';
import { MapView, Marker, type MapViewRef, type MarkerRef } from '@lugg/maps';

const mapRef = useRef<MapViewRef>(null);
const markerRef = useRef<MarkerRef>(null);

<MapView ref={mapRef}>
  <Marker ref={markerRef} coordinate={coord} title="Hi" />
</MapView>
```

`MapView` and `Marker` are class components on native, so `useRef<MapView>(null)` also works, but `MapViewRef` / `MarkerRef` are the portable types across native and web.

Wrapping the map in your own component? Forward the methods explicitly:

```tsx
export interface AppMapRef extends MapViewRef {
  showMarkerCallout(id: string): void;
}

useImperativeHandle(ref, () => ({
  moveCamera: (...args) => mapRef.current?.moveCamera(...args),
  fitCoordinates: (...args) => mapRef.current?.fitCoordinates(...args),
  setEdgeInsets: (...args) => mapRef.current?.setEdgeInsets(...args),
  reload: () => mapRef.current?.reload(),
  showMarkerCallout: (id) => markerRefs.current.get(id)?.showCallout(),
}), []);
```
