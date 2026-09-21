# Advanced Patterns

Production patterns for `@lugg/maps`, distilled from the example app.

## Table of Contents

- [Bottom sheet with edge insets and center pin](#bottom-sheet-with-edge-insets-and-center-pin)
- [Marker registry (show callouts by id)](#marker-registry-show-callouts-by-id)
- [Animated marker along a route](#animated-marker-along-a-route)
- [Route polylines](#route-polylines)
- [Marker stacking order](#marker-stacking-order)
- [Add marker on long press](#add-marker-on-long-press)
- [Provider switching at runtime](#provider-switching-at-runtime)
- [Fitted camera for static maps](#fitted-camera-for-static-maps)
- [Static map list with detail hand-off](#static-map-list-with-detail-hand-off)
- [Location permission flow](#location-permission-flow)
- [GeoJSON with custom rendering](#geojson-with-custom-rendering)
- [Web](#web)
- [Apple Maps only builds](#apple-maps-only-builds)
- [Jest testing](#jest-testing)

---

## Bottom sheet with edge insets and center pin

Keep `MapView` full-screen. When a sheet covers the bottom, inset the viewport instead of resizing the map — the camera center, attribution, and compass shift together, and `fitCoordinates` respects the visible area.

```tsx
import { useRef, useCallback } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import Animated, { useAnimatedStyle, type SharedValue } from 'react-native-reanimated';
import { MapView, type MapViewRef } from '@lugg/maps';
import { TrueSheet, type DetentChangeEvent } from '@lodev09/react-native-true-sheet';

const bottomInsets = (bottom: number) => ({ top: 0, left: 0, bottom, right: 0 });

export function PickupScreen({ animatedPosition }: { animatedPosition: SharedValue<number> }) {
  const mapRef = useRef<MapViewRef>(null);
  const { height } = useWindowDimensions();

  // Sheet position is measured from the top; bottom inset = covered height
  const syncInsets = useCallback(
    (e: DetentChangeEvent) => {
      mapRef.current?.setEdgeInsets(bottomInsets(height - e.nativeEvent.position));
    },
    [height]
  );

  // Fixed pin that follows the inset center
  const pinStyle = useAnimatedStyle(() => {
    const bottom = height - animatedPosition.value;
    return { transform: [{ translateY: -bottom / 2 }] };
  });

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <MapView
        ref={mapRef}
        style={StyleSheet.absoluteFill}
        onReady={() => mapRef.current?.setEdgeInsets(bottomInsets(height - animatedPosition.value))}
        onCameraIdle={(e) => setPickup(e.nativeEvent.coordinate)} // already inset-adjusted
      />
      <Animated.View style={[styles.pin, pinStyle]} pointerEvents="none" />
      <TrueSheet detents={['auto', 0.5]} dimmed={false} dismissible={false} initialDetentIndex={0}
        onDidPresent={syncInsets} onDetentChange={syncInsets}>
        {/* sheet content */}
      </TrueSheet>
    </View>
  );
}
```

Why this works: `onCameraIdle` reports the logical center after insets, so the coordinate under the pin is exactly `e.nativeEvent.coordinate`. No manual projection math.

For a static-height card instead of a sheet, pass `edgeInsets={{ top: 0, left: 0, right: 0, bottom: CARD_HEIGHT }}` as a prop — it works for static maps too.

## Marker registry (show callouts by id)

Collect marker refs in a `Map` keyed by your data id, then expose `showCallout` through the wrapping component:

```tsx
const markerRefs = useRef(new globalThis.Map<string, MarkerRef>());

const registerMarker = useCallback((id: string, r: MarkerRef | null) => {
  if (r) markerRefs.current.set(id, r);
  else markerRefs.current.delete(id);
}, []);

{places.map((p) => (
  <Marker key={p.id} ref={(r) => registerMarker(p.id, r)} coordinate={p.coordinate} title={p.name} />
))}

// Later
mapRef.current?.moveCamera(place.coordinate);
markerRefs.current.get(place.id)?.showCallout();
```

Name the ref map `globalThis.Map` when `Map` collides with your map component.

## Animated marker along a route

Native: drive `coordinate`, `rotate`, `scale`, and `zIndex` from Reanimated shared values with `animatedProps`. No re-renders per frame.

```tsx
import Animated, { Easing, useAnimatedProps, useDerivedValue, useSharedValue, withTiming } from 'react-native-reanimated';
import { Marker, type Coordinate } from '@lugg/maps';
import { getRhumbLineBearing } from 'geolib';

const AnimatedMarker = Animated.createAnimatedComponent(Marker);

// Shortest-turn bearing so the icon never spins the long way round
const nextBearing = (from: Coordinate, to: Coordinate, current: number) => {
  let b = getRhumbLineBearing(from, to);
  while (b - current > 180) b -= 360;
  while (b - current < -180) b += 360;
  return b;
};

export function Vehicle({ route, zoom }: { route: Coordinate[]; zoom: number }) {
  const lat = useSharedValue(route[0]!.latitude);
  const lng = useSharedValue(route[0]!.longitude);
  const bearing = useSharedValue(0);
  const scale = useSharedValue(1);
  const bearingRef = useRef(0);

  useEffect(() => {
    scale.value = withTiming(zoomToScale(zoom), { duration: 200 });
  }, [zoom]);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const step = (i: number) => {
      if (i >= route.length - 1) return step(0);
      const from = route[i]!, to = route[i + 1]!;
      bearingRef.current = nextBearing(from, to, bearingRef.current);
      bearing.value = withTiming(bearingRef.current, { duration: 300, easing: Easing.out(Easing.ease) });
      lat.value = withTiming(to.latitude, { duration: 2000 });
      lng.value = withTiming(to.longitude, { duration: 2000 });
      timer = setTimeout(() => step(i + 1), 2000);
    };
    step(0);
    return () => clearTimeout(timer);
  }, [route]);

  const zIndex = useDerivedValue(() => Math.round((90 - lat.value) * 10000));
  const animatedProps = useAnimatedProps(() => ({
    coordinate: { latitude: lat.value, longitude: lng.value },
    rotate: bearing.value,
    scale: scale.value,
    zIndex: zIndex.value,
  }));

  return (
    <AnimatedMarker coordinate={route[0]!} anchor={{ x: 0.5, y: 0.5 }} animatedProps={animatedProps}>
      <TruckIcon />
    </AnimatedMarker>
  );
}
```

- Keep `rasterize` at its default; the bitmap is transformed natively. Only set `rasterize={false}` when the icon *itself* animates.
- Track zoom from `onCameraIdle` to scale the icon (bigger when zoomed in).
- Smooth raw GPS points with a Catmull-Rom spline before animating so turns look natural.

Web: `animatedProps` isn't supported. Ship a `Vehicle.web.tsx` that interpolates with `requestAnimationFrame` and `setState` on `coordinate` / `rotate`.

## Route polylines

```tsx
export function Route({ coordinates }: { coordinates: Coordinate[] }) {
  if (coordinates.length < 2) return null;
  return (
    <>
      <Polyline coordinates={coordinates} strokeWidth={6} strokeColors={['#B0B0B0']} />
      <Polyline
        coordinates={coordinates}
        strokeWidth={6}
        strokeColors={['#B321E0', '#3744FF']}
        animated
        animatedOptions={{ duration: 1250, easing: 'easeInOut', trailLength: 1 }}
      />
    </>
  );
}
```

- Show "remaining route" by slicing coordinates from the vehicle's current segment: `route.slice(segmentIndex)`.
- `trailLength: 0.2` gives a short worm instead of a growing line.
- Use `delay` to stagger multiple animated routes.

## Marker stacking order

Real pins overlap so the southern (lower on screen) one is in front. Derive `zIndex` from latitude:

```tsx
<Marker coordinate={c} zIndex={Math.round((90 - c.latitude) * 10000)} />
```

Give the selected marker an explicit higher `zIndex` to lift it above everything.

## Add marker on long press

```tsx
<MapView
  onLongPress={(e) => addMarker(e.nativeEvent.coordinate)}
  onPress={() => setSelected(null)} // empty-map tap clears selection
/>
```

Marker taps don't bubble to `onPress`, so this pairing is safe.

## Provider switching at runtime

`provider` is applied when the native map is created. Remount to switch:

```tsx
const [provider, setProvider] = useState<MapProviderType>('apple');

<MapView key={provider} provider={provider} initialCoordinate={lastCenter} initialZoom={lastZoom} />
```

Carry the camera over by storing the last `onCameraIdle` payload and feeding it back as `initialCoordinate` / `initialZoom`. Disable the toggle on Android and web (`Platform.OS !== 'ios'`).

## Fitted camera for static maps

Static maps can't animate, so compute the camera before mount instead of calling `fitCoordinates` in `onReady`. This mirrors the native static framing (Google: world is `256 · 2^zoom` points wide; Apple fits a square span to the short side):

```ts
const mercatorX = (lng: number) => (lng + 180) / 360;
const mercatorY = (lat: number) => (1 - Math.asinh(Math.tan((lat * Math.PI) / 180)) / Math.PI) / 2;

export const fittedCamera = (
  coordinates: Coordinate[],
  provider: MapProviderType,
  size: { width: number; height: number },
  padding: number
) => {
  const xs = coordinates.map((c) => mercatorX(c.longitude));
  const ys = coordinates.map((c) => mercatorY(c.latitude));
  const [minX, maxX, minY, maxY] = [Math.min(...xs), Math.max(...xs), Math.min(...ys), Math.max(...ys)];
  const centerY = (minY + maxY) / 2;
  const coordinate = {
    latitude: (Math.atan(Math.sinh(Math.PI * (1 - 2 * centerY))) * 180) / Math.PI,
    longitude: ((minX + maxX) / 2) * 360 - 180,
  };
  const scale = Math.max(
    (maxX - minX) / Math.max(size.width - padding * 2, 1),
    (maxY - minY) / Math.max(size.height - padding * 2, 1)
  );
  const zoom =
    provider === 'apple'
      ? 0.5 + Math.log2(1 / (scale * Math.min(size.width, size.height) * Math.cos((coordinate.latitude * Math.PI) / 180)))
      : Math.log2(1 / (256 * scale));
  return { coordinate, zoom };
};
```

Use with `initialCoordinate={camera.coordinate} initialZoom={camera.zoom}`. For a single point just pass it with a fixed zoom.

## Static map list with detail hand-off

```tsx
const PlaceCard = ({ place, provider, onSelect }) => {
  const { width } = useWindowDimensions();
  const camera = fittedCamera(placeCoordinates(place), provider, { width: width - 32, height: 140 }, 16);

  return (
    <Pressable onPress={() => onSelect(place)}>
      <View style={{ height: 140 }} pointerEvents="none">
        <MapView
          key={provider}
          staticMode
          staticKey={place.id}
          style={StyleSheet.absoluteFill}
          provider={provider}
          initialCoordinate={camera.coordinate}
          initialZoom={camera.zoom}
        >
          <Marker coordinate={place.coordinate} />
          <Polyline coordinates={place.path} strokeWidth={3} strokeColors={['#007aff']} />
        </MapView>
      </View>
    </Pressable>
  );
};

<FlatList
  data={places}
  keyExtractor={(p) => p.id}
  renderItem={({ item }) => <PlaceCard place={item} provider={provider} onSelect={open} />}
  windowSize={5}
  initialNumToRender={4}
  maxToRenderPerBatch={4}
/>
```

- On the detail screen, render the same children with the same `staticKey` — on iOS the cached base image is reused instantly (the camera and size are part of the key, so a different framing renders fresh).
- Keep the marker/shape content deterministic per `staticKey` (no `Math.random()` in render) or the cache never hits.
- Provide a "Reload" affordance calling `mapRef.current?.reload()` for rows that rendered offline.

## Location permission flow

```tsx
export const useLocationPermission = () => {
  const [granted, setGranted] = useState(false);

  useEffect(() => {
    (async () => {
      if (Platform.OS === 'web') {
        const status = await navigator.permissions.query({ name: 'geolocation' });
        setGranted(status.state !== 'denied');
        return;
      }
      if (Platform.OS === 'ios') {
        // Add NSLocationWhenInUseUsageDescription to Info.plist and request via
        // expo-location / react-native-permissions; MapKit doesn't prompt by itself.
        setGranted(true);
        return;
      }
      const result = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION);
      setGranted(result === PermissionsAndroid.RESULTS.GRANTED);
    })();
  }, []);

  return granted;
};

<MapView userLocationEnabled={granted} />
```

Set the prop only after the grant — Android evaluates permission when the prop is applied.

## GeoJSON with custom rendering

```tsx
const geojson = useMemo(() => parse(raw), [raw]);

const renderPolygon = useCallback(
  (props: PolygonProps, feature: Feature) => (
    <Polygon
      key={String(feature.id ?? props.coordinates[0]?.latitude)}
      {...props}
      fillColor={feature.properties?.zone === 'restricted' ? 'rgba(244,67,54,0.25)' : 'rgba(66,133,244,0.2)'}
      onPress={() => select(feature)}
    />
  ),
  [select]
);

<GeoJson geojson={geojson} zIndex={1} renderPolygon={renderPolygon} />
```

- `GeoJson` is `memo`'d on `geojson` and the render callbacks; unstable references rebuild every element each render.
- Return `null` from a callback to skip a feature.
- Attach `onPress` in the callback — default rendering has no press handlers.
- Large collections: pre-filter features to the visible bounds from `onCameraIdle` rather than rendering thousands of markers.

## Web

Web renders through `@vis.gl/react-google-maps` (optional peer dependency). One `MapProvider` at the root with the browser key:

```tsx
<MapProvider apiKey={process.env.EXPO_PUBLIC_GOOGLE_MAPS_WEB_KEY}>
  <App />
</MapProvider>
```

Differences to plan for:

- Google only. `provider="apple"` is ignored.
- Markers are Advanced Markers, so a `mapId` is required; the library falls back to `DEMO_MAP_ID`. Supply your own for production.
- Ignored props: `rotateEnabled`, `poiEnabled`, `poiFilter`, `staticKey`, `insetAdjustment`, `userLocationButtonEnabled`, `rasterize`.
- `staticMode` keeps a live map with gestures, POI clicks, keyboard shortcuts, and press events disabled.
- `onLongPress` is emulated (500 ms mousedown without drag).
- Reanimated `animatedProps` on `Marker` isn't available — animate with state in a `.web.tsx` file.
- `Polyline` gradients and snake animation are drawn in JS with `requestAnimationFrame`.
- `GroundOverlay.bearing` is not applied.
- Restrict the browser key by HTTP referrer in Google Cloud; it's public in the bundle.

## Apple Maps only builds

Drop the Google SDK (smaller binary, no key needed):

- Expo: `"iosGoogleMapsEnabled": false` in the plugin config, then `npx expo prebuild --platform ios`.
- Bare: `$LuggMapsGoogleEnabled = false` at the top of the Podfile, remove `import GoogleMaps` / `GMSServices.provideAPIKey`, `pod install`.

Android still needs its Google key. Any `MapView` asking for `provider="google"` on iOS falls back to Apple and logs a warning.

## Jest testing

The package ships no Jest mocks. Native components come from Codegen, so mock the module:

```ts
// jest.setup.ts
jest.mock('@lugg/maps', () => {
  const React = require('react');
  const { View } = require('react-native');
  const stub = (name: string) =>
    Object.assign(
      React.forwardRef((props: any, ref: any) => {
        React.useImperativeHandle(ref, () => ({
          moveCamera: jest.fn(),
          fitCoordinates: jest.fn(),
          setEdgeInsets: jest.fn(),
          reload: jest.fn(),
          showCallout: jest.fn(),
          hideCallout: jest.fn(),
        }));
        return React.createElement(View, { ...props, testID: props.testID ?? name }, props.children);
      }),
      { displayName: name }
    );

  return {
    MapView: stub('MapView'),
    MapProvider: ({ children }: any) => children,
    Marker: stub('Marker'),
    Polyline: stub('Polyline'),
    Polygon: stub('Polygon'),
    Circle: stub('Circle'),
    GeoJson: stub('GeoJson'),
    GroundOverlay: stub('GroundOverlay'),
    TileOverlay: stub('TileOverlay'),
  };
});
```

Fire events in tests with `fireEvent(getByTestId('MapView'), 'cameraIdle', { nativeEvent: { coordinate, zoom: 12, gesture: false } })` — the prop name minus `on`, lower-camel-cased.
