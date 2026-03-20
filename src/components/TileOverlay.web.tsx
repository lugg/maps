import { useCallback, useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { TileOverlayProps } from './TileOverlay.types';

export const TileOverlay = ({
  urlTemplate,
  tileSize = 256,
  opacity = 1,
  bounds,
  zIndex = 0,
  onPress,
}: TileOverlayProps) => {
  const { map } = useMapContext();
  const overlayRef = useRef<google.maps.ImageMapType | null>(null);
  const indexRef = useRef<number>(-1);

  const handleClick = useCallback(() => {
    onPress?.();
  }, [onPress]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (overlayRef.current && indexRef.current >= 0) {
        map?.overlayMapTypes.removeAt(indexRef.current);
      }
      overlayRef.current = null;
      indexRef.current = -1;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Sync overlay with props
  useEffect(() => {
    if (!map) return;

    // Remove old overlay
    if (overlayRef.current && indexRef.current >= 0) {
      map.overlayMapTypes.removeAt(indexRef.current);
      overlayRef.current = null;
      indexRef.current = -1;
    }

    if (!urlTemplate) return;

    const imageMapType = new google.maps.ImageMapType({
      getTileUrl: (coord, zoom) => {
        if (bounds) {
          const n = Math.pow(2, zoom);
          const tileSWLat =
            (Math.atan(Math.sinh(Math.PI * (1 - (2 * (coord.y + 1)) / n))) *
              180) /
            Math.PI;
          const tileNELat =
            (Math.atan(Math.sinh(Math.PI * (1 - (2 * coord.y) / n))) * 180) /
            Math.PI;
          const tileSWLng = (coord.x / n) * 360 - 180;
          const tileNELng = ((coord.x + 1) / n) * 360 - 180;

          if (
            tileNELat < bounds.southwest.latitude ||
            tileSWLat > bounds.northeast.latitude ||
            tileNELng < bounds.southwest.longitude ||
            tileSWLng > bounds.northeast.longitude
          ) {
            return null;
          }
        }

        return urlTemplate
          .replace('{x}', String(coord.x))
          .replace('{y}', String(coord.y))
          .replace('{z}', String(zoom));
      },
      tileSize: new google.maps.Size(tileSize, tileSize),
      opacity,
    });

    const length = map.overlayMapTypes.getLength();
    map.overlayMapTypes.insertAt(length, imageMapType);
    overlayRef.current = imageMapType;
    indexRef.current = length;
  }, [
    map,
    urlTemplate,
    tileSize,
    opacity,
    bounds,
    zIndex,
    onPress,
    handleClick,
  ]);

  return null;
};
