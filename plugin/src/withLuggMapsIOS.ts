import {
  type ConfigPlugin,
  withInfoPlist,
  withAppDelegate,
  withPodfile,
} from '@expo/config-plugins';

export interface MapsIOSPluginProps {
  apiKey?: string;
  googleEnabled?: boolean;
}

const GMS_EXCLUSION_PODFILE_FLAG = '$LuggMapsGoogleEnabled = false';

export const withLuggMapsIOS: ConfigPlugin<MapsIOSPluginProps> = (
  config,
  { apiKey, googleEnabled = true }
) => {
  if (!googleEnabled) {
    return withPodfile(config, (c) => {
      if (!c.modResults.contents.includes(GMS_EXCLUSION_PODFILE_FLAG)) {
        c.modResults.contents = `${GMS_EXCLUSION_PODFILE_FLAG}\n${c.modResults.contents}`;
      }
      return c;
    });
  }

  if (!apiKey) {
    return config;
  }

  config = withInfoPlist(config, (c) => {
    c.modResults.GMSApiKey = apiKey;
    return c;
  });

  config = withAppDelegate(config, (c) => {
    const contents = c.modResults.contents;

    // Add import for GoogleMaps
    if (!contents.includes('import GoogleMaps')) {
      c.modResults.contents = contents.replace(
        /(import (?:UIKit|Expo))/,
        '$1\nimport GoogleMaps'
      );
    }

    // Add GMSServices.provideAPIKey call
    if (!c.modResults.contents.includes('GMSServices.provideAPIKey')) {
      c.modResults.contents = c.modResults.contents.replace(
        /(func application\([^)]+\)[^{]*\{)/,
        `$1\n    GMSServices.provideAPIKey("${apiKey}")\n`
      );
    }

    return c;
  });

  return config;
};
