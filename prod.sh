#!/bin/bash

# this pulls in new images and restarts everything

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi
. "${DIR}/bash_functions.sh"

check_files

fix_file_perms

docker compose pull
docker compose stop
docker compose rm -f -v -s
docker compose up -d --remove-orphans
docker image prune -f
