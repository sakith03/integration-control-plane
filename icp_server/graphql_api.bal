// Copyright (c) 2025, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import icp_server.storage;
import icp_server.types;
import icp_server.utils;

import ballerina/graphql;
import ballerina/http;
import ballerina/lang.value;
import ballerina/log;

// GraphQL listener configuration
listener graphql:Listener graphqlListener = new (graphqlPort
// ,
//     secureSocket = {
//         key: {
//             path: keystorePath,
//             password: keystorePassword
//         }
//     }
);

isolated function contextInit(http:RequestContext reqCtx, http:Request request) returns graphql:Context {
    string|error authorization = request.getHeader("Authorization");
    graphql:Context context = new;
    if authorization is string {
        context.set("Authorization", authorization);
    }

    return context;
}

// GraphQL service for runtime details

@graphql:ServiceConfig {
    contextInit,
    cors: {
        allowOrigins: ["*"]
    },
    auth: [
        {
            jwtValidatorConfig: {
                issuer: frontendJwtIssuer,
                audience: frontendJwtAudience,
                signatureConfig: {
                    secret: defaultJwtHMACSecret
                }
            }
        }
    ]
}
service /graphql on graphqlListener {

    function init() {
        log:printInfo("GraphQL service started at " + serverHost + ":" + graphqlPort.toString());
    }

    // ----------- Runtime Resources
    // Get all runtimes with optional filtering
    isolated resource function get runtimes(string? status, string? runtimeType, string? environmentId, string? projectId, string? componentId) returns types:Runtime[]|error {
        return check storage:getRuntimes(status, runtimeType, environmentId, projectId, componentId);
    }

    // Get a specific runtime by ID
    isolated resource function get runtime(string runtimeId) returns types:Runtime?|error {
        return check storage:getRuntimeById(runtimeId);
    }

    // Get services for a specific runtime
    isolated resource function get services(string runtimeId) returns types:Service[]|error {
        return check storage:getServicesForRuntime(runtimeId);
    }

    // Get listeners for a specific runtime
    isolated resource function get listeners(string runtimeId) returns types:Listener[]|error {
        return check storage:getListenersForRuntime(runtimeId);
    }

    // Delete a runtime by ID
    isolated remote function deleteRuntime(string runtimeId) returns boolean|error {
        check storage:deleteRuntime(runtimeId);
        return true;
    }

    // ----------- Environment Resources
    // Create a new environment
    isolated remote function createEnvironment(types:EnvironmentInput environment) returns types:Environment|error? {
        // Call storage layer to insert environments
        return storage:createEnvironment(environment);
    }

    // Get all environments
    isolated resource function get environments() returns types:Environment[]|error? {
        return check storage:getEnvironments();
    }

    // Delete an environment
    isolated remote function deleteEnvironment(string environmentId) returns boolean|error {
        check storage:deleteEnvironment(environmentId);
        return true;
    }

    // Update environment name and/or description
    isolated remote function updateEnvironment(string environmentId, string? name, string? description) returns types:Environment?|error {
        check storage:updateEnvironment(environmentId, name, description);
        return check storage:getEnvironmentById(environmentId);
    }

    // Update environment production status
    isolated remote function updateEnvironmentProductionStatus(string environmentId, boolean isProduction) returns types:Environment?|error {
        check storage:updateEnvironmentProductionStatus(environmentId, isProduction);
        return check storage:getEnvironmentById(environmentId);
    }

    //------------- Project Resources
    // Create a new project
    isolated remote function createProject(graphql:Context context, types:ProjectInput project) returns types:Project|error? {
        // Extract user context to get the creating user's information
        value:Cloneable|error|isolated object {} authHeader = context.get("Authorization");
        if authHeader !is string {
            return error("Authorization header missing in request");
        }
        
        types:UserContext userContext = check utils:extractUserContext(authHeader);
        
        // Create project and auto-assign admin roles to creating user
        return check storage:createProject(project, userContext);
    }

    // Get all projects (filtered by user's accessible projects via RBAC)
    isolated resource function get projects(graphql:Context context) returns types:Project[]|error {
        value:Cloneable|error|isolated object {} authHeader = context.get("Authorization");
        if authHeader !is string {
            return error("Authorization header missing in request");
        }
        
        // Extract user context for RBAC
        types:UserContext userContext = check utils:extractUserContext(authHeader);
        
        // Get projects filtered by user's access
        return check storage:getProjects(userContext);
    }

    // Get a specific project by ID
    isolated resource function get project(string projectId) returns types:Project?|error {
        return check storage:getProjectById(projectId);
    }

    // Delete a project
    isolated remote function deleteProject(string projectId) returns boolean|error {
        check storage:deleteProject(projectId);
        return true;
    }

    // Update project name and/or description
    isolated remote function updateProject(string projectId, string? name, string? description) returns types:Project?|error {
        check storage:updateProject(projectId, name, description);
        return check storage:getProjectById(projectId);
    }

    // ----------- Component Resources
    // Create a new component
    isolated remote function createComponent(types:ComponentInput component) returns types:Component|error? {
        return storage:createComponent(component);
    }

    // Get all components with optional project filter
    isolated resource function get components(string? projectId) returns types:Component[]|error {
        return check storage:getComponents(projectId);
    }

    // Get a specific component by ID
    isolated resource function get component(string componentId) returns types:Component?|error {
        return check storage:getComponentById(componentId);
    }

    // Delete a component
    isolated remote function deleteComponent(string componentId) returns boolean|error {
        check storage:deleteComponent(componentId);
        return true;
    }

    // Update component name and/or description
    isolated remote function updateComponent(string componentId, string? name, string? description) returns types:Component|error {
        check storage:updateComponent(componentId, name, description);
        return check storage:getComponentById(componentId);
    }
}
