import type { MetadataRoute } from 'next';
import { source } from '@/lib/source';
import { SITE_URL } from '@/lib/metadata';

export default function sitemap(): MetadataRoute.Sitemap {
  const pages = source.getPages().map((page) => ({
    url: new URL(page.url, SITE_URL).toString(),
    changeFrequency: 'weekly' as const,
    priority: page.slugs.length === 0 ? 0.9 : 0.7,
  }));

  return [
    {
      url: SITE_URL,
      changeFrequency: 'weekly',
      priority: 1,
    },
    ...pages,
  ];
}
