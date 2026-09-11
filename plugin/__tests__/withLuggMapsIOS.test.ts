import type {
  ExportedConfig,
  InfoPlist,
  IOSConfig,
  Mod,
} from '@expo/config-plugins';

import {
  type MapsIOSPluginProps,
  withLuggMapsIOS,
} from '../src/withLuggMapsIOS';

const nativeFiles = {
  podfile: "platform :ios, '15.1'\n",
  appDelegate: `import Expo
class AppDelegate {
  func application(_ application: UIApplication) -> Bool {
    return true
  }
}
`,
  infoPlist: { CFBundleDisplayName: 'Maps' } as InfoPlist,
};

async function runMod<T>(mod: Mod<T> | undefined, modResults: T) {
  if (!mod) {
    return modResults;
  }

  const config = { name: 'Maps', slug: 'maps' };
  const result = await mod({
    ...config,
    modResults,
    modRawConfig: config,
    modRequest: {
      projectRoot: '/tmp/maps',
      platformProjectRoot: '/tmp/maps/ios',
      platform: 'ios',
      modName: 'test',
      introspect: false,
    },
  });
  return result.modResults;
}

async function applyPlugin(props: MapsIOSPluginProps, files = nativeFiles) {
  const config: ExportedConfig = withLuggMapsIOS(
    { name: 'Maps', slug: 'maps' },
    props
  );
  const mods = config.mods?.ios;
  const podfileMod = (
    mods as { podfile?: Mod<IOSConfig.Paths.PodfileProjectFile> }
  )?.podfile;
  const podfile = await runMod(podfileMod, {
    path: '/tmp/maps/ios/Podfile',
    language: 'rb' as const,
    contents: files.podfile,
  });
  const appDelegate = await runMod(mods?.appDelegate, {
    path: '/tmp/maps/ios/AppDelegate.swift',
    language: 'swift' as const,
    contents: files.appDelegate,
  });
  const infoPlist = await runMod(mods?.infoPlist, { ...files.infoPlist });
  return {
    podfile: podfile.contents,
    appDelegate: appDelegate.contents,
    infoPlist,
  };
}

it('keeps Google Maps enabled by default', async () => {
  const files = await applyPlugin({ apiKey: 'test-key' });
  expect(files.podfile).toBe(nativeFiles.podfile);
  expect(files.appDelegate).toContain('import GoogleMaps');
  expect(files.appDelegate).toContain('GMSServices.provideAPIKey("test-key")');
  expect(files.infoPlist.GMSApiKey).toBe('test-key');
});

it('excludes Google Maps on a fresh project even when an API key is provided', async () => {
  const files = await applyPlugin({ googleEnabled: false, apiKey: 'test-key' });
  expect(files.podfile).toBe(
    `$LuggMapsGoogleEnabled = false\n${nativeFiles.podfile}`
  );
  expect(files.appDelegate).toBe(nativeFiles.appDelegate);
  expect(files.infoPlist).toEqual(nativeFiles.infoPlist);
});

it('removes Google Maps initialization when disabling an existing project', async () => {
  const enabled = await applyPlugin({ apiKey: 'test-key' });
  const disabled = await applyPlugin({ googleEnabled: false }, enabled);
  expect(disabled.podfile).toContain('$LuggMapsGoogleEnabled = false');
  expect(disabled.appDelegate).toBe(nativeFiles.appDelegate);
  expect(disabled.infoPlist).toEqual(nativeFiles.infoPlist);
});

it.each([true, undefined])(
  'restores Google Maps after disabling it (googleEnabled=%s)',
  async (googleEnabled) => {
    const disabled = await applyPlugin({ googleEnabled: false });
    const enabled = await applyPlugin(
      { googleEnabled, apiKey: 'test-key' },
      disabled
    );
    expect(enabled.podfile).toBe(nativeFiles.podfile);
    expect(enabled.appDelegate).toContain('import GoogleMaps');
    expect(enabled.appDelegate).toContain(
      'GMSServices.provideAPIKey("test-key")'
    );
    expect(enabled.infoPlist.GMSApiKey).toBe('test-key');
  }
);

it('removes the exclusion flag without requiring an API key', async () => {
  const disabled = await applyPlugin({ googleEnabled: false });
  const enabled = await applyPlugin({ googleEnabled: true }, disabled);
  expect(enabled).toEqual(nativeFiles);
});

it.each([true, false])(
  'can run repeatedly without changing the result (googleEnabled=%s)',
  async (googleEnabled) => {
    const props = { googleEnabled, apiKey: 'test-key' };
    const files = await applyPlugin(props);
    expect(await applyPlugin(props, files)).toEqual(files);
  }
);
