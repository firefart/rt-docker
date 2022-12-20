#!/bin/bash

# this pulls in new images and restarts everything

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export COMPOSE_PROFILES=full

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash_functions.sh"

check_files

fix_file_perms

docker compose -f docker-compose.yml pull
docker compose -f docker-compose.yml stop
docker compose -f docker-compose.yml rm -f -v -s
docker compose -f docker-compose.yml up -d --remove-orphans
docker image prune -f
