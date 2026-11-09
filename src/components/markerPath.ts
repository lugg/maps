import type { Coordinate } from '../types';
import type { MarkerPath } from './Marker.types';

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

/**
 * Degrees to turn from `from` to `to` the short way, in [-180, 180).
 */
const shortTurn = (from: number, to: number) =>
  ((((to - from) % 360) + 540) % 360) - 180;

/**
 * Where a marker following `path` is at `time` (milliseconds, as from
 * `Date.now()`), by the same rules the native code uses: straight lines
 * between keyframes, and each turn the short way. Returns `null` unless the
 * path has at least two keyframes and a time for each.
 */
export function pathPositionAt(
  path: MarkerPath,
  time: number
): MarkerPathPosition | null {
  const { coordinates, times, rotations, startTime, loop } = path;
  const count = coordinates.length;
  if (count < 2 || times.length !== count) return null;

  const first = times[0]!;
  const duration = times[count - 1]! - first;
  const elapsed = time - startTime;
  const progress =
    loop && duration > 0
      ? ((elapsed % duration) + duration) % duration
      : Math.min(Math.max(elapsed, 0), duration);
  const t = first + progress;

  let lo = 0;
  let hi = count - 1;
  while (hi - lo > 1) {
    const mid = Math.floor((lo + hi) / 2);
    if (times[mid]! <= t) lo = mid;
    else hi = mid;
  }
  const span = times[hi]! - times[lo]!;
  const f = span > 0 ? (t - times[lo]!) / span : 0;
  const a = coordinates[lo]!;
  const b = coordinates[hi]!;

  let rotation: number | undefined;
  if (rotations?.length === count) {
    const from = rotations[lo]!;
    const turned = from + shortTurn(from, rotations[hi]!) * f;
    rotation = ((turned % 360) + 360) % 360;
  }

  return {
    coordinate: {
      latitude: a.latitude + (b.latitude - a.latitude) * f,
      longitude: a.longitude + (b.longitude - a.longitude) * f,
    },
    rotation,
    index: f >= 1 ? hi : lo,
  };
}
