import { DocsLayout } from 'fumadocs-ui/layouts/notebook';
import { DocsHeader } from '@/components/docs-header';
import { baseOptions } from '@/lib/layout.shared';
import { source } from '@/lib/source';

export default function Layout({ children }: LayoutProps<'/docs'>) {
  const base = baseOptions();

  return (
    <DocsLayout
      {...base}
      tree={source.getPageTree()}
      nav={{ ...base.nav, mode: 'top' }}
      slots={{ header: DocsHeader }}
    >
      {children}
    </DocsLayout>
  );
}
