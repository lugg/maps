import type { Coordinate } from '../types';
import type { MarkerPath, MarkerProps } from './Marker.types';

/**
 * The keyframes native code follows: straight lines between them, and each
 * turn the short way.
 */
export interface NativeMarkerPath {
  coordinates: Coordinate[];
  /**
   * Milliseconds from the start of the path, one per keyframe.
   */
  times: number[];
  rotations?: number[];
  startTime: number;
  loop?: boolean;
  /**
   * For each keyframe, the index in the app's `coordinates` it comes from, or
   * `-1` for keyframes added to settle a turn.
   */
  sources: number[];
}

export interface MarkerPathPosition {
  coordinate: Coordinate;
  /**
   * Degrees clockwise from north, in [0, 360). Only when the path has
   * `rotations`.
   */
  rotation?: number;
  /**
   * Index of the last keyframe passed, within the current lap.
   */
  index: number;
}

// How long `rotateAlongPath` takes to turn onto a segment
const TURN_DURATION = 300;

const toRadians = (degrees: number) => (degrees * Math.PI) / 180;

/**
 * Degrees to turn from `from` to `to` the short way, in [-180, 180).
 */
const shortTurn = (from: number, to: number) =>
  ((((to - from) % 360) + 540) % 360) - 180;

/**
 * Constant-heading bearing from `from` to `to`, in degrees clockwise from
 * north.
 */
const bearing = (from: Coordinate, to: Coordinate) => {
  const φ1 = toRadians(from.latitude);
  const φ2 = toRadians(to.latitude);
  let Δλ = toRadians(to.longitude - from.longitude);
  if (Math.abs(Δλ) > Math.PI) Δλ -= Math.sign(Δλ) * 2 * Math.PI;
  const Δψ = Math.log(
    Math.tan(Math.PI / 4 + φ2 / 2) / Math.tan(Math.PI / 4 + φ1 / 2)
  );
  return ((Math.atan2(Δλ, Δψ) * 180) / Math.PI + 360) % 360;
};

// Proportional to distance, which is all keyframe timing needs
const span = (from: Coordinate, to: Coordinate) => {
  const x =
    (to.longitude - from.longitude) *
    Math.cos(toRadians((from.latitude + to.latitude) / 2));
  return Math.hypot(x, to.latitude - from.latitude);
};

const lerp = (from: Coordinate, to: Coordinate, f: number): Coordinate => ({
  latitude: from.latitude + (to.latitude - from.latitude) * f,
  longitude: from.longitude + (to.longitude - from.longitude) * f,
});

const spreadByDistance = (coordinates: Coordinate[], duration: number) => {
  const spans = coordinates.slice(1).map((c, i) => span(coordinates[i]!, c));
  const total = spans.reduce((sum, s) => sum + s, 0);
  const times = [0];
  spans.forEach((s, i) =>
    times.push(
      times[i]! + (total > 0 ? (s / total) * duration : duration / spans.length)
    )
  );
  return times;
};

// Faces each segment, turning onto it over TURN_DURATION from its first
// keyframe, so the marker drives straight between turns
const alongPath = (
  coordinates: Coordinate[],
  times: number[]
): Pick<
  NativeMarkerPath,
  'coordinates' | 'times' | 'rotations' | 'sources'
> => {
  const path = {
    coordinates: [] as Coordinate[],
    times: [] as number[],
    rotations: [] as number[],
    sources: [] as number[],
  };
  const add = (c: Coordinate, t: number, r: number, source: number) => {
    path.coordinates.push(c);
    path.times.push(t);
    path.rotations.push(r);
    path.sources.push(source);
  };
  let heading = bearing(coordinates[0]!, coordinates[1]!);
  for (let i = 0; i < coordinates.length - 1; i++) {
    const from = coordinates[i]!;
    const to = coordinates[i + 1]!;
    const next = bearing(from, to);
    add(from, times[i]!, heading, i);
    const segment = times[i + 1]! - times[i]!;
    if (next !== heading && segment > 0) {
      const turn = Math.min(TURN_DURATION, segment / 2);
      add(lerp(from, to, turn / segment), times[i]! + turn, next, -1);
    }
    heading = next;
  }
  add(
    coordinates[coordinates.length - 1]!,
    times[times.length - 1]!,
    heading,
    coordinates.length - 1
  );
  return path;
};

const resolvePath = (
  path: MarkerPath,
  rotateAlongPath: boolean,
  now: number
): NativeMarkerPath | undefined => {
  const { coordinates, rotations, startTime = now, loop } = path;
  if (coordinates.length < 2) return undefined;
  const times = path.times ?? spreadByDistance(coordinates, path.duration);
  if (times.length !== coordinates.length) return undefined;
  if (rotateAlongPath && !rotations) {
    return { ...alongPath(coordinates, times), startTime, loop };
  }
  return {
    coordinates,
    times,
    rotations,
    startTime,
    loop,
    sources: coordinates.map((_, i) => i),
  };
};

// Milliseconds into the current lap, measured from the first keyframe's time
const lapTime = (path: NativeMarkerPath, time: number) => {
  const { times, startTime, loop } = path;
  const duration = times[times.length - 1]! - times[0]!;
  const elapsed = time - startTime;
  return (
    times[0]! +
    (loop && duration > 0
      ? ((elapsed % duration) + duration) % duration
      : Math.min(Math.max(elapsed, 0), duration))
  );
};

/**
 * Where a marker following `path` is at `time` (milliseconds, as from
 * `Date.now()`), by the same rules the native code uses.
 */
export function pathPositionAt(
  path: NativeMarkerPath,
  time: number
): MarkerPathPosition {
  const { coordinates, times, rotations } = path;
  const t = lapTime(path, time);

  let lo = 0;
  let hi = coordinates.length - 1;
  while (hi - lo > 1) {
    const mid = Math.floor((lo + hi) / 2);
    if (times[mid]! <= t) lo = mid;
    else hi = mid;
  }
  const length = times[hi]! - times[lo]!;
  const f = length > 0 ? (t - times[lo]!) / length : 0;

  let rotation: number | undefined;
  if (rotations) {
    const from = rotations[lo]!;
    const turned = from + shortTurn(from, rotations[hi]!) * f;
    rotation = ((turned % 360) + 360) % 360;
  }

  return {
    coordinate: lerp(coordinates[lo]!, coordinates[hi]!, f),
    rotation,
    index: f >= 1 ? hi : lo,
  };
}

/**
 * Turns a marker's `path`, or a `coordinate` change with `transitionDuration`,
 * into the keyframes native code follows. Keeps the keyframes across renders,
 * so native only gets new ones when the motion changes.
 */
export class MarkerMotion {
  private source?: MarkerPath;
  private rotateAlongPath = false;
  private target?: Coordinate & { rotate: number };
  private path?: NativeMarkerPath;

  resolve(
    {
      path,
      coordinate,
      rotate = 0,
      rotateAlongPath = false,
      transitionDuration = 0,
    }: MarkerProps,
    now = Date.now()
  ): NativeMarkerPath | undefined {
    if (path) {
      if (path !== this.source || rotateAlongPath !== this.rotateAlongPath) {
        this.source = path;
        this.rotateAlongPath = rotateAlongPath;
        this.path = resolvePath(path, rotateAlongPath, now);
      }
      this.target = undefined;
      return this.path;
    }
    this.source = undefined;

    const { latitude, longitude } = coordinate;
    const last = this.target;
    this.target = { latitude, longitude, rotate };
    if (transitionDuration <= 0 || !last) {
      this.path = undefined;
      return undefined;
    }
    if (
      last.latitude === latitude &&
      last.longitude === longitude &&
      last.rotate === rotate
    ) {
      return this.path;
    }

    // Glide from where the marker is now, which may be mid-move
    const at = this.path && pathPositionAt(this.path, now);
    const from = at?.coordinate ?? {
      latitude: last.latitude,
      longitude: last.longitude,
    };
    const fromRotation = at?.rotation ?? last.rotate;
    const to = { latitude, longitude };
    const moved = from.latitude !== latitude || from.longitude !== longitude;
    const toRotation = !rotateAlongPath
      ? rotate
      : moved
      ? bearing(from, to)
      : fromRotation;
    this.path = {
      coordinates: [from, to],
      times: [0, transitionDuration],
      rotations: [fromRotation, toRotation],
      startTime: now,
      sources: [-1, -1],
    };
    return this.path;
  }
}

/**
 * Calls `onProgress` with the index of each keyframe a marker passes, and once
 * when a path starts. The path is a function of the clock, so one timer per
 * keyframe is enough.
 */
export class PathProgress {
  private path?: NativeMarkerPath;
  private onProgress?: (index: number) => void;
  private timer?: ReturnType<typeof setTimeout>;
  private emitted = -1;

  update(
    path: NativeMarkerPath | undefined,
    onProgress: ((index: number) => void) | undefined
  ) {
    const restart = path !== this.path || !onProgress !== !this.onProgress;
    this.onProgress = onProgress;
    if (!restart) return;
    this.stop();
    this.path = path;
    this.emitted = -1;
    if (path && onProgress && path.sources.some((s) => s >= 0)) this.tick();
  }

  stop() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = undefined;
  }

  private tick = () => {
    const path = this.path!;
    const now = Date.now();
    const { index } = pathPositionAt(path, now);

    let passed = index;
    while (passed > 0 && path.sources[passed]! < 0) passed--;
    const source = path.sources[passed]!;
    if (source >= 0 && source !== this.emitted) {
      this.emitted = source;
      this.onProgress?.(source);
    }

    const { times, startTime, loop } = path;
    const last = times.length - 1;
    if (!loop && index >= last) return;
    const next = times[Math.min(index + 1, last)]!;
    const at = loop
      ? now + (next - lapTime(path, now))
      : startTime + (next - times[0]!);
    this.timer = setTimeout(this.tick, Math.max(at - now, 0) + 1);
  };
}
