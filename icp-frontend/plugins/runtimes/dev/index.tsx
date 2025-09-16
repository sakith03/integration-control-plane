import { createDevApp } from '@backstage/dev-utils';
import { runtimesPlugin, RuntimesPage } from '../src/plugin';

createDevApp()
  .registerPlugin(runtimesPlugin)
  .addPage({
    element: <RuntimesPage />,
    title: 'Root Page',
    path: '/runtimes',
  })
  .render();
