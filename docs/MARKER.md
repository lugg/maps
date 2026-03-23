# Marker

Map marker component.

## Usage

```tsx
import { MapView, Marker } from '@lugg/maps';

<MapView style={{ flex: 1 }}>
  {/* Basic marker */}
  <Marker
    coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
    title="San Francisco"
    description="California, USA"
  />

  {/* Custom marker view */}
  <Marker
    coordinate={{ latitude: 37.8049, longitude: -122.4094 }}
    anchor={{ x: 0.5, y: 1 }}
  >
    <View style={styles.customMarker}>
      <Text>Custom</Text>
    </View>
  </Marker>
</MapView>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `coordinate` | `Coordinate` | **required** | Marker position |
| `title` | `string` | - | Callout title |
| `description` | `string` | - | Callout description |
| `anchor` | `Point` | `{x: 0.5, y: 1}` | Anchor point for custom views |
| `zIndex` | `number` | - | Z-index for marker ordering. Higher values render on top |
| `rotate` | `number` | `0` | Rotation angle in degrees clockwise from north |
| `scale` | `number` | `1` | Scale factor for the marker |
| `rasterize` | `boolean` | `true` | Rasterize custom marker view to bitmap (iOS/Android only) |
| `centerOnPress` | `boolean` | `true` | Whether the map centers on the marker when pressed |
| `draggable` | `boolean` | `false` | Whether the marker can be dragged by the user |
| `onPress` | `(event: MarkerPressEvent) => void` | - | Called when the marker is pressed. Event includes `coordinate` and `point` |
| `onDragStart` | `(event: MarkerDragEvent) => void` | - | Called when marker drag starts. Event includes `coordinate` and `point` |
| `onDragChange` | `(event: MarkerDragEvent) => void` | - | Called continuously as the marker is dragged. Event includes `coordinate` and `point` |
| `onDragEnd` | `(event: MarkerDragEvent) => void` | - | Called when marker drag ends. Event includes `coordinate` and `point` |
| `callout` | `ComponentType \| ReactElement` | - | Callout content displayed when marker is tapped |
| `calloutOptions` | `CalloutOptions` | - | Callout config. Supports `bubbled` and `offset` |
| `children` | `ReactNode` | - | Custom marker view |

## Methods

Access methods via a ref on the `Marker` component.

```tsx
import { useRef } from 'react';
import { Marker, type MarkerRef } from '@lugg/maps';

const markerRef = useRef<MarkerRef>(null);

<Marker
  ref={markerRef}
  coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
  title="San Francisco"
/>

// Show callout programmatically
markerRef.current?.showCallout();

// Hide callout
markerRef.current?.hideCallout();
```

| Method | Description |
|--------|-------------|
| `showCallout()` | Show the marker's callout. No-op if no callout or title is set |
| `hideCallout()` | Hide the marker's callout |

## Draggable Markers

Set `draggable` to enable marker dragging. Use the drag event callbacks to track position changes.

```tsx
<Marker
  coordinate={markerCoordinate}
  draggable
  onDragStart={(e) => console.log('Drag started', e.nativeEvent.coordinate)}
  onDragChange={(e) => console.log('Dragging', e.nativeEvent.coordinate)}
  onDragEnd={(e) => setMarkerCoordinate(e.nativeEvent.coordinate)}
/>
```

## Custom Markers

Use the `children` prop to render a custom marker view. The `anchor` prop controls the point that is placed at the coordinate.

```tsx
<Marker
  coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
  anchor={{ x: 0.5, y: 1 }} // bottom center
>
  <View style={{ backgroundColor: 'red', padding: 8, borderRadius: 4 }}>
    <Text style={{ color: 'white' }}>Custom</Text>
  </View>
</Marker>
```

### Anchor Point

- `{ x: 0, y: 0 }` - top left
- `{ x: 0.5, y: 0 }` - top center
- `{ x: 1, y: 0 }` - top right
- `{ x: 0.5, y: 0.5 }` - center
- `{ x: 0.5, y: 1 }` - bottom center **(default)**

## Callout

Use the `callout` prop to display a callout when the marker is tapped.

```tsx
{/* Native callout using title/description */}
<Marker
  coordinate={{ latitude: 37.7749, longitude: -122.4194 }}
  title="San Francisco"
  description="California, USA"
/>

{/* Custom callout content */}
<Marker
  coordinate={{ latitude: 37.8049, longitude: -122.4094 }}
  callout={
    <View style={{ padding: 8 }}>
      <Text style={{ fontWeight: 'bold' }}>Custom Callout</Text>
      <Text>With React content</Text>
    </View>
  }
/>

{/* Non-bubbled callout (no native chrome) */}
<Marker
  coordinate={{ latitude: 37.7849, longitude: -122.4294 }}
  calloutOptions={{ bubbled: false }}
  callout={
    <View style={{ padding: 12, backgroundColor: 'white', borderRadius: 8 }}>
      <Text style={{ fontWeight: 'bold' }}>Custom Tooltip</Text>
      <Text>Rendered without native bubble</Text>
    </View>
  }
/>
```

### CalloutOptions

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `bubbled` | `boolean` | `true` | Whether to wrap the callout in the native platform bubble |
| `offset` | [`Point`](./TYPES.md#point) | `{x: 0, y: 0}` | Pixel offset for non-bubbled callouts from their default centered position above the marker. Only applies when `bubbled` is `false` |
