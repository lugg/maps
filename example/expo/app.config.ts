import type { ExpoConfig } from 'expo/config';

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

const config: ExpoConfig = {
  name: 'LuggMapsExpo',
  slug: 'lugg-maps-expo',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'light',
  newArchEnabled: true,
  splash: {
    image: './assets/splash-icon.png',
    resizeMode: 'contain',
    backgroundColor: '#ffffff',
  },
  ios: {
    supportsTablet: true,
    bundleIdentifier: 'com.luggmaps.expo.example',
  },
  android: {
    adaptiveIcon: {
      foregroundImage: './assets/adaptive-icon.png',
      backgroundColor: '#ffffff',
    },
    package: 'com.luggmaps.expo.example',
  },
  plugins: [
    [
      '../../app.plugin.js',
      {
        iosGoogleMapsApiKey: GOOGLE_MAPS_API_KEY,
        androidGoogleMapsApiKey: GOOGLE_MAPS_API_KEY,
      },
    ],
    [
      'expo-location',
      {
        locationWhenInUsePermission: 'Show current location on map',
      },
    ],
  ],
};

export default config;
