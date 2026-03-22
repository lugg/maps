import { useColorScheme } from 'react-native';

// Size tokens
export const sizes = {
  // Typography
  fontSm: 12,
  fontBase: 14,
  fontLg: 16,
  fontXl: 18,

  // Spacing
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,

  // Radii
  radiusSm: 4,
  radiusMd: 8,
  radiusLg: 10,
  radiusFull: 9999,

  // Components
  buttonHeight: 40,
  fabSize: 44,
  fabTop: 60,

  // Shadows
  shadowOffset: { width: 0, height: 2 },
  shadowOpacity: 0.25,
  shadowRadius: 4,
  elevation: 4,
} as const;

// Color tokens
const lightColors = {
  text: '#000',
  textSecondary: '#666',
  textInverse: '#FFF',
  textError: '#D32F2F',

  background: '#FFF',
  backgroundElevated: 'rgba(255, 255, 255, 0.95)',

  primary: '#007AFF',
  shadow: '#000',

  border: '#DDD',
  placeholder: '#999',

  inputBackground: '#FFF',
  inputText: '#000',

  icon: '#333',
} as const;

const darkColors = {
  text: '#FFF',
  textSecondary: '#999',
  textInverse: '#FFF',
  textError: '#EF5350',

  background: '#1C1C1E',
  backgroundElevated: 'rgba(40, 40, 42, 0.95)',

  primary: '#0A84FF',
  shadow: '#000',

  border: '#333',
  placeholder: '#666',

  inputBackground: '#1C1C1E',
  inputText: '#FFF',

  icon: '#CCC',
} as const;

export type Colors = typeof lightColors;

export const useTheme = () => {
  const scheme = useColorScheme();
  const isDark = scheme === 'dark';
  const colors = isDark ? darkColors : lightColors;
  return { colors, isDark };
};
