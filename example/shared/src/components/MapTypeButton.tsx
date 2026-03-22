import { Pressable, StyleSheet } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import { sizes, useTheme } from '../theme';

interface MapTypeButtonProps {
  onPress: () => void;
}

export const MapTypeButton = ({ onPress }: MapTypeButtonProps) => {
  const { colors } = useTheme();

  return (
    <Pressable
      style={({ pressed }) => [
        styles.button,
        {
          backgroundColor: colors.backgroundElevated,
          shadowColor: colors.shadow,
        },
        pressed && styles.buttonPressed,
      ]}
      onPress={onPress}
    >
      <Svg width={22} height={22} viewBox="0 0 24 24" fill="none">
        <Path
          d="M3 7l6-3 6 3 6-3v13l-6 3-6-3-6 3V7z"
          stroke={colors.icon}
          strokeWidth={1.75}
          strokeLinejoin="round"
        />
        <Path d="M9 4v13M15 7v13" stroke={colors.icon} strokeWidth={1.75} />
      </Svg>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  button: {
    position: 'absolute',
    top: sizes.fabTop,
    right: sizes.lg,
    width: sizes.fabSize,
    height: sizes.fabSize,
    borderRadius: sizes.fabSize / 2,
    alignItems: 'center',
    justifyContent: 'center',
    shadowOffset: sizes.shadowOffset,
    shadowOpacity: sizes.shadowOpacity,
    shadowRadius: sizes.shadowRadius,
    elevation: sizes.elevation,
  },
  buttonPressed: {
    opacity: 0.7,
  },
});
