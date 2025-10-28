# Migration Plan: Devant/Choreo-Console → ICP-Frontend (On-Prem)

**Version:** 1.1  
**Date:** October 27, 2025  
**Status:** Planning  
**Branch:** `icp2-auth`

---

## Executive Summary

This plan outlines the migration from the **Devant choreo-console** (multi-organization SaaS) to a simplified **ICP-frontend** (single-organization on-premise) authentication and authorization model. The migration involves replacing Asgardeo-based multi-org authentication with a **single default organization** and project-level RBAC, while maintaining OIDC support and token exchange mechanisms.

**Key Decision:** We will **retain the organization layer** with a single "default" organization to preserve multi-tenancy scaffolding for future enhancements while simplifying the current implementation.

---

## Table of Contents

1. [Current State Analysis](#1-current-state-analysis)
2. [Target Architecture](#2-target-architecture)
3. [Migration Strategy](#3-migration-strategy)
4. [Implementation Roadmap](#4-implementation-roadmap)
5. [Key Considerations & Risks](#5-key-considerations--risks)
6. [Success Criteria](#6-success-criteria)
7. [Post-Migration Tasks](#7-post-migration-tasks)
8. [Appendix](#8-appendix)

---

## 1. Current State Analysis

### 1.1 Devant/Choreo-Console (Source System)

#### Authentication Flow:
- **Identity Provider:** Asgardeo (WSO2's cloud IdP)
- **Protocol:** OAuth 2.0 / OIDC with PKCE
- **SDK:** `@asgardeo/auth-react` v5.2.3
- **Token Storage:** Web Worker (access token), sessionStorage (refresh token)
- **Session Management:** ISK-based session extension (8-hour intervals)

#### Authorization Model:
- **Multi-organization:** Users belong to multiple organizations
- **Organization-scoped tokens:** Two-step token exchange:
  1. Asgardeo authentication → user-level token
  2. Token exchange with STS → organization-scoped token
- **Permission Model:** Organization → Project → Component
- **Token Claims:** `org`, `sub`, `scope`, `email`, `groups`

#### Key Features:
- Multiple login methods (Google, GitHub, Microsoft, Email, Enterprise SSO, Anonymous)
- **Organization switching**
- Role-based access at organization level
- Marketplace integrations (Azure, AWS, GCP)

### 1.2 ICP-Server (Target System)

#### Authentication:
- **Pluggable Backend:** Custom authentication backend (default + LDAP/OIDC)
- **OIDC Support:** Already implemented for external IdP integration
- **Token Format:** JWT with HMAC-SHA256 signature
- **Token Expiry:** Configurable (default in config)
- **⚠️ Missing:** Refresh token mechanism (only access token currently issued)

#### Authorization Model:
- **Project-centric RBAC:** `project:environment_type:privilege_level`
- **Environment Types:** `prod` (production), `non-prod` (development/staging)
- **Privilege Levels:** `admin`, `developer` (viewer)
- **Special Roles:** 
  - `isSuperAdmin`: System-wide admin
  - `isProjectAuthor`: Can create projects

#### JWT Token Structure (Current):
```json
{
  "sub": "user-uuid",
  "iss": "icp-server",
  "aud": "icp-frontend",
  "exp": 1234567890,
  "username": "john@example.com",
  "displayName": "John Doe",
  "isSuperAdmin": false,
  "isProjectAuthor": true,
  "roles": [
    {
      "roleId": "uuid",
      "projectId": "proj-123",
      "environmentType": "prod",
      "privilegeLevel": "admin"
    }
  ]
}
```

---

## 2. Target Architecture

### 2.1 Default Organization Model

**Concept:** Maintain the organization layer with a single "default" organization that encompasses all users and projects.

#### Key Characteristics:
- **Single Organization:** All users belong to `organization: "default"`
- **No Organization Switching:** UI removes org selector, but routing preserves org context
- **URL Structure Preserved:** `/organizations/default/projects/...`
- **Database:** Organization table exists but contains only one entry: `default`
- **Future-Proof:** Scaffolding remains for potential multi-tenancy support

#### Benefits:
- ✅ Smaller migration scope (preserve routing structure)
- ✅ No URL structure changes (no broken bookmarks)
- ✅ Future multi-tenancy support possible
- ✅ Gradual migration path (can add orgs later)
- ✅ Less frontend refactoring required

### 2.2 Project-Level RBAC

**Authorization Hierarchy:**
```
Default Organization
  └─ Projects (global within the org)
      └─ Environments (Prod / Non-Prod)
          └─ Components
              └─ Runtimes
```

**Access Control:**
- Users have **project-scoped roles** within the default organization
- Each role specifies: `projectId` + `environmentType` + `privilegeLevel`
- Examples:
  - `project-x:prod:admin` - Admin in project X's production environments
  - `project-y:non-prod:developer` - Developer (view-only) in project Y's non-prod environments

### 2.3 Default Organization Implementation

#### Database Schema:
```sql
-- Organizations table (single row)
CREATE TABLE organizations (
    org_id VARCHAR(255) PRIMARY KEY DEFAULT 'default',
    org_name VARCHAR(255) NOT NULL DEFAULT 'Default Organization',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT single_org CHECK (org_id = 'default')
);

-- Seed data
INSERT INTO organizations (org_id, org_name) 
VALUES ('default', 'Default Organization');
```

#### Frontend Context:
```typescript
// Simplified organization context (always "default")
interface OrganizationContextType {
  currentOrg: Organization;  // Always { id: 'default', name: 'Default Organization' }
  // Remove: switchOrganization()
  // Remove: availableOrganizations
}
```

---

## 3. Migration Strategy

### Phase 1: Frontend Architecture Changes

#### 3.1 Simplify Organization Concepts (Retain Scaffolding)

**Files/Components to Modify:**
- ~~Remove: Organization selector components~~ **Hide** organization selector (keep code)
- ~~Remove: Organization context~~ **Simplify** organization context (single default org)
- **Keep:** Organization-based routing (`/organizations/default/...`)
- **Keep:** Organization context structure (for future use)

**URL Structure:**
```
Current: /organizations/{dynamicOrgHandle}/projects/proj-1/components/comp-1
Target:  /organizations/default/projects/proj-1/components/comp-1
                        ^^^^^^^^ (hardcoded)
```

**Implementation Strategy:**
```typescript
// config.ts
export const DEFAULT_ORG_HANDLE = 'default';
export const DEFAULT_ORG_NAME = 'Default Organization';

// OrganizationContext.tsx
const OrganizationProvider = ({ children }) => {
  // Always use default organization
  const currentOrg = {
    handle: DEFAULT_ORG_HANDLE,
    name: DEFAULT_ORG_NAME,
    uuid: 'default-uuid'
  };
  
  // No organization switching logic needed
  return (
    <OrgContext.Provider value={{ currentOrg }}>
      {children}
    </OrgContext.Provider>
  );
};
```

#### 3.2 Replace Asgardeo SDK

**Current:** `@asgardeo/auth-react` with complex multi-org token exchange

**Target:** Simplified authentication flow similar to existing `icp-frontend/AuthContext.tsx`

**Approach:**
1. **Keep OIDC Support:** Leverage existing ICP server's OIDC implementation
2. **Remove Multi-Step Token Exchange:** Single authentication → single JWT
3. **Remove Asgardeo-Specific Features:**
   - ISK session extension (replace with refresh token)
   - Organization token exchange (not needed with default org)
   - Multi-IdP federation (keep only needed options)
4. **Add Refresh Token Support:** Implement proper refresh token flow

**Recommended Frontend Auth Flow:**
```typescript
// Simplified AuthContext (similar to existing icp-frontend)
interface AuthContextType {
  user: AuthUser | null;
  login: (credentials: Credentials) => Promise<void>;
  loginWithOIDC: () => void;
  logout: () => void;
  refreshToken: () => Promise<void>;  // New implementation
  isAuthenticated: boolean;
}

interface AuthUser {
  userId: string;
  username: string;
  displayName: string;
  token: string;           // Access token (JWT)
  refreshToken: string;    // NEW: Refresh token
  expiresAt: number;       // Access token expiry
  refreshExpiresAt: number; // NEW: Refresh token expiry
  roles: ProjectRole[];
  isSuperAdmin: boolean;
  isProjectAuthor: boolean;
}

interface ProjectRole {
  roleId: string;
  projectId: string;
  projectName: string;  // For better UX
  environmentType: 'prod' | 'non-prod';
  privilegeLevel: 'admin' | 'developer';
}
```

#### 3.3 Project-Based Access Control in UI

**Authorization Checks:**
```typescript
// Helper functions for UI authorization
function canViewProject(user: AuthUser, projectId: string): boolean {
  return user.isSuperAdmin || 
         user.roles.some(r => r.projectId === projectId);
}

function canAdminEnvironment(
  user: AuthUser, 
  projectId: string, 
  envType: 'prod' | 'non-prod'
): boolean {
  return user.isSuperAdmin || 
         user.roles.some(r => 
           r.projectId === projectId && 
           r.environmentType === envType && 
           r.privilegeLevel === 'admin'
         );
}

function canCreateProject(user: AuthUser): boolean {
  return user.isSuperAdmin || user.isProjectAuthor;
}

function getAccessibleProjects(user: AuthUser): string[] {
  if (user.isSuperAdmin) return ['*']; // All projects
  return [...new Set(user.roles.map(r => r.projectId))];
}
```

**UI Components to Update:**
- Project list: Filter by accessible projects
- Component list: Show only components in accessible projects
- Environment views: Restrict based on environment type permissions
- User management: Show only users with shared project access (if not super admin)

#### 3.4 Navigation & Layout Simplification

**Changes:**
- ~~Remove organization breadcrumbs~~ **Keep** breadcrumbs with hardcoded "Default Organization"
- **Hide** organization selector (keep component for future)
- Simplify sidebar navigation (no org switching, but preserve org routing)
- Update main navigation to be project-centric:
  ```
  Home (redirects to /organizations/default/projects)
  ├─ Projects (list all accessible)
  ├─ Runtimes (filtered by accessible projects)
  ├─ Environments (global view with RBAC filtering)
  ├─ Observability
  │   ├─ Metrics
  │   └─ Logs
  └─ Settings
      ├─ Profile
      └─ Users (if admin/super admin)
  ```

---

### Phase 2: Backend Token Enhancement

#### 3.5 ICP-Server Refresh Token Implementation

**Current State:** ICP server issues only access tokens (JWT)
- ✅ Custom authentication backend integration
- ✅ OIDC support (`/auth/login/oidc`)
- ✅ JWT generation with project-scoped roles
- ❌ **Missing:** Refresh token generation and validation

**Enhancement Required:** Implement refresh token mechanism

##### 3.5.1 Refresh Token Flow Design

**Token Pair Structure:**
```ballerina
type LoginResponse record {
    string accessToken;        // Short-lived JWT (15-60 minutes)
    string refreshToken;       // Long-lived opaque token (7-30 days)
    int accessTokenExpiresIn;  // Seconds until access token expires
    int refreshTokenExpiresIn; // Seconds until refresh token expires
    string username;
    string displayName;
    Role[] roles;
    boolean isSuperAdmin;
    boolean isProjectAuthor;
    boolean isOidcUser;
};
```

**Database Schema Addition:**
```sql
CREATE TABLE refresh_tokens (
    token_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,  -- SHA256 hash of token
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMP NULL,
    user_agent VARCHAR(500),
    ip_address VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_token_hash (token_hash),
    INDEX idx_expires_at (expires_at)
);

-- Cleanup job for expired tokens (run periodically)
-- DELETE FROM refresh_tokens WHERE expires_at < NOW() OR revoked = TRUE;
```

##### 3.5.2 Backend Implementation Tasks

**New Endpoints:**
1. **POST `/auth/refresh-token`** - Exchange refresh token for new access token
2. **POST `/auth/revoke-token`** - Revoke a refresh token (logout)

**Modified Endpoints:**
1. **POST `/auth/login`** - Return both access and refresh tokens
2. **POST `/auth/login/oidc`** - Return both access and refresh tokens

**Implementation Steps:**
```ballerina
// 1. Generate refresh token (cryptographically random)
isolated function generateRefreshToken() returns string {
    // Generate 256-bit random token
    // Return base64-encoded string
}

// 2. Store refresh token in database
isolated function storeRefreshToken(
    string userId, 
    string token, 
    int expirySeconds,
    string? userAgent,
    string? ipAddress
) returns error? {
    string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
    // Insert into refresh_tokens table
}

// 3. Validate refresh token
isolated function validateRefreshToken(string token) 
    returns types:User|http:Unauthorized {
    string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
    // Query database for token_hash
    // Check expiry and revoked status
    // Update last_used_at
    // Return user details
}

// 4. Revoke refresh token
isolated function revokeRefreshToken(string token) returns error? {
    string tokenHash = crypto:hashSha256(token.toBytes()).toBase16();
    // UPDATE refresh_tokens SET revoked = TRUE, revoked_at = NOW()
}
```

**Modified Login Response:**
```ballerina
// auth_service.bal - login endpoint
isolated resource function post login(types:Credentials credentials) 
    returns http:Ok|http:Unauthorized|http:InternalServerError|error {
    // ... existing authentication logic ...
    
    // Generate access token (existing)
    string|error jwtToken = utils:generateJWTToken(...);
    
    // NEW: Generate refresh token
    string refreshToken = check utils:generateRefreshToken();
    
    // NEW: Store refresh token in database
    check storage:storeRefreshToken(
        userDetails.userId, 
        refreshToken, 
        refreshTokenExpiryTime,  // e.g., 7 days
        // Extract from request headers:
        userAgent,
        ipAddress
    );
    
    return <http:Ok>{
        body: {
            accessToken: jwtToken,
            refreshToken: refreshToken,
            accessTokenExpiresIn: defaultTokenExpiryTime,
            refreshTokenExpiresIn: refreshTokenExpiryTime,
            username: username,
            displayName: userDetails.displayName,
            roles: userRoles,
            isSuperAdmin: userDetails.isSuperAdmin,
            isProjectAuthor: userDetails.isProjectAuthor,
            isOidcUser: false
        }
    };
}

// NEW: Refresh token endpoint
isolated resource function post 'refresh\-token(
    types:RefreshTokenRequest request
) returns http:Ok|http:Unauthorized|http:InternalServerError {
    log:printInfo("Refresh token requested");
    
    // Validate refresh token and get user
    types:User|http:Unauthorized userResult = 
        check storage:validateRefreshToken(request.refreshToken);
    
    if userResult is http:Unauthorized {
        return userResult;
    }
    
    types:User user = userResult;
    
    // Fetch latest roles from database
    types:Role[]|error userRoles = storage:getUserRoles(user.userId);
    if userRoles is error {
        log:printError("Error fetching user roles", userRoles);
        return utils:createInternalServerError("Failed to fetch user roles");
    }
    
    // Generate new access token with updated roles
    string|error newAccessToken = utils:generateJWTToken(
        user,
        userRoles,
        frontendJwtIssuer,
        defaultTokenExpiryTime,
        frontendJwtAudience,
        jwtSignatureConfig
    );
    
    if newAccessToken is error {
        log:printError("Error generating new access token", newAccessToken);
        return utils:createInternalServerError("Error generating access token");
    }
    
    // Optionally: Rotate refresh token (issue new refresh token)
    // This is a security best practice
    string? newRefreshToken = ();
    if rotateRefreshTokens {  // Config option
        newRefreshToken = check utils:generateRefreshToken();
        check storage:storeRefreshToken(user.userId, newRefreshToken, ...);
        check storage:revokeRefreshToken(request.refreshToken);
    }
    
    log:printInfo("Token refreshed successfully", userId = user.userId);
    return <http:Ok>{
        body: {
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?: request.refreshToken,
            accessTokenExpiresIn: defaultTokenExpiryTime,
            refreshTokenExpiresIn: refreshTokenExpiryTime,
            username: user.username,
            displayName: user.displayName,
            roles: userRoles,
            isSuperAdmin: user.isSuperAdmin,
            isProjectAuthor: user.isProjectAuthor
        }
    };
}

// NEW: Revoke token endpoint (logout)
isolated resource function post 'revoke\-token(
    types:RevokeTokenRequest request
) returns http:Ok|http:InternalServerError {
    log:printInfo("Token revocation requested");
    
    error? revokeResult = storage:revokeRefreshToken(request.refreshToken);
    if revokeResult is error {
        log:printError("Error revoking refresh token", revokeResult);
        return utils:createInternalServerError("Failed to revoke token");
    }
    
    log:printInfo("Token revoked successfully");
    return <http:Ok>{
        body: {
            message: "Token revoked successfully"
        }
    };
}
```

##### 3.5.3 Frontend Integration

**AuthContext Update:**
```typescript
// src/contexts/AuthContext.tsx

// Store both tokens
interface AuthUser {
  // ... existing fields
  token: string;           // Access token
  refreshToken: string;    // NEW
  expiresAt: number;       // Access token expiry timestamp
  refreshExpiresAt: number; // NEW: Refresh token expiry timestamp
}

// Automatic token refresh before expiry
useEffect(() => {
  if (!user) return;
  
  // Schedule refresh 5 minutes before access token expires
  const refreshTime = user.expiresAt - Date.now() - (5 * 60 * 1000);
  
  if (refreshTime > 0) {
    const timeoutId = setTimeout(async () => {
      try {
        await refreshToken();
      } catch (error) {
        console.error('Failed to refresh token:', error);
        logout(); // Force logout on refresh failure
      }
    }, refreshTime);
    
    return () => clearTimeout(timeoutId);
  } else {
    // Token already expired or about to expire, refresh immediately
    refreshToken().catch(() => logout());
  }
}, [user?.expiresAt]);

// Refresh token implementation
const refreshToken = async () => {
  if (!user?.refreshToken) {
    throw new Error('No refresh token available');
  }
  
  try {
    const response = await icpApiClient.refreshToken(user.refreshToken);
    
    // Calculate new expiry timestamps
    const newExpiresAt = Date.now() + (response.accessTokenExpiresIn * 1000);
    const newRefreshExpiresAt = Date.now() + (response.refreshTokenExpiresIn * 1000);
    
    const updatedUser: AuthUser = {
      ...user,
      token: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: newExpiresAt,
      refreshExpiresAt: newRefreshExpiresAt,
      roles: response.roles,  // Update with latest roles
    };
    
    setUser(updatedUser);
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(updatedUser));
    
    console.log('Access token refreshed successfully');
  } catch (error) {
    console.error('Token refresh failed:', error);
    throw error;
  }
};

// Logout - revoke refresh token
const logout = async () => {
  if (user?.refreshToken) {
    try {
      await icpApiClient.revokeToken(user.refreshToken);
    } catch (error) {
      console.error('Failed to revoke token on logout:', error);
      // Continue with logout even if revocation fails
    }
  }
  
  setUser(null);
  localStorage.removeItem(AUTH_STORAGE_KEY);
};
```

**API Client Update:**
```typescript
// src/services/ICPApiClient.ts

async refreshToken(refreshToken: string): Promise<LoginResponse> {
  const response = await fetch(`${this.authEndpoint}/refresh-token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });
  
  if (!response.ok) {
    throw new Error('Token refresh failed');
  }
  
  return await response.json();
}

async revokeToken(refreshToken: string): Promise<void> {
  const response = await fetch(`${this.authEndpoint}/revoke-token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });
  
  if (!response.ok) {
    throw new Error('Token revocation failed');
  }
}
```

##### 3.5.4 Security Considerations

**Refresh Token Best Practices:**
1. ✅ Store as opaque token (not JWT) in database
2. ✅ Hash tokens before storage (SHA-256)
3. ✅ Set reasonable expiry (7-30 days)
4. ✅ Implement token rotation (optional but recommended)
5. ✅ Track token usage (last_used_at)
6. ✅ Support token revocation
7. ✅ Clean up expired tokens periodically
8. ✅ Bind to user agent and IP (optional, for additional security)
9. ✅ Limit concurrent refresh tokens per user (optional)

**Frontend Best Practices:**
1. ✅ Store refresh token in localStorage (or httpOnly cookie if server-side)
2. ✅ Automatic refresh before access token expires
3. ✅ Graceful handling of refresh failures (redirect to login)
4. ✅ Revoke on logout
5. ✅ Clear on 401 errors

---

### Phase 3: Data Model & Storage

#### 3.6 Database Schema Updates

**Add Default Organization:**
```sql
-- Create organizations table if it doesn't exist
CREATE TABLE IF NOT EXISTS organizations (
    org_id VARCHAR(255) PRIMARY KEY,
    org_name VARCHAR(255) NOT NULL,
    org_handle VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default organization
INSERT INTO organizations (org_id, org_name, org_handle) 
VALUES ('default-org-uuid', 'Default Organization', 'default')
ON DUPLICATE KEY UPDATE org_name = org_name;

-- Add refresh_tokens table (for refresh token mechanism)
CREATE TABLE refresh_tokens (
    token_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN DEFAULT FALSE,
    revoked_at TIMESTAMP NULL,
    user_agent VARCHAR(500),
    ip_address VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_token_hash (token_hash),
    INDEX idx_expires_at (expires_at)
);
```

**Observation:** ✅ **Minimal migration needed!** Just add the default organization and refresh tokens table.

---

### Phase 4: Feature Parity & Migration

#### 3.7 Features to Migrate

| Feature | Devant/Choreo | ICP Target | Migration Strategy |
|---------|---------------|------------|-------------------|
| **Multi-Login Methods** | Google, GitHub, Microsoft, Email, SSO, Anonymous | Email/Password, OIDC SSO | Remove social login buttons; keep email + OIDC |
| **Organization Selector** | Dynamic org switching | Hidden (default org only) | Hide UI component, keep routing |
| **Token Exchange** | Asgardeo → STS (org-scoped) | OIDC → ICP JWT (project-scoped) | Use existing ICP OIDC flow |
| **Session Extension** | ISK-based (8-hour intervals) | Refresh token mechanism | **NEW:** Implement refresh token flow |
| **Project List** | Filtered by org | Filtered by project roles | Update GraphQL queries with RBAC |
| **User Management** | Org-level users | System-level users (filtered by shared projects) | Use existing ICP user management |
| **Environment Access** | Org-wide | Project + environment type | RBAC enforcement in backend |
| **Observability** | Org-scoped logs/metrics | Project-scoped logs/metrics | Update filters to use projectId |

#### 3.8 Features to Remove

1. **Organization Management UI:**
   - ~~Create/update/delete organizations~~ (hide, keep code)
   - ~~Organization settings~~ (hide)
   - ~~Organization invitations~~ (hide)
   - Keep organization context for future use
   
2. **Marketplace Integrations:**
   - Azure/AWS/GCP subscription flows
   - Marketplace token handling
   
3. **Multi-IdP Federation UI:**
   - Google/GitHub/Microsoft login buttons (remove from UI)
   - Anonymous login with reCAPTCHA (remove)
   - Keep OIDC generic implementation
   
4. **Growth Hacking:**
   - UTM parameter tracking
   - User signup analytics
   
5. **Multi-Perspective Views:**
   - Platform Engineer perspective
   - Developer perspective switching

---

## 4. Implementation Roadmap

### Week 1: Setup & Planning

**Tasks:**
- [x] Create migration plan document
- [x] Create feature branch: `icp2-auth` (Devant)
- [x] Set up ICP server dev environment (docker-compose.local.yml)
- [x] Document current routing structure
- [x] Create component inventory (to migrate vs. to hide)
- [x] Set up development database with default organization

**Deliverables:**
- [x] Migration plan (this document)
- [x] Routing structure documentation (`ROUTING_STRUCTURE.md`)
- [x] Component inventory & migration matrix (`COMPONENT_INVENTORY.md`)

---

### Week 2-3: Backend Refresh Token Implementation

**Priority:** HIGH (Required for frontend auth to work properly)

**Tasks:**
1. [ ] Design refresh token database schema
2. [ ] Implement refresh token generation utility
3. [ ] Implement refresh token storage functions
4. [ ] Implement refresh token validation
5. [ ] Update `/auth/login` endpoint to return refresh token
6. [ ] Update `/auth/login/oidc` endpoint to return refresh token
7. [ ] Implement `/auth/refresh-token` endpoint
8. [ ] Implement `/auth/revoke-token` endpoint
9. [ ] Add refresh token cleanup job (scheduled task)
10. [ ] Add configuration options (token expiry times, rotation)
11. [ ] Write unit tests for refresh token logic
12. [ ] Update API documentation

**Files to Create/Modify:**
```
icp_server/
  auth_service.bal (update login endpoints, add refresh/revoke)
  modules/
    storage/
      mysql_repository.bal (add refresh token CRUD functions)
    types/
      types.bal (add RefreshToken types)
    utils/
      auth_utils.bal (add token generation/validation)
  Config.toml (add refresh token configuration)
  resources/
    db/
      init-scripts/
        03_refresh_tokens.sql (new migration script)
```

**Testing Checklist:**
- [ ] Login returns both access and refresh tokens
- [ ] Refresh token can be used to get new access token
- [ ] Refresh token includes updated user roles
- [ ] Expired refresh token is rejected
- [ ] Revoked refresh token is rejected
- [ ] Revoke token successfully invalidates token
- [ ] Token rotation works (if enabled)
- [ ] Cleanup job removes expired tokens

**Configuration:**
```toml
# Config.toml additions
[auth.tokens]
accessTokenExpirySeconds = 3600          # 1 hour
refreshTokenExpirySeconds = 604800       # 7 days
rotateRefreshTokens = true               # Optional: issue new refresh token on refresh
maxRefreshTokensPerUser = 5              # Optional: limit concurrent sessions
```

---

### Week 3-4: Core Frontend Auth Replacement

**Tasks:**
1. [ ] Remove `@asgardeo/auth-react` dependency
2. [ ] Create new `AuthProvider` context (based on `icp-frontend/AuthContext.tsx`)
3. [ ] Implement login page with:
   - [ ] Email/password form
   - [ ] OIDC SSO button
4. [ ] Implement OIDC callback handler
5. [ ] Implement refresh token mechanism in frontend
   - [ ] Automatic refresh before expiry
   - [ ] Token refresh on user action (project creation)
   - [ ] Graceful handling of refresh failures
6. [ ] Implement logout with token revocation
7. [ ] Update API client to use new token structure
8. [ ] Handle token expiry and automatic refresh

**Files to Create/Modify:**
```
src/
  contexts/
    AuthContext.tsx (new - based on icp-frontend, with refresh token support)
  services/
    AuthApiClient.ts (new - with refresh token methods)
  pages/
    Login.tsx (replace with simplified version)
    OIDCCallback.tsx (new)
  providers/
    BaseProvider.tsx (update - remove Asgardeo)
  utils/
    auth.ts (update - simplify for default org)
```

**Testing Checklist:**
- [ ] Email/password login works
- [ ] OIDC login works
- [ ] Both access and refresh tokens are stored
- [ ] Token refresh happens automatically before expiry
- [ ] Token refresh works on user-triggered actions
- [ ] Logout revokes refresh token
- [ ] Expired access token triggers refresh
- [ ] Failed refresh redirects to login
- [ ] No Asgardeo-related errors in console

---

### Week 4-5: Default Organization Implementation

**Tasks:**
1. [ ] Create default organization seed data
2. [ ] Update organization context to always use "default"
3. [ ] Hide organization selector in UI (keep component code)
4. [ ] Update routing configuration:
   - [ ] Hardcode `/organizations/default` prefix
   - [ ] Update route guards
   - [ ] Update navigation links
5. [ ] Update breadcrumbs (show "Default Organization")
6. [ ] Remove organization switching logic (keep hooks structure)
7. [ ] Update organization-related API calls to use "default"

**Files to Create/Modify:**
```
src/
  config/
    index.ts (add DEFAULT_ORG_HANDLE, DEFAULT_ORG_NAME)
  contexts/
    OrganizationContext.tsx (simplify to single org)
  components/
    Navigation.tsx (hide org selector)
    Breadcrumbs.tsx (show default org)
  utils/
    route.ts (update route helpers for default org)
  hooks/
    organizations.tsx (simplify, keep structure)

icp_server/
  resources/
    db/
      init-scripts/
        02_seed_default_org.sql (new)
```

**Testing Checklist:**
- [ ] All routes include `/organizations/default`
- [ ] Organization selector is hidden
- [ ] Breadcrumbs show "Default Organization"
- [ ] No organization switching occurs
- [ ] All API calls use default organization
- [ ] No org-related errors in console
- [ ] URL bookmarks work correctly

---

### Week 5-6: Implement Project-Based RBAC

**Tasks:**
1. [ ] Create RBAC utility functions:
   ```typescript
   src/utils/rbac.ts
   - hasProjectAccess()
   - hasEnvironmentAccess()
   - canCreateProject()
   - canManageUsers()
   - getAccessibleProjects()
   - canAdminProject()
   ```
2. [ ] Update GraphQL queries to include RBAC filtering
3. [ ] Implement permission checks in components:
   - [ ] Project list (filter by accessible)
   - [ ] Component list (filter by project access)
   - [ ] Environment views (restrict by env type)
   - [ ] User management (filter by shared projects)
   - [ ] Runtime management (check project access)
4. [ ] Add permission-based UI rendering (hide/disable actions)
5. [ ] Update context hooks to expose RBAC helpers

**Files to Create/Update:**
```
src/
  utils/
    rbac.ts (new - comprehensive RBAC utilities)
  graphql/
    queries.ts (update with RBAC filtering)
  components/
    ProjectsPage.tsx (filter by access)
    ComponentsPage.tsx (filter by project)
    EnvironmentsPage.tsx (filter by access)
    EnvironmentOverview.tsx (restrict actions)
    RuntimesPage.tsx (filter by project)
    UsersPage.tsx (filter by shared projects)
```

**Testing Checklist:**
- [ ] Super admin sees all projects
- [ ] Regular user sees only accessible projects
- [ ] Project admin can manage project resources
- [ ] Developer has read-only access to non-prod
- [ ] Prod environments are restricted correctly
- [ ] User management shows only relevant users
- [ ] Actions are disabled based on permissions
- [ ] No unauthorized API calls succeed

---

### Week 6-7: Update UI Components

**Tasks:**
1. [ ] Update main layout (simplify for default org)
2. [ ] Update project pages:
   - [ ] Project list view (RBAC filtering)
   - [ ] Project details
   - [ ] Component management (permission checks)
3. [ ] Update environment pages:
   - [ ] Environment list (RBAC-filtered)
   - [ ] Environment overview (action restrictions)
4. [ ] Update observability pages:
   - [ ] Logs (project-filtered with RBAC)
   - [ ] Metrics (project-filtered with RBAC)
5. [ ] Update user management:
   - [ ] User list (RBAC-filtered by shared projects)
   - [ ] Role assignment UI (project-based)
6. [ ] Add permission indicators (badges, tooltips)

**Files to Update:**
```
src/
  layouts/
    MainLayout.tsx (simplify org context)
  components/
    ProjectsPage.tsx (RBAC filtering)
    ComponentsPage.tsx (RBAC filtering)
    EnvironmentsPage.tsx (RBAC filtering)
    EnvironmentOverview.tsx (action restrictions)
    LogsPage.tsx (project filtering)
    MetricsPage.tsx (project filtering)
    UsersPage.tsx (RBAC filtering)
    UserRoleEditor.tsx (new - project-based role UI)
    ProfilePage.tsx (remove org-specific fields)
```

**Testing Checklist:**
- [ ] All pages render correctly
- [ ] RBAC filtering works on all lists
- [ ] No default org references cause errors
- [ ] Permission checks work in all components
- [ ] Action buttons show correct enabled/disabled state
- [ ] Tooltips explain permission requirements
- [ ] No console errors or warnings

---

### Week 7-8: User Management Migration

**Tasks:**
1. [ ] Update user management page:
   - [ ] Show system-level users (with shared project filtering)
   - [ ] Remove org-level user context
2. [ ] Update role assignment UI:
   - [ ] Display project-based roles in table
   - [ ] Allow assigning project + environment + privilege
   - [ ] Validate role assignments (admin must have access)
3. [ ] Implement user creation flow (super admin only)
4. [ ] Update profile page (remove org-specific fields)
5. [ ] Add role visualization (show user's project access)

**Files to Update:**
```
src/
  components/
    UsersPage.tsx (update filtering logic)
    UserRoleEditor.tsx (project-based role UI)
    UserRoleTable.tsx (new - visualize project roles)
    ProfilePage.tsx (simplify)
  hooks/
    users.tsx (update RBAC filtering)
```

**Testing Checklist:**
- [ ] Super admin can create users
- [ ] Admins can manage users in their projects
- [ ] Role assignment UI works correctly
- [ ] Project/environment/privilege selection works
- [ ] Cannot assign roles to projects without admin access
- [ ] Profile updates work
- [ ] User list shows correct filtered users

---

### Week 8: Cleanup & Optimization

**Tasks:**
1. [ ] Remove unused dependencies:
   ```json
   "@asgardeo/auth-react"
   "@asgardeo/auth-js"
   "@asgardeo/auth-spa"
   ```
2. [ ] Remove/hide unused components:
   - [ ] Multi-org management (keep hidden)
   - [ ] Marketplace integrations (remove)
   - [ ] Social login components (remove)
   - [ ] Anonymous login (remove)
3. [ ] Remove unused utilities:
   - [ ] ISK session extension
   - [ ] Multi-perspective switching
   - [ ] Growth hacking/UTM tracking
4. [ ] Update configuration:
   - [ ] Remove Asgardeo config
   - [ ] Simplify environment variables
   - [ ] Add ICP-specific config
5. [ ] Clean up types (remove org-multi-tenancy types)
6. [ ] Optimize bundle size
7. [ ] Code cleanup and linting

**Files to Remove/Clean:**
```
src/
  modules/
    login/
      IdentityProviderInfo/ (remove Asgardeo branding)
  utils/
    growthHacking/ (remove)
  types/
    marketplace.ts (remove)
```

**Testing Checklist:**
- [ ] No broken imports
- [ ] Bundle size reduced significantly
- [ ] No console warnings/errors
- [ ] All linting passes
- [ ] No unused code warnings

---

### Week 9: Testing & Documentation

**Tasks:**
1. [ ] End-to-end testing:
   - [ ] Login flows (email/password, OIDC)
   - [ ] Token refresh scenarios
   - [ ] Project access (different user roles)
   - [ ] RBAC enforcement across all pages
   - [ ] User management flows
2. [ ] Performance testing:
   - [ ] Page load times
   - [ ] GraphQL query efficiency
   - [ ] Token refresh overhead
3. [ ] Security testing:
   - [ ] Token validation
   - [ ] RBAC bypass attempts
   - [ ] Refresh token security
4. [ ] Documentation:
   - [ ] Update README.md
   - [ ] Create deployment guide
   - [ ] Document RBAC model
   - [ ] Update API documentation
   - [ ] Create user guide
   - [ ] Document refresh token mechanism

**Deliverables:**
- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Documentation complete
- [ ] Migration guide for existing deployments
- [ ] Security audit report

---

## 5. Key Considerations & Risks

### 5.1 Data Migration

**Risk:** N/A - This is a fork for a separate on-prem project

**Context:** 
- Existing Devant/Choreo-Console deployments are **NOT affected**
- This is a **separate fork** for the ICP on-prem project
- No data migration from Devant needed
- Fresh ICP deployments start with empty database + default organization

**Action:** 
- ✅ No migration concerns
- ✅ Only need to seed default organization
- ✅ Add refresh tokens table to schema

---

### 5.2 URL Structure Changes

**Risk:** ~~Breaking existing bookmarks and links~~ **MITIGATED**

**Mitigation:** 
- ✅ **Using default organization preserves URL structure**
- ✅ URLs remain: `/organizations/default/projects/...`
- ✅ No redirect rules needed
- ✅ Existing routing logic mostly intact
- ✅ Bookmarks continue to work

**Note:** Since this is a new deployment, there are no existing users with bookmarks. The preserved URL structure is for future-proofing and easier migration path.

---

### 5.3 RBAC Complexity

**Risk:** Project-level RBAC more complex than org-level

**Mitigation:**
- Comprehensive RBAC utility functions (`src/utils/rbac.ts`)
- Clear permission matrices in documentation
- UI indicators for permission states (disabled buttons, tooltips)
- Extensive testing of edge cases
- Backend RBAC enforcement (frontend is just UX)

**Testing Strategy:**
- Unit tests for RBAC utilities
- Integration tests for permission checks
- E2E tests for user flows with different roles
- Security testing for RBAC bypass attempts

---

### 5.4 Token Refresh Strategy

**Risk:** Token expiry during long sessions; current implementation only issues access tokens

**Current State:**
- ICP server only issues access tokens (JWT)
- No refresh token mechanism exists
- Current `/auth/refresh-token` endpoint is used only when creating projects (to get updated roles)
- Not a true refresh token flow like Asgardeo's ISK

**Required Implementation:**
1. **Backend:** 
   - Generate and store refresh tokens in database
   - Implement token rotation (optional but recommended)
   - Add refresh token validation
   - Add token revocation support
   
2. **Frontend:**
   - Store refresh token separately from access token
   - Implement automatic refresh before access token expires
   - Handle refresh failures gracefully (redirect to login)
   - Revoke refresh token on logout
   
3. **Security:**
   - Hash refresh tokens in database (SHA-256)
   - Set appropriate expiry times (access: 1 hour, refresh: 7 days)
   - Bind tokens to user agent/IP (optional)
   - Clean up expired tokens periodically

**Timeline:**
- **Week 2-3:** Implement backend refresh token mechanism (PRIORITY)
- **Week 3-4:** Integrate frontend with refresh token flow

**See Section 3.5** for detailed implementation plan.

---

### 5.5 OIDC Provider Configuration

**Risk:** Different OIDC providers have different requirements

**Mitigation:**
- Document supported OIDC providers (Azure AD, Okta, Keycloak, etc.)
- Provide configuration examples for common providers
- Support standard OIDC discovery (already in ICP server)
- Test with multiple providers during development
- Add configuration validation

**Supported Providers (Planned Testing):**
- Azure AD (Microsoft Entra ID)
- Okta
- Keycloak
- Auth0
- Google Identity Platform

---

### 5.6 Default Organization Future Changes

**Risk:** Need to support multi-tenancy later

**Mitigation:**
- ✅ **Organization scaffolding preserved**
- ✅ Database schema supports multiple organizations
- ✅ Routing structure supports dynamic org handles
- ✅ Context and hooks remain organization-aware
- ✅ Only UI components hide multi-org features

**Future Migration Path:**
1. Unhide organization selector
2. Update organization context to be dynamic
3. Add organization management pages
4. Update API calls to use dynamic org handle
5. Add organization switching logic

**Estimated Effort for Multi-Tenancy:** 2-3 weeks (much less than full migration)

---

## 6. Success Criteria

### 6.1 Functional Requirements
- ✅ Users can log in with email/password
- ✅ Users can log in with OIDC SSO
- ✅ Token exchange works correctly with ICP server
- ✅ **Refresh token mechanism works (automatic + manual)**
- ✅ **Logout revokes refresh tokens**
- ✅ Default organization is used throughout the app
- ✅ URLs include `/organizations/default` prefix
- ✅ Organization selector is hidden (not removed)
- ✅ Project-based RBAC enforced on all pages
- ✅ Super admins have full access
- ✅ Project admins can manage their projects
- ✅ Developers have read-only access to non-prod
- ✅ Users can only see projects they have access to
- ✅ Observability data is filtered by project access
- ✅ User management shows only relevant users (shared projects)

### 6.2 Non-Functional Requirements
- ✅ Organization scaffolding preserved for future use
- ✅ Bundle size reduced (removing Asgardeo SDK)
- ✅ Page load times < 2 seconds
- ✅ All GraphQL queries include RBAC filtering
- ✅ No security vulnerabilities in dependencies
- ✅ **Refresh tokens stored securely in database**
- ✅ **Token refresh is transparent to users**
- ✅ Documentation complete and accurate
- ✅ Migration path to multi-tenancy documented

---

## 7. Post-Migration Tasks

### 7.1 Deployment Configuration

**Environment Variables:**
```bash
# ICP Server
ICP_GRAPHQL_ENDPOINT=https://icp-server.company.com/graphql
ICP_AUTH_ENDPOINT=https://icp-server.company.com/auth

# Default Organization
DEFAULT_ORG_HANDLE=default
DEFAULT_ORG_NAME=Default Organization

# OIDC (optional)
OIDC_ENABLED=true
OIDC_PROVIDER_NAME=Azure AD
# Server-side configuration for OIDC endpoints

# Token Configuration
ACCESS_TOKEN_EXPIRY_SECONDS=3600        # 1 hour
REFRESH_TOKEN_EXPIRY_SECONDS=604800     # 7 days
ROTATE_REFRESH_TOKENS=true
```

**TLS Certificates:**
- Set up valid TLS certificates for ICP server
- Configure trusted certificate store for OIDC provider

---

### 7.2 Initial Super Admin Setup

**Default Credentials:**
```sql
-- Create initial super admin user
INSERT INTO users (user_id, username, display_name, is_super_admin, is_project_author)
VALUES ('admin-uuid', 'admin@company.com', 'System Administrator', TRUE, TRUE);

-- Store in auth backend (default implementation)
-- Password: Use secure generation and share via secure channel
```

**Credential Management:**
- Document super admin creation process
- Provide password reset mechanism
- Implement audit logging for admin actions

---

### 7.3 Database Migrations

**Migration Scripts:**
```sql
-- 01_default_organization.sql
INSERT INTO organizations (org_id, org_name, org_handle) 
VALUES ('default-org-uuid', 'Default Organization', 'default')
ON DUPLICATE KEY UPDATE org_name = org_name;

-- 02_refresh_tokens.sql
CREATE TABLE refresh_tokens (
    -- ... (see Phase 2 for full schema)
);

-- 03_cleanup_job.sql
-- Create scheduled event to clean expired tokens
CREATE EVENT IF NOT EXISTS cleanup_expired_refresh_tokens
ON SCHEDULE EVERY 1 DAY
DO
  DELETE FROM refresh_tokens 
  WHERE expires_at < NOW() OR revoked = TRUE;
```

---

### 7.4 Training & Documentation

**User Guides:**
1. **User Guide:** How to use ICP with project-based access
2. **Admin Guide:** Managing users and project permissions
3. **OIDC Setup Guide:** Configuring external identity providers
4. **RBAC Reference:** Understanding project/environment/privilege levels

**Training Materials:**
- Admin training for user/role management
- Developer training for project access model
- Differences from Devant/Choreo (for reference)

---

### 7.5 Monitoring & Maintenance

**Monitoring:**
- Token refresh success/failure rates
- Login success/failure rates
- OIDC provider availability
- Database performance (especially refresh_tokens queries)
- Expired token cleanup job execution

**Maintenance:**
- Regular security updates for dependencies
- Token cleanup job monitoring
- Database index optimization (refresh_tokens table)
- Log rotation for auth-related logs

---

## 8. Appendix

### 8.1 Configuration Comparison

#### Before (Devant/Choreo):
```javascript
ASGARDEO_SDK_CONFIG: {
  clientID: 'zL9kF4GCPiN2veO8judQvwlqLb8a',
  baseUrl: 'https://dev.api.asgardeo.io',
  enablePKCE: 'true',
  storage: 'sessionStorage',
  checkSessionInterval: '-1',
  disableTrySignInSilently: 'true',
}
TOKEN_EXCHANGE_CONFIG: {
  tokenEndpoint: 'https://sts.choreo.dev/oauth2/token',
  grant_type: 'urn:ietf:params:oauth:grant-type:token-exchange',
  subject_token_type: 'urn:ietf:params:oauth:token-type:jwt',
  orgHandle: '{dynamicOrg}',
}
ORGANIZATION_ENDPOINT: 'https://app.choreo.dev/organizations'
ASGARDEO_SESSION_EXTENSION_RESOURCE: '/t/a/identity/extend-session'
ASGARDEO_SESSION_EXTENSION_INTERVAL: '28800000' // 8 hours
```

#### After (ICP On-Prem):
```javascript
ICP_API_CONFIG: {
  graphqlEndpoint: 'https://icp-server.company.com/graphql',
  authEndpoint: 'https://icp-server.company.com/auth',
}
DEFAULT_ORG_CONFIG: {
  orgHandle: 'default',
  orgName: 'Default Organization',
  orgId: 'default-org-uuid',
}
OIDC_CONFIG: {
  enabled: true,
  providerName: 'Azure AD', // or 'Okta', 'Keycloak'
  // All OIDC endpoints configured server-side
}
TOKEN_CONFIG: {
  accessTokenExpiry: 3600,        // 1 hour (in seconds)
  refreshTokenExpiry: 604800,     // 7 days (in seconds)
  autoRefreshEnabled: true,
  refreshBeforeExpiry: 300,       // Refresh 5 min before expiry
}
```

---

### 8.2 Estimated Effort Summary

| Phase | Duration | Team Size | Dependencies | Notes |
|-------|----------|-----------|--------------|-------|
| Setup & Planning | 1 week | 1-2 devs | None | Architecture decisions |
| **Backend Refresh Token** | **2 weeks** | **2 devs** | **None** | **PRIORITY - Blocking** |
| Core Auth Replacement | 2 weeks | 2 devs | Refresh token | Critical path |
| Default Org Implementation | 1 week | 1-2 devs | Core auth | Parallel with RBAC |
| Implement RBAC | 2 weeks | 2 devs | Core auth | Complex logic |
| Update UI Components | 2 weeks | 2-3 devs | RBAC | Can be parallelized |
| User Management | 1 week | 1-2 devs | RBAC | Depends on RBAC |
| Cleanup & Optimization | 1 week | 1 dev | All above | Final polish |
| Testing & Documentation | 1 week | 2-3 devs | All above | QA involvement |
| **Total** | **~9 weeks** | **2-3 devs** | | With parallel work |

**Critical Path:** Backend Refresh Token → Core Auth Replacement → RBAC → UI Components

---

### 8.3 Risk Matrix

| Risk | Probability | Impact | Mitigation Status | Priority |
|------|------------|--------|-------------------|----------|
| Token refresh not implemented | High | High | ✅ Added to roadmap | **P0 - Critical** |
| RBAC bypass vulnerabilities | Medium | High | Backend enforcement + testing | P1 |
| OIDC provider compatibility | Low | Medium | Multi-provider testing | P2 |
| Performance degradation | Low | Medium | Query optimization | P2 |
| Default org confusion | Low | Low | ✅ Good documentation | P3 |

---

### 8.4 Decision Log

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| 2025-10-27 | Keep organization scaffolding with "default" org | Preserve multi-tenancy path, reduce migration scope | Low - Simplified implementation |
| 2025-10-27 | Implement refresh token mechanism | Required for proper session management | High - Backend + frontend work |
| 2025-10-27 | Remove Asgardeo SDK completely | Simplify dependencies, reduce bundle size | Medium - Core auth rewrite |
| 2025-10-27 | Use project-based RBAC (existing ICP model) | Already implemented in backend | Low - Leverage existing |

---

### 8.5 Contact & Resources

**Project Team:**
- [ ] Project Lead: _TBD_
- [ ] Backend Lead: _TBD_
- [ ] Frontend Lead: _TBD_
- [ ] QA Lead: _TBD_

**Resources:**
- [ICP Server Repository](../icp_server/)
- [ICP Frontend Repository](../icp-frontend/)
- [Devant Choreo Console (Source)](../devant/workspaces/apps/choreo-console/)
- [Ballerina JWT Documentation](https://lib.ballerina.io/ballerina/jwt/latest)
- [OIDC Specification](https://openid.net/specs/openid-connect-core-1_0.html)

---

### 8.6 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-27 | AI Assistant | Initial migration plan |
| 1.1 | 2025-10-27 | AI Assistant | Updated with default org, refresh token, clarified risks |

---

## Next Steps

1. ✅ Review and approve this migration plan
2. [ ] Create feature branch: `feature/icp-frontend-migration`
3. [ ] Set up development environment
4. [ ] **Start with refresh token implementation (Week 2-3)** ← PRIORITY
5. [ ] Schedule kick-off meeting
6. [ ] Assign team members to phases
7. [ ] Begin Week 1 tasks

---

**End of Migration Plan**
