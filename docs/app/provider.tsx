'use client';

import { fetchRepositoryInfo } from 'fumadocs-ui/components/github-info';
import { RootProvider } from 'fumadocs-ui/provider/next';
import { createContext, useEffect, useState, type ReactNode } from 'react';
import { GITHUB_URL } from '@/lib/layout.shared';

export const GitHubStarsContext = createContext<number | undefined>(undefined);

export function Provider({ children }: { children: ReactNode }) {
  const [stars, setStars] = useState<number>();

  useEffect(() => {
    const [owner, repo] = new URL(GITHUB_URL).pathname.slice(1).split('/');
    fetchRepositoryInfo({ owner, repo })
      .then((info) => setStars(info.stars))
      .catch((error) => console.error('Failed to load GitHub stars:', error));
  }, []);

  return (
    <RootProvider>
      <GitHubStarsContext value={stars}>{children}</GitHubStarsContext>
    </RootProvider>
  );
}
