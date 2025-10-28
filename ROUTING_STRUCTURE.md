# Routing Structure Documentation: Devant Choreo-Console

**Version:** 1.0  
**Date:** October 27, 2025  
**Branch:** icp2-auth  
**Status:** Planning Phase - Week 1

---

## Table of Contents

1. [Overview](#overview)
2. [Route Hierarchy](#route-hierarchy)
3. [URL Pattern Structure](#url-pattern-structure)
4. [Core Route Definitions](#core-route-definitions)
5. [Organization-Aware Routes](#organization-aware-routes)
6. [Helper Functions](#helper-functions)
7. [Migration Impact Analysis](#migration-impact-analysis)

---

## Overview

The Devant choreo-console uses **React Router v5** with a hierarchical routing structure centered around **organizations**. All authenticated routes are organization-scoped, meaning URLs follow the pattern:

```
/organizations/{orgHandle}/{resource}/{...}
```

### Key Characteristics:
- **Organization-centric:** Every resource (project, component, environment) belongs to an organization
- **Dynamic routing:** Uses React Router's `useRouteMatch()` and URL parameters (`:orgHandle`, `:projectId`, `:componentHandler`)
- **Route generation:** Helper functions in `utils/route.ts` generate type-safe URLs
- **Lazy loading:** Heavy components use code-splitting with `React.lazy()`
- **Protected routes:** All authenticated routes wrapped in `<ProtectedRoute>`

---

## Route Hierarchy

```
App (/)
├─ Login (/login)
├─ Signup (/signup, /signup_embedded)
└─ DeferredRoot (/* - lazy loaded)
   ├─ Public Routes
   │  ├─ /signin
   │  ├─ /accept-invitation
   │  ├─ /vscode-auth
   │  ├─ /editor-auth
   │  ├─ /ghapp
   │  └─ Marketplace registrations (Azure/AWS/GCP)
   │
   └─ ProtectedApp (/* - authenticated)
      ├─ User Settings (/account/settings)
      ├─ PE Routes (/pe-view/organizations/:orgHandle/...)
      └─ Organization Routes (/organizations/:orgHandle)
         ├─ Home (/home)
         ├─ Listing (/listing)
         ├─ Architecture (/architecture)
         ├─ Internal Marketplace (/internal-marketplace)
         ├─ CIO Dashboard (/cio-dashboard)
         ├─ Analytics (/analytics)
         ├─ Projects (/projects)
         │  └─ Project Routes (/:projectId)
         │     ├─ Components (/components)
         │     │  └─ Component Routes (/:componentHandler)
         │     │     ├─ Develop
         │     │     ├─ Build
         │     │     ├─ Deploy
         │     │     ├─ Test
         │     │     ├─ Observe
         │     │     └─ Settings
         │     ├─ Environments (/devops/environments)
         │     ├─ Internal Marketplace (/internal-marketplace)
         │     └─ Observability (/observe)
         ├─ Observability (/observe)
         │  ├─ Metrics
         │  └─ Logs (/runtimelogs, /auditlogs)
         ├─ Admin Resources (/admin)
         │  ├─ Databases (/databases)
         │  ├─ Vector Databases (/vector-databases)
         │  ├─ RAG Ingestion (/rag-ingestion)
         │  ├─ Message Brokers (/message-brokers)
         │  ├─ Third Party Services (/third-party-services)
         │  ├─ Gen AI Services (/gen-ai-services)
         │  ├─ Connections (/connections)
         │  └─ CD Pipelines (/cd-pipelines)
         ├─ DevOps (/devops)
         │  └─ Config Groups (/config-groups)
         ├─ Environments (/environments)
         ├─ Deployment Pipelines (/deployment-pipelines)
         ├─ API Governance (/api-governance)
         ├─ Governance (/governance/manage)
         ├─ Approvals (/approvals)
         ├─ Data Planes (/dataplanes)
         └─ Settings (/settings)
```

---

## URL Pattern Structure

### 1. Organization-Level Routes

```
/organizations/:orgHandle/...
```

**Examples:**
```
/organizations/wso2/home
/organizations/wso2/projects
/organizations/wso2/observe/metrics
/organizations/wso2/settings/members
/organizations/wso2/admin/databases
```

### 2. Project-Level Routes

```
/organizations/:orgHandle/projects/:projectId/...
```

**Examples:**
```
/organizations/wso2/projects/my-api-project/components
/organizations/wso2/projects/my-api-project/observe/metrics
/organizations/wso2/projects/my-api-project/settings
/organizations/wso2/projects/my-api-project/devops/environments
```

### 3. Component-Level Routes

```
/organizations/:orgHandle/projects/:projectId/components/:componentHandler/...
```

**Examples:**
```
/organizations/wso2/projects/my-api-project/components/user-service/deploy
/organizations/wso2/projects/my-api-project/components/user-service/observe/metrics
/organizations/wso2/projects/my-api-project/components/user-service/settings
```

### 4. Internal Marketplace Routes

**Organization Level:**
```
/organizations/:orgHandle/internal-marketplace/services/:serviceId
/organizations/:orgHandle/internal-marketplace/databases/:resourceId
/organizations/:orgHandle/internal-marketplace/config-groups/:resourceId
```

**Project Level:**
```
/organizations/:orgHandle/projects/:projectId/internal-marketplace/services/:serviceId
```

### 5. Platform Engineer (PE) Perspective Routes

```
/pe-view/organizations/:orgHandle/...
/pe-view/organizations/:orgHandle/projects/:projectId/...
/pe-view/organizations/:orgHandle/projects/:projectId/components/:componentHandler/...
```

**Examples:**
```
/pe-view/organizations/wso2/overview
/pe-view/organizations/wso2/infrastructure
/pe-view/organizations/wso2/devops/cd-pipelines
/pe-view/organizations/wso2/insights
```

---

## Core Route Definitions

### From `utils/route.ts`

#### Path Constants

```typescript
// Authentication
export const SIGN_IN_PATH = '/signin';
export const USER_SETTINGS_PATH = '/account/settings';

// Organization
export const ORG_PATH = '/organizations/:orgHandle';
export const HOME_PATH = `${ORG_PATH}/home`;
export const SETTINGS_PATH = `${ORG_PATH}/settings`;

// Projects
export const PROJECTS_PATH = `${ORG_PATH}/projects`;
export const NEW_PROJECT_PATH = `${PROJECTS_PATH}/new`;
export const PROJECT_PATH = `${PROJECTS_PATH}/:projectId`;

// Components
export const COMPONENTS_PATH = `${PROJECT_PATH}/components`;
export const NEW_COMPONENT_PATH = `${COMPONENTS_PATH}/new`;
export const COMPONENT_PATH = `${COMPONENTS_PATH}/:componentHandler`;

// Observability
export const PROJECTS_OBSERVE_PATH = `${ORG_PATH}/observe`;
export const PROJECT_OBSERVE_PATH = `${PROJECT_PATH}/observe`;
export const COMPONENT_OBSERVE_PATH = `${COMPONENT_PATH}/observe`;

// Logs (Unified)
export const ORG_LEVEL_AUDIT_LOGS_PATH = `${ORG_PATH}/auditlogs`;
export const ORG_LEVEL_RUNTIME_LOGS_PATH = `${ORG_PATH}/observe/runtimelogs`;
export const PROJECT_LEVEL_RUNTIME_LOGS_PATH = `${PROJECT_PATH}/observe/runtimelogs`;
export const COMPONENT_LEVEL_RUNTIME_LOGS_PATH = `${COMPONENT_PATH}/observe/runtimelogs`;

// Admin Resources
export const DATAPLANES_PATH = `${ORG_PATH}/dataplanes`;
export const ORG_ENVIRONMENTS_PATH = `${ORG_PATH}/environments`;
export const ORG_CLOUD_STORAGE_PATH = `${ORG_PATH}/admin/databases`;
export const ORG_ENVIRONMENTS_PIPELINES_PATH = `${ORG_PATH}/deployment-pipelines`;

// Internal Marketplace
export const ORG_LEVEL_INTERNAL_MARKETPLACE_PATH = `${ORG_PATH}/internal-marketplace`;
export const PROJECT_LEVEL_INTERNAL_MARKETPLACE_PATH = `${PROJECT_PATH}/internal-marketplace`;

// CIO Dashboard / Analytics
export const CIO_DASHBOARD_PATH = `${ORG_PATH}/cio-dashboard`;
export const CIO_DASHBOARD_PROJECT_PATH = `${PROJECT_PATH}/cio-dashboard`;

// Marketplace subscriptions
export const AZURE_SUBSCRIPTION_CONFIG = '/configure-account/azure';
export const REGISTER_GCP_SUBSCRIPTION = '/register/gcp';
export const REGISTER_AWS_SUBSCRIPTION = '/register/aws';
```

---

## Organization-Aware Routes

### From `pages/Organization.routes.tsx`

This is the main routing component for organization-level navigation after authentication.

**Key Routes:**

| Route Pattern | Component | Description |
|--------------|-----------|-------------|
| `${path}` | Redirect → `/home` | Organization root redirects to home |
| `${path}/home` | `OrganizationHome` | Organization dashboard/home page |
| `${path}/listing` | `OrganizationListing` | List all resources |
| `${path}/architecture` | `OrgArchitectureDiagram` | Architecture visualization |
| `${path}/internal-marketplace` | `InternalMarketplace` | Service catalog |
| `${path}/cio-dashboard` | `CIODashboard` | Executive insights |
| `${path}/analytics/*` | `CIODashboard` | Analytics views |
| `${path}/projects` | `Projects` | Project listing + nested routes |
| `${path}/observe/*` | `Observe` / `LogsRoutes` | Metrics and logs |
| `${path}/dataplanes` | `DataPlanes` | Data plane management |
| `${path}/admin/connections/*` | Connection management | CRUD for connections |
| `${path}/admin/databases` | `CloudStorageRoutes` | Database management |
| `${path}/admin/vector-databases` | `CloudVectorStorageRoutes` | Vector DB management |
| `${path}/admin/rag-ingestion` | `RAGIngestionRoutes` | RAG ingestion pipelines |
| `${path}/admin/message-brokers` | `MessageBrokersRoutes` | Message broker setup |
| `${path}/admin/third-party-services` | `ThirdPartyServices` | External service integration |
| `${path}/admin/gen-ai-services` | `GenAIServicesRoutes` | Gen AI services |
| `${path}/admin/cd-pipelines` | `DeploymentPipelinesPage` | CD pipeline management |
| `${path}/dependencies/config-groups` | `ConfigGroupRoutes` | Configuration groups |
| `${path}/environments` | `OrgEnvironmentRoutes` | Environment management |
| `${path}/deployment-pipelines/*` | `DeploymentPipelinesPage` | Deployment pipelines |
| `${path}/api-governance` | `APIGovernanceOrganization` | API governance |
| `${path}/governance/manage` | `Governance` | Governance policies |
| `${path}/devops/config-groups` | `ConfigGroupRoutes` | DevOps config |
| `${path}/approvals` | `ApprovalsContainer` | Approval workflows |
| `${path}/settings` | `Settings` | Organization settings |

---

## Helper Functions

### From `utils/route.ts` and `hooks/route.tsx`

The codebase provides extensive helper functions to generate type-safe routes. These functions ensure consistency and reduce hardcoding URLs.

#### Base Path Generators

```typescript
// Generate organization base path
generateBasePath(orgHandle: string, subPath?: string): string
// Example: generateBasePath('wso2', '/home') → '/organizations/wso2/home'

// Generate project path
generateProjectPath(orgHandle: string, projectId: string, subPath?: string): string
// Example: generateProjectPath('wso2', 'api-proj', '/components') 
//          → '/organizations/wso2/projects/api-proj/components'

// Generate component path
generateComponentPath(orgHandle: string, projectId: string, componentHandler: string, subPath?: string): string
// Example: generateComponentPath('wso2', 'api-proj', 'user-svc', '/deploy')
//          → '/organizations/wso2/projects/api-proj/components/user-svc/deploy'
```

#### Observability Path Generators

```typescript
generateOrgLevelObservePath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/observe{subPath}'

generateProjectLevelObservePath(orgHandle: string, projectId: string, subPath?: string): string
// → '/organizations/{orgHandle}/projects/{projectId}/observe{subPath}'

generateComponentLevelObservePath(orgHandle: string, projectId: string, componentHandler: string, subPath?: string): string
// → '/organizations/{orgHandle}/projects/{projectId}/components/{componentHandler}/observe{subPath}'
```

#### Settings Path Generators

```typescript
generateSettingsPath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/settings{subPath}'

generateProjectSettingsPath(orgHandle: string, projectId: string, subPath?: string): string
// → '/organizations/{orgHandle}/projects/{projectId}/settings{subPath}'

generateComponentSettingsPath(orgHandle: string, projectId: string, componentHandler: string, subPath?: string): string
// → '/organizations/{orgHandle}/projects/{projectId}/components/{componentHandler}/settings{subPath}'
```

#### CIO Dashboard / Analytics Path Generators

```typescript
generateCIODashboardPath(orgHandle: string, projectId?: string, componentHandler?: string, subPath?: string): string
// Org level: '/organizations/{orgHandle}/cio-dashboard{subPath}'
// Project level: '/organizations/{orgHandle}/projects/{projectId}/cio-dashboard{subPath}'
// Component level: '/organizations/{orgHandle}/projects/{projectId}/components/{componentHandler}/cio-dashboard{subPath}'

generateInsightPath(orgHandle: string, projectId?: string, componentHandler?: string, subPath?: string): string
// Similar hierarchy for analytics/insights

generateCombinedInsightsSubPath(subPathType: string, orgHandle: string, projectId?: string, componentHandler?: string, subPath?: string): string
// For specific insight types: 'operational-insights', 'business-insights', 'delivery-insights', 'cost-insights'
```

#### Admin Resource Path Generators

```typescript
generateOrgCloudStoragePath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/admin/databases{subPath}'

generateOrgCloudVectorStoragePath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/admin/vector-databases{subPath}'

generateOrgMessageBrokersPath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/admin/message-brokers{subPath}'

generateOrgConfigGroupsPath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/devops/config-groups{subPath}'

generateOrgEnvironmentsPath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/environments{subPath}'

generateOrgEnvironmentsPipelinesPath(orgHandle: string, subPath?: string): string
// → '/organizations/{orgHandle}/deployment-pipelines{subPath}'
```

#### Internal Marketplace Path Generators

```typescript
generateInternalMarketplacePath(orgHandle: string): string
// → '/organizations/{orgHandle}/internal-marketplace'

// Service-specific paths
ORG_LEVEL_INTERNAL_MARKETPLACE_SERVICES_PATH = `${ORG_LEVEL_INTERNAL_MARKETPLACE_PATH}/services`
ORG_LEVEL_INTERNAL_MARKETPLACE_SERVICE_PATH = `${ORG_LEVEL_INTERNAL_MARKETPLACE_SERVICES_PATH}/:serviceId`

// Database-specific paths
ORG_LEVEL_INTERNAL_MARKETPLACE_DBS_PATH = `${ORG_LEVEL_INTERNAL_MARKETPLACE_PATH}/databases`
ORG_LEVEL_INTERNAL_MARKETPLACE_DB_PATH = `${ORG_LEVEL_INTERNAL_MARKETPLACE_DBS_PATH}/:resourceId`

// Config group paths
ORG_LEVEL_INTERNAL_MARKETPLACE_CONFIG_GROUPS_PATH = `${ORG_LEVEL_INTERNAL_MARKETPLACE_PATH}/config-groups`
ORG_LEVEL_INTERNAL_MARKETPLACE_CONFIG_GROUP_PATH = `${ORG_LEVEL_INTERNAL_MARKETPLACE_CONFIG_GROUPS_PATH}/:resourceId`

// Similar structure for PROJECT_LEVEL_INTERNAL_MARKETPLACE_*
```

#### URL Manipulation Utilities

```typescript
replaceOrgHandleInUrl(originalUrl: string, newOrgHandle: string): string
// Updates organization handle in existing URL

replaceProjectIdInUrl(originalUrl: string, newProjectId: string): string
// Updates project ID in existing URL
```

---

## Custom Hooks

### `useRoutePath()` Hook

Located in `hooks/route.tsx`, this hook provides access to all route generation functions within components. It automatically uses the current organization handle from context.

**Usage Example:**
```typescript
import { useRoutePath } from 'hooks/route';

function MyComponent() {
  const { getProjectPath, getComponentPath, getSettingsPath } = useRoutePath();
  
  // Automatically uses current organization
  const projectUrl = getProjectPath('my-project-id'); 
  // → '/organizations/wso2/projects/my-project-id' (if current org is 'wso2')
  
  const componentUrl = getComponentPath('my-project-id', 'my-component');
  // → '/organizations/wso2/projects/my-project-id/components/my-component'
  
  return <Link to={projectUrl}>Go to Project</Link>;
}
```

**Available Methods (80+ functions):**
- `getBasePath(subPath?)`
- `getProjectsPath(subPath?)`
- `getProjectPath(projectId, subPath?)`
- `getComponentPath(projectId, componentHandler, subPath?)`
- `getSettingsPath(subPath?)`
- `getProjectSettingsPath(projectId, subPath?)`
- `getComponentSettingsPath(componentHandler, subPath?)`
- `getOrgLevelObservePath(subPath?)`
- `getProjectLevelObservePath(projectId, subPath?)`
- `getComponentLevelObservePath(projectId, componentId, subPath?)`
- `getCIODashboardPath(subPath?)`
- `getDataPlanesPath(subPath?)`
- `getInternalMarketplacePath()`
- ... and many more

---

## Migration Impact Analysis

### For ICP On-Prem Migration (Default Organization Approach)

#### 1. **Minimal URL Structure Changes**

With the "default organization" approach:

**Before (Devant - Multi-Org):**
```
/organizations/wso2/projects/api-project/components/user-service
/organizations/acme/projects/web-app/components/frontend
```

**After (ICP - Default Org):**
```
/organizations/default/projects/api-project/components/user-service
/organizations/default/projects/web-app/components/frontend
```

**Impact:** 
- ✅ URL structure preserved (no routing refactor needed)
- ✅ Route helper functions work as-is
- ✅ No bookmark breakage
- ⚠️ Need to hardcode `DEFAULT_ORG_HANDLE = 'default'` in config

---

#### 2. **Organization Context Simplification**

**Current Implementation:**
```typescript
// hooks/organizations.tsx
const useSelectedOrgHandle = () => {
  const { selectedOrg } = useContext(OrganizationContext);
  return selectedOrg?.handle; // Dynamic based on user selection
};
```

**Target Implementation (Default Org):**
```typescript
// config/index.ts
export const DEFAULT_ORG_HANDLE = 'default';
export const DEFAULT_ORG_NAME = 'Default Organization';

// hooks/organizations.tsx (simplified)
const useSelectedOrgHandle = () => DEFAULT_ORG_HANDLE; // Always 'default'
```

**Impact:**
- ✅ Simplifies organization context logic
- ✅ No organization switching UI needed
- ✅ Route generation still works (just returns hardcoded 'default')
- ⚠️ Organization scaffolding remains for future multi-tenancy

---

#### 3. **Route Components Requiring Updates**

**Files to Modify:**

1. **`utils/route.ts`** - Add default org constants
   ```typescript
   export const DEFAULT_ORG_HANDLE = 'default';
   export const DEFAULT_ORG_NAME = 'Default Organization';
   ```

2. **`hooks/organizations.tsx`** - Simplify org selection
   ```typescript
   export const useSelectedOrgHandle = () => DEFAULT_ORG_HANDLE;
   ```

3. **`contexts/OrganizationContext.tsx`** - Hardcode default org
   ```typescript
   const currentOrg = {
     handle: DEFAULT_ORG_HANDLE,
     name: DEFAULT_ORG_NAME,
     uuid: 'default-org-uuid'
   };
   ```

4. **`hooks/route.tsx`** - No changes needed (uses `useSelectedOrgHandle()`)

5. **Navigation Components** - Hide org selector, show "Default Organization"
   - `layouts/Main/Header.tsx` - Hide org dropdown
   - `components/Breadcrumbs.tsx` - Show "Default Organization"

---

#### 4. **Routes to Remove/Hide**

**Remove from UI (keep code structure):**
- Organization management pages
  - Create organization
  - Update organization settings
  - Delete organization
  - Organization invitations
- Organization selector dropdown
- Organization listing page (unless showing single default org)

**Keep (with default org context):**
- All project-level routes
- All component-level routes
- All observability routes
- All admin resource routes
- All settings routes (with project/component RBAC)

---

#### 5. **Route Testing Checklist**

After migration, verify all routes work with default org:

- [ ] `/organizations/default/home` - Organization home
- [ ] `/organizations/default/projects` - Project listing (RBAC filtered)
- [ ] `/organizations/default/projects/:projectId` - Project detail
- [ ] `/organizations/default/projects/:projectId/components` - Component list
- [ ] `/organizations/default/projects/:projectId/components/:componentId` - Component detail
- [ ] `/organizations/default/projects/:projectId/observe/metrics` - Project metrics
- [ ] `/organizations/default/projects/:projectId/components/:componentId/observe/metrics` - Component metrics
- [ ] `/organizations/default/observe/runtimelogs` - Org-level logs (RBAC filtered)
- [ ] `/organizations/default/admin/databases` - Admin resources (RBAC)
- [ ] `/organizations/default/settings` - Settings (RBAC)
- [ ] `/organizations/default/environments` - Environments (RBAC)

---

#### 6. **Route Generation Pattern Preservation**

**Key Principle:** All route generation functions remain functional with minimal changes.

**Example Migration:**
```typescript
// Before (Devant - user selects org)
const { getProjectPath } = useRoutePath();
const projectUrl = getProjectPath('my-project'); 
// → '/organizations/{selectedOrg}/projects/my-project'

// After (ICP - always default org)
const { getProjectPath } = useRoutePath();
const projectUrl = getProjectPath('my-project');
// → '/organizations/default/projects/my-project'
// Same function call, different orgHandle source!
```

**No changes needed to component code** - routing logic abstracted in hooks!

---

## Summary for Migration

### ✅ What Stays the Same:
1. URL structure: `/organizations/{orgHandle}/...`
2. Route helper functions in `utils/route.ts`
3. `useRoutePath()` hook API (all 80+ methods)
4. Route patterns for projects, components, observability
5. Nested routing structure
6. React Router v5 setup

### 🔄 What Changes:
1. Organization context always returns "default"
2. Organization selector hidden (not removed)
3. Breadcrumbs show "Default Organization"
4. URL generation uses hardcoded `DEFAULT_ORG_HANDLE`
5. Organization management pages hidden

### 📊 Migration Complexity: **LOW**
- **Reason:** Preserving organization scaffolding means minimal routing changes
- **Main Work:** Simplifying organization context and hiding UI elements
- **Benefit:** Future multi-tenancy requires only unhiding features

---

## Next Steps (Week 1)

1. ✅ Review this routing documentation
2. [ ] Create component inventory (which components use routing)
3. [ ] Identify all organization selector UI components
4. [ ] Map RBAC requirements to route access
5. [ ] Plan route guard/protection strategy for project-level RBAC
6. [ ] Begin Week 2 tasks (Backend refresh token implementation)

---

**End of Routing Structure Documentation**
