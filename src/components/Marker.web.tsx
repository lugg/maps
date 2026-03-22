import React, {
  forwardRef,
  isValidElement,
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';
import {
  AdvancedMarker,
  InfoWindow,
  useAdvancedMarkerRef,
} from '@vis.gl/react-google-maps';
import { useMapContext } from '../MapProvider.web';
import type { MarkerProps, MarkerRef } from './Marker.types';

const CALLOUT_ARROW_HEIGHT = 12;
const UNBUBBLED_CLASS = 'rnm-callout-unbubbled';
const UNBUBBLED_STYLE_ID = 'rnm-callout-unbubbled-style';

function injectUnbubbledStyle() {
  if (document.getElementById(UNBUBBLED_STYLE_ID)) return;
  const style = document.createElement('style');
  style.id = UNBUBBLED_STYLE_ID;
  style.textContent = `
    .gm-style-iw-c:has(.${UNBUBBLED_CLASS}) {
      background: transparent !important;
      box-shadow: none !important;
      padding: 0 !important;
      border-radius: 0 !important;
    }
    .gm-style-iw-d:has(.${UNBUBBLED_CLASS}) {
      overflow: visible !important;
    }
    .gm-style-iw-t:has(.${UNBUBBLED_CLASS})::after,
    .gm-style-iw-t:has(.${UNBUBBLED_CLASS}) .gm-style-iw-tc {
      display: none !important;
    }
  `;
  document.head.appendChild(style);
}

const toWebAnchor = (value: number) => `-${value * 100}%`;

const createEvent = (
  e: google.maps.MapMouseEvent,
  coordinate: MarkerProps['coordinate']
) =>
  ({
    nativeEvent: {
      coordinate: {
        latitude: e.latLng?.lat() ?? coordinate.latitude,
        longitude: e.latLng?.lng() ?? coordinate.longitude,
      },
      point: {
        x: (e.domEvent as MouseEvent)?.clientX ?? 0,
        y: (e.domEvent as MouseEvent)?.clientY ?? 0,
      },
    },
  } as any);

export const Marker = forwardRef<MarkerRef, MarkerProps>(
  (
    {
      coordinate,
      title,
      description,
      anchor,
      zIndex,
      rotate,
      scale,
      draggable,
      onPress,
      onDragStart,
      onDragChange,
      onDragEnd,
      callout,
      calloutOptions,
      children,
    },
    ref
  ) => {
    const { moveCamera, onCalloutClose, closeCallouts } = useMapContext();
    const dragPositionRef = useRef<google.maps.LatLngLiteral | null>(null);
    const [markerRef, markerElement] = useAdvancedMarkerRef();
    const [infoWindowOpen, setInfoWindowOpen] = useState(false);
    const calloutBubbled = calloutOptions?.bubbled ?? true;
    const calloutOffset = calloutOptions?.offset;

    const closeCallout = useCallback(() => setInfoWindowOpen(false), []);

    useEffect(
      () => onCalloutClose(closeCallout),
      [onCalloutClose, closeCallout]
    );

    useEffect(() => {
      if (!calloutBubbled) injectUnbubbledStyle();
    }, [calloutBubbled]);

    const hasCallout = !!(callout || title);

    useImperativeHandle(
      ref,
      () => ({
        showCallout() {
          if (hasCallout) {
            closeCallouts(closeCallout);
            setInfoWindowOpen(true);
          }
        },
        hideCallout() {
          setInfoWindowOpen(false);
        },
      }),
      [hasCallout, closeCallouts, closeCallout]
    );

    const calloutContent = callout
      ? isValidElement(callout)
        ? callout
        : React.createElement(callout)
      : title
      ? React.createElement(
          'div',
          { style: { fontSize: 14 } },
          React.createElement('div', { style: { fontWeight: 500 } }, title),
          description ? React.createElement('div', null, description) : null
        )
      : null;

    const transforms: string[] = [];
    if (rotate) transforms.push(`rotate(${rotate}deg)`);
    if (scale && scale !== 1) transforms.push(`scale(${scale})`);

    const handleClick = useCallback(
      (e: google.maps.MapMouseEvent) => {
        const pos = dragPositionRef.current;
        const coord = pos
          ? { latitude: pos.lat, longitude: pos.lng }
          : coordinate;
        moveCamera(coord);
        onPress?.(createEvent(e, coordinate));
        if (hasCallout) {
          closeCallouts(closeCallout);
          setInfoWindowOpen((prev) => !prev);
        }
      },
      [moveCamera, onPress, coordinate, hasCallout, closeCallouts, closeCallout]
    );

    const handleDragStart = useCallback(
      (e: google.maps.MapMouseEvent) => {
        const latLng = e.latLng;
        if (latLng) {
          dragPositionRef.current = { lat: latLng.lat(), lng: latLng.lng() };
        }
        onDragStart?.(createEvent(e, coordinate));
      },
      [onDragStart, coordinate]
    );

    const handleDrag = useCallback(
      (e: google.maps.MapMouseEvent) => {
        const latLng = e.latLng;
        if (latLng) {
          dragPositionRef.current = { lat: latLng.lat(), lng: latLng.lng() };
        }
        onDragChange?.(createEvent(e, coordinate));
      },
      [onDragChange, coordinate]
    );

    const handleDragEnd = useCallback(
      (e: google.maps.MapMouseEvent) => {
        const latLng = e.latLng;
        if (latLng) {
          dragPositionRef.current = { lat: latLng.lat(), lng: latLng.lng() };
        }
        onDragEnd?.(createEvent(e, coordinate));
      },
      [onDragEnd, coordinate]
    );

    useEffect(() => {
      dragPositionRef.current = null;
    }, [coordinate.latitude, coordinate.longitude]);

    const latLngPosition = {
      lat: coordinate.latitude,
      lng: coordinate.longitude,
    };

    const position = dragPositionRef.current ?? latLngPosition;

    return (
      <>
        <AdvancedMarker
          ref={markerRef}
          position={position}
          title={title}
          zIndex={zIndex}
          anchorLeft={anchor ? toWebAnchor(anchor.x) : undefined}
          anchorTop={anchor ? toWebAnchor(anchor.y) : undefined}
          clickable
          draggable={draggable}
          onClick={handleClick}
          onDragStart={handleDragStart}
          onDrag={handleDrag}
          onDragEnd={handleDragEnd}
          style={
            transforms.length > 0
              ? { transform: transforms.join(' ') }
              : undefined
          }
        >
          {children}
        </AdvancedMarker>
        {calloutContent && infoWindowOpen && markerElement && (
          <InfoWindow
            anchor={markerElement}
            pixelOffset={
              !calloutBubbled
                ? [
                    calloutOffset?.x ?? 0,
                    CALLOUT_ARROW_HEIGHT + (calloutOffset?.y ?? 0),
                  ]
                : undefined
            }
            headerDisabled
            onClose={() => setInfoWindowOpen(false)}
          >
            {!calloutBubbled ? (
              <div className={UNBUBBLED_CLASS}>{calloutContent}</div>
            ) : (
              calloutContent
            )}
          </InfoWindow>
        )}
      </>
    );
  }
);
