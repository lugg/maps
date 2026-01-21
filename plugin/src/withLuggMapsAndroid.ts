import {
  AndroidConfig,
  type ConfigPlugin,
  withAndroidManifest,
} from '@expo/config-plugins';

export interface MapsAndroidPluginProps {
  apiKey?: string;
}

export const withLuggMapsAndroid: ConfigPlugin<MapsAndroidPluginProps> = (
  config,
  { apiKey }
) => {
  if (!apiKey) {
    return config;
  }

  return withAndroidManifest(config, (c) => {
    const mainApplication = AndroidConfig.Manifest.getMainApplicationOrThrow(
      c.modResults
    );

    AndroidConfig.Manifest.addMetaDataItemToMainApplication(
      mainApplication,
      'com.google.android.geo.API_KEY',
      apiKey
    );

    return c;
  });
};
