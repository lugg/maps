import {
  MarkerMotion,
  PathProgress,
  pathPositionAt,
  type NativeMarkerPath,
} from '../components/markerPath';
import type { MarkerPath } from '../components/Marker.types';

const square: NativeMarkerPath = {
  coordinates: [
    { latitude: 0, longitude: 0 },
    { latitude: 1, longitude: 0 },
    { latitude: 1, longitude: 1 },
    { latitude: 0, longitude: 0 },
  ],
  times: [0, 1000, 2000, 4000],
  rotations: [350, 10, 90, 350],
  startTime: 10_000,
  sources: [0, 1, 2, 3],
};

const coordinate = { latitude: 0, longitude: 0 };

describe('pathPositionAt', () => {
  it('interpolates between keyframes from the wall clock', () => {
    expect(pathPositionAt(square, 10_500)).toEqual({
      coordinate: { latitude: 0.5, longitude: 0 },
      rotation: 0,
      index: 0,
    });
    expect(pathPositionAt(square, 11_500)).toMatchObject({
      coordinate: { latitude: 1, longitude: 0.5 },
      index: 1,
    });
  });

  it('turns the short way between keyframes', () => {
    // 10 → 90 is +80; 90 → 350 is -100, not +260.
    expect(pathPositionAt(square, 11_500).rotation).toBeCloseTo(50);
    expect(pathPositionAt(square, 13_000).rotation).toBeCloseTo(40);
  });

  it('holds the ends without loop and wraps laps with it', () => {
    expect(pathPositionAt(square, 0).coordinate).toEqual(square.coordinates[0]);
    expect(pathPositionAt(square, 99_000)).toMatchObject({
      coordinate: square.coordinates[3],
      index: 3,
    });
    const looping = { ...square, loop: true };
    expect(pathPositionAt(looping, 10_500 + 4000 * 3).coordinate).toEqual({
      latitude: 0.5,
      longitude: 0,
    });
    expect(pathPositionAt(looping, 10_500 - 4000).coordinate).toEqual({
      latitude: 0.5,
      longitude: 0,
    });
  });
});

describe('MarkerMotion', () => {
  // An L: 2 units north, then 1 unit east, near the equator
  const route = [
    { latitude: 0, longitude: 0 },
    { latitude: 0.002, longitude: 0 },
    { latitude: 0.002, longitude: 0.001 },
  ];

  it('spreads duration by distance and starts when set', () => {
    const path: MarkerPath = { coordinates: route, duration: 3000 };
    const resolved = new MarkerMotion().resolve({ coordinate, path }, 500)!;
    expect(resolved.times[0]).toBe(0);
    expect(resolved.times[1]).toBeCloseTo(2000);
    expect(resolved.times[2]).toBeCloseTo(3000);
    expect(resolved.startTime).toBe(500);
    expect(resolved.rotations).toBeUndefined();
  });

  it('keeps the keyframes until a field changes', () => {
    const motion = new MarkerMotion();
    const path: MarkerPath = { coordinates: route, duration: 3000 };
    const first = motion.resolve({ coordinate, path }, 0);
    expect(motion.resolve({ coordinate, path }, 1000)).toBe(first);
    expect(motion.resolve({ coordinate, path: { ...path } }, 1000)).toBe(first);
    expect(
      motion.resolve({ coordinate, path: { ...path, loop: true } }, 1000)
        ?.startTime
    ).toBe(1000);
    expect(
      motion.resolve(
        { coordinate, path: { ...path, coordinates: [...route] } },
        2000
      )?.startTime
    ).toBe(2000);
  });

  it('faces each segment, settling turns after the corner', () => {
    const path: MarkerPath = { coordinates: route, times: [0, 2000, 3000] };
    const resolved = new MarkerMotion().resolve(
      { coordinate, path, rotateAlongPath: true },
      0
    )!;
    expect(resolved.times).toEqual([0, 2000, 2300, 3000]);
    expect(resolved.sources).toEqual([0, 1, -1, 2]);
    expect(resolved.rotations![0]).toBeCloseTo(0);
    expect(resolved.rotations![1]).toBeCloseTo(0);
    expect(resolved.rotations![2]).toBeCloseTo(90);
    expect(resolved.rotations![3]).toBeCloseTo(90);
  });

  it('glides from where the marker is to each new coordinate', () => {
    const motion = new MarkerMotion();
    const props = { transitionDuration: 1000, rotateAlongPath: true };
    expect(motion.resolve({ ...props, coordinate }, 0)).toBeUndefined();

    const north = { latitude: 1, longitude: 0 };
    const first = motion.resolve({ ...props, coordinate: north }, 0)!;
    expect(first.coordinates).toEqual([coordinate, north]);
    expect(first.rotations![1]).toBeCloseTo(0);

    // Halfway there, a new fix restarts from the current position
    const east = { latitude: 0.5, longitude: 1 };
    const second = motion.resolve({ ...props, coordinate: east }, 500)!;
    expect(second.coordinates[0]).toEqual({ latitude: 0.5, longitude: 0 });
    expect(second.startTime).toBe(500);
    expect(second.rotations![1]).toBeCloseTo(90);
  });

  it('keeps the heading through GPS drift', () => {
    const motion = new MarkerMotion();
    const props = { transitionDuration: 1000, rotateAlongPath: true };
    motion.resolve({ ...props, coordinate }, 0);
    const north = { latitude: 0.001, longitude: 0 };
    motion.resolve({ ...props, coordinate: north }, 0);
    // About 2 m east, after the first move ends
    const drift = { latitude: 0.001, longitude: 0.00002 };
    const resolved = motion.resolve({ ...props, coordinate: drift }, 1000)!;
    expect(resolved.rotations![1]).toBeCloseTo(0);
  });

  it('jumps without transitionDuration', () => {
    const motion = new MarkerMotion();
    motion.resolve({ coordinate }, 0);
    expect(
      motion.resolve({ coordinate: { latitude: 1, longitude: 1 } }, 0)
    ).toBeUndefined();
  });
});

describe('PathProgress', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(10_000);
  });
  afterEach(() => jest.useRealTimers());

  it('reports each app keyframe passed, skipping turn keyframes', () => {
    const path: NativeMarkerPath = {
      ...square,
      rotations: undefined,
      sources: [0, 1, -1, 2],
    };
    const progress = new PathProgress();
    const onProgress = jest.fn();
    progress.update(path, onProgress);
    expect(onProgress.mock.calls).toEqual([[0]]);

    // Each check fires 1 ms after its keyframe
    jest.advanceTimersByTime(1001);
    expect(onProgress.mock.calls).toEqual([[0], [1]]);
    jest.advanceTimersByTime(1000);
    expect(onProgress.mock.calls).toEqual([[0], [1]]);
    jest.advanceTimersByTime(2000);
    expect(onProgress.mock.calls).toEqual([[0], [1], [2]]);
    progress.stop();
  });

  it('wraps to the first keyframe on loop', () => {
    const progress = new PathProgress();
    const onProgress = jest.fn();
    progress.update({ ...square, loop: true }, onProgress);
    jest.advanceTimersByTime(4001);
    expect(onProgress.mock.calls).toEqual([[0], [1], [2], [0]]);
    progress.stop();
  });
});
