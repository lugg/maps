import { HomeLayout } from 'fumadocs-ui/layouts/home';
import { DefaultNotFound } from 'fumadocs-ui/layouts/home/not-found';
import { HomeHeader } from '@/components/home-header';
import { baseOptions } from '@/lib/layout.shared';

export default function NotFound() {
  return (
    <HomeLayout {...baseOptions()} slots={{ header: HomeHeader }}>
      <DefaultNotFound />
    </HomeLayout>
  );
}
