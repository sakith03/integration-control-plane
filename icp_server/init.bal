// Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import icp_server.utils;

import ballerina/jwt;

function init() returns error? {
    // Initialize HTTP client to authentication backend using resolved TLS and JWT secrets
    authBackendClient = check new (authBackendUrl,
        secureSocket = {
            cert: {
                path: truststorePath,
                password: resolvedTruststorePassword
            }
        },
        auth = {
            issuer: userServiceJwtIssuer,
            audience: userServiceJwtAudience,
            expTime: 3600,
            signatureConfig: {
                algorithm: jwt:HS256,
                config: resolvedUserServiceJwtHMACSecret
            }
        }
    );

    // Initialize JWT signature config used throughout auth_service.bal
    jwtSignatureConfig = {
        algorithm: jwt:HS256,
        config: resolvedDefaultJwtHMACSecret
    };

    // Initialize OpenSearch client using resolved credentials
    opensearchClient = check new (opensearchUrl,
        config = {
            auth: {
                username: resolvedOpensearchUsername,
                password: resolvedOpensearchPassword
            },
            secureSocket: {
                enable: false
            }
        }
    );

    // Initialize DB connection manager and DB client with resolved credentials
    credentialsDbManager = check new storage:DatabaseConnectionManager(
        credentialsDbType, credentialsDbHost, credentialsDbPort,
        credentialsDbName, resolvedCredDbUser, resolvedCredDbPassword
    );
    credentialsDbClient = credentialsDbManager.getClient();

    // Initialize the runtime scheduler
    check initRuntimeScheduler();
}

// Resolves a secret: looks up the key in the [secrets] config map and decrypts it.
// Falls back to the plain configurable value if the key is absent from the secrets map.
// Throws an error if the key is present but decryption fails.
function resolveSecret(string key, string fallback) returns string|error {
    string? secretVal = secrets[key];
    if secretVal is string {
        return utils:decrypt(secretVal);
    }
    return fallback;
}
