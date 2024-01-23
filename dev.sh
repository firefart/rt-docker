#!/bin/bash

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash_functions.sh"

check_files

fix_file_perms

docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml pull
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml stop
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml rm -f 
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml build --progress=plain --pull
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dozzle.yml -f docker-compose.pgadmin.yml up --remove-orphans
