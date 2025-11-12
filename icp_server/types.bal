import ballerina/graphql;
import icp_server.types as types;

type schema_graphql service object {
    *graphql:Service;
    # Runtime Queries
    resource function get runtimes(string? status, string? runtimeType, string? environmentId, string? projectId, string? componentId) returns Runtime[];
    resource function get runtime(string runtimeId) returns Runtime?;
    resource function get services(string runtimeId) returns Service[];
    resource function get listeners(string runtimeId) returns Listener[];
    # Environment Queries
    resource function get environments(string? orgUuid, string? 'type, string? projectId) returns Environment[];
    resource function get adminEnvironments() returns Environment[];
    # Project Queries
    resource function get projects(int? orgId) returns Project[];
    resource function get adminProjects() returns Project[];
    resource function get project(int? orgId, string projectId) returns Project?;
    resource function get projectCreationEligibility(int orgId, string orgHandler) returns ProjectCreationEligibility;
    resource function get projectHandlerAvailability(int orgId, string projectHandlerCandidate) returns ProjectHandlerAvailability;
    # Component Queries
    resource function get components(string orgHandler, string? projectId, ComponentOptionsInput? options) returns Component[];
    resource function get component(string? componentId, string? projectId, string? componentHandler) returns Component?;
    resource function get componentDeployment(string orgHandler, string orgUuid, string componentId, string versionId, string environmentId) returns ComponentDeployment?;
    # Runtime Mutations
    remote function deleteRuntime(string runtimeId) returns boolean;
    # Environment Mutations
    remote function createEnvironment(EnvironmentInput environment) returns Environment?;
    remote function deleteEnvironment(string environmentId) returns boolean;
    remote function updateEnvironment(string environmentId, string? name, string? description) returns Environment?;
    remote function updateEnvironmentProductionStatus(string environmentId, boolean isProduction) returns Environment?;
    # Project Mutations
    remote function createProject(ProjectInput project) returns Project?;
    remote function deleteProject(int orgId, string projectId) returns DeleteResponse;
    remote function updateProject(ProjectUpdateInput project) returns Project?;
    # Component Mutations
    remote function createComponent(ComponentInput component) returns Component?;
    remote function deleteComponent(string componentId) returns boolean;
    remote function deleteComponentV2(string orgHandler, string componentId, string projectId) returns DeleteComponentV2Response;
    remote function updateComponent(string? componentId, string? name, string? description, ComponentUpdateInput? component) returns Component;
};

# ============================================
# Input Types for Queries
# ============================================
# Component Filter Input
public type ComponentFilterInput record {|
    boolean? withSystemComponents;
    string? displayType;
    string? status;
    string? componentSubType;
|};

# Component Input
public type ComponentInput record {|
    # Required Fields
    string projectId;
    string name;
    # Recommended Fields
    string? displayName;
    string? description;
    # Organization Context (optional - can derive from projectId)
    int? orgId;
    string? orgHandler;
    # Component Classification (optional - can have defaults)
    types:RuntimeType? componentType;
    string? technology;
    # Repository Integration (optional - for future use)
    string? repository;
    string? branch;
    string? directoryPath;
    string? secretRef;
    boolean? isPublicRepo;
|};

# Component Options Input
public type ComponentOptionsInput record {|
    ComponentFilterInput? filter;
    ComponentSortInput? sort;
    PaginationInput? pagination;
|};

# Component Sort Input
public type ComponentSortInput record {|
    string sortField;
    string sortOrder;
|};

# Component Update Input
public type ComponentUpdateInput record {|
    # Required field - component ID to update
    string id;
    # Basic fields that can be updated
    string? name;
    string? displayName;
    string? description;
    types:RuntimeType? componentType;
    string? version;
    string? labels;
    string? serviceAccessMode;
    # Extended fields (accepted for compatibility but may not be persisted)
    string? apiId;
    boolean? httpBased;
    boolean? isMigrationCompleted;
    boolean? skipDeploy;
    boolean? endpointShortUrlEnabled;
    boolean? isUnifiedConfigMapping;
    string? componentSubType;
|};

# ============================================
# Input Types for Mutations
# ============================================
# Environment Input
public type EnvironmentInput record {|
    string name;
    string? description;
    boolean? isProduction;
|};

# Pagination Input
public type PaginationInput record {|
    int? 'limit;
    int? offset;
    string? cursor;
|};

# Project Input
public type ProjectInput record {|
    int orgId;
    string orgHandler;
    string name;
    string? version;
    string projectHandler;
    string? handler;
    string? region;
    string? description;
    string? defaultDeploymentPipelineId;
    string[]? deploymentPipelineIds;
    string? 'type;
    string? gitProvider;
    string? gitOrganization;
    string? repository;
    string? branch;
    string? secretRef;
|};

# Project Update Input
public type ProjectUpdateInput record {|
    string id;
    int? orgId;
    string? name;
    string? version;
    string? description;
|};

# ============================================
# ArtifactState Enum - Artifact Status
# ============================================
public enum ArtifactState {
    FAILED,
    STOPPING,
    STARTING,
    DISABLED,
    ENABLED
}

# ============================================
# API Revision Type
# ============================================
public distinct service class ApiRevision {
    resource function get id() returns string {
    
        return "";
    }

    resource function get displayName() returns string {
    
        return "";
    }
}

# ============================================
# API Version Type - API Management
# ============================================
public distinct service class ApiVersion {
    # Identity
    resource function get id() returns string {
    
        return "";
    }

    resource function get apiVersion() returns string {
    
        return "";
    }

    resource function get versionId() returns string? {
    
        return ();
    }

    # Proxy Configuration
    resource function get proxyName() returns string? {
    
        return ();
    }

    resource function get proxyUrl() returns string? {
    
        return ();
    }

    resource function get proxyId() returns string? {
    
        return ();
    }

    # State Management
    resource function get state() returns string {
    
        return "";
    }

    resource function get latest() returns boolean {
    
        return false;
    }

    # Git Integration
    resource function get branch() returns string? {
    
        return ();
    }

    # Access Control
    resource function get accessibility() returns string? {
    
        return ();
    }

    # Deployment Settings
    resource function get autoDeployEnabled() returns boolean? {
    
        return ();
    }

    # Environment Versions
    resource function get appEnvVersions() returns AppEnvVersion[]? {
    
        return ();
    }

    # Observability
    resource function get cellDiagram() returns CellDiagram? {
    
        return ();
    }

    # API Specification
    resource function get openApiSpec() returns string? {
    
        return ();
    }

    resource function get graphqlSchema() returns string? {
    
        return ();
    }

    # Metadata
    resource function get createdAt() returns string? {
    
        return ();
    }

    resource function get updatedAt() returns string? {
    
        return ();
    }

    resource function get description() returns string? {
    
        return ();
    }
}

# ============================================
# App Environment Version Type
# ============================================
public distinct service class AppEnvVersion {
    resource function get environmentId() returns string {
    
        return "";
    }

    resource function get releaseId() returns string {
    
        return "";
    }

    resource function get release() returns Release? {
    
        return ();
    }
}

# ============================================
# Artifacts Type - Runtime Artifacts Container
# ============================================
public distinct service class Artifacts {
    resource function get listeners() returns Listener[] {
    
        return [];
    }

    resource function get services() returns Service[] {
    
        return [];
    }
}

# ============================================
# Author Info Type - Commit Author Information
# ============================================
public distinct service class AuthorInfo {
    resource function get name() returns string {
    
        return "";
    }

    resource function get date() returns string {
    
        return "";
    }

    resource function get email() returns string {
    
        return "";
    }

    resource function get avatarUrl() returns string {
    
        return "";
    }
}

# ============================================
# Build Info Type - Build Information
# ============================================
public distinct service class BuildInfo {
    resource function get buildId() returns string {
    
        return "";
    }

    resource function get deployedAt() returns string? {
    
        return ();
    }

    resource function get 'commit() returns CommitInfo? {
    }

    resource function get sourceConfigMigrationStatus() returns SourceConfigMigrationStatus? {
    
        return ();
    }

    resource function get runId() returns string {
    
        return "";
    }
}

public distinct service class Buildpack {
    resource function get id() returns string {
    
        return "";
    }

    resource function get name() returns string? {
    
        return ();
    }

    resource function get language() returns string {
    
        return "";
    }

    resource function get version() returns string? {
    
        return ();
    }

    resource function get description() returns string? {
    
        return ();
    }
}

# ============================================
# Buildpack Configuration
# ============================================
public distinct service class BuildpackConfig {
    resource function get versionId() returns string? {
    
        return ();
    }

    resource function get buildContext() returns string? {
    
        return ();
    }

    resource function get languageVersion() returns string? {
    
        return ();
    }

    resource function get buildCommand() returns string? {
    
        return ();
    }

    resource function get runCommand() returns string? {
    
        return ();
    }

    resource function get isUnitTestEnabled() returns boolean? {
    
        return ();
    }

    resource function get pullLatestSubmodules() returns boolean? {
    
        return ();
    }

    resource function get enableTrivyScan() returns boolean? {
    
        return ();
    }

    resource function get buildpack() returns Buildpack? {
    
        return ();
    }

    resource function get keyValues() returns KeyValue[]? {
    
        return ();
    }
}

# ============================================
# BYOC Build Configuration
# ============================================
public distinct service class ByocBuildConfig {
    resource function get id() returns string? {
    
        return ();
    }

    resource function get isMainContainer() returns boolean? {
    
        return ();
    }

    resource function get containerId() returns string? {
    
        return ();
    }

    resource function get componentId() returns string? {
    
        return ();
    }

    resource function get repositoryId() returns string? {
    
        return ();
    }

    resource function get dockerContext() returns string? {
    
        return ();
    }

    resource function get dockerfilePath() returns string? {
    
        return ();
    }

    resource function get oasFilePath() returns string? {
    
        return ();
    }
}

# ============================================
# BYOC Web App Build Configuration
# ============================================
public distinct service class ByocWebAppBuildConfig {
    resource function get id() returns string? {
    
        return ();
    }

    resource function get containerId() returns string? {
    
        return ();
    }

    resource function get componentId() returns string? {
    
        return ();
    }

    resource function get repositoryId() returns string? {
    
        return ();
    }

    resource function get dockerContext() returns string? {
    
        return ();
    }

    resource function get webAppType() returns string? {
    
        return ();
    }

    resource function get port() returns int? {
    
        return ();
    }

    resource function get imageUrl() returns string? {
    
        return ();
    }

    resource function get registryId() returns string? {
    
        return ();
    }

    resource function get dockerfile() returns string? {
    
        return ();
    }

    resource function get buildCommand() returns string? {
    
        return ();
    }

    resource function get packageManagerVersion() returns string? {
    
        return ();
    }

    resource function get outputDirectory() returns string? {
    
        return ();
    }

    resource function get enableTrivyScan() returns boolean? {
    
        return ();
    }
}

# ============================================
# Cell Diagram - Observability & Architecture View
# ============================================
public distinct service class CellDiagram {
    resource function get data() returns string? {
    
        return ();
    }

    resource function get message() returns string? {
    
        return ();
    }

    resource function get errorName() returns string? {
    
        return ();
    }

    resource function get success() returns boolean {
    
        return false;
    }
}

# ============================================
# Commit Info Type - Git Commit Information
# ============================================
public distinct service class CommitInfo {
    resource function get author() returns AuthorInfo {
        // Return a dummy AuthorInfo object
        return new AuthorInfo();
    }

    resource function get sha() returns string {
    
        return "";
    }

    resource function get message() returns string {
    
        return "";
    }

    resource function get isLatest() returns boolean {
    
        return false;
    }
}

# ============================================
# Component Type - Application Component
# ============================================
public distinct service class Component {
    # Basic Identity Fields
    resource function get id() returns string {
    
        return "";
    }

    resource function get projectId() returns string {
    
        return "";
    }

    resource function get orgHandler() returns string {
    
        return "";
    }

    resource function get orgId() returns int? {
    
        return ();
    }

    # Component Metadata
    resource function get name() returns string {
    
        return "";
    }

    resource function get handler() returns string {
    
        return "";
    }

    resource function get displayName() returns string {
    
        return "";
    }

    resource function get displayType() returns string {
    
        return "";
    }

    resource function get description() returns string? {
    
        return ();
    }

    resource function get ownerName() returns string? {
    
        return ();
    }

    # Status Fields
    resource function get status() returns string {
    
        return "";
    }

    resource function get initStatus() returns string? {
    
        return ();
    }

    # Version & Timestamps
    resource function get version() returns string {
    
        return "";
    }

    resource function get createdAt() returns string {
    
        return "";
    }

    resource function get lastBuildDate() returns string? {
    
        return ();
    }

    resource function get updatedAt() returns string? {
    
        return ();
    }

    # Classification
    resource function get componentSubType() returns string? {
    
        return ();
    }

    resource function get componentType() returns types:RuntimeType? {
        return ();
    }

    resource function get labels() returns string? {
        return "";
    }

    # System Component Flag
    resource function get isSystemComponent() returns boolean? {
        return ();
    }

    # Component Configuration Flags
    resource function get apiId() returns string? {
        return ();
    }

    resource function get httpBased() returns boolean? {
        return ();
    }

    resource function get isMigrationCompleted() returns boolean? {
        return ();
    }

    resource function get skipDeploy() returns boolean? {
        return ();
    }

    resource function get endpointShortUrlEnabled() returns boolean? {
        return ();
    }

    resource function get isUnifiedConfigMapping() returns boolean? {
        return ();
    }

    resource function get serviceAccessMode() returns string? {
        return ();
    }

    # Nested Objects
    resource function get repository() returns Repository? {
        return ();
    }

    resource function get apiVersions() returns ApiVersion[]? {
        return ();
    }

    resource function get deploymentTracks() returns DeploymentTrack[]? {
        return ();
    }

    # Git Integration (for components with source control)
    resource function get gitProvider() returns string? {
        return ();
    }

    resource function get gitOrganization() returns string? {
        return ();
    }

    resource function get gitRepository() returns string? {
        return ();
    }

    resource function get branch() returns string? {
        return ();
    }

    # Advanced Fields (used in specific views)
    resource function get endpoints() returns Endpoint[]? {
        return ();
    }

    resource function get environmentVariables() returns EnvironmentVariable[]? {
        return ();
    }

    resource function get secrets() returns Secret[]? {
        return ();
    }

    # Legacy fields for backward compatibility
    resource function get createdBy() returns string? {
        return ();
    }

    resource function get updatedBy() returns string? {
        return ();
    }

    resource function get componentId() returns string? {
        return ();
    }

    resource function get project() returns Project? {
        return ();
    }
}

# ============================================
# Component Deployment Type - Deployment Information
# ============================================
public distinct service class ComponentDeployment {
    resource function get environmentId() returns string {
    
        return "";
    }

    resource function get configCount() returns int {
    
        return 0;
    }

    resource function get apiId() returns string? {
    
        return ();
    }

    resource function get releaseId() returns string {
    
        return "";
    }

    resource function get apiRevision() returns ApiRevision? {
    
        return ();
    }

    resource function get build() returns BuildInfo {
        // Return a dummy BuildInfo object  
        return new BuildInfo();
    }

    resource function get imageUrl() returns string {
    
        return "";
    }

    resource function get invokeUrl() returns string {
    
        return "";
    }

    resource function get versionId() returns string {
    
        return "";
    }

    resource function get deploymentStatus() returns string {
    
        return "";
    }

    resource function get deploymentStatusV2() returns string {
    
        return "";
    }

    resource function get version() returns string? {
    
        return ();
    }

    resource function get cron() returns string? {
    
        return ();
    }

    resource function get cronTimezone() returns string? {
    
        return ();
    }
}

# ============================================
# Delete Component V2 Response Type
# ============================================
public distinct service class DeleteComponentV2Response {
    resource function get status() returns string {
    
        return "";
    }

    resource function get canDelete() returns boolean {
    
        return false;
    }

    resource function get message() returns string {
    
        return "";
    }

    resource function get encodedData() returns string {
    
        return "";
    }
}

# ============================================
# Delete Response Type
# ============================================
public distinct service class DeleteResponse {
    resource function get status() returns string {
    
        return "";
    }

    resource function get details() returns string {
    
        return "";
    }
}

# ============================================
# Deployment Track Type - CI/CD Configuration
# ============================================
public distinct service class DeploymentTrack {
    # Identity
    resource function get id() returns string {
    
        return "";
    }

    resource function get componentId() returns string {
    
        return "";
    }

    # Timestamps
    resource function get createdAt() returns string {
    
        return "";
    }

    resource function get updatedAt() returns string {
    
        return "";
    }

    # Version Configuration
    resource function get apiVersion() returns string {
    
        return "";
    }

    resource function get branch() returns string? {
    
        return ();
    }

    resource function get latest() returns boolean {
    
        return false;
    }

    resource function get versionStrategy() returns string? {
    
        return ();
    }

    # Deployment Settings
    resource function get description() returns string? {
    
        return ();
    }

    resource function get autoDeployEnabled() returns boolean? {
    
        return ();
    }

    resource function get autoBuildEnabled() returns boolean? {
    
        return ();
    }

    # Environment Settings
    resource function get environmentName() returns string? {
    
        return ();
    }

    resource function get environmentId() returns string? {
    
        return ();
    }

    # Deployment Status
    resource function get deploymentStatus() returns string? {
    
        return ();
    }

    resource function get lastDeployedAt() returns string? {
    
        return ();
    }
}

# ============================================
# Docker Build Configuration
# ============================================
public distinct service class DockerBuildConfig {
    resource function get id() returns string? {
    
        return ();
    }

    resource function get dockerContext() returns string? {
    
        return ();
    }

    resource function get dockerfile() returns string? {
    
        return ();
    }

    resource function get port() returns int? {
    
        return ();
    }

    resource function get imageUrl() returns string? {
    
        return ();
    }

    resource function get registryId() returns string? {
    
        return ();
    }
}

# ============================================
# Endpoint Type - Service Endpoints
# ============================================
public distinct service class Endpoint {
    resource function get id() returns string {
    
        return "";
    }

    resource function get componentId() returns string {
    
        return "";
    }

    resource function get name() returns string {
    
        return "";
    }

    resource function get url() returns string {
    
        return "";
    }

    resource function get 'type() returns string {
        return "";
    }

    resource function get protocol() returns string? {
    
        return ();
    }

    resource function get port() returns int? {
    
        return ();
    }

    resource function get visibility() returns string? {
    
        return ();
    }
}

# ============================================
# Environment Type - Deployment Environment
# ============================================
public distinct service class Environment {
    # Core Identity
    resource function get environmentId() returns string {
    
        return "";
    }

    resource function get id() returns string {
    
        return "";
    }

    resource function get name() returns string {
    
        return "";
    }

    resource function get description() returns string? {
    
        return ();
    }

    resource function get isProduction() returns boolean {
    
        return false;
    }

    # Choreo Environment Configuration
    resource function get choreoEnv() returns string? {
    
        return ();
    }

    # Virtual Host Configuration
    resource function get vhost() returns string? {
    
        return ();
    }

    resource function get sandboxVhost() returns string? {
    
        return ();
    }

    # API Management
    resource function get apiEnvName() returns string? {
    
        return ();
    }

    resource function get apimEnvId() returns string? {
    
        return ();
    }

    # Migration & Deployment
    resource function get isMigrating() returns boolean? {
    
        return ();
    }

    resource function get promoteFrom() returns string? {
    
        return ();
    }

    # Infrastructure
    resource function get namespace() returns string? {
    
        return ();
    }

    resource function get dpId() returns string? {
    
        return ();
    }

    resource function get templateId() returns string {
    
        return "";
    }

    # Features & Flags
    resource function get critical() returns boolean? {
    
        return ();
    }

    resource function get isPdp() returns boolean? {
    
        return ();
    }

    resource function get scaleToZeroEnabled() returns boolean {
    
        return false;
    }

    # Audit Fields
    resource function get createdAt() returns string? {
    
        return ();
    }

    resource function get updatedAt() returns string? {
    
        return ();
    }

    resource function get updatedBy() returns string? {
    
        return ();
    }

    resource function get createdBy() returns string? {
    
        return ();
    }
}

# ============================================
# Environment Variable Type
# ============================================
public distinct service class EnvironmentVariable {
    resource function get key() returns string {
    
        return "";
    }

    resource function get value() returns string? {
    
        return ();
    }

    resource function get isSecret() returns boolean {
    
        return false;
    }

    resource function get description() returns string? {
    
        return ();
    }
}

# ============================================
# Key Value Pair
# ============================================
public distinct service class KeyValue {
    resource function get id() returns string? {
    
        return ();
    }

    resource function get key() returns string {
    
        return "";
    }

    resource function get value() returns string? {
    
        return ();
    }
}

# ============================================
# Listener Type - Listener Artifacts
# ============================================
public distinct service class Listener {
    resource function get name() returns string {
    
        return "";
    }

    resource function get package() returns string {
    
        return "";
    }

    resource function get protocol() returns string {
    
        return "";
    }

    resource function get state() returns ArtifactState {
        return ENABLED;
    }
}

# ============================================
# Project Type - Project Details
# ============================================
public distinct service class Project {
    resource function get id() returns string {
    
        return "";
    }

    resource function get projectId() returns string {
    
        return "";
    }

    resource function get orgId() returns int {
    
        return 0;
    }

    resource function get name() returns string {
    
        return "";
    }

    resource function get version() returns string? {
    
        return ();
    }

    resource function get createdDate() returns string? {
    
        return ();
    }

    resource function get handler() returns string {
    
        return "";
    }

    resource function get extendedHandler() returns string? {
    
        return ();
    }

    resource function get region() returns string? {
    
        return ();
    }

    resource function get description() returns string? {
    
        return ();
    }

    resource function get owner() returns string? {
    
        return ();
    }

    resource function get labels() returns string[]? {
    
        return ();
    }

    resource function get defaultDeploymentPipelineId() returns string? {
    
        return ();
    }

    resource function get deploymentPipelineIds() returns string[]? {
    
        return ();
    }

    resource function get 'type() returns string? {
        return ();
    }

    resource function get gitProvider() returns string? {
    
        return ();
    }

    resource function get gitOrganization() returns string? {
    
        return ();
    }

    resource function get repository() returns string? {
    
        return ();
    }

    resource function get branch() returns string? {
    
        return ();
    }

    resource function get secretRef() returns string? {
    
        return ();
    }

    resource function get createdBy() returns string? {
    
        return ();
    }

    resource function get updatedAt() returns string? {
    
        return ();
    }

    resource function get updatedBy() returns string? {
    
        return ();
    }
}

# ============================================
# Project Creation Eligibility Type
# ============================================
public distinct service class ProjectCreationEligibility {
    resource function get isProjectCreationAllowed() returns boolean {
    
        return false;
    }
}

# ============================================
# Project Handler Availability Type
# ============================================
public distinct service class ProjectHandlerAvailability {
    resource function get handlerUnique() returns boolean {
    
        return false;
    }

    resource function get alternateHandlerCandidate() returns string? {
    
        return ();
    }
}

public distinct service class Release {
    resource function get id() returns string {
    
        return "";
    }

    resource function get metadata() returns ReleaseMetadata? {
    
        return ();
    }

    resource function get environmentId() returns string? {
    
        return ();
    }

    resource function get environment() returns string? {
    
        return ();
    }

    resource function get gitHash() returns string? {
    
        return ();
    }

    resource function get gitOpsHash() returns string? {
    
        return ();
    }
}

public distinct service class ReleaseMetadata {
    resource function get choreoEnv() returns string? {
    
        return ();
    }
}

# ============================================
# Repository Type - Build & Deploy Configuration
# ============================================
public distinct service class Repository {
    # Build Configurations
    resource function get buildpackConfig() returns BuildpackConfig? {
    
        return ();
    }

    resource function get byocWebAppBuildConfig() returns ByocWebAppBuildConfig? {
    
        return ();
    }

    resource function get byocBuildConfig() returns ByocBuildConfig? {
    
        return ();
    }

    resource function get dockerBuildConfig() returns DockerBuildConfig? {
    
        return ();
    }

    resource function get testRunnerConfig() returns TestRunnerConfig? {
    
        return ();
    }

    # Repository Source Information
    resource function get repositoryType() returns string? {
    
        return ();
    }

    resource function get repositoryBranch() returns string? {
    
        return ();
    }

    resource function get repositorySubPath() returns string? {
    
        return ();
    }

    resource function get repositoryUrl() returns string? {
    
        return ();
    }

    # Git Provider Information
    resource function get bitbucketServerUrl() returns string? {
    
        return ();
    }

    resource function get serverUrl() returns string? {
    
        return ();
    }

    resource function get gitProvider() returns string? {
    
        return ();
    }

    resource function get nameApp() returns string? {
    
        return ();
    }

    resource function get nameConfig() returns string? {
    
        return ();
    }

    resource function get branch() returns string? {
    
        return ();
    }

    resource function get branchApp() returns string? {
    
        return ();
    }

    resource function get organizationApp() returns string? {
    
        return ();
    }

    resource function get organizationConfig() returns string? {
    
        return ();
    }

    resource function get appSubPath() returns string? {
    
        return ();
    }

    # Repository Flags
    resource function get isUserManage() returns boolean? {
    
        return ();
    }

    resource function get isAuthorizedRepo() returns boolean? {
    
        return ();
    }

    resource function get isBuildConfigurationMigrated() returns boolean? {
    
        return ();
    }
}

# ============================================
# Resource Type - Service Resources
# ============================================
public distinct service class Resource {
    resource function get methods() returns string[] {
        return [];
    }

    resource function get url() returns string {
    
        return "";
    }
}

# ============================================
# Runtime Type - Runtime Instance Details
# ============================================
public distinct service class Runtime {
    resource function get runtimeId() returns string {
    
        return "";
    }

    resource function get runtimeType() returns string {
    
        return "";
    }

    resource function get status() returns string {
    
        return "";
    }

    resource function get version() returns string? {
    
        return ();
    }

    resource function get component() returns Component {
        return new Component();
    }

    resource function get environment() returns Environment {
        return new Environment();
    }

    resource function get platformName() returns string? {
    
        return ();
    }

    resource function get platformVersion() returns string? {
    
        return ();
    }

    resource function get platformHome() returns string? {
    
        return ();
    }

    resource function get osName() returns string? {
    
        return ();
    }

    resource function get osVersion() returns string? {
    
        return ();
    }

    resource function get registrationTime() returns string? {
    
        return ();
    }

    resource function get lastHeartbeat() returns string? {
    
        return ();
    }

    resource function get artifacts() returns Artifacts? {
    
        return ();
    }
}

# ============================================
# Secret Type
# ============================================
public distinct service class Secret {
    resource function get key() returns string {
    
        return "";
    }

    resource function get description() returns string? {
    
        return ();
    }

    resource function get createdAt() returns string? {
    
        return ();
    }

    resource function get updatedAt() returns string? {
    
        return ();
    }
}

# ============================================
# Service Type - Service Artifacts
# ============================================
public distinct service class Service {
    resource function get name() returns string {
    
        return "";
    }

    resource function get package() returns string {
    
        return "";
    }

    resource function get basePath() returns string {
    
        return "";
    }

    resource function get state() returns ArtifactState {
        return ENABLED;
    }

    resource function get resources() returns Resource[] {
    
        return [];
    }
}

# ============================================
# Source Config Migration Status Type
# ============================================
public distinct service class SourceConfigMigrationStatus {
    resource function get canMigrate() returns boolean {
    
        return false;
    }

    resource function get existingFileName() returns string {
    
        return "";
    }

    resource function get existingFileSchemaVersion() returns string {
    
        return "";
    }
}

# ============================================
# Test Runner Configuration
# ============================================
public distinct service class TestRunnerConfig {
    resource function get dockerContext() returns string? {
    
        return ();
    }

    resource function get postmanDirectory() returns string? {
    
        return ();
    }

    resource function get testRunnerType() returns string? {
    
        return ();
    }
}
