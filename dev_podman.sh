#!/bin/bash

set -euf -o pipefail

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/bash_functions.sh"

check_files

fix_file_perms

podman-compose pull
podman-compose stop
podman-compose down
podman-compose build --pull
podman-compose up --remove-orphans
