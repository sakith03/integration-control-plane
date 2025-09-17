import {
  createPlugin,
  createRoutableExtension,
  createApiFactory,
  configApiRef,
  fetchApiRef,
} from '@backstage/core-plugin-api';

import { rootRouteRef } from './routes';
import {
  environmentsApiRef,
  EnvironmentsApiService,
} from './api/EnvironmentsApiService';
import {
  runtimesApiRef,
  RuntimesApiService,
} from './api/RuntimesApiService';

export const runtimeOverviewPlugin = createPlugin({
  id: 'runtime-overview',
  routes: {
    root: rootRouteRef,
  },
  apis: [
    createApiFactory({
      api: environmentsApiRef,
      deps: {
        configApi: configApiRef,
        fetchApi: fetchApiRef,
      },
      factory: ({ configApi, fetchApi }) =>
        new EnvironmentsApiService(configApi, fetchApi),
    }),
    createApiFactory({
      api: runtimesApiRef,
      deps: {
        configApi: configApiRef,
        fetchApi: fetchApiRef,
      },
      factory: ({ configApi, fetchApi }) =>
        new RuntimesApiService(configApi, fetchApi),
    }),
  ],
});

export const RuntimeOverviewPage = runtimeOverviewPlugin.provide(
  createRoutableExtension({
    name: 'RuntimeOverviewPage',
    component: () =>
      import('./components/RuntimeOverview').then(m => m.RuntimeOverviewComponent),
    mountPoint: rootRouteRef,
  }),
);
