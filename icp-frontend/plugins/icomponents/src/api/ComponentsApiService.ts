import {
    createApiRef,
    ConfigApi,
    FetchApi
} from '@backstage/core-plugin-api';

export interface Project {
    projectId: string;
    name: string;
    description: string;
    createdBy: string;
    createdAt: string;
    updatedAt: string;
    updatedBy: string;
}

export interface Component {
    componentId: string;
    name: string;
    description: string;
    createdBy: string;
    createdAt: string;
    updatedAt: string;
    updatedBy: string;
    project: {
        projectId: string;
        name: string;
        description: string;
        createdBy: string;
        createdAt: string;
        updatedAt: string;
        updatedBy: string;
    };
}

export interface CreateComponentRequest {
    projectId: string;
    name: string;
    description: string;
}

export interface UpdateComponentRequest {
    componentId: string;
    name: string;
    description: string;
}

export interface ComponentsApi {
    getProjects(): Promise<Project[]>;
    getComponents(projectId: string): Promise<Component[]>;
    createComponent(request: CreateComponentRequest): Promise<Component>;
    updateComponent(request: UpdateComponentRequest): Promise<Component>;
    deleteComponent(componentId: string): Promise<void>;
}

export const componentsApiRef = createApiRef<ComponentsApi>({
    id: 'plugin.icomponents.service',
});

export class ComponentsApiService implements ComponentsApi {
    constructor(
        private readonly configApi: ConfigApi,
        private readonly fetchApi: FetchApi,
    ) { }


    private async request<T>(query: string, variables?: Record<string, any>): Promise<T> {
        let proxyUrl = '';
        let response: Response;
        let lastError: Error;

        try {
            const baseUrl = 'http://localhost:9446'
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
            throw new Error(`Proxy connection failed: ${lastError.message} (URL: ${proxyUrl || 'unknown'})`);
        }
    }

    async getProjects(): Promise<Project[]> {
        const query = `
            query GetProjects {
                projects {
                    projectId
                    name
                    description
                    createdBy
                    createdAt
                    updatedAt
                    updatedBy
                }
            }
        `;

        const data = await this.request<{ projects: Project[] }>(query);
        return data.projects || [];
    }

    async getComponents(projectId: string): Promise<Component[]> {
        const query = `
            query GetComponents($projectId: String!) {
                components(projectId: $projectId) {
                    componentId
                    name
                    description
                    createdBy
                    createdAt
                    updatedAt
                    updatedBy
                    project {
                        projectId
                        name
                        description
                        createdBy
                        createdAt
                        updatedAt
                        updatedBy
                    }
                }
            }
        `;

        const data = await this.request<{ components: Component[] }>(
            query,
            { projectId }
        );
        return data.components || [];
    }

    async createComponent(request: CreateComponentRequest): Promise<Component> {
        const query = `
            mutation CreateComponent($projectId: String!, $name: String!, $description: String!) {
                createComponent(component: { projectId: $projectId, name: $name, description: $description }) {
                    componentId
                    name
                    description
                    createdBy
                    createdAt
                    updatedAt
                    updatedBy
                    project {
                        projectId
                        name
                        description
                        createdBy
                        createdAt
                        updatedAt
                        updatedBy
                    }
                }
            }
        `;

        const data = await this.request<{ createComponent: Component }>(
            query,
            {
                projectId: request.projectId,
                name: request.name,
                description: request.description
            }
        );
        return data.createComponent;
    }

    async updateComponent(request: UpdateComponentRequest): Promise<Component> {
        const query = `
            mutation UpdateComponent($componentId: String!, $name: String!, $description: String!) {
                updateComponent(componentId: $componentId, name: $name, description: $description) {
                    componentId
                    name
                    description
                    createdBy
                    createdAt
                    updatedAt
                    updatedBy
                    project {
                        projectId
                        name
                        description
                        createdBy
                        createdAt
                        updatedAt
                        updatedBy
                    }
                }
            }
        `;

        const data = await this.request<{ updateComponent: Component }>(
            query,
            request
        );
        return data.updateComponent;
    }

    async deleteComponent(componentId: string): Promise<void> {
        const query = `
            mutation DeleteComponent($componentId: String!) {
                deleteComponent(componentId: $componentId)
            }
        `;

        await this.request<{ deleteComponent: boolean }>(
            query,
            { componentId }
        );
    }
}