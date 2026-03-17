import { Text, type TextProps, StyleSheet, useColorScheme } from 'react-native';

interface ThemedTextProps extends TextProps {
  variant?: 'body' | 'title' | 'caption';
}

export const ThemedText = ({
  variant = 'body',
  style,
  ...props
}: ThemedTextProps) => {
  const isDark = useColorScheme() === 'dark';

  return (
    <Text
      style={[styles[variant], isDark ? styles.dark : styles.light, style]}
      {...props}
    />
  );
};

const styles = StyleSheet.create({
  light: {
    color: '#000',
  },
  dark: {
    color: '#FFF',
  },
  body: {
    fontSize: 14,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
  },
  caption: {
    fontSize: 14,
    fontWeight: '600',
    opacity: 0.5,
  },
});
