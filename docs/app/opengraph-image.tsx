import { ImageResponse } from 'next/og';
import { OgImage } from '@/components/og-image';
export const alt = '@lugg/maps · Universal maps for React Native';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function Image() {
  return new ImageResponse(
    (
      <OgImage
        title="Universal maps for React Native"
        description="Native Apple Maps and Google Maps on iOS, Android, and Web. Built for the New Architecture."
      />
    ),
    size
  );
}
