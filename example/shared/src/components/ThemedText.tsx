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
      style={[styles[variant], { color: isDark ? '#FFF' : '#000' }, style]}
      {...props}
    />
  );
};

const styles = StyleSheet.create({
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
