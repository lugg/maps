# Native debugging (temporary logs, map object counts, crashes)

## Temporary logs

Log at the branches under test: which path ran, which early return fired, which map object was added or removed. Prefix every line with `MAPDBG`, so the lines are easy to find and to remove.

- iOS: `RCTLogWarn(@"MAPDBG <what> %@", value);`. Rebuild, run the scenario, then read the log from `debugger-log-registry` (Debug), or with `xcrun simctl spawn <UDID> log show --last 2m --predicate 'process == "LuggMapsExample"' | grep MAPDBG`.
- Android: `android.util.Log.w("MAPDBG", "<what> ${value}")`. Run `adb logcat -c` before the run, and `adb logcat -d -s MAPDBG` after it. Release builds log too, so you don't need Metro.

Check with `grep -rn MAPDBG ios android/src src` that nothing is left before the final build.

## Counting map objects

Most "disappears" or "flickers" bugs are a map object (a Google marker, an annotation, a polyline) that is removed, re-created, or never added back. Log the provider's add and remove calls with the view's id:

```kotlin
android.util.Log.w("MAPDBG", "add ${markerView.id}")     // after map.addMarker
android.util.Log.w("MAPDBG", "remove ${markerView.id} marker=${markerView.marker?.id}")
```

Then read the counts:

```sh
adb logcat -d -s MAPDBG | awk '{print $NF}' | sort | uniq -c | sort -rn | head   # adds per view
adb logcat -d -s MAPDBG | grep -c add
```

- A `remove` for a view that JS still renders, with no `add` after it, means the object is gone from the map: the marker disappears.
- More than one `add` for the same view means the object is re-created: the marker flickers.
- When nothing is wrong, each view is added once at mount.

Example: the fleet trucks in Reanimated motion disappeared on Android, because each `zIndex` change made Fabric remove the view and insert it again (PR #111).

## Crash triage

If the app drops to the home screen or the launcher, it died. `launch-app` then starts a fresh process.

### iOS

- Simulator crash reports: `~/Library/Logs/DiagnosticReports/LuggMapsExample-<date>.ips` (JSON after the first line). Read the faulting thread's frames.
- Device: `xcrun devicectl device copy from --device <UDID> --domain-type systemCrashLogs --source / --destination /tmp/maps-e2e/crash`. `LuggMapsExample.cpu_resource-*.ips` is a CPU-usage report, not a crash.
- Check that the app is still running: `xcrun devicectl device info processes --device <UDID> | grep LuggMaps`.

### Android

- Kotlin or Java crash: `adb logcat -d -b crash`.
- JS errors: `adb logcat -d -s ReactNativeJS`.
- If `adb shell am ...` says "Can't find service: activity", the Android system itself died, not the app (see the emulator recovery steps in SKILL.md).
