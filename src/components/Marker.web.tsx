import React, {
  forwardRef,
  isValidElement,
  memo,
  useCallback,
  useEffect,
  useImperativeHandle,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { createPortal } from 'react-dom';
import {
  AdvancedMarker,
  InfoWindow,
  useAdvancedMarkerRef,
} from '@vis.gl/react-google-maps';
import { useMapContext } from '../MapProvider.web';
import type { Point } from '../types';
import type { MarkerProps, MarkerRef } from './Marker.types';

const CALLOUT_ARROW_HEIGHT = 12;
const UNBUBBLED_CLASS = 'rnm-callout-unbubbled';
const UNBUBBLED_STYLE_ID = 'rnm-callout-unbubbled-style';
const DEFAULT_ANCHOR: Point = { x: 0.5, y: 1 };

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

const toTransform = (rotate?: number, scale?: number) => {
  const transforms: string[] = [];
  if (rotate) transforms.push(`rotate(${rotate}deg)`);
  if (scale && scale !== 1) transforms.push(`scale(${scale})`);
  return transforms.join(' ');
};

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

/**
 * The props Reanimated's `useAnimatedProps` can drive. On web, Reanimated
 * applies them through `setNativeProps`, so they update without a React render.
 */
type AnimatableProps = Partial<
  Pick<MarkerProps, 'coordinate' | 'rotate' | 'scale' | 'zIndex'>
>;

interface WebMarkerRef extends MarkerRef {
  setNativeProps(props: AnimatableProps): void;
}

const DefaultMarker = forwardRef<MarkerRef, MarkerProps>(
  (
    {
      coordinate,
      title,
      description,
      anchor,
      zIndex,
      rotate,
      scale,
      centerOnPress = true,
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
    const markerElementRef = useRef(markerElement);
    // The latest values, including those `setNativeProps` set between renders.
    const latest = useRef({ coordinate, rotate, scale });
    const [infoWindowOpen, setInfoWindowOpen] = useState(false);
    const calloutBubbled = calloutOptions?.bubbled ?? true;
    const calloutOffset = calloutOptions?.offset;

    useEffect(() => {
      markerElementRef.current = markerElement;
    }, [markerElement]);

    // Props apply when their values change. Reanimated passes its first values
    // again on every render, so a re-render must not pull a moving marker back.
    const { latitude, longitude } = coordinate;
    useEffect(() => {
      latest.current.coordinate = { latitude, longitude };
    }, [latitude, longitude]);
    useEffect(() => {
      latest.current.rotate = rotate;
    }, [rotate]);
    useEffect(() => {
      latest.current.scale = scale;
    }, [scale]);

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
      (): WebMarkerRef => ({
        showCallout() {
          if (hasCallout) {
            closeCallouts(closeCallout);
            setInfoWindowOpen(true);
          }
        },
        hideCallout() {
          setInfoWindowOpen(false);
        },
        setNativeProps(props) {
          const current = latest.current;
          if (props.coordinate) current.coordinate = props.coordinate;
          if (props.rotate !== undefined) current.rotate = props.rotate;
          if (props.scale !== undefined) current.scale = props.scale;

          const marker = markerElementRef.current;
          if (!marker) return;
          if (props.coordinate && !dragPositionRef.current) {
            marker.position = {
              lat: props.coordinate.latitude,
              lng: props.coordinate.longitude,
            };
          }
          if (props.zIndex !== undefined) marker.zIndex = props.zIndex;
          if (props.rotate !== undefined || props.scale !== undefined) {
            // vis.gl wraps the children in a div that carries the `style` prop.
            const content = (marker.content as HTMLElement | null)
              ?.firstElementChild;
            if (content instanceof HTMLElement) {
              content.style.transform = toTransform(
                current.rotate,
                current.scale
              );
            }
          }
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

    const transform = toTransform(rotate, scale);

    const handleClick = useCallback(
      (e: google.maps.MapMouseEvent) => {
        const pos = dragPositionRef.current;
        const coord = pos
          ? { latitude: pos.lat, longitude: pos.lng }
          : latest.current.coordinate;
        if (centerOnPress) moveCamera(coord);
        onPress?.(createEvent(e, coord));
        if (hasCallout) {
          closeCallouts(closeCallout);
          setInfoWindowOpen((prev) => !prev);
        }
      },
      [
        centerOnPress,
        moveCamera,
        onPress,
        hasCallout,
        closeCallouts,
        closeCallout,
      ]
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

    // Keyed by value, so vis.gl only moves the marker when the numbers change.
    const latLngPosition = useMemo(
      () => ({ lat: coordinate.latitude, lng: coordinate.longitude }),
      [coordinate.latitude, coordinate.longitude]
    );

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
          onDragStart={draggable ? handleDragStart : undefined}
          onDrag={draggable ? handleDrag : undefined}
          onDragEnd={draggable ? handleDragEnd : undefined}
          style={transform ? { transform } : undefined}
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

function createLiveElement() {
  const element = document.createElement('div');
  element.style.position = 'absolute';
  element.style.left = '0';
  element.style.top = '0';
  element.style.pointerEvents = 'none';
  element.style.willChange = 'transform';
  return element;
}

/**
 * `rasterize={false}`: the children live in an `OverlayView` element moved
 * with a fractional transform. `AdvancedMarker` rounds its position to whole
 * pixels, so a marker moved every frame steps instead of gliding.
 * Callouts and dragging need the default marker.
 */
const LiveMarker = forwardRef<MarkerRef, MarkerProps>(
  (
    {
      coordinate,
      anchor,
      zIndex,
      rotate,
      scale,
      centerOnPress = true,
      onPress,
      children,
    },
    ref
  ) => {
    const { map, moveCamera } = useMapContext();
    const [element] = useState(createLiveElement);
    const overlayRef = useRef<google.maps.OverlayView | null>(null);
    const onPressRef = useRef(onPress);
    // The latest values, including those `setNativeProps` set between renders.
    const latest = useRef({
      coordinate,
      rotate: rotate ?? 0,
      scale: scale ?? 1,
      anchor: anchor ?? DEFAULT_ANCHOR,
    });
    const pressable = !!onPress;

    const place = useCallback(() => {
      const projection = overlayRef.current?.getProjection();
      if (!projection) return;
      const { coordinate: at, rotate: r, scale: s, anchor: a } = latest.current;
      const point = projection.fromLatLngToDivPixel(
        new google.maps.LatLng(at.latitude, at.longitude)
      );
      if (!point) return;
      element.style.transformOrigin = `${a.x * 100}% ${a.y * 100}%`;
      element.style.transform =
        `translate(${point.x}px, ${point.y}px) ` +
        `translate(${-a.x * 100}%, ${-a.y * 100}%) rotate(${r}deg) scale(${s})`;
    }, [element]);

    useEffect(() => {
      if (!map) return;
      const overlay = new google.maps.OverlayView();
      overlay.onAdd = () => {
        const panes = overlay.getPanes();
        const pane = pressable
          ? panes?.overlayMouseTarget
          : panes?.overlayLayer;
        pane?.appendChild(element);
      };
      // The map calls draw whenever the camera moves.
      overlay.draw = place;
      overlay.onRemove = () => element.remove();
      overlay.setMap(map);
      overlayRef.current = overlay;
      return () => {
        overlay.setMap(null);
        overlayRef.current = null;
      };
    }, [map, element, place, pressable]);

    useEffect(() => {
      onPressRef.current = onPress;
    }, [onPress]);

    useEffect(() => {
      if (!map || !pressable) return;
      element.style.pointerEvents = 'auto';
      element.style.cursor = 'pointer';
      google.maps.OverlayView.preventMapHitsAndGesturesFrom(element);
      const handleClick = (event: MouseEvent) => {
        const at = latest.current.coordinate;
        if (centerOnPress) moveCamera(at);
        onPressRef.current?.({
          nativeEvent: {
            coordinate: { latitude: at.latitude, longitude: at.longitude },
            point: { x: event.clientX, y: event.clientY },
          },
        } as any);
      };
      element.addEventListener('click', handleClick);
      return () => {
        element.removeEventListener('click', handleClick);
        element.style.pointerEvents = 'none';
        element.style.cursor = '';
      };
    }, [map, element, pressable, centerOnPress, moveCamera]);

    // Props apply when their values change. Reanimated passes its first values
    // again on every render, so a re-render must not pull a moving marker back.
    const { latitude, longitude } = coordinate;
    useLayoutEffect(() => {
      latest.current.coordinate = { latitude, longitude };
      place();
    }, [latitude, longitude, place]);
    useLayoutEffect(() => {
      latest.current.rotate = rotate ?? 0;
      place();
    }, [rotate, place]);
    useLayoutEffect(() => {
      latest.current.scale = scale ?? 1;
      place();
    }, [scale, place]);
    const anchorX = anchor?.x ?? DEFAULT_ANCHOR.x;
    const anchorY = anchor?.y ?? DEFAULT_ANCHOR.y;
    useLayoutEffect(() => {
      latest.current.anchor = { x: anchorX, y: anchorY };
      place();
    }, [anchorX, anchorY, place]);
    useLayoutEffect(() => {
      element.style.zIndex = zIndex === undefined ? '' : String(zIndex);
    }, [element, zIndex]);

    useImperativeHandle(
      ref,
      (): WebMarkerRef => ({
        // Live markers have no callouts.
        showCallout() {},
        hideCallout() {},
        setNativeProps(props) {
          const current = latest.current;
          if (props.coordinate) current.coordinate = props.coordinate;
          if (props.rotate !== undefined) current.rotate = props.rotate;
          if (props.scale !== undefined) current.scale = props.scale;
          if (props.zIndex !== undefined) {
            element.style.zIndex = String(props.zIndex);
          }
          if (
            props.coordinate ||
            props.rotate !== undefined ||
            props.scale !== undefined
          ) {
            place();
          }
        },
      }),
      [element, place]
    );

    return createPortal(children, element);
  }
);

export const Marker = memo(
  forwardRef<MarkerRef, MarkerProps>((props, ref) =>
    props.rasterize === false ? (
      <LiveMarker {...props} ref={ref} />
    ) : (
      <DefaultMarker {...props} ref={ref} />
    )
  )
);
