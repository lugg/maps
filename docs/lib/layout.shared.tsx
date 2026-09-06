import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { Logo } from '@/components/logo';

export const GITHUB_URL = 'https://github.com/lugg/maps';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: (
        <span className="inline-flex items-center gap-2 font-semibold">
          <Logo className="size-5" />
          @lugg/maps
        </span>
      ),
      transparentMode: 'top',
    },
    githubUrl: GITHUB_URL,
    links: [
      {
        text: 'Docs',
        url: '/docs',
        active: 'nested-url',
      },
    ],
  };
}
