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

podman-compose -f docker-compose.yml pull
podman-compose -f docker-compose.yml stop
podman-compose -f docker-compose.yml down
podman-compose -f docker-compose.yml up -d --remove-orphans
podman image prune -f
