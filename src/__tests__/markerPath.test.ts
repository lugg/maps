import { pathPositionAt } from '../components/markerPath';
import type { MarkerPath } from '../components/Marker.types';

const square: MarkerPath = {
  coordinates: [
    { latitude: 0, longitude: 0 },
    { latitude: 1, longitude: 0 },
    { latitude: 1, longitude: 1 },
    { latitude: 0, longitude: 0 },
  ],
  times: [0, 1000, 2000, 4000],
  rotations: [350, 10, 90, 350],
  startTime: 10_000,
};

it('interpolates between keyframes from the wall clock', () => {
  expect(pathPositionAt(square, 10_500)).toEqual({
    coordinate: { latitude: 0.5, longitude: 0 },
    rotation: 0,
    index: 0,
  });
  expect(pathPositionAt(square, 11_500)?.coordinate).toEqual({
    latitude: 1,
    longitude: 0.5,
  });
  expect(pathPositionAt(square, 11_500)?.index).toBe(1);
});

it('turns the short way between keyframes', () => {
  // 10 → 90 is +80; 90 → 350 is -100, not +260.
  expect(pathPositionAt(square, 11_500)?.rotation).toBeCloseTo(50);
  expect(pathPositionAt(square, 13_000)?.rotation).toBeCloseTo(40);
});

it('holds the ends without loop and wraps laps with it', () => {
  expect(pathPositionAt(square, 0)?.coordinate).toEqual(square.coordinates[0]);
  expect(pathPositionAt(square, 99_000)).toMatchObject({
    coordinate: square.coordinates[3],
    index: 3,
  });
  const looping = { ...square, loop: true };
  expect(pathPositionAt(looping, 10_500 + 4000 * 3)?.coordinate).toEqual({
    latitude: 0.5,
    longitude: 0,
  });
  expect(pathPositionAt(looping, 10_500 - 4000)?.coordinate).toEqual({
    latitude: 0.5,
    longitude: 0,
  });
});

it('needs two keyframes with a time each', () => {
  expect(pathPositionAt({ ...square, times: [0, 1000] }, 10_500)).toBeNull();
  expect(
    pathPositionAt(
      { coordinates: [square.coordinates[0]!], times: [0], startTime: 0 },
      0
    )
  ).toBeNull();
});
