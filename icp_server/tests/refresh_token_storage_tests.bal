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

import icp_server.auth as auth;
import icp_server.storage as storage;
import icp_server.types;

import ballerina/log;
import ballerina/test;

// Test: Validate refresh token with valid token
@test:Config {
    groups: ["refresh-token", "storage"]
}
function testValidateRefreshTokenValid() returns error? {
    log:printInfo("Test: Validate valid refresh token");

    // Generate and store a valid token
    string tokenId = auth:generateTokenId();
    string userId = "550e8400-e29b-41d4-a716-446655440000"; // admin user
    string refreshToken = auth:generateRefreshToken();
    string tokenHash = auth:hashRefreshToken(refreshToken);
    int expirySeconds = 604800; // 7 days - won't expire during test

    // Store the token
    error? storeResult = storage:storeRefreshToken(
            tokenId,
            userId,
            tokenHash,
            expirySeconds,
            "Test User Agent",
            "192.168.1.100"
    );
    test:assertFalse(storeResult is error, "Should store token successfully");

    // Validate the token
    types:User|error validationResult = storage:validateRefreshToken(tokenHash);

    // Assert validation succeeded and returned user
    test:assertFalse(validationResult is error, "Should validate token successfully");

    if validationResult is types:User {
        test:assertEquals(validationResult.userId, userId, "Should return correct user ID");
        test:assertEquals(validationResult.username, "admin", "Should return correct username");
    }

    log:printInfo("Test passed: Valid token validated successfully");
}

// Test: Validate refresh token with expired token
@test:Config {
    groups: ["refresh-token", "storage"]
}
function testValidateRefreshTokenExpired() returns error? {
    log:printInfo("Test: Validate expired refresh token");

    // Generate and store an expired token
    string tokenId = auth:generateTokenId();
    string userId = "550e8400-e29b-41d4-a716-446655440000"; // admin user
    string refreshToken = auth:generateRefreshToken();
    string tokenHash = auth:hashRefreshToken(refreshToken);
    int expirySeconds = -1; // Expired 1 second ago

    // Store the expired token
    error? storeResult = storage:storeRefreshToken(
            tokenId,
            userId,
            tokenHash,
            expirySeconds,
            "Test User Agent",
            "192.168.1.100"
    );
    test:assertFalse(storeResult is error, "Should store expired token successfully");

    // Try to validate the expired token
    types:User|error validationResult = storage:validateRefreshToken(tokenHash);

    // Assert validation failed
    test:assertTrue(validationResult is error, "Should reject expired token");

    if validationResult is error {
        log:printInfo("Test passed: Expired token rejected with error", errorMsg = validationResult.message());
    }
}

// Test: Validate refresh token with revoked token
@test:Config {
    groups: ["refresh-token", "storage"]
}
function testValidateRefreshTokenRevoked() returns error? {
    log:printInfo("Test: Validate revoked refresh token");

    // Generate and store a valid token
    string tokenId = auth:generateTokenId();
    string userId = "550e8400-e29b-41d4-a716-446655440000"; // admin user
    string refreshToken = auth:generateRefreshToken();
    string tokenHash = auth:hashRefreshToken(refreshToken);
    int expirySeconds = 604800; // 7 days

    // Store the token
    error? storeResult = storage:storeRefreshToken(
            tokenId,
            userId,
            tokenHash,
            expirySeconds,
            "Test User Agent",
            "192.168.1.100"
    );
    test:assertFalse(storeResult is error, "Should store token successfully");

    // Revoke the token
    error? revokeResult = storage:revokeRefreshToken(tokenHash);
    test:assertFalse(revokeResult is error, "Should revoke token successfully");

    // Try to validate the revoked token
    types:User|error validationResult = storage:validateRefreshToken(tokenHash);

    // Assert validation failed
    test:assertTrue(validationResult is error, "Should reject revoked token");

    if validationResult is error {
        log:printInfo("Test passed: Revoked token rejected with error", errorMsg = validationResult.message());
    }
}

// Test: Validate refresh token with non-existent token
@test:Config {
    groups: ["refresh-token", "storage"]
}
function testValidateRefreshTokenNotFound() returns error? {
    log:printInfo("Test: Validate non-existent refresh token");

    // Generate a hash that doesn't exist in database
    string nonExistentToken = auth:generateRefreshToken();
    string nonExistentHash = auth:hashRefreshToken(nonExistentToken);

    // Try to validate non-existent token
    types:User|error validationResult = storage:validateRefreshToken(nonExistentHash);

    // Assert validation failed
    test:assertTrue(validationResult is error, "Should reject non-existent token");

    if validationResult is error {
        log:printInfo("Test passed: Non-existent token rejected with error", errorMsg = validationResult.message());
    }
}

