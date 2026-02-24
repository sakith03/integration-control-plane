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

// The [secrets] table contents, shared by the default module via setConfigs().
// Isolated so it is safely accessible from isolated functions via lock.
isolated map<string> _secrets = {};

// Called by the default module's init() to populate this module with the
// [secrets] configurable map (which only the default module can read from Config.toml).
public isolated function setConfigs(map<string> secretsMap) {
    lock {
        _secrets = secretsMap.clone();
    }
}

// Resolves a config value:
//   - If the value matches "$secret{alias}", the alias is looked up in the secrets map
//     and the corresponding encrypted value is decrypted and returned.
//   - Otherwise the value is returned unchanged (plain-text config).
//
// Called by any module that needs to resolve secrets, after setConfigs() has been called
// by the default module.
public isolated function resolveConfig(string configValue) returns string|error {
    if configValue.startsWith("$secret{") && configValue.endsWith("}") {
        string alias = configValue.substring(8, configValue.length() - 1);
        string encrypted;
        lock {
            string? aliasVal = _secrets[alias];
            if aliasVal is () {
                log:printError(string `Secret alias '${alias}' not found in [secrets] table.`);
                return error(string `Secret alias ${alias} not found in [secrets] table.`);
            }
            encrypted = aliasVal;
        }
        string|error decryptedVal = utils:decrypt(encrypted);
        if decryptedVal is error {
            log:printError(string `Failed to decrypt secret for alias '${alias}'`, decryptedVal);
            return error(string `Failed to decrypt secret for alias '${alias}'`, decryptedVal);
        }
        return decryptedVal;
    }
    return configValue;
}
