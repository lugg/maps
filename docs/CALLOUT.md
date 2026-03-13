# Callout

Callout component displayed when a marker is tapped. Use as a child of `Marker`.

## Usage

```tsx
import { MapView, Marker, Callout } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* Native callout with press handler */}
  <Marker
    coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
    title="San Francisco"
    description="California, USA"
  >
    <Callout onPress={() => console.log('Callout pressed')} />
  </Marker>

  {/* Custom callout content */}
  <Marker coordinate={{ latitude: 37.8049, longitude: -122.4094 }}>
    <Callout onPress={() => console.log('Callout pressed')}>
      <View style={{ padding: 8 }}>
        <Text style={{ fontWeight: 'bold' }}>Custom Callout</Text>
        <Text>With React content</Text>
      </View>
    </Callout>
  </Marker>
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `onPress` | `() => void` | - | Called when the callout is pressed |
| `children` | `ReactNode` | - | Custom callout content. If not provided, the native callout is used |

## Platform Behavior

### Apple Maps (iOS)

Custom callout content is rendered as a live interactive view inside the native callout bubble using `detailCalloutAccessoryView`. Content is fully interactive.

### Google Maps (iOS & Android)

Custom callout content is rasterized into the info window. Individual elements inside the callout are **not interactive** — only the entire callout is tappable via `onPress`. This is a Google Maps platform limitation.

### Web

Uses Google Maps `InfoWindow`. The callout opens on marker tap and closes when the close button is clicked. Content is rendered as live HTML.
