#!/bin/bash

# this pulls in new images and restarts everything

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export COMPOSE_PROFILES=pgadmin,dozzle

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash_functions.sh"

check_files

fix_file_perms

docker compose -f docker-compose.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml pull
docker compose -f docker-compose.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml stop
docker compose -f docker-compose.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml rm -f -v -s
docker compose -f docker-compose.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml up -d --remove-orphans
docker image prune -f
