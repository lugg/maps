import { forwardRef } from 'react';
import { StyleSheet, View, Text } from 'react-native';
import { Marker, type MarkerProps } from '@lugg/maps';

interface MarkerTextProps extends MarkerProps {
  text: string;
  color?: string;
}

export const MarkerText = forwardRef<Marker, MarkerTextProps>(
  ({ text, color = '#EA4335', anchor = { x: 0.5, y: 0.5 }, ...rest }, ref) => {
    return (
      <Marker ref={ref} key={text} anchor={anchor} {...rest}>
        <View style={[styles.container, { backgroundColor: color }]}>
          <Text style={styles.text}>{text}</Text>
        </View>
      </Marker>
    );
  }
);

const styles = StyleSheet.create({
  container: {
    borderRadius: 16,
    width: 32,
    height: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  text: {
    color: 'white',
    fontWeight: 'bold',
    fontSize: 14,
  },
});
