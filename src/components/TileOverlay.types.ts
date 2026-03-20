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
   * Z-index for layering
   */
  zIndex?: number;
  /**
   * Called when the tile overlay is tapped
   */
  onPress?: () => void;
}
