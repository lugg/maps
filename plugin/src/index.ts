import { type ConfigPlugin, createRunOncePlugin } from '@expo/config-plugins';

import { withLuggMapsAndroid } from './withLuggMapsAndroid';
import { withLuggMapsIOS } from './withLuggMapsIOS';

const pkg = require('../../package.json');

export interface MapsPluginProps {
  /**
   * Google Maps API key for iOS.
   * Required if using Google Maps provider on iOS.
   */
  iosGoogleMapsApiKey?: string;

  /**
   * Google Maps API key for Android.
   * Required for Android as it only supports Google Maps.
   */
  androidGoogleMapsApiKey?: string;
}

const withMaps: ConfigPlugin<MapsPluginProps | void> = (config, props = {}) => {
  const { iosGoogleMapsApiKey, androidGoogleMapsApiKey } = props ?? {};

  config = withLuggMapsIOS(config, { apiKey: iosGoogleMapsApiKey });
  config = withLuggMapsAndroid(config, { apiKey: androidGoogleMapsApiKey });

  return config;
};

export default createRunOncePlugin(withMaps, pkg.name, pkg.version);
