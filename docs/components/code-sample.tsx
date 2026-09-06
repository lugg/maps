import { highlight } from 'fumadocs-core/highlight';
import { CodeBlock, Pre } from 'fumadocs-ui/components/codeblock';
import type { ReactNode } from 'react';

interface CodeSampleProps {
  code: string;
  lang?: string;
  title?: ReactNode;
}

export async function CodeSample({
  code,
  lang = 'tsx',
  title,
}: CodeSampleProps) {
  return highlight(code, {
    lang,
    themes: { light: 'github-light', dark: 'github-dark' },
    defaultColor: false,
    components: {
      pre: (props) => (
        <CodeBlock {...props} title={title} className="my-0">
          <Pre>{props.children}</Pre>
        </CodeBlock>
      ),
    },
  });
}
