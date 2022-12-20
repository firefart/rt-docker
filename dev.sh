#!/bin/bash

set -euf -o pipefail

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export COMPOSE_PROFILES=full

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash_functions.sh"

check_files

fix_file_perms

awk '/^FROM / { print $2 }' Dockerfile | xargs -I % sh -c 'echo %; docker pull %'
awk '/^FROM / { print $2 }' ./nginx/Dockerfile | xargs -I % sh -c 'echo %; docker pull %'

docker compose pull
docker compose stop
docker compose rm -f 
docker compose build --progress=plain
docker compose up --remove-orphans
