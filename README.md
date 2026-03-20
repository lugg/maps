# @lugg/maps

Universal maps for your React Native apps 📍

<img alt="@lugg/maps" src="docs/preview.gif" width="720" />

> [!IMPORTANT]
> This library is currently under heavy development. APIs may change without notice.

## Installation

```sh
npm install @lugg/maps
```

### Expo

Add the plugin to your `app.json`:

```json
{
  "expo": {
    "plugins": [
      [
        "@lugg/maps",
        {
          "iosGoogleMapsApiKey": "YOUR_IOS_API_KEY",
          "androidGoogleMapsApiKey": "YOUR_ANDROID_API_KEY"
        }
      ]
    ]
  }
}
```

### Bare React Native

#### iOS

Add your Google Maps API key to `AppDelegate.swift`:

```swift
import GoogleMaps

// In application(_:didFinishLaunchingWithOptions:)
GMSServices.provideAPIKey("YOUR_API_KEY")
```

#### Android

Add your Google Maps API key to `AndroidManifest.xml`:

```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY" />
</application>
```

### Web

Wrap your app with `MapProvider` and pass your Google Maps API key:

```tsx
import { MapProvider } from '@lugg/maps';

function App() {
  return (
    <MapProvider apiKey="YOUR_WEB_API_KEY">
      {/* Your app */}
    </MapProvider>
  );
}
```

## Usage

```tsx
import { MapView, Marker, Polyline, Polygon } from '@lugg/maps';

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
  <Polyline
    coordinates={[
      { latitude: 37.7749, longitude: -122.4194 },
      { latitude: 37.8049, longitude: -122.4094 },
    ]}
    strokeWidth={3}
  />
  <Polygon
    coordinates={[
      { latitude: 37.784, longitude: -122.428 },
      { latitude: 37.784, longitude: -122.422 },
      { latitude: 37.779, longitude: -122.422 },
      { latitude: 37.779, longitude: -122.428 },
    ]}
    fillColor="rgba(66, 133, 244, 0.3)"
    strokeColor="#4285F4"
    strokeWidth={2}
  />
</MapView>
```

## Components

- [MapView](docs/MAPVIEW.md) - Main map component
- [Marker](docs/MARKER.md) - Map markers with callout support
- [Polyline](docs/POLYLINE.md) - Draw lines on the map
- [Polygon](docs/POLYGON.md) - Draw filled shapes on the map
- [Circle](docs/CIRCLE.md) - Draw circular overlays on the map
- [GeoJson](docs/GEOJSON.md) - Render GeoJSON data on the map
- [GroundOverlay](docs/GROUND_OVERLAY.md) - Display images on the map
- [TileOverlay](docs/TILE_OVERLAY.md) - Display custom tile layers on the map

## Types

See [Types](docs/TYPES.md) for common type definitions (`Coordinate`, `Point`, `EdgeInsets`).

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT
