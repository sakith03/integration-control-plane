# Component Inventory: Devant Choreo-Console → ICP-Frontend

**Version:** 1.0  
**Date:** October 27, 2025  
**Branch:** icp2-auth  
**Status:** Planning Phase - Week 1

---

## Table of Contents

1. [Overview](#overview)
2. [Categorization Strategy](#categorization-strategy)
3. [Pages Inventory](#pages-inventory)
4. [Components Inventory](#components-inventory)
5. [Modules Inventory](#modules-inventory)
6. [Layout Components](#layout-components)
7. [Migration Priority Matrix](#migration-priority-matrix)
8. [Detailed Analysis by Category](#detailed-analysis-by-category)

---

## Overview

This document catalogs all pages, components, and modules in the Devant choreo-console application and categorizes them based on their migration strategy for the ICP on-premise deployment.

### Total Inventory Count:
- **Pages:** ~60 page components
- **Reusable Components:** ~100+ UI components
- **Modules:** ~35 feature modules
- **Layouts:** 3 main layout components

---

## Categorization Strategy

### 🟢 **MIGRATE** - Essential for ICP
Components that are critical for core functionality (projects, components, observability, settings) and must be migrated.

### 🟡 **ADAPT** - Keep with Modifications
Components that need RBAC enforcement or simplified organization logic. Keep the component but modify for default org and project-level permissions.

### 🟠 **HIDE** - Keep Code, Hide UI
Components related to organization management that should be hidden but preserved for future multi-tenancy support.

### 🔴 **REMOVE** - Delete from Codebase
Components specific to SaaS features (marketplace integrations, social login, growth hacking) that are not needed for on-premise deployment.

---

## Pages Inventory

### Authentication & Onboarding

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Login | `pages/login/Login.tsx` | 🟡 **ADAPT** | Replace Asgardeo multi-IdP with email + OIDC | **P0** |
| Signup | `pages/signup/` | 🔴 **REMOVE** | No self-service signup in on-prem | P3 |
| Signup Embedded | `pages/signup/signupEmbedded.tsx` | 🔴 **REMOVE** | Growth hacking feature | P3 |
| Accept Invitation | `pages/AcceptInvitation/` | 🟠 **HIDE** | Org invitations (keep for future) | P2 |
| VSCode Auth | `pages/vscode-auth/` | 🟢 **MIGRATE** | Developer tools integration | P1 |
| Editor Auth | `pages/editor-auth/` | 🟢 **MIGRATE** | Cloud editor integration | P1 |
| Register Organization | `pages/RegisterOrganization/` | 🟠 **HIDE** | Org creation (hide UI, keep logic) | P2 |

---

### Organization-Level Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Organization Home | `pages/OrganizationHome/` | 🟡 **ADAPT** | Default org dashboard | **P0** |
| Organization Listing | `pages/OrganizationListing/` | 🟠 **HIDE** | Shows resources, adapt for default org | P2 |
| Organization Architecture | `pages/OrganizationHome/OrgArchitectureDiagram/` | 🟢 **MIGRATE** | System architecture view | P1 |
| No Org Access | `pages/NoOrgAccess/` | 🟠 **HIDE** | Org switching UI (hide) | P2 |

---

### Project-Level Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Projects | `pages/Projects/Projects.tsx` | 🟢 **MIGRATE** | Core: project listing + RBAC filtering | **P0** |
| Project Home | `pages/ProjectHome/` | 🟢 **MIGRATE** | Project dashboard | **P0** |
| New Project | `pages/Projects/NewProject/` | 🟡 **ADAPT** | Project creation with RBAC | **P0** |
| Import Project | `pages/Projects/ImportProject/` | 🟢 **MIGRATE** | Import from Git | P1 |
| Project Routes | `pages/Projects/Projects.routes.tsx` | 🟡 **ADAPT** | Update for default org | **P0** |

---

### Component-Level Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Component Listing | `pages/ComponentListing/` | 🟢 **MIGRATE** | Component list with RBAC | **P0** |
| Component Create View | `modules/component/ComponentCreateView/` | 🟢 **MIGRATE** | Create components | **P0** |
| Component Overview | `modules/componentOverview/` | 🟢 **MIGRATE** | Component details | **P0** |
| Develop Component | `modules/developComponent/` | 🟢 **MIGRATE** | Component development | P1 |
| Build | `modules/build/` | � **REMOVE** | Build not provided in on-prem ICP | P3 |
| Deploy | `modules/deploy/` | � **REMOVE** | Deploy not provided in on-prem ICP | P3 |
| Test Component | `modules/testComponent/` | 🟢 **MIGRATE** | Testing interface | P1 |

---

### Observability Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Observability Routes | `pages/Observabilty/Observablilty.routes.tsx` | 🟢 **MIGRATE** | Metrics & logs routing | **P0** |
| Observe Project | `pages/Observabilty/ObserveProject.tsx` | 🟢 **MIGRATE** | Project-level metrics | **P0** |
| Organization Observability | `pages/OrganizationObservability/` | 🟡 **ADAPT** | Org-level metrics (RBAC filter) | **P0** |
| Logs Routes | `pages/Logs/Logs.routes.tsx` | 🟢 **MIGRATE** | Log viewer routing | **P0** |
| Logs View | `modules/observability/LogsView/` | 🟢 **MIGRATE** | Log streaming UI | **P0** |
| Observability Sample | `pages/Projects/ObservabilitySample/` | 🟢 **MIGRATE** | Sample app for testing | P2 |

---

### Analytics & Insights Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| CIO Dashboard | `pages/CIODashboard/` | 🟡 **ADAPT** | Executive insights (RBAC filter) | P1 |
| Operational Analytics | `pages/CIODashboard/OperationalAnalytics.tsx` | 🟡 **ADAPT** | Operations metrics | P1 |
| Business Insights | `pages/CIODashboard/BusinessInsights.tsx` | 🟡 **ADAPT** | Business metrics | P1 |
| DORA Metrics | `pages/CIODashboard/DORAMetrics.tsx` | 🟢 **MIGRATE** | DevOps metrics | P1 |
| Cost Insights | `pages/CostInsights/` | 🔴 **REMOVE** | Cloud cost tracking (not for on-prem) | P3 |
| Insights | `pages/Insights/` | 🟡 **ADAPT** | General analytics | P1 |

---

### Settings Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Settings | `pages/Settings/Settings.tsx` | 🟡 **ADAPT** | Org settings (adapt for default org) | **P0** |
| Settings Routes | `pages/Settings/Settings.routes.tsx` | 🟡 **ADAPT** | Settings routing | **P0** |
| Organization Select | `pages/Settings/OrganizationSelect/` | 🟠 **HIDE** | Org switcher (hide UI) | P2 |
| Access Control | `pages/Settings/AccessControl/` | 🟢 **MIGRATE** | User/role management | **P0** |
| Project Access Control | `pages/Settings/ProjectAccessControl/` | 🟢 **MIGRATE** | Project RBAC management | **P0** |
| Project Roles | `pages/Settings/ProjectRoles/` | 🟢 **MIGRATE** | Role assignment UI | **P0** |
| Identity Providers | `pages/Settings/IdentityProviders/` | 🟡 **ADAPT** | OIDC configuration | P1 |
| Application Security | `pages/Settings/ApplicationSecurity/` | 🟢 **MIGRATE** | Security settings | P1 |
| Credentials | `pages/Settings/Credentials/` | 🟢 **MIGRATE** | API keys, tokens | P1 |
| Onprem Keys | `pages/Settings/OnpremKeys/` | 🟢 **MIGRATE** | On-premise keys | **P0** |
| Project Overview | `pages/Settings/ProjectOverview/` | 🟢 **MIGRATE** | Project settings | **P0** |
| Project Settings | `pages/Settings/ProjectSettings.tsx` | 🟢 **MIGRATE** | Project configuration | **P0** |
| Config Management | `pages/Settings/ConfigManagement/` | 🟢 **MIGRATE** | Config groups | P1 |
| Approval Workflows | `pages/Settings/ApprovalWorkflows/` | 🟢 **MIGRATE** | Approval policies | P1 |

---

### Admin/DevOps Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Data Planes | `pages/DataPlanes/` | 🟢 **MIGRATE** | Data plane management | **P0** |
| Environments | `pages/Environments/` | 🟢 **MIGRATE** | Environment management | **P0** |
| Deployment Pipelines | `pages/DeploymentPipelines/` | 🟢 **MIGRATE** | CD pipelines | P1 |
| Connections | `pages/Connections/` | 🟢 **MIGRATE** | External connections | P1 |
| Message Brokers | `pages/MessageBrokers/` | 🟢 **MIGRATE** | Message broker setup | P1 |
| Automation Pipelines | `pages/AutomationPipelines/` | 🟢 **MIGRATE** | CI/CD automation | P1 |
| Config Groups | `pages/OrganizationDevOps/ConfigurationGroups/` | 🟢 **MIGRATE** | Configuration management | P1 |
| Tailscale VPN | `pages/TailscaleVpn/` | 🟢 **MIGRATE** | VPN configuration | P2 |

---

### Marketplace & External Integrations

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Internal Marketplace | `pages/InternalMarketplace/` | 🟢 **MIGRATE** | Service catalog (internal) | P1 |
| Marketplace | `pages/Marketplace/` | 🔴 **REMOVE** | External marketplace | P3 |
| Azure Subscription | `pages/AttachAzureSubscription/`, `pages/AwsSubscription*` | 🔴 **REMOVE** | Cloud subscriptions | P3 |
| GCP Subscription | `pages/GcpSubscription*` | 🔴 **REMOVE** | Cloud subscriptions | P3 |
| Marketplace Registration | `pages/MarketplaceRegistration/` | 🔴 **REMOVE** | SaaS marketplace | P3 |
| GitHub Auth Redirect | `pages/GitHubAuthRedirectView/` | 🔴 **REMOVE** | Social login redirect | P3 |

---

### Governance & Approvals

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| API Governance | `pages/ApiGovernance/` | 🟢 **MIGRATE** | API governance policies | P1 |
| Governance (General) | `modules/governance/` | 🟢 **MIGRATE** | Governance management | P1 |
| Approvals Container | `pages/Approvals/ApprovalsContainer.tsx` | 🟢 **MIGRATE** | Approval workflows | P1 |
| Approvals List | `pages/Approvals/ApprovalsListPage.tsx` | 🟢 **MIGRATE** | Pending approvals | P1 |
| Past Approvals | `pages/Approvals/PastApprovals.tsx` | 🟢 **MIGRATE** | Approval history | P1 |

---

### Special Views

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| PE Routes (Platform Engineer) | `pages/PERoutes/` | 🔴 **REMOVE** | Multi-perspective feature | P3 |
| PE Overview | `pages/PEOverview/` | 🔴 **REMOVE** | PE perspective | P3 |
| Developer Portal | `pages/DeveloperPortal/` | 🟢 **MIGRATE** | API consumer portal | P2 |
| Helm Marketplace | `pages/HelmMarketplace/` | 🟢 **MIGRATE** | Helm charts | P2 |
| Cloud Editor Deployment | `pages/CloudEditorDeployment/` | 🟢 **MIGRATE** | Browser-based editor | P2 |
| Alerts | `pages/Alerts/` | 🟢 **MIGRATE** | Alert configuration | P1 |

---

### Error & Utility Pages

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| Not Found | `pages/NotFoundPage/` | 🟢 **MIGRATE** | 404 page | **P0** |
| Internal Server Error | `pages/InternalServerError/` | 🟢 **MIGRATE** | 500 page | **P0** |
| Enterprise Error | `pages/EnterpriseError/` | 🔴 **REMOVE** | Enterprise-specific | P3 |
| Workspace Error | `pages/workspaceError/` | 🟢 **MIGRATE** | Workspace errors | P2 |
| Not Available | `pages/NotAvailable/` | 🟢 **MIGRATE** | Feature unavailable | P2 |
| Coming Soon | `pages/ComingSoonView/` | 🟢 **MIGRATE** | Feature preview | P2 |
| Pre-loader | `pages/preloader/` | 🟢 **MIGRATE** | Loading screen | **P0** |
| Maintenance | `pages/Maintenance/` | 🟢 **MIGRATE** | Maintenance mode | P2 |

---

### User Settings

| Page | Path | Category | Reason | Priority |
|------|------|----------|--------|----------|
| User Settings | `pages/user-settings/` | 🟢 **MIGRATE** | User profile/preferences | **P0** |
| User Settings Routes | `pages/user-settings/UserSettings.routes.tsx` | 🟢 **MIGRATE** | Settings routing | **P0** |

---

## Components Inventory

### Core UI Components (Reusable)

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Navigation Menu | `components/NavMenu/` | 🟡 **ADAPT** | Remove org selector, keep rest | **P0** |
| Page Header | `components/PageHeader/` | 🟢 **MIGRATE** | Page headers | **P0** |
| Page Container | `components/PageContainer/` | 🟢 **MIGRATE** | Page wrapper | **P0** |
| Page Breadcrumb | `components/PageBreadcrumb/` | 🟡 **ADAPT** | Update for default org | **P0** |
| Table | `components/Table/` | 🟢 **MIGRATE** | Data tables | **P0** |
| Search Field | `components/SearchField/` | 🟢 **MIGRATE** | Search UI | **P0** |
| Infinite Loader | `components/InfiniteLoader/` | 🟢 **MIGRATE** | Pagination | **P0** |
| Dialog Box | `components/DialogBox/` | 🟢 **MIGRATE** | Modal dialogs | **P0** |
| Confirmation Dialog | `components/ConfirmationDialog/` | 🟢 **MIGRATE** | Confirm actions | **P0** |
| Error Component | `components/ErrorComponent/` | 🟢 **MIGRATE** | Error display | **P0** |
| Error Boundary | `components/ErrorBoundary/` | 🟢 **MIGRATE** | Error handling | **P0** |
| Pre-Loader | `components/PreLoader/` | 🟢 **MIGRATE** | Loading indicators | **P0** |
| Notification | `components/Notification/` | 🟢 **MIGRATE** | Toasts/alerts | **P0** |
| Tooltip | `components/Tooltip/`, `components/TooltipV2/` | 🟢 **MIGRATE** | Tooltips | **P0** |

---

### Form Components

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Text Input | `components/TextInput/` | 🟢 **MIGRATE** | Text fields | **P0** |
| Text Area | `components/TextArea/` | 🟢 **MIGRATE** | Multi-line text | **P0** |
| Select | `components/Select/` | 🟢 **MIGRATE** | Dropdown select | **P0** |
| Selector | `components/Selector/` | 🟢 **MIGRATE** | Custom selectors | **P0** |
| Dropdown | `components/DropDown/` | 🟢 **MIGRATE** | Dropdowns | **P0** |
| Radio Group | `components/RadioGroup/` | 🟢 **MIGRATE** | Radio buttons | **P0** |
| Switch | `components/Switch/`, `components/PrimarySwitch/` | 🟢 **MIGRATE** | Toggle switches | **P0** |
| Editable Text Area | `components/EditableTextArea/` | 🟢 **MIGRATE** | Inline editing | P1 |
| Editable Key-Value Input | `components/EditableKeyValueInput/` | 🟢 **MIGRATE** | Config editing | P1 |
| Form Fields | `components/FormFields/` | 🟢 **MIGRATE** | Form utilities | **P0** |
| Auto Complete | `components/AutoCompleteWithChips/` | 🟢 **MIGRATE** | Autocomplete | P1 |
| Chip Input | `components/ChipInput/` | 🟢 **MIGRATE** | Tag input | P1 |
| Drop Zone | `components/DropZone/` | 🟢 **MIGRATE** | File upload | P1 |
| Date Range Picker | `components/DateRangePicker/` | 🟢 **MIGRATE** | Date selection | P1 |

---

### Observability Components

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Infinite Logs Panel | `components/InfiniteLogsPanel/` | 🟢 **MIGRATE** | Log streaming | **P0** |
| Logs View Components | `components/LogsViewComponents/` | 🟢 **MIGRATE** | Log filtering/display | **P0** |
| Observability Header | `components/ObservabilityHeader/` | 🟢 **MIGRATE** | Observability nav | **P0** |
| Pie Charts | `components/PieCharts/` | 🟢 **MIGRATE** | Chart visualization | P1 |

---

### Deployment & DevOps Components

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Deployment Track Picker | `components/DeploymentTrackPicker/` | 🔴 **REMOVE** | Deploy not provided in on-prem ICP | P3 |
| Deployment Track List | `components/DeploymentTrackList/` | 🔴 **REMOVE** | Deploy not provided in on-prem ICP | P3 |
| Deploy Status Box | `components/DeployStatusBox/` | 🟢 **MIGRATE** | Useful for runtime status display | P1 |
| Deployment Status Wrapper | `components/DeploymentStatusWrapper/` | 🟢 **MIGRATE** | Useful for runtime status UI | P1 |
| Version Picker | `components/VersionPicker/` | 🟢 **MIGRATE** | Version selection | P1 |
| Version List | `components/VersionList/` | 🟢 **MIGRATE** | Version history | P1 |
| Branch Selector | `components/BranchSelector/` | 🟢 **MIGRATE** | Git branch picker | P1 |
| Commit Detail Box | `components/CommitDetailBox/` | 🟢 **MIGRATE** | Commit info | P1 |
| Config Groups Button | `components/ConfigGroupsButton/` | 🟢 **MIGRATE** | Config management | P1 |

---

### Component Management

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Component Selector | `components/ComponentSelector/` | 🟢 **MIGRATE** | Component picker | **P0** |
| Component Labels | `components/ComponentLabels/` | 🟢 **MIGRATE** | Component tags | P1 |
| Template Card | `components/TemplateCard/` | 🟢 **MIGRATE** | Component templates | **P0** |

---

### Utility Components

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Copy to Clipboard | `components/CopyToClipboard/` | 🟢 **MIGRATE** | Copy buttons | **P0** |
| Truncate Text | `components/TruncateText/` | 🟢 **MIGRATE** | Text ellipsis | **P0** |
| Status Indicator | `components/StatusIndicator/` | 🟢 **MIGRATE** | Status badges | **P0** |
| Progress Bar | `components/ProgressBar/` | 🟢 **MIGRATE** | Progress UI | P1 |
| Circular Loading | `components/CircularLoading/` | 🟢 **MIGRATE** | Spinners | **P0** |
| Horizontal Stepper | `components/HorizontalStepper/` | 🟢 **MIGRATE** | Wizard steps | P1 |
| Custom Stepper | `components/CustomStepper/` | 🟢 **MIGRATE** | Custom wizards | P1 |
| Split Views | `components/splitViews/` | 🟢 **MIGRATE** | Split pane layouts | P1 |
| Markdown | `components/Markdown/` | 🟢 **MIGRATE** | Markdown rendering | P1 |

---

### Banners & Notifications

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Notification Banner | `components/NotificationBanner/` | 🟢 **MIGRATE** | System banners | **P0** |
| Info Banner | `components/InfoBanner/` | 🟢 **MIGRATE** | Info messages | **P0** |
| Warning Banner | `components/WarningBanner/` | 🟢 **MIGRATE** | Warnings | **P0** |
| Error Banner | `components/ErrorBanner/` | 🟢 **MIGRATE** | Error messages | **P0** |
| Mobile Users Banner | `components/MobileUsersBanner/` | 🟢 **MIGRATE** | Mobile warning | P2 |
| Heavy Traffic Banner | `components/HeavyTrafficBanner/` | 🔴 **REMOVE** | SaaS-specific | P3 |
| Email Consent | `components/EmailConsent/` | 🔴 **REMOVE** | Marketing feature | P3 |
| ToS Consent | `components/ToSConsent/` | 🟡 **ADAPT** | Terms acceptance | P2 |
| Demo Org Viewer Notification | `pages/DemoOrgViewerNotification/` | 🔴 **REMOVE** | Demo org feature | P3 |

---

### Authentication & User

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Idle Timeout Dialog | `components/IdleTimeoutDialog/` | 🟢 **MIGRATE** | Session timeout | **P0** |

---

### Third-Party Integrations

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| HotJar | `components/HotJar/` | 🔴 **REMOVE** | Analytics tracking | P3 |
| Swagger Import | `components/SwaggerImport/` | 🟢 **MIGRATE** | API import | P1 |

---

### Design System

| Component | Path | Category | Reason | Priority |
|-----------|------|----------|--------|----------|
| Choreo System | `components/ChoreoSystem/` | 🟢 **MIGRATE** | Design system components | **P0** |
| Custom Icons | `components/CustomIcons/` | 🟢 **MIGRATE** | Icon library | **P0** |

---

## Modules Inventory

### Core Modules

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| Component | `modules/component/` | 🟢 **MIGRATE** | Component management | **P0** |
| Component Overview | `modules/componentOverview/` | 🟢 **MIGRATE** | Component details | **P0** |
| Develop Component | `modules/developComponent/` | 🟢 **MIGRATE** | Development UI | P1 |
| Manage Component | `modules/manageComponent/` | 🟢 **MIGRATE** | Component config | **P0** |
| Build | `modules/build/` | � **REMOVE** | Build not provided in on-prem ICP | P3 |
| Deploy | `modules/deploy/` | � **REMOVE** | Deploy not provided in on-prem ICP | P3 |
| Test Component | `modules/testComponent/` | 🟢 **MIGRATE** | Testing | P1 |
| Project | `modules/project/` | 🟢 **MIGRATE** | Project management | **P0** |
| Observability | `modules/observability/` | 🟢 **MIGRATE** | Metrics & logs | **P0** |
| Settings | `modules/settings/` | 🟡 **ADAPT** | Settings (adapt for default org) | **P0** |

---

### DevOps Modules

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| DevOps | `modules/devops/` | 🟢 **MIGRATE** | DevOps workflows | P1 |
| Organization DevOps | `modules/organizationDevOps/` | 🟡 **ADAPT** | Org-level DevOps (RBAC) | P1 |
| Automation Pipelines | `modules/AutomationPipelines/` | 🟢 **MIGRATE** | CI/CD | P1 |
| Executions | `modules/executions/` | 🟢 **MIGRATE** | Pipeline runs | P1 |

---

### Governance & Security

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| API Governance | `modules/ApiGovernance/` | 🟢 **MIGRATE** | API policies | P1 |
| Governance | `modules/governance/` | 🟢 **MIGRATE** | Governance management | P1 |
| Access Control | `modules/accessControl/` | 🟢 **MIGRATE** | RBAC management | **P0** |
| Approvals | `modules/Approvals/` | 🟢 **MIGRATE** | Approval workflows | P1 |
| Endpoint Security | `modules/endpointSecurity/` | 🟢 **MIGRATE** | API security | P1 |
| Mediation | `modules/mediation/` | 🟢 **MIGRATE** | API mediation | P1 |

---

### Integrations & Resources

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| Connections | `modules/connections/` | 🟢 **MIGRATE** | External connections | P1 |
| Message Brokers | `modules/messageBrokers/` | 🟢 **MIGRATE** | Message brokers | P1 |
| Internal Marketplace | `modules/internalMarketplace/` | 🟢 **MIGRATE** | Service catalog | P1 |

---

### Analytics & Monitoring

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| CIO Dashboard | `modules/cioDashboard/` | 🟡 **ADAPT** | Analytics (RBAC filter) | P1 |
| Cost Insights | `modules/costInsights/` | 🔴 **REMOVE** | Cloud cost (not for on-prem) | P3 |
| Alerts | `modules/alerts/` | 🟢 **MIGRATE** | Alert management | P1 |

---

### Authentication & User Management

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| Login | `modules/login/` | 🟡 **ADAPT** | Replace Asgardeo | **P0** |
| Signup | `modules/signup/` | 🔴 **REMOVE** | No self-service signup | P3 |
| Invitation | `modules/invitation/` | 🟠 **HIDE** | Org invitations | P2 |
| Organization | `modules/organization/` | 🟠 **HIDE** | Org management | P2 |

---

### Special Features

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| PE Perspective | `modules/PEPerspective/` | 🔴 **REMOVE** | Multi-perspective feature | P3 |
| AI Copilot | `modules/aiCopilot/` | 🟢 **MIGRATE** | AI assistance | P2 |
| Feature Preview | `modules/FeaturePreview/` | 🟢 **MIGRATE** | Beta features | P2 |
| Tailscale VPN | `modules/tailscaleVpn/` | 🟢 **MIGRATE** | VPN setup | P2 |

---

### Utilities

| Module | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| Shared | `modules/shared/` | 🟢 **MIGRATE** | Shared utilities | **P0** |
| Isolated Modules | `modules/isolatedModules/` | 🟢 **MIGRATE** | Isolated features | P1 |
| Deferred Root | `modules/deferredRoot/` | 🟡 **ADAPT** | Lazy loading root | **P0** |
| Root Error Boundary | `modules/RootErrorBoundary/` | 🟢 **MIGRATE** | Error handling | **P0** |

---

## Layout Components

| Layout | Path | Category | Reason | Priority |
|--------|------|----------|--------|----------|
| Main Layout | `layouts/Main/Main.tsx` | 🟡 **ADAPT** | App layout (remove org selector) | **P0** |
| Header | `layouts/components/Header/` | 🟡 **ADAPT** | Header (hide org dropdown) | **P0** |
| Main Left Nav | `layouts/components/MainLeftNav/` | 🟡 **ADAPT** | Sidebar navigation | **P0** |
| Right Nav | `layouts/components/RightNav/` | 🟢 **MIGRATE** | Right sidebar | P1 |
| Footer | `layouts/components/Footer/` | 🟢 **MIGRATE** | Footer | P2 |
| Page Layout | `layouts/Page.tsx` | 🟢 **MIGRATE** | Page wrapper | **P0** |

---

## Migration Priority Matrix

### Priority 0 (P0) - Critical Path - Week 2-5

**Must be completed for MVP functionality**

**Backend:**
- Refresh token implementation (Week 2-3)

**Frontend:**
- Authentication flow replacement (Week 3-4)
  - `modules/login/` (adapt)
  - `pages/login/Login.tsx` (adapt)
- Default organization implementation (Week 4-5)
  - `layouts/Main/Main.tsx` (adapt)
  - `layouts/components/Header/` (adapt - hide org selector)
  - `components/PageBreadcrumb/` (adapt - show "Default Organization")
  - `components/NavMenu/` (adapt - remove org switching)
- Core project management (Week 5-6)
  - `pages/Projects/` (migrate)
  - `pages/ProjectHome/` (migrate)
  - `modules/project/` (migrate)
- Component management (Week 5-6)
  - `pages/ComponentListing/` (migrate)
  - `modules/component/` (migrate)
  - `modules/componentOverview/` (migrate)
  - `modules/manageComponent/` (migrate)
- Observability (Week 6-7)
  - `pages/Observabilty/` (migrate)
  - `pages/Logs/` (migrate)
  - `modules/observability/` (migrate)
  - `components/InfiniteLogsPanel/` (migrate)
- Settings & Access Control (Week 7-8)
  - `pages/Settings/` (adapt)
  - `pages/Settings/AccessControl/` (migrate)
  - `pages/Settings/ProjectAccessControl/` (migrate)
  - `pages/Settings/ProjectRoles/` (migrate)
  - `modules/accessControl/` (migrate)
- Core UI components (Week 6-7)
  - Design system (`components/ChoreoSystem/`)
  - Tables, forms, dialogs
  - Error handling, notifications
  - Loading indicators

**Count:** ~38 critical components (Build & Deploy removed)

---

### Priority 1 (P1) - Essential Features - Week 6-8

**Important for production readiness**

- Testing interface (`modules/testComponent/`)
- Runtime status components (`components/DeployStatusBox/`, `components/DeploymentStatusWrapper/`)
- DevOps workflows (`modules/devops/`, `modules/organizationDevOps/`)
- Analytics & insights (`modules/cioDashboard/`, `pages/Insights/`)
- Governance (`modules/governance/`, `modules/ApiGovernance/`)
- Approvals (`modules/Approvals/`, `pages/Approvals/`)
- Admin resources
  - Data planes (`pages/DataPlanes/`)
  - Environments (`pages/Environments/`)
  - Connections (`modules/connections/`, `pages/Connections/`)
  - Message brokers (`modules/messageBrokers/`, `pages/MessageBrokers/`)
- Identity providers (`pages/Settings/IdentityProviders/`)
- Security settings (`pages/Settings/ApplicationSecurity/`)
- Internal marketplace (`modules/internalMarketplace/`, `pages/InternalMarketplace/`)
- Version management (`components/VersionPicker/`, `components/VersionList/`)
- Git integration (`components/BranchSelector/`, `components/CommitDetailBox/`)

**Count:** ~50 components

---

### Priority 2 (P2) - Nice to Have - Week 8-9

**Can be added post-MVP**

- Organization invitation flow (hidden but functional)
- Organization management UI (hidden)
- Developer portal (`pages/DeveloperPortal/`)
- Helm marketplace (`pages/HelmMarketplace/`)
- Cloud editor (`pages/CloudEditorDeployment/`)
- AI Copilot (`modules/aiCopilot/`)
- Feature preview (`modules/FeaturePreview/`)
- Tailscale VPN (`modules/tailscaleVpn/`, `pages/TailscaleVpn/`)
- Terms of Service consent (`components/ToSConsent/`)

**Count:** ~20 components

---

### Priority 3 (P3) - Remove/Skip - Post-Migration Cleanup

**Not needed for on-premise deployment**

- Build & Deploy features (not provided in on-prem ICP)
  - `modules/build/`
  - `modules/deploy/`
  - `components/DeploymentTrackPicker/`
  - `components/DeploymentTrackList/`
- All marketplace subscriptions (Azure, AWS, GCP)
  - `pages/AttachAzureSubscription/`
  - `pages/AwsSubscription*/`
  - `pages/GcpSubscription*/`
  - `pages/MarketplaceRegistration/`
- Social login features
  - `pages/GitHubAuthRedirectView/`
  - Multi-IdP in `pages/login/` (keep OIDC only)
- Self-service signup
  - `pages/signup/`
  - `modules/signup/`
- Growth hacking features
  - `pages/signup/signupEmbedded*`
  - `components/EmailConsent/`
- SaaS-specific features
  - `components/HeavyTrafficBanner/`
  - `pages/DemoOrgViewerNotification/`
  - `pages/EnterpriseError/`
- Multi-perspective (PE view)
  - `pages/PERoutes/`
  - `pages/PEOverview/`
  - `modules/PEPerspective/`
- Cloud cost tracking
  - `pages/CostInsights/`
  - `modules/costInsights/`
- External marketplace
  - `pages/Marketplace/`
- Analytics tracking
  - `components/HotJar/`

**Count:** ~34 components to remove

---

## Detailed Analysis by Category

### 🟢 MIGRATE (Direct Migration) - ~100 components

**Characteristics:**
- Core functionality needed for ICP
- No organization-specific logic
- Project/component-scoped features
- Infrastructure management
- Observability and monitoring

**Examples:**
- Project listing and management
- Component CRUD operations
- Metrics and logs
- Testing interface
- Data planes
- Environments
- Settings (non-org)

**Effort:** Medium to Low
- Code can be migrated as-is with minimal changes
- May need RBAC filtering added for list views
- Update API endpoints to ICP server

---

### 🟡 ADAPT (Modify for Default Org) - ~30 components

**Characteristics:**
- Organization-aware routing
- Organization context dependencies
- Navigation components
- Settings with org scope
- Analytics with org-level views

**Required Changes:**
1. Replace `useSelectedOrgHandle()` with hardcoded "default"
2. Update organization context to single default org
3. Add RBAC filtering for project-scoped data
4. Simplify breadcrumbs (show "Default Organization")
5. Update route generation to use default org

**Examples:**
- `layouts/Main/Main.tsx` - Remove org selector from header
- `layouts/components/Header/` - Hide org dropdown
- `pages/OrganizationHome/` - Adapt for default org dashboard
- `pages/Settings/Settings.tsx` - Update org settings for default org
- `modules/login/` - Replace Asgardeo with email + OIDC
- `modules/cioDashboard/` - Add RBAC filtering

**Effort:** Medium
- Straightforward changes to organization context
- RBAC filtering may require backend queries
- Testing needed for all adapted routes

---

### 🟠 HIDE (Keep Code, Hide UI) - ~15 components

**Characteristics:**
- Organization management features
- Organization switching UI
- Organization invitations
- Multi-tenancy scaffolding

**Implementation Strategy:**
1. Keep all code and components
2. Remove from navigation menus
3. Hide UI elements (buttons, dropdowns)
4. Comment out routes (don't delete)
5. Document for future use

**Examples:**
- `pages/Settings/OrganizationSelect/` - Organization selector
- `pages/RegisterOrganization/` - Org creation
- `pages/AcceptInvitation/` - Org invitations
- `pages/NoOrgAccess/` - Org access errors
- `modules/organization/` - Org management
- Organization dropdown in header

**Effort:** Low
- Simply hide UI components
- No code deletion
- Easy to re-enable later

---

### 🔴 REMOVE (Delete from Codebase) - ~30 components

**Characteristics:**
- SaaS-specific features
- Cloud marketplace integrations
- Social login redirects
- Growth hacking features
- Multi-perspective UI

**Deletion Strategy:**
1. Remove component files
2. Remove from imports
3. Remove route definitions
4. Remove from navigation
5. Clean up dependencies in package.json

**Examples:**
- Build & Deploy modules (on-prem does not provide these features)
- All Azure/AWS/GCP subscription pages
- Embedded signup flows
- GitHub auth redirect
- PE perspective routes
- Cost insights (cloud cost)
- HotJar analytics
- Email consent
- Heavy traffic banner
- Deployment track picker/list (not status display components)

**Effort:** Low
- Clean deletion
- No dependencies on kept code
- Reduces bundle size significantly

---

## Summary Statistics

### Component Count by Category:

| Category | Pages | Components | Modules | Total | Percentage |
|----------|-------|------------|---------|-------|------------|
| 🟢 **MIGRATE** | ~33 | ~48 | ~18 | ~99 | **50%** |
| 🟡 **ADAPT** | ~12 | ~8 | ~10 | ~30 | **15%** |
| 🟠 **HIDE** | ~5 | ~5 | ~5 | ~15 | **8%** |
| 🔴 **REMOVE** | ~17 | ~12 | ~7 | ~36 | **18%** |
| **Uncategorized** | ~3 | ~27 | ~0 | ~20 | **10%** |
| **TOTAL** | **~70** | **~100** | **~40** | **~200** | **100%** |

### Migration Effort Distribution:

| Priority | Count | Weeks | Team Size | Effort |
|----------|-------|-------|-----------|--------|
| **P0 (Critical)** | ~38 | 2-5 | 2-3 devs | High |
| **P1 (Essential)** | ~50 | 6-8 | 2-3 devs | Medium |
| **P2 (Nice to Have)** | ~20 | 8-9 | 1-2 devs | Low |
| **P3 (Remove)** | ~36 | 8 | 1 dev | Low |

### Bundle Size Impact:

**Estimated Reduction:**
- Remove ~36 components (P3)
- Remove `@asgardeo/auth-react` SDK
- Remove Build & Deploy modules
- Remove multi-perspective feature
- Remove marketplace integrations
- Remove deployment track picker/list (keeping status display components)

**Expected Savings:** ~25-35% bundle size reduction

---

## Next Steps (Week 1)

1. ✅ Document current routing structure (completed)
2. ✅ Create component inventory (this document)
3. [ ] Set up development database with default organization
4. [ ] Create detailed ADRs (Architecture Decision Records)
5. [ ] Begin Week 2 tasks (Backend refresh token implementation)

---

**End of Component Inventory**
