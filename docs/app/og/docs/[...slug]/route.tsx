import { ImageResponse } from 'next/og';
import { notFound } from 'next/navigation';
import { OgImage } from '@/components/og-image';
import { source } from '@/lib/source';

export const revalidate = false;

export async function GET(
  _req: Request,
  { params }: RouteContext<'/og/docs/[...slug]'>
) {
  const { slug } = await params;
  const page = source.getPage(slug.slice(0, -1));
  if (!page) notFound();

  const section = page.slugs[0] === 'components' ? 'Components' : 'Docs';

  return new ImageResponse(
    (
      <OgImage
        title={page.data.title}
        description={page.data.description}
        section={section}
      />
    ),
    { width: 1200, height: 630 }
  );
}

export function generateStaticParams() {
  return source.generateParams().map((param) => ({
    slug: [...param.slug, 'image.png'],
  }));
}
