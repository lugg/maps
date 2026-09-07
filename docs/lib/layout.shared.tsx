import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { Logo } from '@/components/logo';

export const GITHUB_URL = 'https://github.com/lugg/maps';
export const DOCS_URL = '/intro';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: (
        <>
          <Logo className="size-6" />
          <span className="font-semibold tracking-tight">@lugg/maps</span>
        </>
      ),
    },
    githubUrl: GITHUB_URL,
    links: [
      { text: 'Docs', url: DOCS_URL, active: 'none' },
      {
        text: 'Example',
        url: `${GITHUB_URL}/tree/main/example`,
        external: true,
      },
    ],
  };
}
