import {
    createApiRef,
    ConfigApi,
    FetchApi
} from '@backstage/core-plugin-api';

export interface Environment {
    environmentId: string;
    name: string;
    description: string;
    createdAt: string;
    updatedAt: string;
    updatedBy: string;
    createdBy: string;
}

export interface CreateEnvironmentRequest {
    name: string;
    description: string;
}

export interface UpdateEnvironmentRequest {
    environmentId: string;
    name: string;
    description: string;
}

export interface EnvironmentsApi {
    getEnvironments(): Promise<Environment[]>;
    createEnvironment(request: CreateEnvironmentRequest): Promise<Environment>;
    updateEnvironment(request: UpdateEnvironmentRequest): Promise<Environment>;
    deleteEnvironment(environmentId: string): Promise<void>;
}

export const environmentsApiRef = createApiRef<EnvironmentsApi>({
    id: 'plugin.environments.service',
});

export class EnvironmentsApiService implements EnvironmentsApi {
    constructor(
        private readonly configApi: ConfigApi,
        private readonly fetchApi: FetchApi,
    ) { }

    private async getBaseUrl(): Promise<string> {
        // For development, try different URL strategies
        const backendUrl = this.configApi.getString('backend.baseUrl');

        // Try proxy first, but allow fallback for development
        if (process.env.NODE_ENV === 'development') {
            // In development, we can try direct connection if proxy fails
            return `${backendUrl}/api/proxy/icp-api`;
        } else {
            // In production, always use proxy
            return `${backendUrl}/api/proxy/icp-api`;
        }
    }

    private getDirectUrl(): string {
        // Fallback to direct URL for development
        try {
            const icpBackendUrl = this.configApi.getOptionalString('icp.backend.baseUrl') || 'http://localhost:9446';
            const graphqlEndpoint = this.configApi.getOptionalString('icp.backend.graphqlEndpoint') || '/graphql';
            return `${icpBackendUrl}${graphqlEndpoint}`;
        } catch (error) {
            // If config is not visible, use default values
            console.warn('Using default ICP backend URL due to config visibility issue:', error);
            return 'http://localhost:9446/graphql';
        }
    }

    private async request<T>(query: string, variables?: Record<string, any>): Promise<T> {
        let proxyUrl = '';
        let response: Response;
        let lastError: Error;

        try {
            // Try proxy endpoint first
            const baseUrl = await this.getBaseUrl();
            proxyUrl = `${baseUrl}/graphql`;

            response = await this.fetchApi.fetch(proxyUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    query,
                    variables,
                }),
            });

            if (response.ok) {
                const json = await response.json();
                if (json.errors) {
                    throw new Error(`GraphQL Error: ${json.errors[0].message}`);
                }
                return json.data;
            } else {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
        } catch (proxyError) {
            lastError = proxyError as Error;
            console.warn('Proxy endpoint failed, trying direct connection:', proxyError);

            // If proxy fails in development, try direct connection
            if (process.env.NODE_ENV === 'development') {
                try {
                    const directUrl = this.getDirectUrl();

                    response = await fetch(directUrl, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                            query,
                            variables,
                        }),
                    });

                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText} (Direct URL: ${directUrl})`);
                    }

                    const json = await response.json();

                    if (json.errors) {
                        throw new Error(`GraphQL Error: ${json.errors[0].message}`);
                    }

                    return json.data;
                } catch (directError) {
                    console.error('Direct connection also failed:', directError);
                    throw new Error(`Both proxy and direct connection failed. Proxy error: ${lastError.message}. Direct error: ${(directError as Error).message}`);
                }
            } else {
                throw new Error(`Proxy connection failed: ${lastError.message} (URL: ${proxyUrl || 'unknown'})`);
            }
        }
    }

    async getEnvironments(): Promise<Environment[]> {
        const query = `
      query GetEnvironments {
        environments {
          environmentId
          name
          description
          createdAt
          updatedAt
          updatedBy
          createdBy
        }
      }
    `;

        const data = await this.request<{ environments: Environment[] }>(query);
        return data.environments || [];
    }

    async createEnvironment(request: CreateEnvironmentRequest): Promise<Environment> {
        const query = `
      mutation CreateEnvironment($environment: CreateEnvironmentInput!) {
        createEnvironment(environment: $environment) {
          environmentId
          name
          description
          createdAt
          updatedAt
          updatedBy
          createdBy
        }
      }
    `;

        const data = await this.request<{ createEnvironment: Environment }>(
            query,
            { environment: request }
        );
        return data.createEnvironment;
    }

    async updateEnvironment(request: UpdateEnvironmentRequest): Promise<Environment> {
        const query = `
      mutation UpdateEnvironment($environmentId: ID!, $name: String!, $description: String!) {
        updateEnvironment(environmentId: $environmentId, name: $name, description: $description) {
          environmentId
          name
          description
          createdAt
          updatedAt
          updatedBy
          createdBy
        }
      }
    `;

        const data = await this.request<{ updateEnvironment: Environment }>(
            query,
            request
        );
        return data.updateEnvironment;
    }

    async deleteEnvironment(environmentId: string): Promise<void> {
        const query = `
      mutation DeleteEnvironment($environmentId: ID!) {
        deleteEnvironment(environmentId: $environmentId)
      }
    `;

        await this.request<{ deleteEnvironment: boolean }>(
            query,
            { environmentId }
        );
    }
}