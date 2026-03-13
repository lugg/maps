import type { ReactNode } from 'react';

export interface CalloutProps {
  /**
   * Called when the callout is pressed
   */
  onPress?: () => void;
  /**
   * Custom callout content. If not provided, the native callout is used.
   */
  children?: ReactNode;
}
