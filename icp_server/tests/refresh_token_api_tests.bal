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

import ballerina/http;
import ballerina/log;
import ballerina/test;

// ============================================================================
// Test: /auth/refresh-token endpoint (Subtask 11.5)
// ============================================================================

// Test: Refresh token with invalid token
@test:Config {
    groups: ["refresh-token", "api", "negative"]
}
function testRefreshTokenWithInvalidToken() returns error? {
    log:printInfo("Test: Refresh token with invalid token");

    json refreshRequest = {
        refreshToken: "invalid-refresh-token-12345"
    };

    http:Response response = check authClient->post("/auth/refresh-token", refreshRequest);
    test:assertEquals(response.statusCode, 401, "Should reject invalid refresh token");

    json responseBody = check response.getJsonPayload();
    test:assertTrue(responseBody.message is string, "Error message should be present");

    log:printInfo("Test passed: Invalid refresh token rejected");
}

// Test: Refresh token with empty token
@test:Config {
    groups: ["refresh-token", "api", "negative"]
}
function testRefreshTokenWithEmptyToken() returns error? {
    log:printInfo("Test: Refresh token with empty token");

    json refreshRequest = {
        refreshToken: ""
    };

    http:Response response = check authClient->post("/auth/refresh-token", refreshRequest);
    test:assertTrue(response.statusCode == 400 || response.statusCode == 401, "Should reject empty refresh token");

    json responseBody = check response.getJsonPayload();
    test:assertTrue(responseBody.message is string, "Error message should be present");

    log:printInfo("Test passed: Empty refresh token rejected");
}

// Test: Refresh token with missing token field
@test:Config {
    groups: ["refresh-token", "api", "negative"]
}
function testRefreshTokenWithMissingToken() returns error? {
    log:printInfo("Test: Refresh token with missing token field");

    json refreshRequest = {};

    http:Response response = check authClient->post("/auth/refresh-token", refreshRequest);
    test:assertTrue(response.statusCode == 400 || response.statusCode == 401, "Should reject missing refresh token");

    json responseBody = check response.getJsonPayload();
    test:assertTrue(responseBody.message is string, "Error message should be present");

    log:printInfo("Test passed: Missing refresh token rejected");
}

// Test: Refresh token with expired token
@test:Config {
    groups: ["refresh-token", "api", "negative"],
    enable: false // Enable manually to test with expired tokens
}
function testRefreshTokenWithExpiredToken() returns error? {
    log:printInfo("Test: Refresh token with expired token");

    // This test requires creating an expired token in the database
    // For now, we'll test with a token that was valid but has expired

    json refreshRequest = {
        refreshToken: "expired-refresh-token"
    };

    http:Response response = check authClient->post("/auth/refresh-token", refreshRequest);
    test:assertEquals(response.statusCode, 401, "Should reject expired refresh token");

    json responseBody = check response.getJsonPayload();
    test:assertTrue(responseBody.message is string, "Error message should be present");

    log:printInfo("Test passed: Expired refresh token rejected");
}

// ============================================================================
// Test: /auth/revoke-token endpoint (Subtask 11.6)
// ============================================================================

// Test: Revoke token without authentication
@test:Config {
    groups: ["revoke-token", "api", "negative"]
}
function testRevokeTokenWithoutAuth() returns error? {
    log:printInfo("Test: Revoke token without authentication");

    json revokeRequest = {
        refreshToken: "some-refresh-token"
    };

    http:Response response = check authClient->post("/auth/revoke-token", revokeRequest);
    test:assertEquals(response.statusCode, 401, "Should require authentication");

    json responseBody = check response.getJsonPayload();
    test:assertTrue(responseBody.message is string, "Error message should be present");

    log:printInfo("Test passed: Revoke requires authentication");
}

// Test: Revoke token with invalid JWT
@test:Config {
    groups: ["revoke-token", "api", "negative"]
}
function testRevokeTokenWithInvalidJWT() returns error? {
    log:printInfo("Test: Revoke token with invalid JWT");

    json revokeRequest = {
        refreshToken: "some-refresh-token"
    };

    http:Request req = new;
    req.setJsonPayload(revokeRequest);
    req.setHeader("Authorization", "Bearer invalid-jwt-token");

    http:Response response = check authClient->post("/auth/revoke-token", req);
    test:assertEquals(response.statusCode, 401, "Should reject invalid JWT");

    log:printInfo("Test passed: Invalid JWT rejected for revoke");
}

