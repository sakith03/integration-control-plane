import { useState, useCallback, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import {
  Table,
  TableColumn,
  Progress,
  ResponseErrorPanel,
} from '@backstage/core-components';
import {
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,

} from '@material-ui/core';
import { useApi } from '@backstage/core-plugin-api';
import useAsync from 'react-use/lib/useAsync';
import RefreshIcon from '@material-ui/icons/Refresh';
import {
  runtimesApiRef,
  Runtime
} from '../../api';

export const RuntimesFetchComponent = () => {
  const runtimesApi = useApi(runtimesApiRef);
  const location = useLocation();

  // For now, we'll create interfaces for Project, Component, and Environment here
  // until we properly export them from their respective plugins
  interface Project {
    projectId: string;
    name: string;
    description: string;
    createdBy: string;
    createdAt: string;
    updatedAt: string;
    updatedBy: string;
  }

  interface Component {
    componentId: string;
    name: string;
    description: string;
    createdBy: string;
    createdAt: string;
    updatedAt: string;
    updatedBy: string;
    project: Project;
  }

  interface Environment {
    environmentId: string;
    name: string;
    description: string;
    createdAt: string;
    updatedAt: string;
    updatedBy: string;
    createdBy: string;
  }

  // Extract URL parameters for initial filter state
  const urlParams = new URLSearchParams(location.search);
  const initialProjectId = urlParams.get('projectId') || undefined;
  const initialComponentId = urlParams.get('componentId') || undefined;

  // Filter state - initialize with URL parameters if available
  const [filters, setFilters] = useState<{
    status?: string;
    runtimeType?: string;
    environment?: string;
    projectId?: string;
    componentId?: string;
  }>({
    projectId: initialProjectId,
    componentId: initialComponentId,
  });
  const [refreshIndex, setRefreshIndex] = useState(0);

  // State for dropdown data
  const [projects, setProjects] = useState<Project[]>([]);
  const [components, setComponents] = useState<Component[]>([]);
  const [environments, setEnvironments] = useState<Environment[]>([]);
  const [loadingProjects, setLoadingProjects] = useState(false);
  const [loadingComponents, setLoadingComponents] = useState(false);
  const [loadingEnvironments, setLoadingEnvironments] = useState(false);

  // Fetch projects when component mounts
  useEffect(() => {
    const fetchProjects = async () => {
      setLoadingProjects(true);
      try {
        const projectsData = await runtimesApi.getProjects();
        setProjects(projectsData);
      } catch (error) {
        console.error('Failed to fetch projects:', error);
      } finally {
        setLoadingProjects(false);
      }
    };

    fetchProjects();
  }, [runtimesApi]);

  // Fetch environments when component mounts
  useEffect(() => {
    const fetchEnvironments = async () => {
      setLoadingEnvironments(true);
      try {
        const environmentsData = await runtimesApi.getEnvironments();
        setEnvironments(environmentsData);
      } catch (error) {
        console.error('Failed to fetch environments:', error);
      } finally {
        setLoadingEnvironments(false);
      }
    };

    fetchEnvironments();
  }, [runtimesApi]);

  // Fetch components when project changes
  useEffect(() => {
    if (filters.projectId) {
      const fetchComponents = async () => {
        setLoadingComponents(true);
        try {
          const componentsData = await runtimesApi.getComponents(filters.projectId!);
          setComponents(componentsData);
        } catch (error) {
          console.error('Failed to fetch components:', error);
        } finally {
          setLoadingComponents(false);
        }
      };

      fetchComponents();
    } else {
      setComponents([]);
      setFilters(prev => ({ ...prev, componentId: undefined }));
    }
  }, [filters.projectId, runtimesApi]);

  // Fetch runtimes
  const { value: runtimes, loading, error } = useAsync(async (): Promise<Runtime[]> => {
    try {
      return await runtimesApi.getRuntimes(filters);
    } catch (err) {
      throw new Error(err instanceof Error ? err.message : 'Failed to fetch runtimes');
    }
  }, [filters, refreshIndex]);

  // Filter handlers
  const handleStatusChange = useCallback((event: React.ChangeEvent<{ value: unknown }>) => {
    setFilters(prev => ({ ...prev, status: event.target.value as string || undefined }));
  }, []);

  const handleRuntimeTypeChange = useCallback((event: React.ChangeEvent<{ value: unknown }>) => {
    setFilters(prev => ({ ...prev, runtimeType: event.target.value as string || undefined }));
  }, []);

  const handleProjectChange = useCallback((event: React.ChangeEvent<{ value: unknown }>) => {
    const projectId = event.target.value as string || undefined;
    setFilters(prev => ({
      ...prev,
      projectId,
      componentId: undefined // Reset component when project changes
    }));
  }, []);

  const handleComponentChange = useCallback((event: React.ChangeEvent<{ value: unknown }>) => {
    setFilters(prev => ({ ...prev, componentId: event.target.value as string || undefined }));
  }, []);

  const handleEnvironmentChange = useCallback((event: React.ChangeEvent<{ value: unknown }>) => {
    setFilters(prev => ({ ...prev, environment: event.target.value as string || undefined }));
  }, []);

  const handleRefresh = useCallback(() => {
    setRefreshIndex(prev => prev + 1);
  }, []);

  const clearFilters = useCallback(() => {
    setFilters({});
    setComponents([]); // Clear components when clearing filters
  }, []);

  // Loading and error states
  if (loading) {
    return <Progress />;
  }

  if (error) {
    return (
      <ResponseErrorPanel
        error={error}
        title="Failed to load runtimes"
      />
    );
  }

  // Table configuration
  const columns: TableColumn[] = [
    { title: 'Runtime ID', field: 'runtimeId' },
    { title: 'Type', field: 'runtimeType' },
    { title: 'Status', field: 'status' },
    { title: 'Platform', field: 'platformName' },
    { title: 'Platform Version', field: 'platformVersion' },
    { title: 'OS', field: 'osName' },
    { title: 'OS Version', field: 'osVersion' },
    { title: 'Environment', field: 'environment.name' },
    { title: 'Component', field: 'component.name' },
    { title: 'Project', field: 'component.project.name' },
    {
      title: 'Registration Time',
      field: 'registrationTime',
      render: (data) => {
        const row = data as Runtime;
        return row.registrationTime ? new Date(row.registrationTime).toLocaleString() : '';
      },
    },
    {
      title: 'Last Heartbeat',
      field: 'lastHeartbeat',
      render: (data) => {
        const row = data as Runtime;
        return row.lastHeartbeat ? new Date(row.lastHeartbeat).toLocaleString() : '';
      },
    },
    {
      title: 'Services',
      field: 'artifacts.services',
      render: (data) => {
        const row = data as Runtime;
        return row.artifacts?.services?.length || 0;
      },
    },
    {
      title: 'Listeners',
      field: 'artifacts.listeners',
      render: (data) => {
        const row = data as Runtime;
        return row.artifacts?.listeners?.length || 0;
      },
    },
  ];

  return (
    <>
      <Box mb={2}>
        <Box display="flex" flexWrap="wrap" mb={2} style={{ gap: '16px' }}>
          <FormControl variant="outlined" style={{ minWidth: 120 }}>
            <InputLabel id="project-select-label">Project</InputLabel>
            <Select
              labelId="project-select-label"
              value={filters.projectId || ''}
              onChange={handleProjectChange}
              label="Project"
              disabled={loadingProjects}
            >
              <MenuItem value="">All Projects</MenuItem>
              {projects.map((project) => (
                <MenuItem key={project.projectId} value={project.projectId}>
                  {project.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl variant="outlined" style={{ minWidth: 120 }}>
            <InputLabel id="component-select-label">Component</InputLabel>
            <Select
              labelId="component-select-label"
              value={filters.componentId || ''}
              onChange={handleComponentChange}
              label="Component"
              disabled={loadingComponents || !filters.projectId}
            >
              <MenuItem value="">All Components</MenuItem>
              {components.map((component) => (
                <MenuItem key={component.componentId} value={component.componentId}>
                  {component.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl variant="outlined" style={{ minWidth: 140 }}>
            <InputLabel id="environment-select-label">Environment</InputLabel>
            <Select
              labelId="environment-select-label"
              value={filters.environment || ''}
              onChange={handleEnvironmentChange}
              label="Environment"
              disabled={loadingEnvironments}
            >
              <MenuItem value="">All Environments</MenuItem>
              {environments.map((environment) => (
                <MenuItem key={environment.environmentId} value={environment.name}>
                  {environment.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl variant="outlined" style={{ minWidth: 120 }}>
            <InputLabel id="status-select-label">Status</InputLabel>
            <Select
              labelId="status-select-label"
              value={filters.status || ''}
              onChange={handleStatusChange}
              label="Status"
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="ACTIVE">Active</MenuItem>
              <MenuItem value="OFFLINE">Offline</MenuItem>
              <MenuItem value="STOPPED">Stopped</MenuItem>
            </Select>
          </FormControl>

          <FormControl variant="outlined" style={{ minWidth: 150 }}>
            <InputLabel id="runtime-type-select-label">Runtime Type</InputLabel>
            <Select
              labelId="runtime-type-select-label"
              value={filters.runtimeType || ''}
              onChange={handleRuntimeTypeChange}
              label="Runtime Type"
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value="BI">BI</MenuItem>
              <MenuItem value="MI">MI</MenuItem>
            </Select>
          </FormControl>

          <Button
            variant="outlined"
            color="primary"
            onClick={handleRefresh}
            style={{ marginRight: 8 }}
            startIcon={<RefreshIcon />}
          >
            Refresh
          </Button>

          <Button
            variant="outlined"
            onClick={clearFilters}
          >
            Clear Filters
          </Button>
        </Box>
      </Box>

      <Table
        title=""
        options={{
          search: true,
          paging: true,
          pageSize: 10,
          emptyRowsWhenPaging: false,
        }}
        columns={columns}
        data={(runtimes || []).map(runtime => ({
          ...runtime,
          id: runtime.runtimeId,
        }))}
      />
    </>
  );
};
