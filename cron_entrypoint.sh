#!/bin/sh

# workaournd as docker configs are mounted and do not support the uid parameter:
# https://github.com/docker/compose/issues/9648

# cron.d files need to have special permissions
cp /crontab /etc/cron.d/crontab
chown root:root /etc/cron.d/crontab
chmod 0644 /etc/cron.d/crontab

/usr/sbin/cron -f
