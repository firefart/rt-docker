#!/bin/bash

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

docker-compose -f docker-compose.yml pull
docker-compose -f docker-compose.yml stop
docker-compose -f docker-compose.yml rm -f -v -s
docker-compose -f docker-compose.yml up -d
docker image prune -f
