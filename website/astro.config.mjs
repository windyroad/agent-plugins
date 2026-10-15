import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://windyroad.github.io',
  base: '/agent-plugins',
  output: 'static',
  // Bundle Astro's cookie version instead of resolving the older root test dependency.
  vite: { environments: { prerender: { resolve: { noExternal: ['cookie'] } } } },
  integrations: [starlight({
    title: 'Windy Road Agent Plugins',
    description: 'Choose, install and use the guardrails relevant to your coding project.',
    expressiveCode: { defaultProps: { wrap: true } },
    components: { Search: './src/components/Search.astro' },
    social: [{ icon: 'github', label: 'Windy Road Agent Plugins on GitHub', href: 'https://github.com/windyroad/agent-plugins' }],
    customCss: ['./src/styles/docs.css'],
    sidebar: [
      { label: 'Start here', items: ['index', 'getting-started', 'runtimes', 'updating', 'outcome-led-planning'] },
      { label: 'Plugins', items: [{ autogenerate: { directory: 'plugins' } }] },
      { label: 'Skills', collapsed: true, items: [{ autogenerate: { directory: 'skills' } }] },
    ],
  })],
});
