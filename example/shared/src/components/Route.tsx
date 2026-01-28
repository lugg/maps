import { Polyline, type Coordinate } from '@lugg/maps';

export const catmullRom = (
  p0: Coordinate,
  p1: Coordinate,
  p2: Coordinate,
  p3: Coordinate,
  t: number
): Coordinate => {
  const t2 = t * t;
  const t3 = t2 * t;

  return {
    latitude:
      0.5 *
      (2 * p1.latitude +
        (-p0.latitude + p2.latitude) * t +
        (2 * p0.latitude - 5 * p1.latitude + 4 * p2.latitude - p3.latitude) *
          t2 +
        (-p0.latitude + 3 * p1.latitude - 3 * p2.latitude + p3.latitude) * t3),
    longitude:
      0.5 *
      (2 * p1.longitude +
        (-p0.longitude + p2.longitude) * t +
        (2 * p0.longitude -
          5 * p1.longitude +
          4 * p2.longitude -
          p3.longitude) *
          t2 +
        (-p0.longitude + 3 * p1.longitude - 3 * p2.longitude + p3.longitude) *
          t3),
  };
};

export const smoothCoordinates = (
  coords: Coordinate[],
  segments = 10
): Coordinate[] => {
  const first = coords[0];
  const last = coords.at(-1);
  if (coords.length < 3 || !first || !last) return coords;

  const clamp = (i: number) => Math.max(0, Math.min(i, coords.length - 1));
  const result: Coordinate[] = [];

  for (let i = 0; i < coords.length - 1; i++) {
    const p0 = coords[clamp(i - 1)] ?? first;
    const p1 = coords[clamp(i)] ?? first;
    const p2 = coords[clamp(i + 1)] ?? first;
    const p3 = coords[clamp(i + 2)] ?? first;

    for (let j = 0; j < segments; j++) {
      result.push(catmullRom(p0, p1, p2, p3, j / segments));
    }
  }

  result.push(last);
  return result;
};

interface SmoothedRouteProps {
  coordinates: Coordinate[];
}

export const Route = ({ coordinates }: SmoothedRouteProps) => {
  if (coordinates.length < 2) return null;

  return (
    <>
      <Polyline
        strokeColors={['#B0B0B0']}
        coordinates={coordinates}
        strokeWidth={6}
      />
      <Polyline
        strokeColors={['#B321E0', '#3744FF']}
        coordinates={coordinates}
        strokeWidth={6}
        animated
      />
    </>
  );
};
