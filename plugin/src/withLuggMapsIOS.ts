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
  config = withPodfile(config, (c) => {
    const contents = c.modResults.contents.replace(
      /^\$LuggMapsGoogleEnabled = false\r?\n/gm,
      ''
    );
    c.modResults.contents = googleEnabled
      ? contents
      : `${GMS_EXCLUSION_PODFILE_FLAG}\n${contents}`;
    return c;
  });

  if (googleEnabled && !apiKey) {
    return config;
  }

  config = withInfoPlist(config, (c) => {
    if (googleEnabled) {
      c.modResults.GMSApiKey = apiKey;
    } else {
      delete c.modResults.GMSApiKey;
    }
    return c;
  });

  config = withAppDelegate(config, (c) => {
    if (!googleEnabled) {
      c.modResults.contents = c.modResults.contents
        .replace(/^[ \t]*import GoogleMaps\r?\n/gm, '')
        .replace(/^[ \t]*GMSServices\.provideAPIKey\("[^"\r\n]*"\)\r?\n/gm, '');
      return c;
    }

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
        `$1\n    GMSServices.provideAPIKey("${apiKey}")`
      );
    }

    return c;
  });

  return config;
};
