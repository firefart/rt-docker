# Request Tracker with Docker

This is a complete setup for [Request Tracker](https://bestpractical.com/request-tracker) with docker and docker compose. The production setup assumes you have an external postgres database and an external SMTP server for outgoing emails. A local database server is only started in the dev configuration.

The prebuilt image is available from [https://hub.docker.com/r/firefart/requesttracker](https://hub.docker.com/r/firefart/requesttracker). The image is rebuilt on a daily basis.

The [Request Tracker for Incident Response (RT-IR)](https://bestpractical.com/rtir) Extension is also installed.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with the `compose` plugin
- an external SMTP server to send emails
- an external IMAP server to receive emails from

## Instruction

To start use either `./dev.sh` which builds the images locally or `./prod.sh` which uses the prebuilt ones from docker hub. Before running this you also need to add the required configuration files (see Configuration).

## Configuration

The following configuration files need to be present before starting:

- `RT_SiteConfig.pm` : RTs main configuration file. This needs to be present in the root of the dir. See `RT_SiteConfig.pm.example` for an example configration and the needed paths and settings for this configuration.
- `./msmtp/msmtp.conf` : config for mstmp (outgoing email). See msmtp.conf for an example. The ./msmtp folder is also mounted to /msmtp/ in the container so you can load certificates from the config file.
- `./nginx/certs/pub.pem` : Public TLS certficate for nginx
- `./nginx/certs/priv.pem` : Private key for nginx' TLS certficate
- `crontab` : Crontab file that will be run as the RT user. See contab.example for an example. Crontab output will be sent to the MAILTO address (it uses the msmtp config).

Additional configs:

- `./gpg/` : This folder should contain the gpg keyring if used in rt. Be sure to chmod the files to user 1000 with 0600 so RT will not complain.
- `./smime/` : This folder should contain the SMIME certificate if configured in RT
- `./nginx/startup-scripts/` : This folder should contain executable bash files that will be executed on nginx start. This can be used to modify the default nginx config to add client certificate authentication for example. There are several placeholders in the config file which can be replaced with sed to add some config directives at the right places.
- `./shredder/` : This directory will be used by the shredder functionality [https://docs.bestpractical.com/rt/latest/RT/Shredder.html](https://docs.bestpractical.com/rt/latest/RT/Shredder.html) so the backups are stored on the host

For output of your crontabs you can use the `/cron` directory so the output will be available on the host.

In the default configuration all output from RT, nginx, getmail and msmtp is available via `docker logs` (or `docker compose -f ... logs`).

### Full Profile

There is also a `full` profile in docker compose which enables `dozzle` for viewing logs and `pgadmin` for easy db access. You can enable this profile by `docker compose --profile=full ....` or by setting the `COMPOSE_PROFILES` environment variable to `full`. For example `export COMPOSE_PROFILES=full`

#### Dozzle

The full profile starts `dozzle` which makes all logs available under `/logs/` without authentication. To change the path of `/logs/` you can put the environment var `DOZZLE_BASE` in your `.env` file of the project root and change the nginx config on startup using a custom startup script.
If you want to enable authorization on the `logs` endpoint add the following lines with the values of your choice into the `.env` file of the project root.

```
DOZZLE_USERNAME=root
DOZZLE_PASSWORD=password
```

#### PGADMIN

pgadmin will be available under `/pgadmin`. It requires a master email and password on start so this needs to be configured. For the username put the following line in `.env` with the email of your choice. If you do not supply an email the default will be `root@root.com`.

```
PGADMIN_DEFAULT_EMAIL=root@root.com
```

For the password create the file `pgadmin_password.secret` in the project root and simply put your master password in without any special syntax. This will be loaded as a docker secret.

### nginx-startup-scripts

You can use nginx-startup-scripts to change the nginx config on the fly on startup without rebuilding the image. The config contains the patterns `# __SERVER_REPLACE__` and `# __LOCATION_REPLACE__` which can be replaced to inject common patterns in the config.

Here is an example of adding client certificate authentication to the main nginx config:

```bash
#!/bin/sh

set -e

echo "adding client certificate check"
client_dn="CN=root,OU=Dep,O=Org,C=AT"
client_serial="126F4828EA098B11"
sed -i 's/# __SERVER_REPLACE__/ssl_verify_client on;\nssl_verify_depth 5;\nssl_client_certificate \/certs\/chain.pem;\nif ($ssl_client_verify != SUCCESS) { return 407; }\nif ($ssl_client_s_dn != "'"$client_dn"'") { return 408; }\nif ($ssl_client_serial !~ "'"$client_serial"'") { return 409; }/' /etc/nginx/conf.d/default.conf
echo "finished"
```

## Create Certificate

This certificate will be used by nginx. If you want another certificate just place it in the folder.

```bash
openssl req -x509 -newkey rsa:4096 -keyout ./nginx/certs/priv.pem -out ./nginx/certs/pub.pem -days 3650 -nodes
```

## Init database

This initializes a fresh database

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action init'
```

You might need to restart the rt service after this step as it crashes if the database is not initialized.

Hint: Add `--skip-create` in dev as the database is created by docker

## Upgrade steps

### Upgrade Database

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4'
```

### Fix data inconsistencies

Run multiple times with the `--resolve` switch until no errors occur

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-validator --check --resolve'
```

## RT-IR

You can simply enable RT-IR in your `RT_SiteConfig.pm` by including `Plugin('RT::IR');`. Please refer to the [docs](https://docs.bestpractical.com/rtir/latest/index.html) for additional install or upgrade steps.

To initialize the database (ONLY ON THE FIRST RUN!!!! and only after rt is fully set up)

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action insert --skip-create --datafile /opt/rtir/initialdata'
```

To upgrade

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action upgrade --skip-create --datadir /opt/rtir/upgrade --package RT::IR --ext-version 5.0.4'
```

Restart Webserver after all steps to fully load RT-IR
