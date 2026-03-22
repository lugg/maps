export const INITIAL_ZOOM = 14;

export const CIRCLE_CENTER = { latitude: 37.78, longitude: -122.43 };

const CIRCLE_RADIUS = 0.003;
export const CIRCLE_COORDS = Array.from({ length: 36 }, (_, i) => {
  const angle = (i * 10 * Math.PI) / 180;
  return {
    latitude: CIRCLE_CENTER.latitude + CIRCLE_RADIUS * Math.cos(angle),
    longitude:
      CIRCLE_CENTER.longitude +
      (CIRCLE_RADIUS * Math.sin(angle)) /
        Math.cos((CIRCLE_CENTER.latitude * Math.PI) / 180),
  };
});

const HOLE_RADIUS = 0.0015;
export const CIRCLE_HOLES = [
  Array.from({ length: 36 }, (_, i) => {
    const angle = (i * 10 * Math.PI) / 180;
    return {
      latitude: CIRCLE_CENTER.latitude + HOLE_RADIUS * Math.cos(angle),
      longitude:
        CIRCLE_CENTER.longitude +
        (HOLE_RADIUS * Math.sin(angle)) /
          Math.cos((CIRCLE_CENTER.latitude * Math.PI) / 180),
    };
  }),
];
