@echo off
REM Copyright (c) 2025, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
REM
REM WSO2 Inc. licenses this file to you under the Apache License,
REM Version 2.0 (the "License"); you may not use this file except
REM in compliance with the License.
REM You may obtain a copy of the License at
REM
REM      http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing,
REM software distributed under the License is distributed on an
REM "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
REM KIND, either express or implied.  See the License for the
REM specific language governing permissions and limitations
REM under the License.

REM ICP Server Launcher Script
REM Usage: icp.bat [start^|stop^|restart^|version]

setlocal EnableDelayedExpansion
set SCRIPT_DIR=%~dp0
set JAR_FILE=!SCRIPT_DIR!icp-server.jar
for %%A in ("!SCRIPT_DIR!..") do set PARENT_DIR=%%~fA
set CONFIG_FILE=!PARENT_DIR!\conf\deployment.toml
set PID_FILE=!PARENT_DIR!\icp.pid
set LOG_DIR=!PARENT_DIR!\logs
set LOG_FILE=!LOG_DIR!\icp.log
set COMMAND=run

if /I "%~1"=="start" (
    set COMMAND=start
    shift
) else if /I "%~1"=="--start" (
    set COMMAND=start
    shift
) else if /I "%~1"=="-start" (
    set COMMAND=start
    shift
) else if /I "%~1"=="stop" (
    set COMMAND=stop
    shift
) else if /I "%~1"=="--stop" (
    set COMMAND=stop
    shift
) else if /I "%~1"=="-stop" (
    set COMMAND=stop
    shift
) else if /I "%~1"=="restart" (
    set COMMAND=restart
    shift
) else if /I "%~1"=="--restart" (
    set COMMAND=restart
    shift
) else if /I "%~1"=="-restart" (
    set COMMAND=restart
    shift
) else if /I "%~1"=="version" (
    set COMMAND=version
    shift
) else if /I "%~1"=="--version" (
    set COMMAND=version
    shift
) else if /I "%~1"=="-version" (
    set COMMAND=version
    shift
) else if /I "%~1"=="run" (
    set COMMAND=run
    shift
) else if /I "%~1"=="--run" (
    set COMMAND=run
    shift
) else if /I "%~1"=="-run" (
    set COMMAND=run
    shift
)

if /I "!COMMAND!"=="start" goto startServer
if /I "!COMMAND!"=="stop" goto stopServer
if /I "!COMMAND!"=="restart" goto restartServer
if /I "!COMMAND!"=="version" goto printVersion
goto runServer

:printVersion
set VERSION=
if exist "!PARENT_DIR!\version.txt" (
    set /p VERSION=<"!PARENT_DIR!\version.txt"
)
if defined VERSION (
    echo WSO2 Integration Control Plane !VERSION!
    goto end
)
for %%I in ("!PARENT_DIR!") do set DIST_NAME=%%~nxI
if /I not "!DIST_NAME:wso2-integration-control-plane-=!"=="!DIST_NAME!" (
    set VERSION=!DIST_NAME:wso2-integration-control-plane-=!
)
if not defined VERSION set VERSION=unknown
echo WSO2 Integration Control Plane !VERSION!
goto end

:checkJar
if not exist "!JAR_FILE!" (
    echo Error: icp-server.jar not found in !SCRIPT_DIR!
    exit /b 1
)
exit /b 0

:isRunning
set SERVER_PID=
if exist "!PID_FILE!" (
    set /p SERVER_PID=<"!PID_FILE!"
    if defined SERVER_PID (
        tasklist /FI "PID eq !SERVER_PID!" | find "!SERVER_PID!" >nul 2>&1 && exit /b 0
    )
)
exit /b 1

:prepareRun
call :checkJar
if errorlevel 1 goto end
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
cd /d "!SCRIPT_DIR!"
if exist "!CONFIG_FILE!" (
    echo Starting ICP Server with configuration: !CONFIG_FILE!
    set "BAL_CONFIG_FILES=!CONFIG_FILE!"
) else (
    echo Warning: Configuration file not found at !CONFIG_FILE!
    echo Starting ICP Server without custom configuration...
    set "BAL_CONFIG_FILES="
)
exit /b 0

:buildArgsJson
setlocal EnableDelayedExpansion
set "ARGS_JSON=["
:buildArgsJsonLoop
if "%~1"=="" goto buildArgsJsonDone
set "ARG_VALUE=%~1"
set "ARG_VALUE=!ARG_VALUE:\=\\!"
set "ARG_VALUE=!ARG_VALUE:"=\"!"
if "!ARGS_JSON!"=="[" (
    set "ARGS_JSON=!ARGS_JSON!\"!ARG_VALUE!\""
) else (
    set "ARGS_JSON=!ARGS_JSON!,\"!ARG_VALUE!\""
)
shift
goto buildArgsJsonLoop

:buildArgsJsonDone
set "ARGS_JSON=!ARGS_JSON!]"
endlocal & set "ICP_APP_ARGS_JSON=%ARGS_JSON%"
exit /b 0

:startServer
call :isRunning
if not errorlevel 1 (
    echo Process is already running with PID !SERVER_PID!
    goto end
)
if exist "!PID_FILE!" del /f /q "!PID_FILE!" >nul 2>&1
call :prepareRun
if errorlevel 1 goto end
call :buildArgsJson %*
set "ICP_JAR_FILE=!JAR_FILE!"
set "ICP_LOG_FILE=!LOG_FILE!"
set "ICP_SCRIPT_DIR=!SCRIPT_DIR!"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$jar = $env:ICP_JAR_FILE; $log = $env:ICP_LOG_FILE; $wd = $env:ICP_SCRIPT_DIR; $appArgs = @(); if ($env:ICP_APP_ARGS_JSON -and $env:ICP_APP_ARGS_JSON -ne '[]') { $appArgs = @(ConvertFrom-Json -InputObject $env:ICP_APP_ARGS_JSON) }; $javaArgs = @('-jar', $jar) + $appArgs; $p = Start-Process -FilePath 'java' -ArgumentList $javaArgs -WorkingDirectory $wd -RedirectStandardOutput $log -RedirectStandardError $log -PassThru -WindowStyle Hidden; $p.Id" > "!PID_FILE!"
set /p SERVER_PID=<"!PID_FILE!"
if not defined SERVER_PID (
    echo Failed to start ICP Server
    if exist "!PID_FILE!" del /f /q "!PID_FILE!" >nul 2>&1
    goto end
)
echo ICP Server started with PID !SERVER_PID!
echo Logs are available at !LOG_FILE!
goto end

:stopServer
call :isRunning
if errorlevel 1 (
    if exist "!PID_FILE!" del /f /q "!PID_FILE!" >nul 2>&1
    echo ICP Server is not running
    goto end
)
echo Stopping ICP Server ^(PID !SERVER_PID!^)
taskkill /PID !SERVER_PID! /T /F >nul 2>&1
del /f /q "!PID_FILE!" >nul 2>&1
echo ICP Server stopped
goto end

:restartServer
call :isRunning
if not errorlevel 1 (
    echo Stopping ICP Server ^(PID !SERVER_PID!^)
    taskkill /PID !SERVER_PID! /T /F >nul 2>&1
    del /f /q "!PID_FILE!" >nul 2>&1
    set /a WAIT_COUNT=0
    :restartWaitLoop
    tasklist /FI "PID eq !SERVER_PID!" | find "!SERVER_PID!" >nul 2>&1
    if errorlevel 1 goto startServer
    set /a WAIT_COUNT+=1
    if !WAIT_COUNT! GEQ 10 goto startServer
    ping -n 2 127.0.0.1 >nul
    goto restartWaitLoop
)
goto startServer

:runServer
call :prepareRun
if errorlevel 1 goto end
java -jar "!JAR_FILE!" %*
if exist "!PID_FILE!" del /f /q "!PID_FILE!" >nul 2>&1

:end
endlocal
