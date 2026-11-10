# Benchmarks and profiles

Measure in a Release build, with the camera still, and with the same scenario for every variant. Use 30 s windows, and start them after a 15–20 s warm-up following the launch, so that mounting the fleet isn't counted. Take two windows per scenario. If they differ by more than a few points, something else is running.

Report CPU as % of one core. Report the app and backboardd (the system process that composites the screen) separately: a change can move work from one to the other.

## iOS simulator: per-process CPU

`scripts/sim-cpu.sh <UDID> <label> [seconds]` reads the cumulative CPU time of the app and of the simulator's backboardd before and after the window. It prints one line and appends it to `/tmp/maps-e2e/results.tsv`:

```
before google reanimated24 #1	app 55.6%	backboardd 16.5%
```

Boot only one simulator while you measure: the script picks the first simulator backboardd it finds.

## Physical iPhone: per-process CPU

`scripts/device-cpu.py <DEVICE_UDID> <label> [seconds]` records an Instruments Activity Monitor trace, reads the change in each process's CPU time, and logs the device's thermal state:

```
before google path 24 #1 [Nominal]	LuggMapsExample 43.5% (30s)	backboardd 13.3% (30s)
```

- xctrace often fails with "Waiting for device to boot" or "Timed out waiting for device". The script calls `devicectl device info details` first, which wakes the connection, and retries.
- The `(30s)` is the span the samples cover. A much shorter span (for example 1 s, with CPU over 500%) means the device was overloaded and the sampler starved. Discard that window.
- Thermal: a phone that is charging and running back-to-back windows reaches `Serious` within about 15 minutes, and every number after that is invalid. Stop the app and wait for `Nominal` or `Fair` before the next window. Don't benchmark while the phone charges, if you can avoid it.

## Per-thread profile (simulator)

Use argent `native-profiler-start` with `app_process: "LuggMapsExample"`. Wait 20 s with a Bash `sleep 20`, then call `native-profiler-stop`. Its `exportedFiles.cpu` is a time-profile XML. Then:

```sh
python3 -I scripts/thread-cpu.py <cpu.xml> 20 \
  '-[GMSVectorMapView draw]' 'createScaledIconImage' 'applyMarkerStyle'
```

It prints each thread's CPU %, and how much of the main thread is spent under each given frame (inclusive). Example: Google, 50 Reanimated markers, re-creating the icon on every update vs skipping it:

|                       | Skip | Re-create |
| --------------------- | ---- | --------- |
| Main thread           | 64%  | 87%       |
| GMSVectorMapView draw | 36%  | 17%       |
| createScaledIconImage | 4%   | 60%       |

The map drew half as much with the re-created icon only because the busy main thread rendered fewer frames.

### Is it fewer frames, or less work?

The trace's `runloop-events` table records each main run loop iteration. If the main thread goes idle (`waiting_for_events`) less often per second, it renders fewer frames:

```sh
xcrun xctrace export --input <trace> --xpath '/trace-toc/run[@number="1"]/data/table[@schema="runloop-events"]' > rl.xml
```

Count the `interval-type` values of the rows whose `thread` is the app's main thread. In the example above, the main thread went idle 282 times a second with the skip and 120 times with the re-created icon.

## Side-by-side builds

These let the user compare two variants by hand on the same device.

Simulator: copy each built `.app`. In each copy, change `CFBundleIdentifier` (for example `luggmaps.example.fix2`) and `CFBundleDisplayName` (for example `Maps Fix2`) with PlistBuddy, then run `codesign -f -s - --deep <app>`. Install with `reinstall-app` under the new bundle id, and grant location for each id.

Device: build each variant with `PRODUCT_BUNDLE_IDENTIFIER=luggmaps.example.<variant>` and a separate `-derivedDataPath`. Then set the display name and sign again with the same identity and entitlements:

```sh
APP=<dd>/Build/Products/Release-iphoneos/LuggMapsExample.app
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Maps Fix2" $APP/Info.plist
ID=$(codesign -dvv $APP 2>&1 | awk -F= '/^Authority=Apple Development/{print $2; exit}')
codesign -d --entitlements :- $APP > /tmp/maps-e2e/ent.plist
codesign -f -s "$ID" --entitlements /tmp/maps-e2e/ent.plist $APP
xcrun devicectl device install app --device <DEVICE_UDID> $APP
```

The display name is fixed in `Info.plist` (`LuggMapsExample`), so it has to be set on the built app.

## Reference numbers

These come from Release builds after #110. Use them to spot a scenario that is far off. Fleet 24 means the fleet plus the crew marker; the camera was still.

| Scenario                     | iPhone 17 Pro Max sim (app + backboardd) | iPhone 17 Pro Max device |
| ---------------------------- | ---------------------------------------- | ------------------------ |
| Google, Reanimated, fleet 24 | 55–58% + 16–18%                          | 89% + 22%                |
| Google, path, fleet 24       | 25% + 9%                                 | 44% + 13%                |
| Apple, Reanimated, fleet 24  | 39% + 9%                                 | 60% + 45%                |
| Apple, path, fleet 24        | 37% + 8%                                 | 71% + 42%                |

The device numbers may include some throttling. On the device, Apple path costs more than Apple Reanimated.
