'use client';

import { useCopyButton } from 'fumadocs-ui/utils/use-copy-button';
import { Check, Copy } from 'lucide-react';

export function InstallCommand({ command }: { command: string }) {
  const [checked, onClick] = useCopyButton(() =>
    navigator.clipboard.writeText(command)
  );

  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={`Copy "${command}"`}
      className="group inline-flex items-center gap-3 rounded-full border border-fd-border bg-fd-card/70 py-2.5 pl-4 pr-3 font-mono text-sm text-fd-foreground shadow-sm backdrop-blur transition-colors hover:bg-fd-accent"
    >
      <span className="select-none text-fd-muted-foreground">$</span>
      <span>{command}</span>
      <span className="flex size-7 items-center justify-center rounded-full bg-fd-secondary text-fd-muted-foreground transition-colors group-hover:text-fd-foreground">
        {checked ? (
          <Check className="size-3.5 text-fd-primary" />
        ) : (
          <Copy className="size-3.5" />
        )}
      </span>
    </button>
  );
}
