import icp_server.storage;
import icp_server.types;

import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// MI dispatch: fire HTTP calls immediately via sendMIControlCommandAsync.
public isolated function dispatchMI(string runtimeId, types:ReconcileArtifactKey artifact,
        types:ReconcileAction[] actions) returns types:ControlCommand[]|error? {
    foreach types:ReconcileAction a in actions {
        if a.key == "status" {
            string miAction = a.value == "enabled" ? types:ARTIFACT_ENABLE : types:ARTIFACT_DISABLE;
            storage:sendMIControlCommandAsync(runtimeId, artifact.artifactType, artifact.artifactName, miAction);
        } else if a.key == "tracing" {
            string miAction = a.value == "enabled" ? types:ARTIFACT_ENABLE_TRACING : types:ARTIFACT_DISABLE_TRACING;
            storage:sendMIControlCommandAsync(runtimeId, artifact.artifactType, artifact.artifactName, miAction);
        } else if a.key == "statistics" {
            string miAction = a.value == "enabled" ? types:ARTIFACT_ENABLE_STATISTICS : types:ARTIFACT_DISABLE_STATISTICS;
            storage:sendMIControlCommandAsync(runtimeId, artifact.artifactType, artifact.artifactName, miAction);
        } else {
            log:printWarn("dispatchMI: unknown key", runtimeId = runtimeId, key = a.key);
        }
    }
    return [];
}

// BI dispatch: converts ReconcileActions to ControlCommands returned to the caller.
isolated function dispatchBI(string runtimeId, types:ReconcileArtifactKey artifact,
        types:ReconcileAction[] actions) returns types:ControlCommand[]|error? {
    time:Utc now = time:utcNow();
    types:ControlCommand[] commands = [];
    // Preserve the package qualifier for disambiguation across packages
    string qualifiedName = artifact.artifactName;
    string rawName = types:rawArtifactName(qualifiedName);
    string pkg = qualifiedName != rawName
        ? qualifiedName.substring(0, qualifiedName.length() - rawName.length() - 1)
        : "";
    foreach types:ReconcileAction a in actions {
        if a.key == "status" {
            types:ControlAction action = a.value == "enabled" ? types:START : types:STOP;
            commands.push({
                commandId: uuid:createType1AsString(),
                runtimeId: runtimeId,
                targetArtifact: {name: rawName, "package": pkg},
                action: action,
                issuedAt: now,
                status: types:PENDING
            });
        } else if a.key == "logLevel" {
            json payload = {
                "componentName": rawName,
                "componentPackage": pkg,
                "logLevel": a.value
            };
            commands.push({
                commandId: uuid:createType1AsString(),
                runtimeId: runtimeId,
                targetArtifact: {name: rawName, "package": pkg},
                action: types:SET_LOGGER_LEVEL,
                issuedAt: now,
                status: types:PENDING,
                payload: payload.toJsonString()
            });
        } else {
            log:printWarn("dispatchBI: unknown key", runtimeId = runtimeId, key = a.key);
        }
    }
    return commands;
}

// Reconcile from a full heartbeat. Called from runtime_service after processHeartbeat.
// Returns BI control commands to send back in heartbeat response.
public isolated function reconcileFromHeartbeat(string runtimeId, string componentId, string envId,
        string runtimeType) returns types:ControlCommand[] {
    do {
        // Determine component type
        types:Component component = check storage:getComponentById(componentId);
        string componentType = component.componentType;

        // Query all desired-state artifact keys for this component+env
        types:ReconcileArtifactKey[] artifactKeys = check storage:readReconcileArtifactKeys(componentId, envId);

        // Reconcile each artifact
        types:ControlCommand[] biCommands = [];
        log:printInfo("Starting reconciliation from heartbeat", runtimeId = runtimeId,
                componentType = componentType, artifactCount = artifactKeys.length());
        foreach types:ReconcileArtifactKey ak in artifactKeys {
            if componentType == types:MI {
                types:ControlCommand[]|error? result = reconcileArtifact(runtimeId, componentId, envId, ak, dispatchMI);
                if result is error {
                    log:printWarn("reconcileFromHeartbeat MI failed", runtimeId = runtimeId,
                            artifactName = ak.artifactName, err = result.message());
                }
            } else if componentType == types:BI {
                types:ControlCommand[]|error? result = reconcileArtifact(runtimeId, componentId, envId, ak, dispatchBI);
                if result is error {
                    log:printWarn("reconcileFromHeartbeat BI failed", runtimeId = runtimeId,
                            artifactName = ak.artifactName, err = result.message());
                } else if result is types:ControlCommand[] {
                    foreach types:ControlCommand cmd in result {
                        biCommands.push(cmd);
                    }
                }
            }
        }

        return biCommands;
    } on fail error e {
        log:printWarn("reconcileFromHeartbeat failed", runtimeId = runtimeId, err = e.message());
        return [];
    }
}

// Reconcile from delta heartbeat (no artifact payload — query desired state keys).
public isolated function reconcileDelta(string runtimeId) returns types:ControlCommand[] {
    log:printDebug("reconcileDelta: start", runtimeId = runtimeId);
    do {
        // Look up runtime context
        types:Runtime? runtimeOpt = check storage:getRuntimeById(runtimeId);
        if runtimeOpt is () {
            log:printDebug("reconcileDelta: runtime not found", runtimeId = runtimeId);
            return [];
        }
        types:Runtime runtime = runtimeOpt;
        string componentId = runtime.component.id;
        string envId = runtime.environment.id;
        string componentType = runtime.component.componentType;

        types:ReconcileArtifactKey[] artifactKeys = check storage:readReconcileArtifactKeys(componentId, envId);

        types:ControlCommand[] biCommands = [];
        foreach types:ReconcileArtifactKey ak in artifactKeys {
            if componentType == types:MI {
                types:ControlCommand[]|error? result = reconcileArtifact(runtimeId, componentId, envId, ak, dispatchMI);
                if result is error {
                    log:printWarn("reconcileDelta MI failed", runtimeId = runtimeId,
                            artifactName = ak.artifactName, err = result.message());
                }
            } else if componentType == types:BI {
                types:ControlCommand[]|error? result = reconcileArtifact(runtimeId, componentId, envId, ak, dispatchBI);
                if result is error {
                    log:printWarn("reconcileDelta BI failed", runtimeId = runtimeId,
                            artifactName = ak.artifactName, err = result.message());
                } else if result is types:ControlCommand[] {
                    foreach types:ControlCommand cmd in result {
                        biCommands.push(cmd);
                    }
                }
            }
        }

        return biCommands;
    } on fail error e {
        log:printWarn("reconcileDelta failed", runtimeId = runtimeId, err = e.message());
        return [];
    }
}
