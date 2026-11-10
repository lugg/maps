import type { ComponentType, ReactElement, ReactNode } from 'react';
import type { NativeSyntheticEvent } from 'react-native';
import type { Coordinate, Point, PressEventPayload } from '../types';

export type MarkerPressEvent = NativeSyntheticEvent<PressEventPayload>;
export type MarkerDragEvent = NativeSyntheticEvent<PressEventPayload>;

export interface CalloutOptions {
  /**
   * Whether to wrap the callout in the native platform bubble.
   * Set to `false` to render custom content directly without the native callout chrome.
   *
   * @default true
   */
  bubbled?: boolean;
  /**
   * Pixel offset for non-bubbled callouts from their default centered position above the marker.
   * Positive `x` moves right, positive `y` moves down.
   * Only applies when `bubbled` is `false`.
   *
   * @default {x: 0, y: 0}
   */
  offset?: Point;
}

interface MarkerPathBase {
  /**
   * Keyframe positions. The marker moves in a straight line between consecutive keyframes.
   */
  coordinates: Coordinate[];
  /**
   * Rotation for each keyframe, in degrees clockwise from north. Each segment turns the short
   * way. Overrides `rotateAlongPath`. Without either, the marker keeps `rotate`.
   */
  rotations?: number[];
  /**
   * Wall-clock time in milliseconds, as from `Date.now()`, at which the marker is at the first
   * keyframe. Set it to keep markers or devices in sync.
   * @default when the path is set
   */
  startTime?: number;
  /**
   * Repeat the path. Without it, the marker waits at the first keyframe until `startTime` and
   * stays at the last one after the path ends.
   * @default false
   */
  loop?: boolean;
}

/**
 * A route that a marker follows natively, with no React renders or prop updates per frame.
 * Time it with `duration`, or with `times` for exact timing.
 */
export type MarkerPath = MarkerPathBase &
  (
    | {
        /**
         * Milliseconds to travel the whole path, at a constant speed.
         */
        duration: number;
        times?: never;
      }
    | {
        /**
         * Milliseconds from the start of the path for each keyframe, in increasing order.
         * Same length as `coordinates`.
         */
        times: number[];
        duration?: never;
      }
  );

export interface MarkerPathProgressEvent {
  nativeEvent: {
    /**
     * Index in `coordinates` of the last keyframe the marker passed, within the current lap.
     */
    index: number;
  };
}

export interface MarkerRef {
  showCallout(): void;
  hideCallout(): void;
}

export interface MarkerProps {
  /**
   * Name used for debugging purposes
   */
  name?: string;
  /**
   * Marker position
   */
  coordinate: Coordinate;
  /**
   * Callout title
   */
  title?: string;
  /**
   * Callout description
   */
  description?: string;
  /**
   * Anchor point for custom marker views.
   * `{x: 0.5, y: 1}` places the bottom-center of the marker at the coordinate.
   *
   * @default {x: 0.5, y: 1}
   */
  anchor?: Point;
  /**
   * Z-index for marker ordering. Higher values render on top.
   */
  zIndex?: number;
  /**
   * Rotation angle in degrees clockwise from north.
   * @default 0
   */
  rotate?: number;
  /**
   * Scale factor for the marker.
   * @default 1
   */
  scale?: number;
  /**
   * Rasterize custom marker view to bitmap for better performance.
   * Set to false if you need live view updates (e.g., animations).
   * On web, false positions the custom view between pixels instead of
   * rounding to whole pixels, for markers that move every frame. Markers with
   * `title`, `callout` or `draggable` keep whole-pixel positioning.
   * @default true
   */
  rasterize?: boolean;
  /**
   * Whether the map centers on the marker when pressed.
   * @default true
   */
  centerOnPress?: boolean;
  /**
   * Whether the marker can be dragged by the user.
   * @default false
   */
  draggable?: boolean;
  /**
   * Moves the marker along a route natively, so a moving marker costs no React work per frame.
   * While set, `coordinate` is ignored, and so is `rotate` when the path rotates the marker.
   * Restarts when a field changes. Arrays compare by reference, so keep them stable across renders.
   */
  path?: MarkerPath;
  /**
   * Turns the marker to face its direction of travel, along a `path` or a `transitionDuration`
   * move. Turns take the short way and settle quickly at each keyframe. `transitionDuration` moves
   * shorter than 5 m keep the heading.
   * @default false
   */
  rotateAlongPath?: boolean;
  /**
   * Milliseconds over which the marker glides to a new `coordinate` and turns to a new `rotate`,
   * natively, from where it is. One update per GPS fix gives continuous motion. Applies to
   * `coordinate` changes from renders, not from Reanimated `animatedProps`. `0` jumps. Ignored
   * while `path` is set.
   * @default 0
   */
  transitionDuration?: number;
  /**
   * Called when the marker passes a keyframe of its `path`, and once when the path starts.
   */
  onPathProgress?: (event: MarkerPathProgressEvent) => void;
  /**
   * Called when the marker is pressed
   */
  onPress?: (event: MarkerPressEvent) => void;
  /**
   * Called when marker drag starts
   */
  onDragStart?: (event: MarkerDragEvent) => void;
  /**
   * Called continuously as the marker is dragged
   */
  onDragChange?: (event: MarkerDragEvent) => void;
  /**
   * Called when marker drag ends
   */
  onDragEnd?: (event: MarkerDragEvent) => void;
  /**
   * Callout content displayed when marker is tapped.
   * Pass a `ReactElement` for inline content or a `ComponentType` to be instantiated.
   */
  callout?: ComponentType<unknown> | ReactElement;
  /**
   * Callout configuration options.
   */
  calloutOptions?: CalloutOptions;
  /**
   * Custom marker view
   */
  children?: ReactNode;
}
