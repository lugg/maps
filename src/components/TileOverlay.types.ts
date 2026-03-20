export interface TileOverlayBounds {
  northeast: { latitude: number; longitude: number };
  southwest: { latitude: number; longitude: number };
}

export interface TileOverlayProps {
  /**
   * URL template for tile images.
   * Use `{x}`, `{y}`, `{z}` placeholders for tile coordinates and zoom level.
   * @example "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
   */
  urlTemplate: string;
  /**
   * Size of each tile in pixels
   * @default 256
   */
  tileSize?: number;
  /**
   * Opacity of the tile overlay (0-1)
   */
  opacity?: number;
  /**
   * Restrict tiles to a geographic region.
   * Tiles outside these bounds will not be loaded.
   */
  bounds?: TileOverlayBounds;
  /**
   * Z-index for layering
   */
  zIndex?: number;
  /**
   * Called when the tile overlay is tapped
   */
  onPress?: () => void;
}
