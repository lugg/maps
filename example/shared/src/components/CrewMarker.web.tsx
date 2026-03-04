import { useEffect, useRef, useState } from 'react';
import { Marker, type Coordinate } from '@lugg/maps';
import { getRhumbLineBearing } from 'geolib';

import { PickupIcon } from './PickupIcon';

const DEFAULT_ANCHOR = { x: 0.5, y: 0.5 };
const SEGMENT_DURATION = 2000;

interface CrewMarkerProps {
  route: Coordinate[];
  loaded?: boolean;
  speed?: number;
  zoom?: number;
}

const getBearing = (from: Coordinate, to: Coordinate, currentBearing = 0) => {
  let newBearing = getRhumbLineBearing(from, to);

  while (newBearing - currentBearing > 180) {
    newBearing -= 360;
  }
  while (newBearing - currentBearing < -180) {
    newBearing += 360;
  }

  return newBearing;
};

const BASE_ZOOM = 14;
const MIN_SCALE = 0.5;
const MAX_SCALE = 1.5;
const SCALE_MIN_ZOOM = 10;
const SCALE_MAX_ZOOM = 18;

const getScaleForZoom = (zoom: number) => {
  if (zoom <= SCALE_MIN_ZOOM) return MIN_SCALE;
  if (zoom >= SCALE_MAX_ZOOM) return MAX_SCALE;
  const t = (zoom - SCALE_MIN_ZOOM) / (SCALE_MAX_ZOOM - SCALE_MIN_ZOOM);
  return MIN_SCALE + t * (MAX_SCALE - MIN_SCALE);
};

export const CrewMarker = ({
  route,
  loaded = false,
  speed = 1,
  zoom = BASE_ZOOM,
}: CrewMarkerProps) => {
  const [coordinate, setCoordinate] = useState<Coordinate>(
    route[0] ?? { latitude: 0, longitude: 0 }
  );
  const [rotate, setRotate] = useState(0);
  const scale = getScaleForZoom(zoom);

  const currentBearingRef = useRef(0);
  const segmentIndexRef = useRef(0);
  const animationRef = useRef<number | null>(null);
  const startTimeRef = useRef(0);
  const fromCoordRef = useRef<Coordinate>(route[0]!);

  useEffect(() => {
    if (route.length < 2) return;

    segmentIndexRef.current = 0;
    setCoordinate(route[0]!);
    fromCoordRef.current = route[0]!;

    const animateSegment = (index: number) => {
      if (index >= route.length - 1) {
        segmentIndexRef.current = 0;
        animateSegment(0);
        return;
      }

      const from = route[index]!;
      const to = route[index + 1]!;
      fromCoordRef.current = from;

      const newBearing = getBearing(from, to, currentBearingRef.current);
      currentBearingRef.current = newBearing;
      setRotate(newBearing);

      const zoomScale = Math.pow(2, zoom - BASE_ZOOM);
      const duration = (SEGMENT_DURATION / speed) * zoomScale;

      startTimeRef.current = performance.now();

      const animate = (now: number) => {
        const elapsed = now - startTimeRef.current;
        const progress = Math.min(elapsed / duration, 1);

        const lat = from.latitude + (to.latitude - from.latitude) * progress;
        const lng = from.longitude + (to.longitude - from.longitude) * progress;
        setCoordinate({ latitude: lat, longitude: lng });

        if (progress < 1) {
          animationRef.current = requestAnimationFrame(animate);
        } else {
          segmentIndexRef.current = index + 1;
          animateSegment(index + 1);
        }
      };

      animationRef.current = requestAnimationFrame(animate);
    };

    animateSegment(0);

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, [route, speed, zoom]);

  if (!route[0]) return null;

  const zIndex = Math.round((90 - coordinate.latitude) * 10000);

  return (
    <Marker
      coordinate={coordinate}
      anchor={DEFAULT_ANCHOR}
      zIndex={zIndex}
      rotate={rotate}
      scale={scale}
    >
      <PickupIcon loaded={loaded} />
    </Marker>
  );
};
