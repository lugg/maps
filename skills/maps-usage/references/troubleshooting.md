# Troubleshooting

Common issues with `@lugg/maps`, organized by symptom.

## Table of Contents

- [Map renders blank or zero height](#map-renders-blank-or-zero-height)
- [Blank / beige map with Google provider](#blank--beige-map-with-google-provider)
- [Google requested but Apple Maps shows (iOS)](#google-requested-but-apple-maps-shows-ios)
- [Changing `provider` or `staticMode` does nothing](#changing-provider-or-staticmode-does-nothing)
- [Camera doesn't move on mount](#camera-doesnt-move-on-mount)
- [Buttons inside a callout don't respond](#buttons-inside-a-callout-dont-respond)
- [Animated content inside a marker is frozen](#animated-content-inside-a-marker-is-frozen)
- [Marker snaps back after dragging](#marker-snaps-back-after-dragging)
- [Marker animation janks or re-renders every frame](#marker-animation-janks-or-re-renders-every-frame)
- [Overlapping markers stack wrong](#overlapping-markers-stack-wrong)
- [Center pin / selected coordinate is offset under a sheet](#center-pin--selected-coordinate-is-offset-under-a-sheet)
- [`e.nativeEvent.dragging` is undefined](#enativeeventdragging-is-undefined)
- [User location dot never appears](#user-location-dot-never-appears)
- [Static maps in a list are slow or crash the app](#static-maps-in-a-list-are-slow-or-crash-the-app)
- [Static map row shows a stale or missing image](#static-map-row-shows-a-stale-or-missing-image)
- [Static list map taps don't fire](#static-list-map-taps-dont-fire)
- [`mapType` / `mapId` ignored on Android list maps](#maptype--mapid-ignored-on-android-list-maps)
- [GeoJSON renders in the wrong place](#geojson-renders-in-the-wrong-place)
- [GeoJSON key warnings or flicker](#geojson-key-warnings-or-flicker)
- [Polyline `onPress` doesn't exist](#polyline-onpress-doesnt-exist)
- [Web: `MapProvider` errors or nothing renders](#web-mapprovider-errors-or-nothing-renders)
- [Web: `Animated.createAnimatedComponent(Marker)` doesn't animate](#web-animatedcreateanimatedcomponentmarker-doesnt-animate)
- [Web: import of `MapProviderType` / `MarkerRef` fails typecheck](#web-import-of-mapprovidertype--markerref-fails-typecheck)
- [Build fails: New Architecture / Codegen](#build-fails-new-architecture--codegen)
- [iOS Apple-only build still links GoogleMaps](#ios-apple-only-build-still-links-googlemaps)

---

## Map renders blank or zero height

**Symptom:** Nothing shows, or the map is a thin strip.

**Cause:** `MapView` has no intrinsic size.

**Fix:** Give it `style={{ flex: 1 }}`, a fixed `height`, or `StyleSheet.absoluteFill` inside a sized parent. In lists, wrap in a `View` with an explicit height.

## Blank / beige map with Google provider

**Symptom:** Grid or empty tiles, "For development purposes only" watermark, or console auth errors.

**Cause:** Missing or misconfigured API key, or the key lacks the platform's SDK (Maps SDK for iOS / Android / Maps JavaScript API), or restrictions don't match the bundle id / package name / referrer.

**Fix:** Configure the key per platform (see [Configuration → Setup](./configuration.md#setup)). After changing the Expo plugin config, run `npx expo prebuild --clean` and rebuild — keys are baked into native projects.

## Google requested but Apple Maps shows (iOS)

**Symptom:** `provider="google"` renders Apple Maps and logs `Google Maps SDK is excluded`.

**Cause:** `$LuggMapsGoogleEnabled = false` in the Podfile or `iosGoogleMapsEnabled: false` in the plugin.

**Fix:** Remove the flag / set it to `true`, add the API key back, `pod install` (or prebuild), rebuild.

## Changing `provider` or `staticMode` does nothing

**Cause:** Both are applied when the native map is created.

**Fix:** Remount with a `key`:

```tsx
<MapView key={`${provider}-${staticMode}`} provider={provider} staticMode={staticMode} />
```

## Camera doesn't move on mount

**Symptom:** `moveCamera` / `fitCoordinates` in `useEffect` is a no-op.

**Cause:** Called before the native map exists.

**Fix:** Call from `onReady`, or set `initialCoordinate` / `initialZoom` (compute a [fitted camera](./advanced-patterns.md#fitted-camera-for-static-maps) if you need to fit multiple points up front).

## Buttons inside a callout don't respond

**Symptom:** Custom `callout` content shows, but `Pressable`s inside do nothing on Google Maps (iOS/Android).

**Cause:** Bubbled callouts are info windows, which Google Maps renders as bitmaps.

**Fix:** `calloutOptions={{ bubbled: false }}` renders the content as a live view. Style your own card (background, radius, shadow) and nudge with `offset`.

## Animated content inside a marker is frozen

**Symptom:** Lottie / spinner / pulsing view inside `<Marker>` shows a single frame.

**Cause:** Custom marker views are rasterized by default.

**Fix:** `rasterize={false}` on that marker only. Keep the default for everything else — live marker views cost more during pan/zoom.

## Marker snaps back after dragging

**Cause:** The `coordinate` prop wasn't updated, so the next render resets the native position.

**Fix:**

```tsx
<Marker coordinate={coord} draggable onDragEnd={(e) => setCoord(e.nativeEvent.coordinate)} />
```

## Marker animation janks or re-renders every frame

**Cause:** Driving `coordinate` with `setState` on every tick.

**Fix:** Use Reanimated `animatedProps` on `Animated.createAnimatedComponent(Marker)` — see [Animated marker](./advanced-patterns.md#animated-marker-along-a-route). Also keep `onCameraMove` handlers light; use `onCameraIdle` for state.

## Overlapping markers stack wrong

**Fix:** `zIndex={Math.round((90 - latitude) * 10000)}` so southern markers are in front; bump the selected one higher.

## Center pin / selected coordinate is offset under a sheet

**Symptom:** The coordinate you compute for a fixed center pin is south of where the pin appears.

**Cause:** The map is shrunk or the sheet is ignored, so the visual center and the map center differ.

**Fix:** Keep the map full-size and push the viewport with `setEdgeInsets({ bottom: sheetHeight })`. Camera events then report the inset-adjusted center, and a pin translated up by `bottom / 2` sits exactly on it. See [Bottom sheet pattern](./advanced-patterns.md#bottom-sheet-with-edge-insets-and-center-pin).

## `e.nativeEvent.dragging` is undefined

**Cause:** The camera payload field is `gesture`, not `dragging`.

**Fix:** `const { coordinate, zoom, gesture } = e.nativeEvent;`

## User location dot never appears

**Causes and fixes:**

1. Permission not granted — the library never prompts. Request first, then set `userLocationEnabled`.
2. Android: the prop was set *before* the grant. Re-set it after (`userLocationEnabled={granted}`).
3. iOS: missing `NSLocationWhenInUseUsageDescription` in Info.plist.
4. Simulator has no location — set one in Features → Location (iOS) or the emulator's Extended Controls.
5. `userLocationButtonEnabled` is Android-only; on iOS build your own button that calls `moveCamera` with the device location.

## Static maps in a list are slow or crash the app

**Cause:** Too many rows mounted at once — every mounted static map holds a bitmap, and iOS Google warms up a live map per row.

**Fix:** Bound the list: `windowSize={5}`, `initialNumToRender={4}`, `maxToRenderPerBatch={4}`, `removeClippedSubviews`. Keep row maps small (≈140 pt). Set `staticKey` so iOS reuses images when rows recycle.

## Static map row shows a stale or missing image

**Symptoms / fixes:**

- **Stale content** after data changed — `staticKey` must uniquely identify the content including markers. Include a version or hash: `staticKey={`${place.id}-${place.updatedAt}`}`.
- **Never caches / re-renders each scroll** — children aren't deterministic (random offsets, `Date.now()` in render). Make them pure per key.
- **Blank after being offline** (iOS Google) — the base map only caches once tiles load; the row retries when it reappears. Offer a button that calls `reload()`.
- **Android view larger than ~2048 px** — lite mode can't render it; the map falls back to a full, gesture-less map. Keep static maps small.

## Static list map taps don't fire

**Cause:** `onPress` is disabled in `staticMode`, and the native map view intercepts touches.

**Fix:** `<Pressable onPress>` around a `<View pointerEvents="none">` that contains the map.

## `mapType` / `mapId` ignored on Android list maps

**Cause:** Android lite mode doesn't support cloud styling; iOS static maps ignore map-setting prop changes after the snapshot.

**Fix:** Accept the default style for lite maps, or render a small live map with all gestures disabled (`zoomEnabled={false} scrollEnabled={false} rotateEnabled={false} pitchEnabled={false}`) when styling matters more than memory.

## GeoJSON renders in the wrong place

**Cause:** Coordinates were authored as `[lat, lng]`.

**Fix:** GeoJSON positions are `[longitude, latitude]`. Swap them at the source, not in a render callback.

## GeoJSON key warnings or flicker

**Cause:** Render callbacks returned elements without `key`, or `geojson` / callbacks are recreated every render (the component is memoized on them).

**Fix:** Add `key={String(feature.id ?? index)}` to returned elements; wrap `geojson` in `useMemo` and callbacks in `useCallback`.

## Polyline `onPress` doesn't exist

**Cause:** Polylines are non-interactive on every platform.

**Fix:** Overlay a transparent `Polygon` buffer around the line, or place tappable `Marker`s along it.

## Web: `MapProvider` errors or nothing renders

**Checks:**

1. `@vis.gl/react-google-maps` installed (optional peer dep).
2. `<MapProvider apiKey="…">` wraps the tree — on web it *is* the Google `APIProvider`.
3. The key has Maps JavaScript API enabled and an HTTP referrer restriction matching your origin.
4. Markers need a `mapId` (Advanced Markers). The default `DEMO_MAP_ID` works for development; set your own for production.

## Web: `Animated.createAnimatedComponent(Marker)` doesn't animate

**Cause:** `animatedProps` on `Marker` is native-only.

**Fix:** Add a `.web.tsx` variant that animates `coordinate` / `rotate` with `requestAnimationFrame` + state.

## Web: import of `MapProviderType` / `MarkerRef` fails typecheck

**Cause:** Bundlers resolving the `web` export condition get `index.web.d.ts`, which exports a smaller type surface than native.

**Fix:** Import shared primitives (`Coordinate`, `Point`, `EdgeInsets`, `MapViewRef`, `MapViewProps`, `MarkerProps`) which exist on both, or define the ref type locally (`{ showCallout(): void; hideCallout(): void }`).

## Build fails: New Architecture / Codegen

**Symptom:** `LuggMapView was not found in the UIManager`, or missing `RNMapsSpec` symbols.

**Cause:** New Architecture disabled, or pods/gradle not regenerated after install.

**Fix:** Enable Fabric (`newArchEnabled=true` in `gradle.properties`, `RCT_NEW_ARCH_ENABLED=1` for pods — default in RN 0.76+ / Expo SDK 52+). Then `pod install` / Gradle sync and a clean native rebuild. Expo: `npx expo prebuild --clean`.

## iOS Apple-only build still links GoogleMaps

**Cause:** The Podfile flag isn't at the top, or `AppDelegate.swift` still imports `GoogleMaps`.

**Fix:** `$LuggMapsGoogleEnabled = false` must be the first line of the `Podfile`; remove the import and `provideAPIKey`; `pod install` again. With Expo, set `iosGoogleMapsEnabled: false` and re-run `npx expo prebuild --platform ios` (the plugin edits both files).
