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

import icp_server.types as types;

import ballerina/http;
import ballerina/log;

// OpenSearch response types
type OpenSearchShards record {
    int total;
    int successful;
    int skipped;
    int failed;
};

type OpenSearchHitsTotal record {
    int value;
    string relation;
};

type LogSource record {
    string? app_module?;
    string? spanId?;
    string? app_name?;
    string? time?;
    string? log_file_path?;
    string? module?;
    string? level?;
    string? message?;
    string? service_type?;
    string? product?;
    string? icp_runtimeId?;
    string? deployment?;
    string? app?;
    string? artifact_container?;
    string? 'class?;
    string? traceId?;
};

type OpenSearchHit record {
    string _index;
    string _id;
    decimal? _score;
    LogSource _source;
    int[]? sort?;
};

type OpenSearchHits record {
    OpenSearchHitsTotal total;
    decimal? max_score;
    OpenSearchHit[] hits;
};

type OpenSearchResponse record {
    int took;
    boolean timed_out;
    OpenSearchShards _shards;
    OpenSearchHits hits;
};

// HTTP client for OpenSearch with SSL verification disabled
final http:Client opensearchClient = check new (opensearchUrl,
    config = {
        auth: {
            username: opensearchUsername,
            password: opensearchPassword
        },
        secureSocket: {
            enable: false
        }
    }
);

// HTTP service configuration
listener http:Listener openSerachObservabilityListener = new (defaultOpensearchAdaptorPort,
    config = {
        host: serverHost,
        secureSocket: {
            key: {
                path: keystorePath,
                password: keystorePassword
            }
        }
    }
);

@http:ServiceConfig {
    // auth: [
    //     {
    //         jwtValidatorConfig: {
    //             issuer: frontendJwtIssuer,
    //             audience: frontendJwtAudience,
    //             signatureConfig: {
    //                 secret: defaultobservabilityJwtHMACSecret
    //             }
    //         }
    //     }
    // ],
    cors: {
        allowOrigins: ["*"],
        allowHeaders: ["Content-Type", "Authorization"]
    }
}
service /observability on openSerachObservabilityListener {

    function init() {
        log:printInfo("Opensearch adapter service started at " + serverHost + ":" + observabilityServerPort.toString());
    }

    resource function post logs/[string componentType](@http:Header {name: "X-API-Key"} string? apiKeyHeader, http:Request request, types:LogEntryRequest logRequest) returns types:LogEntriesResponse|error {
        log:printInfo("Received log request for component: " + logRequest.toString());

        // Build OpenSearch query
        json query = buildLogQuery(logRequest);

        // Execute search against OpenSearch
        string sortOrder = logRequest.sort == "asc" ? "asc" : "desc";
        json searchRequest = {
            "query": query,
            "size": logRequest.'limit,
            "sort": [
                {"@timestamp": sortOrder}
            ]
        };

        log:printDebug("OpenSearch query: " + searchRequest.toJsonString());

        // Call OpenSearch
        string indexPattern;
        if componentType == "BI" {
            indexPattern = "/ballerina-application-logs-*/_search";
        } else if componentType == "MI" {
            indexPattern = "/mi-application-logs-*/_search";
        } else if componentType == "ALL" {
            // Multi-index search: combine both index patterns in a single query
            indexPattern = "/ballerina-application-logs-*,mi-application-logs-*/_search";
        } else {
            string errorMessage = "Unknown component type specified: " + componentType;
            log:printWarn(errorMessage);
            return error(errorMessage);
        }

        OpenSearchResponse searchResponse = check opensearchClient->post(indexPattern, searchRequest);
        log:printDebug("Search returned " + searchResponse.hits.total.value.toString() + " results");
        

        // Build response columns
        types:LogColumn[] columns = [
            {name: "TimeGenerated", 'type: "datetime"},
            {name: "LogLevel", 'type: "string"},
            {name: "LogEntry", 'type: "dynamic"},
            {name: "Class", 'type: "dynamic"},
            {name: "LogFilePath", 'type: "dynamic"},
            {name: "AppName", 'type: "dynamic"},
            {name: "Module", 'type: "dynamic"},
            {name: "ServiceType", 'type: "dynamic"},
            {name: "App", 'type: "dynamic"},
            {name: "Deployment", 'type: "dynamic"},
            {name: "ArtifactContainer", 'type: "dynamic"},
            {name: "Product", 'type: "dynamic"},
            {name: "IcpRuntimeId", 'type: "dynamic"},
            {name: "LogContext", 'type: "dynamic"},
            {name: "ComponentVersion", 'type: "string"},
            {name: "ComponentVersionId", 'type: "string"}
        ];

        // Build response rows
        json[][] rows = [];
        foreach OpenSearchHit hit in searchResponse.hits.hits {
            LogSource sourceData = hit._source;

            // Extract fields from the log entry
            anydata timestampData = sourceData["@timestamp"];
            string timestamp = timestampData is string ? timestampData : timestampData.toString();
            string level = sourceData?.level ?: "INFO";
            string? 'class = sourceData?.'class ?: ();
            string logFilePath = sourceData?.log_file_path ?: "";
            string? appName = sourceData?.app_name ?: ();
            string? module = sourceData?.module ?: ();
            string serviceType = sourceData?.service_type ?: "";
            string? app = sourceData?.app ?: ();
            string? deployment = sourceData?.deployment ?: ();
            string? artifactContainer = sourceData?.artifact_container ?: ();
            string product = sourceData?.product ?: "";
            string icpRuntimeId = sourceData?.icp_runtimeId ?: "";

            // Construct the full log entry string
            string logEntry = constructLogEntry(sourceData);

            json[] row = [
                timestamp,
                level,
                logEntry,
                'class,
                logFilePath,
                appName,
                module,
                serviceType,
                app,
                deployment,
                artifactContainer,
                product,
                icpRuntimeId,
                (), // LogContext - null for now
                "",
                ""
            ];
            rows.push(row);
        }

        log:printInfo("Returning " + rows.length().toString() + " log entries");

        return {
            columns: columns,
            rows: rows
        };
    }
}

// Helper function to build OpenSearch query based on request parameters
function buildLogQuery(types:LogEntryRequest logRequest) returns json {
    json[] mustClauses = [];

    // Filter by runtime IDs if specified
    string[] runtimeIds = logRequest.runtimeIdList;
    if (runtimeIds.length() > 0) {
        mustClauses.push({
            "terms": {
                "icp_runtimeId": runtimeIds
            }
        });
    }

    // Filter by log levels if specified
    string[]? levels = logRequest.logLevels;
    if (levels is string[] && levels.length() > 0) {
        mustClauses.push({
            "terms": {
                "level.keyword": levels
            }
        });
    }

    // Filter by search phrase if specified
    string? searchPhrase = logRequest.searchPhrase;
    if (searchPhrase is string && searchPhrase.length() > 0) {
        mustClauses.push({
            "match": {
                "message": searchPhrase
            }
        });
    }

    // Filter by regex phrase if specified
    string? regexPhrase = logRequest.regexPhrase;
    if (regexPhrase is string && regexPhrase.length() > 0) {
        mustClauses.push({
            "regexp": {
                "message": regexPhrase
            }
        });
    }

    // Time range filter
    map<json> timeRange = {};
    string? startTime = logRequest.startTime;
    if (startTime is string) {
        timeRange["gte"] = startTime;
    }
    string? endTime = logRequest.endTime;
    if (endTime is string) {
        timeRange["lte"] = endTime;
    }
    if (timeRange.length() > 0) {
        mustClauses.push({
            "range": {
                "@timestamp": timeRange
            }
        });
    }

    return {
        "bool": {
            "must": mustClauses
        }
    };
}

// Helper function to construct log entry string from OpenSearch document
function constructLogEntry(LogSource sourceData) returns string {
    string time = sourceData?.time ?: "";
    string level = sourceData?.level ?: "";
    string message = sourceData?.message ?: "";
    string serviceType = sourceData?.service_type ?: "";

    // Common fields
    string? traceIdValue = sourceData?.traceId;
    string traceId = traceIdValue is string && traceIdValue != "" ? " traceId=\"" + traceIdValue + "\"" : "";

    string? spanIdValue = sourceData?.spanId;
    string spanId = spanIdValue is string && spanIdValue != "" ? " spanId=\"" + spanIdValue + "\"" : "";

    string? runtimeIdValue = sourceData?.icp_runtimeId;
    string runtimeId = runtimeIdValue is string && runtimeIdValue != "" ? " icp.runtimeId=\"" + runtimeIdValue + "\"" : "";

    // Service-type specific fields
    string serviceSpecificFields = "";
    if serviceType == "ballerina" {
        string? moduleValue = sourceData?.module;
        string module = moduleValue is string && moduleValue != "" ? " module=\"" + moduleValue + "\"" : "";

        string? appNameValue = sourceData?.app_name;
        string appName = appNameValue is string && appNameValue != "" ? " app_name=\"" + appNameValue + "\"" : "";

        serviceSpecificFields = module + appName;
    } else if serviceType == "MI" {
        string? artifactContainerValue = sourceData?.artifact_container;
        string artifactContainer = artifactContainerValue is string && artifactContainerValue != "" ? " artifact_container=\"" + artifactContainerValue + "\"" : "";

        serviceSpecificFields = artifactContainer;
    }

    // Construct the log entry in logfmt style
    return string `time=${time} level=${level}${serviceSpecificFields} message="${message}"${traceId}${spanId}${runtimeId}`;
}
