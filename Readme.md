# RT

This is a complete setup for Request Tracker. The production version assumes you have an external postgres database and an external SMTP server for outgoing emails. A local database server is only started in the dev configuration.

The prebuilt image is available from [https://hub.docker.com/r/firefart/requesttracker](https://hub.docker.com/r/firefart/requesttracker). The image will be automatically rebuilt if one of the base images change.

## Configuration

The following configuration files need to be present before starting:

- `RT_SiteConfig.pm` : RTs main configuration file. This needs to be present in the root of the dir. See `RT_SiteConfig.pm.example` for an example configration and the needed paths and settings for this configuration.
- `./msmtp/msmtp.conf` : config for mstmp (outgoing email). See msmtp.conf for an example. The ./msmtp folder is also mounted to /msmtp/ in the container so you can load certificates from the config file.
- `./nginx/certs/pub.pem` : Public TLS certficate for nginx
- `./nginx/certs/priv.pem` : Private key for nginx' TLS certficate
- `crontab` : Crontab file that will be run as the RT user. See contab.example for an example. Crontab output will be sent via msmtp to the MAILTO address.

Additional configs:

- `./gpg/` : This folder should contain the gpg keyring if used in rt. Be sure to chmod the files to user 1000 with 0600 so RT will not complain.
- `./smim/` : This folder should contain the SMIME certificate if configured in RT
- `./nginx/startup-scripts/` : This folder should contain executable bash files that will be executed on nginx start. This can be used to modify the default nginx config to add client certificate authentication for example. There are several placeholders in the config file which can be replaced with sed to add some config directives at the right places.

For output of your crontabs you can use the `/cron` directory so te output will be available on the host.

In the default configuration all output from RT, nginx, getmail and msmtp is available via `docker logs` (or `docker-compose -f ... logs`).

## Create Certificate

This certificate will be used by nginx. If you want another certificate just place it in the folder.

```bash
openssl req -x509 -newkey rsa:4096 -keyout ./nginx/certs/priv.pem -out ./nginx/certs/pub.pem -days 3650 -nodes
```

## Init database

This initializes a fresh database

```bash
docker-compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action init'
```

You might need to restart the rt service after this step as it crashes if the database is not initialized.

Hint: Add `--skip-create` in dev as the database is created by docker

## Updgrade steps

### Upgrade Database

```bash
docker-compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4'
```

### Fix data inconsitencies

Run multiple times with the `--resolve` switch until no errors occur

```bash
docker-compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-validator --check --resolve'
```
