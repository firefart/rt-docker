#!/bin/sh

# this script removes all definitions from the full profile if it's not set
# otherwise nginx will error out if the hostname is not found
echo "checking for full profile ..."
if ! host dozzle > /dev/null
then
  echo "No ip for dozzle, emptying full.conf"
  echo > /etc/nginx/full.conf
fi
