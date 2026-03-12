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

// MI Management API Response Types
// These types reflect what the MI Management REST API returns
// for single-artifact queries (name-filtered requests).
//   - /management     → operational metadata (status, URLs, etc.)

// GET /management/proxy-services?proxyServiceName={name}
public type MgmtProxyServiceInfo record {|
    string name;
    string wsdl1_1?;
    string wsdl2_0?;
    string configuration?;
|};

// GET /management/apis?apiName={name}
public type MgmtRestApiInfo record {|
    string name;
    string url?;
    string tracing?;
    string stats?;
    string configuration?;
|};

// GET /management/endpoints?endpointName={name}
public type MgmtEndpointInfo record {|
    string name;
    string 'type?;
    boolean isActive?;
|};

// GET /management/sequences?sequenceName={name}
public type MgmtSequenceInfo record {|
    string name;
    string container?;
    string tracing?;
    string stats?;
|};

// GET /management/tasks?taskName={name}
public type MgmtTaskInfo record {|
    string name;
    string configuration?;
    string triggerType?;
    string triggerInterval?;
    string triggerCount?;
    string implementation?;
    string taskGroup?;
|};

// GET /management/local-entries?name={name}
// Open record to accept additional fields from MI Management API
public type MgmtLocalEntryInfo record {
    string name;
    string 'type?;
    string value?;
};

// GET /management/message-stores?name={name}
// Open record to accept additional fields from MI Management API
public type MgmtMessageStoreInfo record {
    string name;
    string 'type?;
    int size?;
    string container?;
};

// GET /management/message-processors?name={name}
// Open record to accept additional fields from MI Management API
// (fileName, configuration, artifactContainer, parameters, etc.)
public type MgmtMessageProcessorInfo record {
    string name;
    string 'type?;
    string status?;
    string messageStore?;
};

// GET /management/inbound-endpoints?inboundEndpointName={name}
// Full single-item response: {name, protocol, sequence, error, status, stats,
//   tracing, configuration, parameters:[{name,value},...]}
// Open record to accept additional fields from MI Management API
public type MgmtInboundEndpointInfo record {
    string name;
    string protocol?;
    string status?;
    string stats?;
    string tracing?;
};

// GET /management/connectors (no name filter — filtered client-side)
public type MgmtConnectorInfo record {|
    string name;
    string 'package?;
    string description?;
    string status?;
|};

// Individual template entry (used in sequence and endpoint template lists)
public type MgmtTemplateInfo record {|
    string name;
|};

// GET /management/data-services?dataServiceName={name}
public type MgmtDataServiceInfo record {|
    string name;
    string wsdl1_1?;
    string wsdl2_0?;
|};

public type MgmtDataServiceDataSource record {|
    string dataSourceId;
    string dataSourceType?;
    MgmtArtifactParameter[] properties;
|};

public type MgmtDataServiceQuery record {|
    string id;
    string dataSourceId?;
    string namespace?;
|};

public type MgmtDataServiceResource record {|
    string resourcePath;
    string resourceMethod?;
    string resourceQuery?;
|};

public type MgmtDataServiceOperation record {|
    string operationName;
    string queryName?;
|};

public type MgmtDataServiceOverview record {|
    string serviceName;
    string serviceDescription?;
    string wsdl1_1?;
    string wsdl2_0?;
    string swagger_url?;
    MgmtDataServiceDataSource[] dataSources;
    MgmtDataServiceQuery[] queries;
    MgmtDataServiceResource[] resources;
    MgmtDataServiceOperation[] operations;
|};

// GET /management/data-sources?name={name}
// Open record to accept additional fields from MI Management API
public type MgmtDataSourceInfo record {
    string name;
    string 'type?;
    string description?;
    string driverClass?;
    string userName?;
    string url?;
};

// Key-value pair extracted from a management API artifact response.
// Equivalent to types:Parameter but sourced from the management API.
// Note: for inbound endpoints, the management API uses field name 'name'
// (not 'key') in the parameters array; this type normalises to 'key'.
public type MgmtArtifactParameter record {|
    string key;
    string value;
|};
