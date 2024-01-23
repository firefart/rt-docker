#!/bin/sh

# this script removes all definitions from the custom profiles if it's not set
# otherwise nginx will error out if the hostname is not found
echo "checking for dozzle profile ..."
if ! host dozzle > /dev/null
then
  echo "No ip for dozzle, emptying dozzle.conf"
  echo > /etc/nginx/dozzle.conf
fi

echo "checking for pgadmin profile ..."
if ! host pgadmin > /dev/null
then
  echo "No ip for pgadmin, emptying pgadmin.conf"
  echo > /etc/nginx/pgadmin.conf
fi
