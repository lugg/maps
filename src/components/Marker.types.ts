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
   * @platform ios, android
   * @default true
   */
  rasterize?: boolean;
  /**
   * Whether the marker can be dragged by the user.
   * @default false
   */
  draggable?: boolean;
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
