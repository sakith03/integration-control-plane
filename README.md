# WSO2 Integration Control Plane

Monitor, troubleshoot and control integration deployments

# How to run

Integration Control Plane (ICP) consists of two main components: the backend server and the frontend application. 
Follow the steps below to set up and run both components.

## Start the backend server

1. Install [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/).
2. Clone this repository.
3. Run the following command in the root directory of the cloned repository:
```sh
docker build -t icp-mysql-server:1.0.0 ./icp_server/resources/db 
```
4. Run the following command to start the ICP mysql server:
```sh
docker run -d --name icp-mysql-server -p 3306:3306 -e MYSQL_ROOT_PASSWORD=icp_root_password -e MYSQL_DATABASE=icp_database icp-server:1.0.0
```
5. Navigate to the `icp_server` directory and run the following command to start the ICP server:
```sh
bal run
```

## Start the frontend application
1. Ensure you have [Node.js](https://nodejs.org/en/download/) (version 18 or above) and [Yarn](https://yarnpkg.com/getting-started/install) installed.
2. Navigate to the `icp-frontend` directory.
3. Install the dependencies by running:
```sh
yarn install
```
4. Start the frontend application by running:
```sh
yarn start
```
