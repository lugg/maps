import { useCallback, useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { TileOverlayProps } from './TileOverlay.types';

export const TileOverlay = ({
  urlTemplate,
  tileSize = 256,
  opacity = 1,
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
  }, [map, urlTemplate, tileSize, opacity, zIndex, onPress, handleClick]);

  return null;
};
