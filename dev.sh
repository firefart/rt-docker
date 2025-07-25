#!/bin/bash

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash_functions.sh"

check_files
check_dev_files

fix_file_perms

docker compose -f docker-compose.yml -f docker-compose.dev.yml stop
docker compose -f docker-compose.yml -f docker-compose.dev.yml rm -f
docker compose -f docker-compose.yml -f docker-compose.dev.yml --progress=plain build --pull
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --remove-orphans
