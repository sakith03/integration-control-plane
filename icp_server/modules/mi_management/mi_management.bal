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

// Package: mi_management
// Provides utility functions to call the WSO2 MI Management REST API
// (at /management path) using HMAC-signed JWT auth

//
// Response format note: when a name filter is provided (e.g. ?apiName=X), the
// MI Management API returns the artifact object directly. Without a filter it
// returns {"count": N, "list": [{...}, ...]}. extractFirstFromMgmtList()
// handles both transparently.

import ballerina/http;
import ballerina/log;
import wso2/icp_server.types;

// Path prefix for all Management API endpoints
const string MGMT_API_PATH = "/management";

// ============================================================
// Internal helpers
// ============================================================

// Extract the first (or name-matching) item from a management API response.
//
// The MI Management API has two response formats:
//   1. List format (no name filter): {"count": N, "list": [{...}, ...]}
//   2. Direct format (name filter):  {"name": "...", "url": "...", ...}
//
// This function handles both transparently.
isolated function extractFirstFromMgmtList(json response, string? expectedName = ()) returns json|error {
    if response !is map<json> {
        return error("Management API response is not a JSON object");
    }
    map<json> respMap = response;
    json listField = respMap["list"];

    // List format: extract the matching item from the array
    if listField is json[] {
        json[] items = listField;
        if items.length() == 0 {
            return error("Management API response list is empty");
        }
        if expectedName is () {
            return items[0];
        }
        foreach json item in items {
            if item is map<json> {
                json nameField = item["name"];
                if nameField is string && nameField == expectedName {
                    return item;
                }
            }
        }
        return error(string `Artifact '${expectedName}' not found in management API response (searched ${items.length()} items)`);
    }

    // Direct format: the response IS the item itself
    return response;
}

// callMgmtApi makes a GET request to a management API path and returns the
// raw JSON payload. Shared by all public functions to avoid duplication.
isolated function callMgmtApi(
        http:Client mgmtClient,
        string hmacToken,
        string path
) returns json|error {
    log:printDebug("Calling MI management API", path = path);
    http:Response|error respResult = mgmtClient->get(path, {
        "Authorization": string `Bearer ${hmacToken}`,
        "Accept": "application/json"
    });

    if respResult is error {
        log:printError("MI management API request failed", 'error = respResult, path = path);
        return error(string `MI management API request failed: ${respResult.message()}`);
    }

    http:Response resp = respResult;
    if resp.statusCode != http:STATUS_OK {
        string|error errPayload = resp.getTextPayload();
        string errMsg = errPayload is string ? errPayload : "Unknown error";
        log:printError("MI management API returned non-OK status",
                statusCode = resp.statusCode, path = path, response = errMsg);
        return error(string `MI management API returned status ${resp.statusCode}: ${errMsg}`);
    }

    return check resp.getJsonPayload();
}

// fetchRawArtifactItem calls the appropriate MI Management API endpoint for
// the given artifact type and returns the raw JSON item.
//
// Handles:
//   - Path construction per artifact type
//   - Both list and direct-object response formats via extractFirstFromMgmtList
//   - Connector client-side name filtering (no name filter param on that endpoint)
//   - Template / carbon-app full-payload return (non-standard response shapes)
isolated function fetchRawArtifactItem(
        http:Client mgmtClient,
        string hmacToken,
        string artifactType,
        string artifactName,
        string? packageName = ()
) returns json|error {
    string path;
    boolean isConnector = false;
    boolean isTemplate = false;
    boolean isCarbonApp = false;
    boolean isTask = false;

    // Artifact type values are the exact strings sent by the frontend
    // (kebab-case, with "api" as the special case for RestApi).
    if artifactType == "api" {
        path = string `${MGMT_API_PATH}/apis?apiName=${artifactName}`;
    } else if artifactType == "proxy-service" {
        path = string `${MGMT_API_PATH}/proxy-services?proxyServiceName=${artifactName}`;
    } else if artifactType == "endpoint" {
        path = string `${MGMT_API_PATH}/endpoints?endpointName=${artifactName}`;
    } else if artifactType == "sequence" {
        path = string `${MGMT_API_PATH}/sequences?sequenceName=${artifactName}`;
    } else if artifactType == "task" {
        path = string `${MGMT_API_PATH}/tasks?taskName=${artifactName}`;
        isTask = true;
    } else if artifactType == "local-entry" {
        path = string `${MGMT_API_PATH}/local-entries?name=${artifactName}`;
    } else if artifactType == "message-store" {
        path = string `${MGMT_API_PATH}/message-stores?name=${artifactName}`;
    } else if artifactType == "message-processor" {
        path = string `${MGMT_API_PATH}/message-processors?name=${artifactName}`;
    } else if artifactType == "inbound-endpoint" {
        path = string `${MGMT_API_PATH}/inbound-endpoints?inboundEndpointName=${artifactName}`;
    } else if artifactType == "connector" {
        // No name filter on this endpoint; filter client-side
        path = string `${MGMT_API_PATH}/connectors`;
        isConnector = true;
    } else if artifactType == "template" {
        // Returns {"sequenceTemplateList":[...], "endpointTemplateList":[...]}
        path = string `${MGMT_API_PATH}/templates?name=${artifactName}`;
        isTemplate = true;
    } else if artifactType == "data-service" {
        path = string `${MGMT_API_PATH}/data-services?dataServiceName=${artifactName}`;
    } else if artifactType == "data-source" {
        path = string `${MGMT_API_PATH}/data-sources?name=${artifactName}`;
    } else if artifactType == "carbon-app" {
        path = string `${MGMT_API_PATH}/applications?carbonAppName=${artifactName}`;
        isCarbonApp = true;
    } else {
        return error(string `Unsupported artifact type for MI management API: ${artifactType}`);
    }

    log:printDebug("Fetching artifact from MI management API",
            artifactType = artifactType, artifactName = artifactName, path = path);

    json payload = check callMgmtApi(mgmtClient, hmacToken, path);
    log:printDebug("Received artifact payload from MI management API", artifactType = artifactType, artifactName = artifactName);
    if isConnector {
        if payload is map<json> {
            json listField = payload["list"];
            if listField is json[] {
                json[] matches = [];
                string[] packages = [];
                foreach json item in listField {
                    if item is map<json> {
                        json nameField = item["name"];
                        if nameField is string && nameField == artifactName {
                            json packageField = item["package"];
                            // If package is specified, filter by both name and package
                            if packageName is string {
                                if packageField is string && packageField == packageName {
                                    return item;
                                }
                            } else {
                                // No package specified, collect all matches for ambiguity detection
                                matches.push(item);
                                if packageField is string {
                                    packages.push(packageField);
                                }
                            }
                        }
                    }
                }

                // If package was specified but not found
                if packageName is string {
                    return error(string `Connector '${artifactName}' with package '${packageName}' not found in MI management API response`);
                }

                // Package not specified - check for ambiguity
                if matches.length() == 0 {
                    return error(string `Connector '${artifactName}' not found in MI management API response`);
                } else if matches.length() > 1 {
                    string packageList = string:'join(", ", ...packages);
                    return error(string `Ambiguous connector '${artifactName}' found in multiple packages: ${packageList}`);
                } else {
                    return matches[0];
                }
            }
        }
        return error(string `Connector '${artifactName}' not found in MI management API response`);
    }

    if isTemplate || isCarbonApp || isTask {
        return payload;
    }

    return check extractFirstFromMgmtList(payload, artifactName);
}

// ============================================================
// Public API functions
// ============================================================

// fetchArtifactDetails returns the synapse configuration XML for the named
// artifact, or the full metadata JSON when no 'configuration' field is present.
public isolated function fetchArtifactDetails(
        http:Client mgmtClient,
        string hmacToken,
        string artifactType,
        string artifactName,
        string? packageName = ()
) returns string|error {
    log:printDebug("Fetching artifact details from MI management API",
            artifactType = artifactType, artifactName = artifactName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, artifactType, artifactName, packageName);

    // The 'configuration' field holds the full synapse XML source.
    // For some artifact types (e.g. tasks) the management API may return the
    // configuration at the top level of the response, or inside a 'list' array.
    // Both layouts are handled below.
    if item is map<json> {
        map<json> itemMap = item;

        // Case 1: configuration is a top-level field (direct-object response or
        //         hybrid response where task details sit alongside a 'list' field).
        json configField = itemMap["configuration"];
        if configField is string && configField.length() > 0 {
            return configField;
        }

        // Case 2: configuration is inside a 'list' array item (list-format response
        //         where the item was not already extracted by extractFirstFromMgmtList).
        json listField = itemMap["list"];
        if listField is json[] {
            foreach json listItem in listField {
                if listItem is map<json> {
                    json listConfigField = listItem["configuration"];
                    if listConfigField is string && listConfigField.length() > 0 {
                        return listConfigField;
                    }
                }
            }
        }
    }

    return item.toJsonString();
}

// fetchArtifactWsdlUrl returns the WSDL 1.1 URL for a proxy service or data
// service, as reported by the MI Management API.
//
// Use fetchWsdlContent to retrieve the actual XML from the returned URL.
public isolated function fetchArtifactWsdlUrl(
        http:Client mgmtClient,
        string hmacToken,
        string artifactType,
        string artifactName,
        string? packageName = ()
) returns string|error {
    if artifactType != "proxy-service" && artifactType != "data-service" {
        return error(string `WSDL not available via MI management API for artifact type: ${artifactType}`);
    }

    log:printDebug("Fetching WSDL URL from MI management API",
            artifactType = artifactType, artifactName = artifactName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, artifactType, artifactName, packageName);

    if item is map<json> {
        json wsdlUrl = item["wsdl1_1"];
        if wsdlUrl is string && wsdlUrl.length() > 0 {
            log:printDebug("Got WSDL URL from MI management API",
                    artifactName = artifactName, wsdlUrl = wsdlUrl);
            return wsdlUrl;
        }
    }
    return error(string `WSDL URL not found for '${artifactName}' in MI management API response`);
}

// isLocalhostVariant checks if a hostname represents localhost or a local development machine.
// Returns true for: localhost, 127.0.0.1, ::1, localhost.localdomain, and *.local hostnames
isolated function isLocalhostVariant(string hostname) returns boolean {
    return hostname == "localhost"
        || hostname == "127.0.0.1"
        || hostname == "::1"
        || hostname == "localhost.localdomain"
        || hostname.endsWith(".local");
}

// fetchWsdlContent fetches the actual WSDL XML from the URL returned by the
// MI Management API. The URL is typically on the MI HTTP service port (e.g.
// http://host:8290/services/TestProxy?wsdl), distinct from the management port.
//
// Security: Validates that the WSDL URL points to the trusted runtime host to prevent SSRF attacks.
public isolated function fetchWsdlContent(string wsdlUrl, string trustedHost, boolean allowInsecureTLS) returns string|error {
    int? schemeEndPos = wsdlUrl.indexOf("://");
    if schemeEndPos is () {
        return error(string `Invalid WSDL URL (missing scheme): ${wsdlUrl}`);
    }

    // Validate scheme is http or https only
    string scheme = wsdlUrl.substring(0, schemeEndPos);
    if scheme != "http" && scheme != "https" {
        return error(string `Invalid WSDL URL scheme '${scheme}' (only http/https allowed): ${wsdlUrl}`);
    }

    int? pathStartPos = wsdlUrl.indexOf("/", schemeEndPos + 3);
    if pathStartPos is () {
        return error(string `Invalid WSDL URL (no path component): ${wsdlUrl}`);
    }

    // Extract host:port from URL
    string hostAndPort = wsdlUrl.substring(schemeEndPos + 3, pathStartPos);

    // Extract hostname (before the port if present)
    string urlHost;
    if hostAndPort.startsWith("[") {
        // IPv6 literal: extract the bracketed address
        int? ipv6EndPos = hostAndPort.indexOf("]");
        if ipv6EndPos is () {
            return error(string `Invalid WSDL URL (unterminated IPv6 host): ${wsdlUrl}`);
        }
        urlHost = hostAndPort.substring(1, ipv6EndPos);
    } else {
        // IPv4 or hostname: split on the port separator
        int? portSeparatorPos = hostAndPort.indexOf(":");
        if portSeparatorPos is () {
            urlHost = hostAndPort;
        } else {
            urlHost = hostAndPort.substring(0, portSeparatorPos);
        }
    }

    // Validate that the URL host matches the trusted runtime host (SSRF protection)
    // Strategy:
    //   - Exact match: always allowed
    //   - Localhost variants: if BOTH are localhost variants (127.0.0.1, ::1, *.local, etc), allow
    //   - Production hostnames: require exact match
    boolean urlIsLocalhost = isLocalhostVariant(urlHost);
    boolean trustedIsLocalhost = isLocalhostVariant(trustedHost);

    boolean isHostTrusted = urlHost == trustedHost
        || (urlIsLocalhost && trustedIsLocalhost);

    if !isHostTrusted {
        return error(string `WSDL URL host '${urlHost}' does not match trusted runtime host '${trustedHost}' (potential SSRF attack)`);
    }

    string wsdlBaseUrl = wsdlUrl.substring(0, pathStartPos);
    string wsdlPath = wsdlUrl.substring(pathStartPos);

    log:printDebug("Fetching WSDL content", wsdlBaseUrl = wsdlBaseUrl, wsdlPath = wsdlPath);

    http:Client|error wsdlClientResult = allowInsecureTLS
        ? new (wsdlBaseUrl, {secureSocket: {enable: false}})
        : new (wsdlBaseUrl);

    if wsdlClientResult is error {
        return error(string `Failed to create HTTP client for WSDL URL: ${wsdlClientResult.message()}`);
    }
    http:Client wsdlClient = wsdlClientResult;

    http:Response|error wsdlRespResult = wsdlClient->get(wsdlPath, {"Accept": "application/xml"});
    if wsdlRespResult is error {
        return error(string `WSDL content fetch failed: ${wsdlRespResult.message()}`);
    }
    http:Response wsdlResp = wsdlRespResult;

    if wsdlResp.statusCode != http:STATUS_OK {
        string|error errPayload = wsdlResp.getTextPayload();
        string errMsg = errPayload is string ? errPayload : "Unknown error";
        return error(string `WSDL content fetch returned status ${wsdlResp.statusCode}: ${errMsg}`);
    }

    string|error wsdlContent = wsdlResp.getTextPayload();
    if wsdlContent is error {
        return error(string `Failed to read WSDL content: ${wsdlContent.message()}`);
    }
    return wsdlContent;
}

// fetchLocalEntryInfo returns the name, type, and value for the named local entry.
public isolated function fetchLocalEntryInfo(
        http:Client mgmtClient,
        string hmacToken,
        string entryName
) returns types:MgmtLocalEntryInfo|error {
    log:printDebug("Fetching local entry info from MI management API", entryName = entryName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, "local-entry", entryName);
    types:MgmtLocalEntryInfo|error result = item.cloneWithType(types:MgmtLocalEntryInfo);
    if result is error {
        log:printError("Failed to parse local entry info from MI management API", result, entryName = entryName);
        return error(string `Invalid response format for local entry '${entryName}': ${result.message()}`);
    }
    return result;
}

// fetchInboundEndpointInfo returns metadata for the named inbound endpoint.
//
// NOTE: Use fetchArtifactParameterInfo to get the full protocol-specific
// parameter list (the 'parameters' array in the management API response).
public isolated function fetchInboundEndpointInfo(
        http:Client mgmtClient,
        string hmacToken,
        string inboundName
) returns types:MgmtInboundEndpointInfo|error {
    log:printDebug("Fetching inbound endpoint info from MI management API", inboundName = inboundName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, "inbound-endpoint", inboundName);
    types:MgmtInboundEndpointInfo|error result = item.cloneWithType(types:MgmtInboundEndpointInfo);
    if result is error {
        log:printError("Failed to parse inbound endpoint info from MI management API", result, inboundName = inboundName);
        return error(string `Invalid response format for inbound endpoint '${inboundName}': ${result.message()}`);
    }
    return result;
}

// fetchArtifactParameterInfo extracts key-value parameters from the management
// API response for the given artifact.
//
// For inbound endpoints: extracts the 'parameters' array [{name, value}, ...].
// For data sources: extracts the 'configurationParameters' object as key-value pairs.
// For message processors: extracts the 'parameters' object {key: value, ...} as key-value pairs.
public isolated function fetchArtifactParameterInfo(
        http:Client mgmtClient,
        string hmacToken,
        string artifactType,
        string artifactName,
        string? packageName = ()
) returns types:MgmtArtifactParameter[]|error {
    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, artifactType, artifactName, packageName);

    types:MgmtArtifactParameter[] params = [];
    if item !is map<json> {
        return params;
    }
    map<json> itemMap = item;

    // Data sources: configurationParameters is a JSON object {key: value, ...}
    if artifactType == "data-source" {
        json configParams = itemMap["configurationParameters"];
        if configParams is map<json> {
            foreach [string, json] [k, v] in configParams.entries() {
                params.push({key: k, value: v.toJsonString()});
            }
        }
        return params;
    }

    // Message processors: parameters is a JSON object {key: value, ...}
    if artifactType == "message-processor" {
        json procParams = itemMap["parameters"];
        if procParams is map<json> {
            foreach [string, json] [k, v] in procParams.entries() {
                params.push({key: k, value: v is string ? <string>v : v.toJsonString()});
            }
        }
        return params;
    }

    // Inbound endpoints: 'parameters' array [{name, value}, ...]
    json paramsField = itemMap["parameters"];
    if paramsField is json[] {
        foreach json p in paramsField {
            if p is map<json> {
                json nameField = p["name"];
                json valueField = p["value"];
                if nameField is string && valueField is string {
                    params.push({key: nameField, value: valueField});
                }
            }
        }
    }

    return params;
}

// fetchDataSourceOverview returns overview metadata for the named data source.
// Overview fields: name, type, description, driverClass, userName, url.
public isolated function fetchDataSourceOverview(
        http:Client mgmtClient,
        string hmacToken,
        string dataSourceName
) returns types:MgmtDataSourceInfo|error {
    log:printDebug("Fetching data source overview from MI management API", dataSourceName = dataSourceName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, "data-source", dataSourceName);
    types:MgmtDataSourceInfo|error result = item.cloneWithType(types:MgmtDataSourceInfo);
    if result is error {
        log:printError("Failed to parse data source info from MI management API", result, dataSourceName = dataSourceName);
        return error(string `Invalid response format for data source '${dataSourceName}': ${result.message()}`);
    }
    return result;
}

// fetchMessageStoreOverview returns overview metadata for the named message store.
// Overview fields: name, type, container, size.
public isolated function fetchMessageStoreOverview(
        http:Client mgmtClient,
        string hmacToken,
        string storeName
) returns types:MgmtMessageStoreInfo|error {
    log:printDebug("Fetching message store overview from MI management API", storeName = storeName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, "message-store", storeName);
    types:MgmtMessageStoreInfo|error result = item.cloneWithType(types:MgmtMessageStoreInfo);
    if result is error {
        log:printError("Failed to parse message store info from MI management API", result, storeName = storeName);
        return error(string `Invalid response format for message store '${storeName}': ${result.message()}`);
    }
    return result;
}

// fetchMessageProcessorOverview returns overview metadata for the named message processor.
// Overview fields: name, type, messageStore.
public isolated function fetchMessageProcessorOverview(
        http:Client mgmtClient,
        string hmacToken,
        string processorName
) returns types:MgmtMessageProcessorInfo|error {
    log:printDebug("Fetching message processor overview from MI management API", processorName = processorName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, "message-processor", processorName);
    types:MgmtMessageProcessorInfo|error result = item.cloneWithType(types:MgmtMessageProcessorInfo);
    if result is error {
        log:printError("Failed to parse message processor info from MI management API", result, processorName = processorName);
        return error(string `Invalid response format for message processor '${processorName}': ${result.message()}`);
    }
    return result;
}

// fetchDataServiceOverview parses the full MI management API response for a data service
// and returns structured overview data: dataSources, queries, resources, operations.
public isolated function fetchDataServiceOverview(
        http:Client mgmtClient,
        string hmacToken,
        string dataServiceName
) returns types:MgmtDataServiceOverview|error {
    log:printDebug("Fetching data service overview from MI management API", dataServiceName = dataServiceName);

    json item = check fetchRawArtifactItem(mgmtClient, hmacToken, "data-service", dataServiceName);
    if item !is map<json> {
        return error(string `Unexpected response format for data service '${dataServiceName}'`);
    }
    map<json> m = item;

    // Parse dataSources: [{dataSourceId, dataSourceType, dataSourceProperties:{k:v}}]
    types:MgmtDataServiceDataSource[] dataSources = [];
    json dsField = m["dataSources"];
    if dsField is json[] {
        foreach json ds in dsField {
            if ds is map<json> {
                map<json> dsMap = ds;
                string dsId = dsMap["dataSourceId"] is string ? <string>dsMap["dataSourceId"] : "";
                string? dsType = dsMap["dataSourceType"] is string ? <string>dsMap["dataSourceType"] : ();
                types:MgmtArtifactParameter[] props = [];
                json propsField = dsMap["dataSourceProperties"];
                if propsField is map<json> {
                    foreach [string, json] [k, v] in propsField.entries() {
                        props.push({key: k, value: v is string ? <string>v : v.toJsonString()});
                    }
                }
                dataSources.push({dataSourceId: dsId, dataSourceType: dsType, properties: props});
            }
        }
    }

    // Parse queries: [{id, dataSourceId, namespace}]
    types:MgmtDataServiceQuery[] queries = [];
    json queriesField = m["queries"];
    if queriesField is json[] {
        foreach json q in queriesField {
            if q is map<json> {
                map<json> qMap = q;
                queries.push({
                    id: qMap["id"] is string ? <string>qMap["id"] : "",
                    dataSourceId: qMap["dataSourceId"] is string ? <string>qMap["dataSourceId"] : (),
                    namespace: qMap["namespace"] is string ? <string>qMap["namespace"] : ()
                });
            }
        }
    }

    // Parse resources: [{resourcePath, resourceMethod, resourceQuery}]
    types:MgmtDataServiceResource[] resources = [];
    json resourcesField = m["resources"];
    if resourcesField is json[] {
        foreach json r in resourcesField {
            if r is map<json> {
                map<json> rMap = r;
                resources.push({
                    resourcePath: rMap["resourcePath"] is string ? <string>rMap["resourcePath"] : "",
                    resourceMethod: rMap["resourceMethod"] is string ? <string>rMap["resourceMethod"] : (),
                    resourceQuery: rMap["resourceQuery"] is string ? <string>rMap["resourceQuery"] : ()
                });
            }
        }
    }

    // Parse operations: [{operationName, queryName}]
    types:MgmtDataServiceOperation[] operations = [];
    json opsField = m["operations"];
    if opsField is json[] {
        foreach json op in opsField {
            if op is map<json> {
                map<json> opMap = op;
                operations.push({
                    operationName: opMap["operationName"] is string ? <string>opMap["operationName"] : "",
                    queryName: opMap["queryName"] is string ? <string>opMap["queryName"] : ()
                });
            }
        }
    }

    return {
        serviceName: m["serviceName"] is string ? <string>m["serviceName"] : dataServiceName,
        serviceDescription: m["serviceDescription"] is string ? <string>m["serviceDescription"] : (),
        wsdl1_1: m["wsdl1_1"] is string ? <string>m["wsdl1_1"] : (),
        wsdl2_0: m["wsdl2_0"] is string ? <string>m["wsdl2_0"] : (),
        swagger_url: m["swagger_url"] is string ? <string>m["swagger_url"] : (),
        dataSources: dataSources,
        queries: queries,
        resources: resources,
        operations: operations
    };
}
