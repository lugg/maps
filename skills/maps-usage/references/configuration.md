# Configuration Reference

Setup snippets and every `@lugg/maps` prop with type, default, and platform support.

**Legend:** 🍎 iOS Apple Maps · 🅶 iOS Google Maps · 🤖 Android · 🌐 Web

## Table of Contents

- [Setup](#setup)
  - [Expo](#expo)
  - [Bare React Native](#bare-react-native)
  - [Web](#web)
- [MapView](#mapview)
- [Marker](#marker)
- [Polyline](#polyline)
- [Polygon](#polygon)
- [Circle](#circle)
- [GeoJson](#geojson)
- [GroundOverlay](#groundoverlay)
- [TileOverlay](#tileoverlay)
- [Shared types](#shared-types)

---

## Setup

Install:

```sh
yarn add @lugg/maps
```

Apple Maps works out of the box on iOS. Google Maps requires an API key per platform (Google Cloud Console → Maps SDK for iOS, Maps SDK for Android, Maps JavaScript API).

### Expo

```json title="app.json"
{
  "expo": {
    "plugins": [
      [
        "@lugg/maps",
        {
          "iosGoogleMapsApiKey": "IOS_KEY",
          "androidGoogleMapsApiKey": "ANDROID_KEY"
        }
      ]
    ]
  }
}
```

Then `npx expo prebuild --clean`.

| Plugin option | Type | Default | Description |
|---------------|------|---------|-------------|
| `iosGoogleMapsApiKey` | `string` | — | Injects `GMSServices.provideAPIKey` into `AppDelegate.swift` and `GMSApiKey` into Info.plist |
| `androidGoogleMapsApiKey` | `string` | — | Adds `com.google.android.geo.API_KEY` meta-data to the manifest |
| `iosGoogleMapsEnabled` | `boolean` | `true` | `false` drops the Google Maps SDK from the iOS build (Apple Maps only). `iosGoogleMapsApiKey` is then ignored. Re-run `npx expo prebuild --platform ios` after changing |

### Bare React Native

iOS (`AppDelegate.swift`):

```swift
import GoogleMaps

// in application(_:didFinishLaunchingWithOptions:)
GMSServices.provideAPIKey("IOS_KEY")
```

Then `cd ios && pod install`. Apple-only apps add this at the top of the `Podfile` and remove the import / `provideAPIKey` lines:

```ruby
$LuggMapsGoogleEnabled = false
```

Android (`AndroidManifest.xml`):

```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="ANDROID_KEY" />
</application>
```

### Web

```sh
yarn add @vis.gl/react-google-maps
```

```tsx
import { MapProvider } from '@lugg/maps';

export function App() {
  return (
    <MapProvider apiKey={process.env.EXPO_PUBLIC_GOOGLE_MAPS_WEB_KEY}>
      <Root />
    </MapProvider>
  );
}
```

| `MapProvider` prop | Type | Platforms | Description |
|--------------------|------|-----------|-------------|
| `apiKey` | `string` | 🌐 | Google Maps JavaScript API key. Ignored on native (pass-through) |
| `children` | `ReactNode` | all | — |

---

## MapView

`MapViewProps extends ViewProps` — `style`, `testID`, etc. pass through.

### Provider and appearance

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `provider` | `'apple' \| 'google'` | `'apple'` iOS, `'google'` elsewhere | 🍎🅶🤖🌐 | Creation-time. Android/Web are always Google. Falls back to Apple with a warning when the Google SDK is excluded on iOS |
| `mapType` | `'standard' \| 'satellite' \| 'terrain' \| 'hybrid' \| 'muted-standard'` | `'standard'` | 🍎🅶🤖🌐 | `'terrain'` → standard on Apple. `'muted-standard'` → standard on Google |
| `mapId` | `string` | `DEMO_MAP_ID` (Google) | 🍎🅶🤖🌐 | Google cloud Map ID (styling, Advanced Markers). Ignored by Android lite-mode static maps. Apple: map configuration name |
| `theme` | `'light' \| 'dark' \| 'system'` | `'system'` | 🍎🅶🤖🌐 | Color scheme override |
| `poiEnabled` | `boolean` | `true` | 🍎 | Show points of interest. `false` hides all POIs regardless of `poiFilter` |
| `poiFilter` | `PoiFilter` | — | 🍎 | `{ mode?: 'including' \| 'excluding', categories: PoiCategory[] }`. Only when `poiEnabled` |
| `compassEnabled` | `boolean` | `true` | 🍎🅶🤖🌐 | Compass. On web toggles the rotate control |

### Camera

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `initialCoordinate` | `Coordinate` | — | 🍎🅶🤖🌐 | Starting center. Later changes are ignored — use `moveCamera` |
| `initialZoom` | `number` | `10` | 🍎🅶🤖🌐 | Starting zoom (Google-style levels). Also the zoom `fitCoordinates` uses for a single coordinate |
| `minZoom` | `number` | — | 🍎🅶🤖🌐 | Lower zoom clamp |
| `maxZoom` | `number` | — | 🍎🅶🤖🌐 | Upper zoom clamp |
| `edgeInsets` | `EdgeInsets` | — | 🍎🅶🤖🌐 | Viewport insets. Shifts the logical center, attribution, and controls. Prefer `setEdgeInsets()` for animated changes |
| `insetAdjustment` | `'never' \| 'automatic'` | `'never'` | 🍎🅶🤖 | `'automatic'` adds safe-area insets to the map padding |

### Gestures

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `zoomEnabled` | `boolean` | `true` | 🍎🅶🤖🌐 | Pinch / double-tap zoom |
| `scrollEnabled` | `boolean` | `true` | 🍎🅶🤖🌐 | Pan. Web maps `scrollEnabled: false` to `gestureHandling: 'cooperative'` (or `'none'` when zoom is also off) |
| `rotateEnabled` | `boolean` | `true` | 🍎🅶🤖 | Two-finger rotate |
| `pitchEnabled` | `boolean` | `true` | 🍎🅶🤖🌐 | Tilt. Web: `false` forces `tilt: 0` |

### Static mode

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `staticMode` | `boolean` | `false` | 🍎🅶🤖🌐 | Creation-time. Non-interactive map for lists. Android lite mode (bitmap ≤ ~2048px, larger views fall back to a gesture-less full map), iOS snapshot, web live map with gestures/POI clicks/keyboard/press off |
| `staticKey` | `string` | — | 🍎🅶 | Stable id for the base-image cache (e.g. row id). Camera, size, provider, and map settings are part of the key automatically. Changing it discards the current image. Only fully loaded renders are cached |

Static-mode behavior notes:

- Ref methods work without animation (`duration` ignored). iOS re-renders at the final camera; Android re-centers.
- Map-setting prop updates after the snapshot (e.g. `mapType`) are ignored on iOS.
- `animated` polylines render complete. Tile overlays are not supported on iOS static maps.
- Markers stay live views over the base image on iOS; marker prop updates still apply.
- A theme-aware placeholder shows while loading; set `style.backgroundColor` to override.
- iOS Google: the base map is captured once tiles finish loading. If tiles fail (offline), the live warm-up map stays and retries next time the row appears. `reload()` forces it.

### Location

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `userLocationEnabled` | `boolean` | `false` | 🍎🅶🤖🌐 | Blue dot. Requires granted permission — the library never prompts. Android checks permission when the prop is set. Web uses `navigator.geolocation` |
| `userLocationButtonEnabled` | `boolean` | `false` | 🤖 | Native my-location button (needs `userLocationEnabled`) |

### Events

| Prop | Payload | Platforms | Description |
|------|---------|-----------|-------------|
| `onReady` | — | 🍎🅶🤖🌐 | Map loaded. Fires again after `reload()` and per new map instance on web |
| `onPress` | `MapPressEvent` | 🍎🅶🤖🌐 | Tap on the map (disabled in static mode) |
| `onLongPress` | `MapPressEvent` | 🍎🅶🤖🌐 | Long press. Web emulates with a 500 ms mousedown timer |
| `onCameraMove` | `MapCameraEvent` | 🍎🅶🤖🌐 | Continuous while moving. `gesture` = user is dragging |
| `onCameraIdle` | `MapCameraEvent` | 🍎🅶🤖🌐 | Camera settled. `gesture` = the move was user-initiated |

---

## Marker

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `coordinate` | `Coordinate` | **required** | 🍎🅶🤖🌐 | Position. Animatable via Reanimated `animatedProps` on native |
| `title` | `string` | — | 🍎🅶🤖🌐 | Native callout title |
| `description` | `string` | — | 🍎🅶🤖🌐 | Native callout subtitle |
| `anchor` | `Point` | `{x: 0.5, y: 1}` | 🍎🅶🤖🌐 | Fraction of the custom view placed at the coordinate. `{0.5, 1}` bottom-center (pin), `{0.5, 0.5}` center |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | Higher renders on top. Animatable |
| `rotate` | `number` | `0` | 🍎🅶🤖🌐 | Degrees clockwise from north. Animatable |
| `scale` | `number` | `1` | 🍎🅶🤖🌐 | Scale factor. Animatable |
| `rasterize` | `boolean` | `true` | 🍎🅶🤖 | Rasterize the custom view to a bitmap. `false` keeps a live view for content that animates internally |
| `centerOnPress` | `boolean` | `true` | 🍎🅶🤖🌐 | Center the map on the marker when tapped |
| `draggable` | `boolean` | `false` | 🍎🅶🤖🌐 | Long-press-and-drag. Update `coordinate` from `onDragEnd` |
| `callout` | `ReactElement \| ComponentType` | — | 🍎🅶🤖🌐 | Custom callout content. Falls back to `title`/`description` bubble when omitted |
| `calloutOptions` | `CalloutOptions` | `{ bubbled: true }` | 🍎🅶🤖🌐 | `bubbled: false` renders the content as a live, interactive view without native chrome. `offset: Point` nudges a non-bubbled callout from its default centered-above position (positive `y` moves down) |
| `name` | `string` | — | 🍎🅶🤖 | Debug label for native logs |
| `onPress` | `MarkerPressEvent` | — | 🍎🅶🤖🌐 | Tap. Also toggles the callout when one exists |
| `onDragStart` / `onDragChange` / `onDragEnd` | `MarkerDragEvent` | — | 🍎🅶🤖🌐 | Drag lifecycle |
| `children` | `ReactNode` | — | 🍎🅶🤖🌐 | Custom marker view. Omit for the platform's default pin |

Callout rendering by platform:

| | Bubbled (`default`) | Non-bubbled |
|-|---------------------|-------------|
| 🍎 | Native `MKAnnotationView` callout, live content | Live view attached to the annotation |
| 🅶 🤖 | Info window — content **rasterized**, not tappable | Live view positioned over the map |
| 🌐 | `InfoWindow` (live) | `InfoWindow` with chrome stripped |

## Polyline

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `coordinates` | `Coordinate[]` | **required** | 🍎🅶🤖🌐 | Path |
| `strokeWidth` | `number` | — (`1` on web) | 🍎🅶🤖🌐 | Points |
| `strokeColors` | `ColorValue[]` | — | 🍎🅶🤖🌐 | One color = solid, many = gradient spread evenly along the path |
| `animated` | `boolean` | `false` | 🍎🅶🤖🌐 | Snake animation from start to end, looping. Static maps render it complete |
| `animatedOptions` | `PolylineAnimatedOptions` | — | 🍎🅶🤖🌐 | `{ duration?: 2150, easing?: 'linear' \| 'easeIn' \| 'easeOut' \| 'easeInOut', trailLength?: 1 (0–1), delay?: 0 }` |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | Layering. Web defaults animated polylines to `1` |

No `onPress`. Polylines are `pointerEvents: 'none'`.

## Polygon

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `coordinates` | `Coordinate[]` | **required** | 🍎🅶🤖🌐 | Outer ring |
| `holes` | `Coordinate[][]` | — | 🍎🅶🤖🌐 | Interior rings |
| `fillColor` | `ColorValue` | — | 🍎🅶🤖🌐 | |
| `strokeColor` | `ColorValue` | — | 🍎🅶🤖🌐 | |
| `strokeWidth` | `number` | — | 🍎🅶🤖🌐 | Points |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | |
| `onPress` | `() => void` | — | 🍎🅶🤖🌐 | Tap inside the fill (holes excluded) |

## Circle

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `center` | `Coordinate` | **required** | 🍎🅶🤖🌐 | |
| `radius` | `number` | **required** | 🍎🅶🤖🌐 | **Meters** |
| `fillColor` | `ColorValue` | — | 🍎🅶🤖🌐 | |
| `strokeColor` | `ColorValue` | — | 🍎🅶🤖🌐 | |
| `strokeWidth` | `number` | — | 🍎🅶🤖🌐 | Points |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | |
| `onPress` | `() => void` | — | 🍎🅶🤖🌐 | |

## GeoJson

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `geojson` | `FeatureCollection \| Feature \| Geometry` | **required** | 🍎🅶🤖🌐 | RFC 7946. Positions are `[lng, lat(, alt)]` |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | Applied to every rendered element |
| `renderMarker` | `(props: MarkerProps, feature) => ReactElement \| null` | — | 🍎🅶🤖🌐 | Point / MultiPoint |
| `renderPolyline` | `(props: PolylineProps, feature) => ReactElement \| null` | — | 🍎🅶🤖🌐 | LineString / MultiLineString |
| `renderPolygon` | `(props: PolygonProps, feature) => ReactElement \| null` | — | 🍎🅶🤖🌐 | Polygon / MultiPolygon |

Geometry → component: Point → `Marker`, MultiPoint → n × `Marker`, LineString → `Polyline`, MultiLineString → n × `Polyline`, Polygon → `Polygon` (first ring outer, rest holes), MultiPolygon → n × `Polygon`, GeometryCollection → recursive.

simplestyle `feature.properties` → props: `title`, `description` (Marker); `stroke` → `strokeColors[0]` / `strokeColor`; `stroke-width` → `strokeWidth`; `fill` → `fillColor`. Render callbacks receive these as `props` and take precedence. `fill-opacity` / `stroke-opacity` are typed but not applied — bake alpha into the color.

Keys: default elements are keyed by `feature.id` (or index). Elements returned from render callbacks must set their own `key`.

## GroundOverlay

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `image` | `ImageSourcePropType` | **required** | 🍎🅶🤖🌐 | `require()` or `{ uri }` |
| `bounds` | `{ northeast: Coordinate; southwest: Coordinate }` | **required** | 🍎🅶🤖🌐 | |
| `opacity` | `number` | `1` | 🍎🅶🤖🌐 | 0–1 |
| `bearing` | `number` | `0` | 🅶🤖 | Degrees clockwise. Not supported on Apple Maps or web |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | |
| `onPress` | `() => void` | — | 🍎🅶🤖🌐 | |

## TileOverlay

| Prop | Type | Default | Platforms | Description |
|------|------|---------|-----------|-------------|
| `urlTemplate` | `string` | **required** | 🍎🅶🤖🌐 | `{x}`, `{y}`, `{z}` placeholders, e.g. `https://tile.openstreetmap.org/{z}/{x}/{y}.png` |
| `tileSize` | `number` | `256` | 🍎🅶🤖🌐 | Pixels |
| `opacity` | `number` | `1` | 🍎🅶🤖🌐 | |
| `bounds` | `{ northeast; southwest }` | — | 🍎🅶🤖🌐 | Only load tiles inside |
| `zIndex` | `number` | — | 🍎🅶🤖🌐 | |
| `onPress` | `() => void` | — | 🌐 | Not supported by the native SDKs |

Not rendered on iOS static maps.

---

## Shared types

```ts
interface Coordinate { latitude: number; longitude: number }
interface Point { x: number; y: number }
interface EdgeInsets { top: number; left: number; bottom: number; right: number }

type MapProviderType = 'google' | 'apple';
type MapType = 'standard' | 'satellite' | 'terrain' | 'hybrid' | 'muted-standard';
type MapTheme = 'light' | 'dark' | 'system';
type InsetAdjustment = 'automatic' | 'never';

interface PoiFilter {
  mode?: 'including' | 'excluding'; // default 'including'
  categories: PoiCategory[];
}
```

`PoiCategory` (Apple Maps): `'airport' | 'amusement-park' | 'aquarium' | 'atm' | 'bakery' | 'bank' | 'beach' | 'brewery' | 'cafe' | 'campground' | 'car-rental' | 'ev-charger' | 'fire-station' | 'fitness-center' | 'food-market' | 'gas-station' | 'hospital' | 'hotel' | 'laundry' | 'library' | 'marina' | 'movie-theater' | 'museum' | 'national-park' | 'nightlife' | 'park' | 'parking' | 'pharmacy' | 'police' | 'post-office' | 'public-transport' | 'restaurant' | 'restroom' | 'school' | 'stadium' | 'store' | 'theater' | 'university' | 'winery' | 'zoo'` (iOS 13+) plus `'animal-service' | 'automotive-repair' | 'baseball' | 'basketball' | 'beauty' | 'bowling' | 'castle' | 'convention-center' | 'distillery' | 'fairground' | 'fishing' | 'fortress' | 'go-kart' | 'golf' | 'hiking' | 'kayaking' | 'landmark' | 'mailbox' | 'mini-golf' | 'music-venue' | 'national-monument' | 'planetarium' | 'rock-climbing' | 'rv-park' | 'skate-park' | 'skating' | 'skiing' | 'soccer' | 'spa' | 'surfing' | 'swimming' | 'tennis' | 'volleyball'` (iOS 18+).

Exported from `@lugg/maps`: `MapView`, `MapProvider`, `Marker`, `Polyline`, `Polygon`, `Circle`, `GeoJson`, `GroundOverlay`, `TileOverlay`, and types `MapViewProps`, `MapViewRef`, `MapProviderProps`, `MapProviderType`, `MarkerProps`, `MarkerRef`, `CalloutOptions`, `PolylineProps`, `PolylineAnimatedOptions`, `PolylineEasing`, `PolygonProps`, `CircleProps`, `GeoJsonProps`, `GroundOverlayProps`, `GroundOverlayBounds`, `TileOverlayProps`, `TileOverlayBounds`, `MoveCameraOptions`, `FitCoordinatesOptions`, `SetEdgeInsetsOptions`, `MapCameraEvent`, `MapPressEvent`, `CameraEventPayload`, `PressEventPayload`, `MarkerPressEvent`, `MarkerDragEvent`, `MapType`, `MapTheme`, `InsetAdjustment`, `PoiCategory`, `PoiFilter`, `Coordinate`, `Point`, `EdgeInsets`, `GeoJSON`, `Feature`, `FeatureCollection`, `FeatureProperties`, `Geometry`, `Position`.
