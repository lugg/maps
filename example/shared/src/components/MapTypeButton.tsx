import { Pressable, StyleSheet } from 'react-native';
import Svg, { Path } from 'react-native-svg';

interface MapTypeButtonProps {
  onPress: () => void;
}

export const MapTypeButton = ({ onPress }: MapTypeButtonProps) => (
  <Pressable
    style={({ pressed }) => [styles.button, pressed && styles.buttonPressed]}
    onPress={onPress}
  >
    <Svg width={22} height={22} viewBox="0 0 24 24" fill="none">
      <Path
        d="M3 7l6-3 6 3 6-3v13l-6 3-6-3-6 3V7z"
        stroke="#333"
        strokeWidth={1.75}
        strokeLinejoin="round"
      />
      <Path d="M9 4v13M15 7v13" stroke="#333" strokeWidth={1.75} />
    </Svg>
  </Pressable>
);

const styles = StyleSheet.create({
  button: {
    position: 'absolute',
    top: 60,
    right: 16,
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 4,
  },
  buttonPressed: {
    opacity: 0.7,
  },
});
