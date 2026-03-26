import { memo, useCallback, useEffect, useRef } from 'react';
import { useMapContext } from '../MapProvider.web';
import type { GroundOverlayProps } from './GroundOverlay.types';

export const GroundOverlay = memo(
  ({ image, bounds, opacity = 1, zIndex = 0, onPress }: GroundOverlayProps) => {
    const { map } = useMapContext();
    const overlayRef = useRef<google.maps.GroundOverlay | null>(null);
    const listenersRef = useRef<google.maps.MapsEventListener[]>([]);

    const handleClick = useCallback(() => {
      onPress?.();
    }, [onPress]);

    // Cleanup on unmount
    useEffect(() => {
      return () => {
        listenersRef.current.forEach((l) => l.remove());
        listenersRef.current = [];
        overlayRef.current?.setMap(null);
        overlayRef.current = null;
      };
    }, []);

    // Sync listeners
    useEffect(() => {
      const overlay = overlayRef.current;
      if (!overlay) return;

      listenersRef.current.forEach((l) => l.remove());
      listenersRef.current = [];

      if (onPress) {
        listenersRef.current.push(overlay.addListener('click', handleClick));
      }
      overlay.set('clickable', !!onPress);
    }, [onPress, handleClick]);

    // Sync overlay with props
    useEffect(() => {
      if (!map) {
        overlayRef.current?.setMap(null);
        return;
      }

      const source =
        typeof image === 'number'
          ? null
          : Array.isArray(image)
          ? image[0]
          : image;
      const imageUrl = source?.uri ?? '';
      if (!imageUrl) return;

      const latLngBounds = new google.maps.LatLngBounds(
        { lat: bounds.southwest.latitude, lng: bounds.southwest.longitude },
        { lat: bounds.northeast.latitude, lng: bounds.northeast.longitude }
      );

      // GroundOverlay bounds are immutable — recreate if bounds change
      overlayRef.current?.setMap(null);
      listenersRef.current.forEach((l) => l.remove());
      listenersRef.current = [];

      const overlay = new google.maps.GroundOverlay(imageUrl, latLngBounds, {
        opacity,
        clickable: !!onPress,
        map,
      });

      overlay.set('zIndex', zIndex);
      overlayRef.current = overlay;

      if (onPress) {
        listenersRef.current.push(overlay.addListener('click', handleClick));
      }
    }, [map, image, bounds, opacity, zIndex, onPress, handleClick]);

    return null;
  }
);
