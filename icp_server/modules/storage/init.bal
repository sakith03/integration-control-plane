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

import icp_server.secrets as sec;

import ballerina/sql;

isolated sql:Client? _dbClient = ();

// Resolves DB credentials via the secrets module and establishes the connection.
public function initDb() returns error? {
    string resolvedUser = check sec:resolveConfig(dbUser);
    string resolvedPassword = check sec:resolveConfig(dbPassword);
    DatabaseConnectionManager dbManager = check new (dbType, dbHost, dbPort, dbName, resolvedUser, resolvedPassword);
    lock {
        _dbClient = dbManager.getClient();
    }
}

// Returns the initialized DB client.
// Panics with a clear message if called before initDb()
isolated function getDb() returns sql:Client {
    sql:Client? dbClient;
    lock {
        dbClient = _dbClient;
    }
    // c = dbRecord._dbClient;
    if dbClient is sql:Client {
        return dbClient;
    }
    panic error("Database client not initialized.");
}
