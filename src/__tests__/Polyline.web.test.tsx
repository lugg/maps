import { Polyline } from '../components/Polyline.web';

jest.mock('react', () => ({
  memo: (component: unknown) => component,
  useCallback: (callback: unknown) => callback,
  useEffect: (effect: () => void) => effect(),
  useMemo: (factory: () => unknown) => factory(),
  useRef: (current: unknown) => ({ current }),
  useState: (value: unknown) => [value, jest.fn()],
}));

jest.mock('../MapProvider.web', () => ({
  useMapContext: () => ({ map: {}, isDraggingRef: { current: false } }),
}));

const originalGoogle = global.google;

afterEach(() => {
  global.google = originalGoogle;
  jest.restoreAllMocks();
});

it.each([60, 90, 120, 144])(
  'renders the trail endpoint during the loop delay at %i Hz',
  (refreshRate) => {
    let nextFrame: FrameRequestCallback = () => {};
    let time = 0;
    const draws: { time: number; path: google.maps.LatLngLiteral[] }[] = [];
    const recordPath = (path: google.maps.LatLngLiteral[]) => {
      draws.push({ time, path });
    };

    jest
      .spyOn(global, 'requestAnimationFrame')
      .mockImplementation((callback) => {
        nextFrame = callback;
        return 1;
      });
    jest.spyOn(global, 'cancelAnimationFrame').mockImplementation(() => {});
    global.google = {
      maps: {
        Polyline: jest.fn().mockImplementation(({ path }) => {
          recordPath(path);
          return {
            setPath: recordPath,
            setOptions: jest.fn(),
            setMap: jest.fn(),
          };
        }),
      },
    } as unknown as typeof google;

    const coordinates = Array.from({ length: 1000 }, (_, i) => ({
      latitude: 0,
      longitude: i / 1000,
    }));
    Polyline({
      coordinates,
      animated: true,
      animatedOptions: { duration: 1010, delay: 500, trailLength: 0.5 },
    });

    for (let frame = 0; frame <= refreshRate * 1.8; frame++) {
      time = (frame * 1000) / refreshRate;
      nextFrame(time);
    }

    const finalDraw = draws[draws.length - 1]!;
    expect(finalDraw.path[finalDraw.path.length - 1]).toEqual({
      lat: 0,
      lng: 0.999,
    });
    expect(finalDraw.time).toBeLessThan(1550);

    for (
      let frame = Math.floor(refreshRate * 1.8) + 1;
      frame <= refreshRate * 2.3;
      frame++
    ) {
      time = (frame * 1000) / refreshRate;
      nextFrame(time);
    }

    expect(draws[draws.length - 1]!.time).toBeGreaterThanOrEqual(
      finalDraw.time + 500
    );
    expect(draws[draws.length - 1]!.path).not.toEqual(finalDraw.path);
    for (let i = 1; i < draws.length; i++) {
      expect(draws[i]!.time - draws[i - 1]!.time).toBeGreaterThanOrEqual(32);
    }
  }
);
