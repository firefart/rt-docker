#!/bin/bash

set -euf -o pipefail

function check_files() {
  # check for needed config files
  # these are mounted using docker-compose and are
  # required by the setup
  if [[ ! -f ./RT_SiteConfig.pm ]]; then
    echo "RT_SiteConfig.pm does not exist. Please see RT_SiteConfig.pm.example for an example configuration."
    exit 1
  fi

    if [[ ! -f ./Caddyfile ]]; then
    echo "Caddyfile does not exist. Please see Caddyfile.example for an example configuration."
    exit 1
  fi

  if [[ ! -f ./msmtp/msmtp.conf ]]; then
    echo "./msmtp/msmtp.conf does not exist. Please see msmtp.conf.example for an example configuration."
    exit 1;
  fi

  if [[ ! -f ./crontab ]]; then
    echo "./crontab does not exist. Please see crontab.example for an example configuration."
    exit 1
  fi

  if [[ ! -f ./getmail/getmailrc ]]; then
    echo "./getmail/getmailrc does not exist. Please see getmailrc.example for an example configuration."
    exit 1
  fi
}

function check_dev_files() {
  if [[ ! -f ./pgadmin_password.secret ]]; then
    echo "./pgadmin_password.secret does not exist. Please set a password."
    exit 1
  fi

  if [[ ! -f ./certs/pub.pem ]]; then
    echo "./certs/pub.pem does not exist. Please see Readme.md if you want to create a self signed certificate."
    exit 1
  fi

  if [[ ! -f ./certs/priv.pem ]]; then
    echo "./certs/priv.pem does not exist. Please see Readme.md if you want to create a self signed certificate."
    exit 1
  fi
}

function fix_file_perms() {
  # needed for the gpg and smime stuff
  # id 1000 is the rt user inside the docker image
  chown -R 1000:1000 ./cron
  chown -R 1000:1000 ./gpg
  chown -R 1000:1000 ./smime
  chown -R 1000:1000 ./shredder

  chmod 0700 ./cron
  chmod 0700 ./gpg
  chmod 0700 ./smime
  chmod 0700 ./shredder

  find ./cron -type f -exec chmod 0600 {} \;
  find ./gpg -type f -exec chmod 0600 {} \;
  find ./smime -type f -exec chmod 0600 {} \;
  find ./shredder -type f -exec chmod 0600 {} \;
}
