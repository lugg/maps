---
name: maps-usage
description: >-
  Consumer-side guide for integrating @lugg/maps (universal Apple Maps / Google Maps for
  React Native) into an app. Use this skill whenever the user wants to render, configure,
  control, or debug a map in a React Native or Expo app — including MapView setup and API
  keys (Expo config plugin, bare iOS/Android, web MapProvider), choosing Apple vs Google,
  camera control (moveCamera, fitCoordinates, setEdgeInsets, reload), markers with custom
  views, callouts, drag, rotation and scale, Reanimated-driven marker animation, polylines
  with gradients and snake animation, polygons, circles, ground and tile overlays, GeoJSON,
  static maps in lists (staticMode / staticKey), user location, edge insets for bottom
  sheets, map events, theming, POI filtering, and Jest testing. Also use when the user
  describes a map, pins, routes, or geofences in a React Native context without naming
  @lugg/maps, or asks about any MapView / Marker / Polyline prop, event, method, or
  platform limitation.
---

# @lugg/maps Consumer Guide

Use this skill to produce correct, idiomatic code for apps that consume `@lugg/maps`. It covers setup, picking the right provider, applying the public API correctly, and avoiding platform-specific pitfalls.

Requires React Native New Architecture (Fabric) — on by default in React Native 0.76+ and Expo SDK 52+. Google Maps needs an API key on every platform; Apple Maps needs none.

## Quick Start

```tsx
import { MapView, Marker } from '@lugg/maps';

export function Map() {
  return (
    <MapView
      style={{ flex: 1 }}
      initialCoordinate={{ latitude: 37.7749, longitude: -122.4194 }}
      initialZoom={12}
    >
      <Marker
        coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
        title="San Francisco"
      />
    </MapView>
  );
}
```

`MapView` must have a size (`flex: 1`, a fixed `height`, or `StyleSheet.absoluteFill`). Children are map overlays only (`Marker`, `Polyline`, `Polygon`, `Circle`, `GeoJson`, `GroundOverlay`, `TileOverlay`) — render buttons and cards as siblings positioned over the map, not as map children.

## Setup at a Glance

| Target | What to do |
|--------|-----------|
| **Expo** | Add the config plugin to `app.json` with `iosGoogleMapsApiKey` / `androidGoogleMapsApiKey`, then `npx expo prebuild --clean`. Apple-only apps: `"iosGoogleMapsEnabled": false` drops the Google SDK |
| **Bare iOS** | `GMSServices.provideAPIKey("KEY")` in `AppDelegate.swift`, `pod install`. Apple-only: `$LuggMapsGoogleEnabled = false` at the top of the Podfile |
| **Bare Android** | `com.google.android.geo.API_KEY` meta-data in `AndroidManifest.xml` |
| **Web** | `yarn add @vis.gl/react-google-maps`, wrap the app in `<MapProvider apiKey="WEB_KEY">` |

`MapProvider` is a pass-through on native, so it's safe to wrap the whole app once. Full snippets in [Configuration](./references/configuration.md#setup).

## Providers

| Platform | Providers | Default |
|----------|-----------|---------|
| iOS | `'apple'`, `'google'` | `'apple'` |
| Android | `'google'` | `'google'` |
| Web | `'google'` (Maps JavaScript API) | `'google'` |

```tsx
<MapView provider="google" />
```

`provider` is creation-time. To switch at runtime, remount: `<MapView key={provider} provider={provider} />`. With the Google SDK excluded on iOS, `provider="google"` falls back to Apple and logs a warning.

The `'google' | 'apple'` string type is exported as `MapProviderType` (the name `MapProvider` is the web context component).

## Camera

Set the starting camera with `initialCoordinate` + `initialZoom` (Google-style zoom levels; Apple Maps emulates them). Everything after that is imperative through a ref:

```tsx
import { useRef } from 'react';
import { MapView, type MapViewRef } from '@lugg/maps';

const mapRef = useRef<MapViewRef>(null);

// Move (keeps heading/pitch; omit zoom to keep current zoom)
mapRef.current?.moveCamera(coordinate, { zoom: 15, duration: 500 });

// Fit many points (resets heading to north)
mapRef.current?.fitCoordinates(coords, {
  padding: { top: 60, left: 40, bottom: 40, right: 40 },
  duration: 500,
});

// Shift the visible viewport (e.g. under a bottom sheet)
mapRef.current?.setEdgeInsets({ top: 0, left: 0, bottom: 240, right: 0 }, { duration: 300 });

// Recover from missing tiles after a network outage
mapRef.current?.reload();

<MapView ref={mapRef} style={{ flex: 1 }} onReady={() => mapRef.current?.fitCoordinates(coords)} />
```

- `duration`: milliseconds. `-1` (default) = platform default animation, `0` = instant.
- `fitCoordinates` with a single coordinate calls `moveCamera` at `initialZoom`.
- `reload()` recreates a live map at its current coordinate and zoom (heading/pitch reset, `onReady` fires again). Markers and overlays stay.
- Clamp zoom with `minZoom` / `maxZoom`.

## Common Recipes

### Custom marker view

```tsx
<Marker coordinate={coord} anchor={{ x: 0.5, y: 1 }} zIndex={2}>
  <View style={{ padding: 6, borderRadius: 8, backgroundColor: '#4285F4' }}>
    <Text style={{ color: 'white' }}>Pickup</Text>
  </View>
</Marker>
```

- `anchor` is the fraction of the view placed at the coordinate. Default `{x: 0.5, y: 1}` (bottom-center, pin-style). Use `{x: 0.5, y: 0.5}` for dots and avatars.
- Custom views are rasterized to a bitmap by default (`rasterize`). Set `rasterize={false}` only when the content itself animates (Lottie, spinners). `coordinate`, `rotate`, `scale`, `zIndex` updates work either way.
- Remote images inside markers appear when loaded — no extra handling.

### Callouts

```tsx
// Native bubble from title/description
<Marker coordinate={coord} title="Ferry Building" description="Embarcadero" />

// Custom content in the native bubble (rasterized on Google Maps → not tappable)
<Marker coordinate={coord} callout={<CalloutCard place={place} />} />

// Interactive custom callout (live view, no native chrome)
<Marker
  coordinate={coord}
  callout={<CalloutCard place={place} onBook={book} />}
  calloutOptions={{ bubbled: false, offset: { x: 0, y: -8 } }}
/>
```

Rule: **buttons inside a callout need `bubbled: false`.** Bubbled callouts are rendered as images on Google Maps (iOS and Android). Show/hide programmatically with `markerRef.current?.showCallout()` / `hideCallout()`.

### Draggable marker

```tsx
const [coord, setCoord] = useState(initial);

<Marker
  coordinate={coord}
  draggable
  onDragEnd={(e) => setCoord(e.nativeEvent.coordinate)}
/>
```

### Route with gradient and snake animation

```tsx
<Polyline coordinates={route} strokeWidth={6} strokeColors={['#B0B0B0']} />
<Polyline
  coordinates={route}
  strokeWidth={6}
  strokeColors={['#B321E0', '#3744FF']}
  animated
  animatedOptions={{ duration: 1250, easing: 'easeInOut', trailLength: 1 }}
/>
```

Layer a static gray line under an animated one for a "progress" look. `strokeColors` with one entry is a solid line; more entries spread evenly as a gradient. Polylines have **no `onPress`**.

### Shapes

```tsx
<Polygon coordinates={outer} holes={[inner]} fillColor="rgba(66,133,244,0.3)" strokeColor="#4285F4" strokeWidth={2} onPress={select} />
<Circle center={coord} radius={500 /* meters */} fillColor="rgba(244,67,54,0.3)" strokeColor="#F44336" strokeWidth={2} />
```

### GeoJSON

```tsx
<GeoJson
  geojson={featureCollection}
  renderMarker={(props, feature) => (
    <Marker key={feature.id} {...props}>
      <Pin color={feature.properties?.color} />
    </Marker>
  )}
/>
```

Points → `Marker`, LineStrings → `Polyline`, Polygons → `Polygon` (holes preserved). Positions are `[longitude, latitude]`. simplestyle props (`title`, `description`, `stroke`, `stroke-width`, `fill`) map automatically; render callbacks win over them. Return **keyed** elements from render callbacks, and keep `geojson` and callbacks referentially stable (`useMemo` / `useCallback`) — the component is memoized on them.

### Static maps in lists

```tsx
<Pressable onPress={() => open(place)}>
  <View style={{ height: 140 }} pointerEvents="none">
    <MapView
      staticMode
      staticKey={place.id}
      style={StyleSheet.absoluteFill}
      initialCoordinate={place.coordinate}
      initialZoom={14}
    >
      <Marker coordinate={place.coordinate} />
    </MapView>
  </View>
</Pressable>
```

- `staticMode` is creation-time. It renders a lite-mode bitmap (Android), an off-thread snapshot (iOS), or a gesture-less live map (web).
- `staticKey` (iOS) caches the base image across list recycling — use the row id. Camera and map settings are part of the key automatically; markers and shapes stay live and re-render from props.
- Bound how many rows mount at once (`windowSize`, `initialNumToRender`, `maxToRenderPerBatch`) — every mounted static map holds an image.
- Taps: wrap in a `Pressable` with `pointerEvents="none"` on the map container; `onPress` is disabled in static mode.
- Compute the camera up front (see [fitted camera](./references/advanced-patterns.md#fitted-camera-for-static-maps)) instead of calling `fitCoordinates` in `onReady`.

### User location

```tsx
<MapView userLocationEnabled={granted} userLocationButtonEnabled /* Android */ />
```

The library never requests permission. Request it first (`expo-location`, `PermissionsAndroid`, `react-native-permissions`), then flip the prop — Android checks permission at the moment the prop is set and silently ignores it otherwise. iOS needs `NSLocationWhenInUseUsageDescription` in Info.plist.

### Map under a bottom sheet

Keep the map full-screen and push the *viewport* up with edge insets so the camera center, attribution, and compass move together:

```tsx
// e.g. from TrueSheet onDetentChange / onDidPresent
const bottom = screenHeight - event.nativeEvent.position;
mapRef.current?.setEdgeInsets({ top: 0, left: 0, bottom, right: 0 });
```

Camera events report the **logical** center (inset-adjusted), so a fixed center pin overlay stays accurate. See [Bottom sheet + center pin](./references/advanced-patterns.md#bottom-sheet-with-edge-insets-and-center-pin).

### Animated marker (Reanimated)

```tsx
const AnimatedMarker = Animated.createAnimatedComponent(Marker);

const animatedProps = useAnimatedProps(() => ({
  coordinate: { latitude: lat.value, longitude: lng.value },
  rotate: bearing.value,
  scale: scale.value,
}));

<AnimatedMarker coordinate={start} anchor={{ x: 0.5, y: 0.5 }} animatedProps={animatedProps}>
  <TruckIcon />
</AnimatedMarker>
```

Native only — on web drive `coordinate` / `rotate` with state (`Platform.select` or a `.web.tsx` file). Full example in [Advanced Patterns](./references/advanced-patterns.md#animated-marker-along-a-route).

## Rules That Save Debugging Time

1. **Size the map.** `MapView` renders nothing without `flex: 1`, a fixed height, or `absoluteFill`.
2. **Only map components as children.** Overlay UI (buttons, cards, center pins) goes as siblings in an outer `View`.
3. **`provider` and `staticMode` are creation-time.** Change them by remounting with `key`.
4. **Web needs `MapProvider` + `@vis.gl/react-google-maps`.** Native ignores it, so wrap once at the root.
5. **Camera payload is `{ coordinate, zoom, gesture }`.** `gesture` is `true` for user-driven moves. Prefer `onCameraIdle` for state; `onCameraMove` fires every frame.
6. **`moveCamera` without `zoom` keeps the current zoom.** `fitCoordinates` resets heading to north and falls back to `moveCamera` for one coordinate.
7. **Interactive callouts need `calloutOptions={{ bubbled: false }}`.** Bubbled custom callouts are bitmaps on Google Maps.
8. **Don't set `rasterize={false}` by default.** Only for markers whose *content* animates. Coordinate/rotate/scale changes don't need it.
9. **Animate markers with `animatedProps`, not `setState` per frame.** Web falls back to state.
10. **`userLocationEnabled` doesn't ask for permission.** Request first, then enable.
11. **No `onPress` on `Polyline`; `TileOverlay.onPress` is not supported natively.** Put a transparent `Polygon` or markers on top if you need taps on a line.
12. **Overlapping markers: derive `zIndex` from latitude** (`Math.round((90 - lat) * 10000)`) so southern markers draw on top, like real pins.
13. **GeoJSON is `[lng, lat]`.** Render callbacks must return keyed elements.
14. **Static lists: `pointerEvents="none"` + `Pressable` wrapper, `staticKey` = row id, bounded `windowSize`.**
15. **Bottom sheets: inset the viewport (`edgeInsets` / `setEdgeInsets`), don't shrink the map.**
16. **`mapId` defaults to `DEMO_MAP_ID` on Google.** Supply your own cloud Map ID for production styling. Ignored by Android lite-mode static maps. On Apple it's a map configuration name.
17. **Apple-only props:** `poiEnabled`, `poiFilter`, `'muted-standard'`. `'terrain'` falls back to standard on Apple. **Android-only:** `userLocationButtonEnabled`. **Google-only:** `GroundOverlay.bearing`.

## Platform Differences at a Glance

| Feature | iOS Apple | iOS Google | Android | Web |
|---------|-----------|------------|---------|-----|
| Provider available | Yes | Yes (needs key, can be excluded) | Google only | Google only |
| `mapType: 'terrain'` | Falls back to standard | Yes | Yes | Yes |
| `mapType: 'muted-standard'` | Yes | Falls back to standard | Falls back | Falls back |
| `mapId` | Configuration name | Cloud Map ID | Cloud Map ID (not in lite static) | Cloud Map ID |
| `theme` (light/dark/system) | Yes | Yes | Yes | Yes |
| `poiEnabled` / `poiFilter` | Yes | No | No | No |
| `rotateEnabled` / `pitchEnabled` | Yes | Yes | Yes | `pitchEnabled` only |
| `compassEnabled` | Yes | Yes | Yes | Toggles rotate control |
| `userLocationButtonEnabled` | No | No | Yes | No |
| `insetAdjustment` (safe area) | Yes | Yes | Yes | No |
| `staticMode` | Snapshot (`MKMapSnapshotter`) | Warm-up map → image | Lite mode bitmap | Live map, gestures off |
| `staticKey` cache | Yes | Yes | No | No |
| Bubbled custom callout | Live view | Rasterized image | Rasterized image | InfoWindow (live) |
| Non-bubbled callout | Live view | Live view | Live view | Styled InfoWindow |
| Marker `rasterize` | Yes | Yes | Yes | N/A |
| Reanimated `animatedProps` on `Marker` | Yes | Yes | Yes | No |
| `Polyline` gradient + `animated` | Yes | Yes | Yes | Yes (JS) |
| `GroundOverlay.bearing` | No | Yes | Yes | No |
| `TileOverlay.onPress` | No | No | No | Yes |
| `onLongPress` | Native | Native | Native | Emulated (500 ms mousedown) |
| Location permission prompt | App's job | App's job | App's job (checked at set time) | Browser prompt |

## Events

| Event | When it fires | Payload (`e.nativeEvent`) |
|-------|--------------|---------------------------|
| `onReady` | Map loaded (again after `reload()`) | — |
| `onPress` / `onLongPress` | Map tapped / long-pressed (not in static mode) | `{ coordinate, point }` |
| `onCameraMove` | Continuously while the camera moves | `{ coordinate, zoom, gesture }` |
| `onCameraIdle` | Camera settled | `{ coordinate, zoom, gesture }` |
| `Marker.onPress` | Marker tapped (also centers the map unless `centerOnPress={false}`) | `{ coordinate, point }` |
| `Marker.onDragStart` / `onDragChange` / `onDragEnd` | Drag lifecycle (`draggable`) | `{ coordinate, point }` |
| `Polygon` / `Circle` / `GroundOverlay` `onPress` | Shape tapped | — |

Full list and types in the [API reference](./references/api.md#events).

## Methods

**`MapViewRef`:** `moveCamera(coordinate, { zoom?, duration? })`, `fitCoordinates(coordinates, { padding?, duration? })`, `setEdgeInsets(insets, { duration? })`, `reload()`

**`MarkerRef`:** `showCallout()`, `hideCallout()`

## Deep-Dive References

| Reference | What's inside |
|-----------|--------------|
| [Configuration](./references/configuration.md) | Setup snippets, every prop of every component with type, default, and platform support |
| [API](./references/api.md) | Ref methods, events, and payload types |
| [Advanced Patterns](./references/advanced-patterns.md) | Bottom sheet insets, center pin, animated markers, routes, marker registries, fitted static cameras, provider switching, web, Expo plugin, Jest |
| [Troubleshooting](./references/troubleshooting.md) | Symptom → cause → fix, by platform |
