import {
  Pressable,
  Text,
  StyleSheet,
  type PressableProps,
  type ViewStyle,
} from 'react-native';
import { sizes, useTheme } from '../theme';

interface ButtonProps extends Omit<PressableProps, 'style'> {
  title: string;
  style?: ViewStyle;
}

export const Button = ({ title, disabled, style, ...props }: ButtonProps) => {
  const { colors } = useTheme();

  return (
    <Pressable
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: colors.primary },
        pressed && !disabled && styles.pressed,
        disabled && styles.disabled,
        style,
      ]}
      disabled={disabled}
      {...props}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  button: {
    height: sizes.buttonHeight,
    paddingHorizontal: sizes.lg,
    borderRadius: sizes.radiusFull,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: {
    opacity: 0.7,
  },
  disabled: {
    opacity: 0.4,
  },
  text: {
    color: '#FFFFFF',
    fontSize: sizes.fontLg,
    fontWeight: '600',
  },
});
