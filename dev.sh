#!/bin/bash

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

docker-compose pull
docker-compose stop
docker-compose rm -f 
docker-compose build
docker-compose up
