import { View } from 'react-native';
import { Marker } from '@lugg/maps';

import { MarkerIcon } from './components/MarkerIcon';
import { MarkerText } from './components/MarkerText';
import { MarkerImage } from './components/MarkerImage';
import type { MarkerData } from './components';

export const renderMarker = (marker: MarkerData) => {
  const {
    id,
    name,
    coordinate,
    type,
    anchor,
    title,
    description,
    text,
    color,
    imageUrl,
  } = marker;

  switch (type) {
    case 'icon':
      return <MarkerIcon key={id} name={name} coordinate={coordinate} />;
    case 'text':
      return (
        <MarkerText
          key={id}
          name={name}
          coordinate={coordinate}
          text={text ?? 'X'}
          color={color}
        />
      );
    case 'image':
      return (
        <MarkerImage
          key={id}
          name={name}
          coordinate={coordinate}
          source={{ uri: imageUrl }}
        />
      );
    case 'custom':
      return (
        <Marker key={id} name={name} coordinate={coordinate} anchor={anchor}>
          <View
            style={{
              backgroundColor: color ?? 'gray',
              height: 30,
              width: 30,
              borderRadius: 15,
            }}
          />
        </Marker>
      );
    default:
      return (
        <Marker
          key={id}
          name={name}
          coordinate={coordinate}
          title={title}
          description={description}
        />
      );
  }
};
