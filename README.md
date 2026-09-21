# @lugg/maps

Universal maps for your React Native apps 📍

<img alt="@lugg/maps" src="docs/public/preview.gif" width="720" />

## Documentation

Full documentation lives at **[maps.lodev09.com](https://maps.lodev09.com)**.

- [Installation](https://maps.lodev09.com/installation) - Expo, bare React Native, and web setup
- [Usage](https://maps.lodev09.com/usage) - Render your first map
- [MapView](https://maps.lodev09.com/components/map-view) - Props, camera methods, events, static maps
- [Marker](https://maps.lodev09.com/components/marker) - Custom views, callouts, dragging
- [Polyline](https://maps.lodev09.com/components/polyline), [Polygon](https://maps.lodev09.com/components/polygon), [Circle](https://maps.lodev09.com/components/circle) - Shapes
- [GeoJson](https://maps.lodev09.com/components/geojson), [GroundOverlay](https://maps.lodev09.com/components/ground-overlay), [TileOverlay](https://maps.lodev09.com/components/tile-overlay) - Data and overlays
- [Types](https://maps.lodev09.com/types) - `Coordinate`, `Point`, `EdgeInsets`

## Quick start

```sh
npm install @lugg/maps
```

```tsx
import { MapView, Marker } from '@lugg/maps';

<MapView
  style={{ flex: 1 }}
  provider="google"
  initialCoordinate={{ latitude: 37.7749, longitude: -122.4194 }}
  initialZoom={12}
>
  <Marker
    coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
    title="San Francisco"
  />
</MapView>
```

Google Maps needs an API key on every platform. See [Installation](https://maps.lodev09.com/installation) for Expo, iOS, Android, and web setup.

## AI Skills

Skills give your AI coding agent working knowledge of `@lugg/maps` - setup, camera control, markers and callouts, static maps, advanced patterns, and platform limitations - so it generates correct code without you explaining the library each time.

```sh
npx skills add lugg/maps
```

This installs the **Maps Usage** skill into your project. The source lives in [`skills/maps-usage`](skills/maps-usage).

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT
