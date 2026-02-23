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

import icp_server.utils;

import ballerina/log;
import ballerina/sql;
import ballerina/toml;

final DatabaseConnectionManager dbManager = check new (dbType, dbHost, dbPort, dbName, resolvedDbUser, resolvedDbPassword);
public final sql:Client dbClient = dbManager.getClient();

// Reads the [secrets] from the deployment.toml.
// Falls back to the corresponding plain configurable values if the file is absent, cannot be parsed, or the section does not exist.
function readStorageSecretsSection() returns map<anydata>? {
    //TODO: handle file name as config
    // map<anydata>|toml:Error config = toml:readFile("../conf/deployment.toml");
    map<anydata>|toml:Error config = toml:readFile("Config.toml");
    if config is toml:Error {
        log:printWarn("Failed to parse deployment.toml; storage module will use plain configurable values.",
            'error = config);
        return ();
    }

    anydata secretsRaw = config["secrets"];
    if secretsRaw is map<anydata> {
        return secretsRaw;
    }
    return ();
}

// Looks up the key in the storage secrets section and decrypts it.
// Falls back to the plain configurable value if the key is absent.
// Throws an error if the key is present but decryption fails.
function resolveStorageSecret(map<anydata>? secretsSection, string key, string fallback) returns string|error {
    if secretsSection is map<anydata> {
        anydata val = secretsSection[key];
        if val is string {
            return utils:decrypt(val);
        }
    }
    return fallback;
}
