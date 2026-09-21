import { createElement } from 'react';
import { loader, type LoaderPlugin } from 'fumadocs-core/source';
import { defineDocs } from 'fumadocs-mdx/macro';

const docs = defineDocs({
  dir: 'content/docs',
});

// Render component pages in the page tree as `<Name />` code
const componentNamesPlugin: LoaderPlugin = {
  name: 'lugg:component-names',
  transformPageTree: {
    file(node, filePath) {
      if (!filePath?.startsWith('components/')) return node;
      const file = this.storage.read(filePath);
      if (file?.format !== 'page') return node;

      node.name = createElement(
        'code',
        { className: 'font-mono text-[0.8125rem]' },
        `<${file.data.title} />`
      );
      return node;
    },
  },
};

export const source = loader({
  baseUrl: '/',
  source: docs.toFumadocsSource(),
  plugins: [componentNamesPlugin],
});
