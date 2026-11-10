---
name: e2e
description: End-to-end test @lugg/maps on the iOS simulator, a physical iPhone, the Android emulator, and web — build and install the bare example (Debug or Release), drive the example's control sheet with argent, A/B two builds side by side, and collect hard evidence (CPU benchmarks per process and per thread, Time Profiler breakdowns, temporary native logs, marker add/remove counts, crash triage). Use when asked to build and e2e on iOS, Android, or web, verify or review a change in ios/, android/, or src/, reproduce a visual glitch (markers that disappear, flicker, jump, or lag), benchmark marker or map performance, compare Apple vs Google providers, or decide whether a bug is a regression vs HEAD.
metadata:
  internal: true
---

# E2E

Verify @lugg/maps on devices with evidence, not eyeballing. Every claim ("fixed", "faster", "regression", "pre-existing") should come with a log, a benchmark table, a profile, or an A/B result.

Read `argent-device-interact` before driving a device.

## When to use

- A change in `ios/`, `android/`, or `src/` needs to run on a device, or needs a review for regressions.
- Something visibly misbehaves: markers disappear, flicker, jump, lag, or overlays draw in the wrong order.
- Performance: a change claims to be faster or slower, or a scenario feels slow.
- A bug report needs classifying as a regression or pre-existing.

## 1. Build, install, launch

The bare example (`example/bare`) is the default. The iOS bundle id and the Android package are both `luggmaps.example`.

- **JS changes** hot-reload through Metro in Debug.
- **Native changes** need a rebuild.
- **Performance work** needs a Release build. Debug numbers are misleading. For example, mounting a 50-marker fleet freezes for about 12 s in Debug.

Metro: `yarn bare start --port 8082` as a background command. Another project often holds 8081; don't kill another project's Metro. iOS Debug then needs `launchArgs: ["-RCT_jsLocation", "localhost:8082"]` on `launch-app`.

### iOS simulator

`yarn bare ios` fails on Xcode 27 (it opens the removed Simulator.app). Run xcodebuild from `example/bare/ios`:

```sh
xcodebuild -workspace LuggMapsExample.xcworkspace -scheme LuggMapsExample \
  -configuration Release -destination id=<UDID> -derivedDataPath /tmp/maps-e2e/dd-sim build \
  > /tmp/maps-e2e/build-sim.log 2>&1; echo "EXIT $?"
```

Install with argent `reinstall-app`, from `<derivedDataPath>/Build/Products/<Config>-iphonesimulator/LuggMapsExample.app`. Grant location with `settings-permissions` (`grant location`) before the launch, or the permission dialog covers the map.

- A branch that adds a codegen prop fails with "no member named X" until `pod install` in `example/bare/ios`. `pod install` also reorders `PrivacyInfo.xcprivacy`; revert that file.
- Never run two xcodebuilds of this workspace at once, even with different `-derivedDataPath`. Both unpack `ReactNativeDependencies` into the shared `Pods` folder, and the builds fail with "Expected ReactNativeDependencies.xcframework ... not found". Run them one after the other.
- Other sessions may use the iPhone 18 Pro Max simulator. Use the iPhone 17 Pro Max unless that one is free.

### Physical iPhone

Argent drives a physical iPhone only over USB. Builds, installs and Instruments work over the network too:

```sh
xcodebuild ... -configuration Release -destination id=<DEVICE_UDID> \
  -allowProvisioningUpdates DEVELOPMENT_TEAM=ZLTMSN9YWT CODE_SIGN_STYLE=Automatic build
xcrun devicectl device install app --device <DEVICE_UDID> <...>/Release-iphoneos/LuggMapsExample.app
xcrun devicectl device process launch --device <DEVICE_UDID> --terminate-existing luggmaps.example -- <args>
```

The shell is zsh. An unquoted `$EXTRA` that holds several arguments does not split, and xcodebuild then fails with "requires a development team". Write the arguments out.

### Android emulator

Boot the emulator yourself with the hardware GPU, as a background command:

```sh
~/Library/Android/sdk/emulator/emulator -avd Pixel_10_Pro_XL -gpu host -no-audio
```

argent `boot-device` can fall back to software rendering, which makes the map drop frames.

```sh
cd example/bare/android && ./gradlew app:assembleRelease -PreactNativeArchitectures=arm64-v8a -q
adb install -r app/build/outputs/apk/release/app-release.apk
```

The Release APK has its bundle built in, so it needs no Metro. Debug (`app:assembleDebug`) loads from Metro:

- The emulator dials `10.0.2.2:<port>`, which times out on this AVD. Write `debug_http_host=localhost:<port>` into `shared_prefs/luggmaps.example_preferences.xml` with `run-as`, while the app is stopped. Also run `adb reverse tcp:<port> tcp:<port>`.
- `reinstall-app` wipes that preference. Use `adb install -r` to keep it.

With `-gpu host`, the emulator once lost its system server: the log showed `DisplaySurfaceGlContextHelper context was preempted`, `am` reported "Can't find service: activity", and the boot animation ran forever. Recover with `adb emu kill`, then boot again with `-no-snapshot-load`. Never `kill -9` the emulator.

### Web

Run `yarn expo start --web --port 8082`, with `EXPO_PUBLIC_GOOGLE_MAPS_API_KEY` set from `GOOGLE_MAPS_API_KEY` in `example/expo/.env`. Then open it in Chrome with `--remote-debugging-port=9222`, and drive it as the argent device `chromium-cdp-9222`. The page shows a "can't load Google Maps correctly" dialog; tap OK, and the map is usable.

## 2. Example app map

The home screen is a full-screen map with a control sheet. iOS starts on Apple Maps; Android and web are always Google.

| Control                        | Exercises                                                                                                                                    |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Add / Remove / Clear Markers   | Marker mount and unmount. There are 12 sample markers: icon, text, image, custom, and navigate types; some are draggable, some have callouts |
| Move Camera / Fit Markers      | Camera commands                                                                                                                              |
| Reload Map / Hide Map          | Map teardown and re-init, with every child re-added                                                                                          |
| Apple Maps / Google Maps       | Provider switch (iOS only). Remounts the map                                                                                                 |
| Load GeoJSON                   | GeoJSON sheet: presets, fetch, clear                                                                                                         |
| Static Maps                    | `staticMode` maps in a list (separate screen)                                                                                                |
| Fleet (0 → 10 → 50)            | Many moving custom markers. Each truck's `zIndex` follows its latitude, so trucks reorder as they pass each other                            |
| Motion: Path / Reanimated      | `path` (native keyframes) vs Reanimated `animatedProps` (a prop commit per frame) for the crew and the fleet                                 |
| Idle: Max fps / … / Power save | `idleFrameRate`                                                                                                                              |
| Tracking: On                   | `transitionDuration` live tracking (a GPS fix every 3 s)                                                                                     |
| Tap a marker                   | `onPress`, and navigation to the Detail screen                                                                                               |

Take tap targets from argent's element tree. The sheet buttons are `ViewGroup "<title>"` on Android and `AXGroup "<title>"` on iOS.

### Fixed scenarios from launch arguments (iOS)

Tapping through the sheet before each run is slow and drifts. For benchmarks, add a temporary hook to `example/shared/src/screens/HomeScreen.tsx`. Revert it before you commit:

```tsx
import { Platform, Settings } from 'react-native';
// e2e (temporary): -bench google,reanimated,24
const BENCH: string[] =
  Platform.OS === 'ios' ? (Settings.get('bench') ?? '').split(',') : [];
// useState initial values:
//   provider:   (BENCH[0] as MapProviderType) || 'apple'
//   crewMotion: (BENCH[1] as CrewMotion) || 'path'
//   fleetSize:  Number(BENCH[2] ?? 0)
```

Launch with `launchArgs: ["-bench", "google,reanimated,24"]` (argent) or `-- -bench google,reanimated,24` (devicectl). On Android, tap the controls with one `run-sequence` instead.

## 3. Evidence tools

- **Benchmarks and profiles:** [references/benchmark.md](references/benchmark.md). It covers per-process CPU on the simulator (`scripts/sim-cpu.sh`) and on a physical iPhone (`scripts/device-cpu.py`), and per-thread Time Profiler breakdowns (`scripts/thread-cpu.py`). It also covers side-by-side builds under different bundle ids, thermal throttling, and how to read the numbers.
- **Native debugging:** [references/native-debugging.md](references/native-debugging.md). It covers temporary `MAPDBG` logs, counting map objects that are added and removed, and crash triage.
- **Screenshots over time:** for "markers disappear" bugs, capture a few frames and put them side by side. A marker that is gone from argent's element tree is gone from the map, not just hidden.

  ```sh
  for i in 1 2 3 4; do sleep 3; adb exec-out screencap -p > /tmp/maps-e2e/f$i.png; done
  magick /tmp/maps-e2e/f{1,2,3,4}.png -crop 1344x1300+0+0 -resize 25% +append /tmp/maps-e2e/strip.png
  ```

## 4. A/B two builds

To prove a regression or a fix, build both versions and run the same steps.

```sh
cp <path> /tmp/maps-e2e/<File>.work        # back up the working change
git show HEAD:<path> > <path>               # swap in HEAD, then build
cp /tmp/maps-e2e/<File>.work <path>         # restore right after the build
git diff --stat                             # check the tree is back to the working change
```

Never `git stash` the user's work. Restore right after the build, so the tree is never left on HEAD.

- Copy each variant's built app (`cp -R .../LuggMapsExample.app /tmp/maps-e2e/before.app`) or APK, and swap them with `reinstall-app` instead of rebuilding.
- Alternate the variants for each scenario (A, B, A, B) instead of running all of A and then all of B. This keeps drift, heat and background load from favoring one side.
- To let the user compare by hand, install both side by side under different bundle ids and names. See [references/benchmark.md](references/benchmark.md#side-by-side-builds). On a 24-truck Google fleet, the two Google iOS icon strategies looked the same in CPU numbers, but one was visibly laggy next to the other.

## 5. Pitfalls

- **Debug vs Release:** never benchmark Debug.
- **Simulator vs device:** the simulator renders through the Mac's GPU. Confirm performance conclusions on a device, or say clearly that they come from the simulator.
- **CPU % alone:** lower app CPU can mean fewer frames rendered, not less work. Check the main thread's share in a profile, and how often its run loop goes idle (see benchmark.md).
- **Overheating:** long device runs push the iPhone into a "Serious" thermal state, and every later number is invalid. Log the thermal state with each window.
- **Fabric reorders children by `zIndex`:** a changed `zIndex` moves the native view with a remove and an insert. Map children must survive that without re-creating their map object; see `LuggMapView` on Android.
- **Google Maps on iOS logs every setter call** (`GMSMapsSDKLogger`). Set only values that changed.
- **The Google Maps API key** worked for the alternate bundle ids on the simulator and on a device.
- **Shared devices:** taps that land elsewhere, or a map that moves between your calls, may mean the user is using the device. Stop and ask before you fight over it.

## 6. Finish

1. Remove every temporary log (`grep -rn MAPDBG ios android/src src` prints nothing), the bench hook, and any other temporary edits to the example.
2. Format what you touched: `yarn tidy` (it includes clang-format for `ios/`), then `yarn typecheck`, `yarn lint` and `yarn test`.
3. Do a final build and install, and a short sanity pass over the scenarios the change touches, on each affected platform.
4. Report each finding with its evidence (log, table, profile, A/B), including pre-existing bugs.
5. Clean up when the user asks, or after the commit and push they asked for:
   - Uninstall the side-by-side apps (`devicectl device uninstall app`, `xcrun simctl uninstall`).
   - Delete `/tmp/maps-e2e`.
   - Kill Metro or the web server you started. Check with `ps -o command -p <pid>` that each one serves this repo.
   - Run `stop-all-simulator-servers` with `devices: [...]` naming the devices you used.
   - Shut down the devices: `xcrun simctl shutdown <UDID>` and `adb -s <serial> emu kill`.
