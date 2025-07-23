#!/bin/bash

# this only restarts prod without pulling in new images

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi
. "${DIR}/bash_functions.sh"

check_files

fix_file_perms

docker compose stop
docker compose rm -f -v -s
docker compose up -d --remove-orphans
docker image prune -f
