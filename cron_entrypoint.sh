#!/bin/sh

# cron.d files need to have special permissions
cp /root/crontab /etc/cron.d/crontab
chown root:root /etc/cron.d/crontab
chmod 0644 /etc/cron.d/crontab

/usr/sbin/cron -f
