# @lugg/maps

Universal maps for your React Native apps 📍

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
import { MapView, Marker, Polyline } from '@lugg/maps';

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
</MapView>
```

## Components

- [MapView](docs/MAPVIEW.md) - Main map component
- [Marker](docs/MARKER.md) - Map markers
- [Polyline](docs/POLYLINE.md) - Draw lines on the map

## Types

```ts
interface Coordinate {
  latitude: number;
  longitude: number;
}

interface Point {
  x: number;
  y: number;
}

interface EdgeInsets {
  top: number;
  left: number;
  bottom: number;
  right: number;
}
```

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT
