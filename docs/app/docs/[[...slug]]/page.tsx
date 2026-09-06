import { source } from '@/lib/source';
import {
  DocsBody,
  DocsDescription,
  DocsPage,
  DocsTitle,
} from 'fumadocs-ui/layouts/docs/page';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/components/mdx';
import type { Metadata } from 'next';
import { createRelativeLink } from 'fumadocs-ui/mdx';
import { createMetadata, SITE_NAME, SITE_URL } from '@/lib/metadata';

function ogImagePath(slugs: string[]) {
  return `/og/docs/${[...slugs, 'image.png'].join('/')}`;
}

export default async function Page(props: PageProps<'/docs/[[...slug]]'>) {
  const params = await props.params;
  const page = source.getPage(params.slug);
  if (!page) notFound();

  const MDX = page.data.body;
  const url = new URL(page.url, SITE_URL).toString();

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'TechArticle',
    'headline': page.data.title,
    'description': page.data.description,
    url,
    'image': new URL(ogImagePath(page.slugs), SITE_URL).toString(),
    'isPartOf': { '@type': 'WebSite', 'name': SITE_NAME, 'url': SITE_URL },
    'author': { '@type': 'Organization', 'name': 'Lugg' },
  };

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDX
          components={getMDXComponents({
            a: createRelativeLink(source, page),
          })}
        />
      </DocsBody>
    </DocsPage>
  );
}

export async function generateStaticParams() {
  return source.generateParams();
}

export async function generateMetadata(
  props: PageProps<'/docs/[[...slug]]'>
): Promise<Metadata> {
  const params = await props.params;
  const page = source.getPage(params.slug);
  if (!page) notFound();

  return createMetadata({
    title: page.data.title,
    description: page.data.description ?? '',
    path: page.url,
    image: ogImagePath(page.slugs),
  });
}
