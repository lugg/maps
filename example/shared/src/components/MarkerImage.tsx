import { StyleSheet, Image, type ImageSourcePropType } from 'react-native';
import { Marker, type MarkerProps } from '@lugg/maps';

interface MarkerImageProps extends MarkerProps {
  source: ImageSourcePropType;
  size?: number;
}

export const MarkerImage = ({
  source,
  size = 40,
  anchor = { x: 0.5, y: 0.5 },
  ...rest
}: MarkerImageProps) => {
  return (
    <Marker anchor={anchor} rasterize={false} {...rest}>
      <Image
        source={source}
        style={[
          styles.image,
          { width: size, height: size, borderRadius: size / 2 },
        ]}
      />
    </Marker>
  );
};

const styles = StyleSheet.create({
  image: {
    borderWidth: 2,
    borderColor: 'white',
  },
});
