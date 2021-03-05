#!/bin/bash

set -euf -o pipefail

# check for needed config files
# these are mounted using docker-compose and are
# required by the setup
[ ! -f RT_SiteConfig.pm ] && { echo "RT_SiteConfig.pm does not exist."; exit 1; }
[ ! -f ./msmtp/msmtp.conf ] && { echo "./msmtp/msmtp.conf does not exist."; exit 1; }
[ ! -f ./nginx/certs/pub.pem ] && { echo "./nginx/certs/pub.pem does not exist."; exit 1; }
[ ! -f ./nginx/certs/priv.pem ] && { echo "./nginx/certs/priv.pem does not exist."; exit 1; }
[ ! -f ./crontab ] && { echo "./crontab does not exist."; exit 1; }
[ ! -f ./getmail/getmailrc ] && { echo "./getmail/getmailrc does not exist."; exit 1; }

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# needed for the gpg and smime stuff
# id 1000 is the rt user inside the docker image
chown 1000 ./gpg
chown 1000 ./smime
chmod 0700 ./gpg
chmod 0700 ./smime
find ./gpg -type f -exec chmod 0600 {} \;
find ./smime -type f -exec chmod 0600 {} \;

docker-compose -f docker-compose.yml pull
docker-compose -f docker-compose.yml stop
docker-compose -f docker-compose.yml rm -f -v -s
docker-compose -f docker-compose.yml up -d
docker image prune -f
