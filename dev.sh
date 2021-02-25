#!/bin/bash

set -euf -o pipefail

# check for needed config files
# these are mounted using docker-compose and are
# required by the setup
[ ! -f RT_SiteConfig.pm ] && { echo "RT_SiteConfig.pm does not exist."; exit 1; }
[ ! -f ./msmtp/msmtp.conf ] && { echo "./msmtp/msmtp.conf does not exist."; exit 1; }
[ ! -f ./nginx/certs/pub.pem ] && { echo "./nginx/certs/pub.pem does not exist."; exit 1; }
[ ! -f ./nginx/certs/priv.pem ] && { echo "./nginx/certs/priv.pem does not exist."; exit 1; }

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

docker-compose pull
docker-compose stop
docker-compose rm -f 
docker-compose build --progress=plain
docker-compose up
