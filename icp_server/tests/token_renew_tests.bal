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

// Test: Token refresh fails without authorization header
@test:Config {
    groups: ["token-renew", "negative"]
}
function testRenewTokenWithoutAuthHeader() returns error? {
    log:printInfo("Test: Token renewal without auth header");

    // Send renew token request without Authorization header
    http:Response response = check authClient->post("/auth/renew-token", {});

    // Assert response status (should be 401 Unauthorized)
    assertStatusCode(response.statusCode, 401, "Expected status code 401 without auth header");

    // Parse response body
    json responseBody = check response.getJsonPayload();

    // Assert error message
    test:assertTrue(responseBody.message is string, "Error message should be present");

    log:printInfo("Test passed: Token renewal rejected without auth header");
}

// Test: Token refresh fails with invalid token
@test:Config {
    groups: ["token-renew", "negative"]
}
function testRenewTokenWithInvalidToken() returns error? {
    log:printInfo("Test: Token renewal with invalid token");

    // Create an invalid token (wrong signature)
    string invalidToken = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";

    // Send renew token request with invalid token
    http:Response response = check authClient->post("/auth/renew-token", {}, {
        "Authorization": invalidToken
    });

    // Assert response status (should be 401 Unauthorized)
    assertStatusCode(response.statusCode, 401, "Expected status code 401 with invalid token");

    log:printInfo("Test passed: Token renewal rejected with invalid token");
}

// Test: Token refresh fails with expired token
// Note: Skipping this test because we cannot generate a token that's already expired
// The JWT library creates tokens with current timestamp, so expTime is always in the future
@test:Config {
    groups: ["token-renew", "negative"],
    enable: false
}
function testRenewTokenWithExpiredToken() returns error? {
    log:printInfo("Test: Token renewal with expired token");

    // Generate an expired token
    string expiredToken = check generateExpiredToken(
            "550e8400-e29b-41d4-a716-446655440000",
            "admin"
    );

    string authHeader = createAuthHeader(expiredToken);

    // Send renew token request with expired token
    http:Response response = check authClient->post("/auth/renew-token", {}, {
        "Authorization": authHeader
    });

    // Assert response status (should be 401 Unauthorized)
    assertStatusCode(response.statusCode, 401, "Expected status code 401 with expired token");

    log:printInfo("Test passed: Token renewal rejected with expired token");
}

