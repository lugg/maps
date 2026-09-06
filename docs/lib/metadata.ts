import type { Metadata } from 'next';

export const SITE_URL = 'https://maps.lodev09.com';
export const SITE_NAME = '@lugg/maps';
export const SITE_DESCRIPTION =
  'Universal maps for React Native. Native Apple Maps and Google Maps on iOS, Android, and Web, built for the New Architecture.';

interface CreateMetadataOptions {
  title: string;
  description: string;
  path: string;
  image?: string;
}

export function createMetadata({
  title,
  description,
  path,
  image,
}: CreateMetadataOptions): Metadata {
  const url = new URL(path, SITE_URL).toString();

  return {
    title,
    description,
    alternates: { canonical: url },
    openGraph: {
      title,
      description,
      url,
      siteName: SITE_NAME,
      type: 'website',
      locale: 'en_US',
      ...(image && {
        images: [{ url: image, width: 1200, height: 630, alt: title }],
      }),
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      ...(image && { images: [image] }),
    },
  };
}
