import { Text, type TextProps, StyleSheet } from 'react-native';
import { sizes, useTheme } from '../theme';

interface ThemedTextProps extends TextProps {
  variant?: 'body' | 'title' | 'caption';
}

export const ThemedText = ({
  variant = 'body',
  style,
  ...props
}: ThemedTextProps) => {
  const { colors } = useTheme();

  return (
    <Text style={[styles[variant], { color: colors.text }, style]} {...props} />
  );
};

const styles = StyleSheet.create({
  body: {
    fontSize: sizes.fontBase,
  },
  title: {
    fontSize: sizes.fontXl,
    fontWeight: '700',
  },
  caption: {
    fontSize: sizes.fontBase,
    fontWeight: '600',
    opacity: 0.6,
  },
});
