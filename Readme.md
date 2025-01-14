# Request Tracker with Docker

This is a complete setup for [Request Tracker](https://bestpractical.com/request-tracker) with docker and docker compose. The production setup assumes you have an external postgres database and an external SMTP server for outgoing emails. A local database server is only started in the dev configuration.

The prebuilt image is available from [https://hub.docker.com/r/firefart/requesttracker](https://hub.docker.com/r/firefart/requesttracker). The image is rebuilt on a daily basis.

The [Request Tracker for Incident Response (RT-IR)](https://bestpractical.com/rtir) Extension is also installed.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with the `compose` plugin
- an external SMTP server to send emails
- an external IMAP server to receive emails from
- an external Postgres database

## Instruction

To start use either `./dev.sh` which builds the images locally or `./prod.sh` which uses the prebuilt ones from docker hub. Before running this you also need to add the required configuration files (see Configuration).

## Configuration

The following configuration files need to be present before starting:

- `RT_SiteConfig.pm` : RTs main configuration file. This needs to be present in the root of the dir. See `RT_SiteConfig.pm.example` for an example configration and the needed paths and settings for this configuration.
- `Caddyfile`: The webserver config. See `Caddyfile.example` for an example.
- `./msmtp/msmtp.conf` : config for msmtp (outgoing email). See `msmtp.conf.example` for an example. The `./msmtp` folder is also mounted to `/msmtp/` in the container so you can load certificates from the config file.
- `crontab` : Crontab file that will be run as the RT user. See contab.example for an example. Crontab output will be sent to the MAILTO address (it uses the msmtp config).
- `./getmail/getmailrc`: This file configures your E-Mail fetching. See `getmailrc.example` for an example. `getmail` configuration docs are available under [https://getmail6.org/configuration.html](https://getmail6.org/configuration.html). The configuration options for `rt-mailgate` which is used to store the emails in request tracker can be viewed under [https://docs.bestpractical.com/rt/5.0.7/rt-mailgate.html](https://docs.bestpractical.com/rt/5.0.7/rt-mailgate.html).

Additional configs:

- `./certs/`: This folder should contain all optional certificates needed for caddy
- `./gpg/` : This folder should contain the gpg keyring if used in rt. Be sure to chmod the files to user 1000 with 0600 so RT will not complain.
- `./smime/` : This folder should contain the SMIME certificate if configured in RT
- `./shredder/` : This directory will be used by the shredder functionality [https://docs.bestpractical.com/rt/latest/RT/Shredder.html](https://docs.bestpractical.com/rt/latest/RT/Shredder.html) so the backups are stored on the host

For output of your crontabs you can use the `/cron` directory so the output will be available on the host.

In the default configuration all output from RT, caddy, getmail and msmtp is available via `docker logs` (or `docker compose -f ... logs`).

## Webserver

The setup uses Caddy as a webserver. You can find an example configuration in [Caddyfile.example](Caddyfile.example). Caddy provides features like auto https with lets encrypt and more stuff that makes it easy to set up. You can find the Caddy documentation here [https://caddyserver.com/docs/caddyfile](https://caddyserver.com/docs/caddyfile).

Feel free to modify the config to your needs like auto https, certificate based authentication, basic authentication and so on. Just be sure the mailgateway host under port `:8080` is untouched and the main host contains a block for the unauth API path, otherwise everyone with access to your RT instance can create emails without the need to log in first.

### Create Certificate

If you don't want to use the auto https feature (for example in dev) you can provide your own certificates.

Create a self signed certificate:
```bash
openssl req -x509 -newkey rsa:4096 -keyout ./certs/priv.pem -out ./certs/pub.pem -days 3650 -nodes
```

## Init database

This initializes a fresh database. This is needed on the first run.

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action init'
```

You need to restart the rt service after this step as it crashes if the database is not initialized.

### DEV

Hint: Add `--skip-create` in dev as the database is created by docker

```bash
docker compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action init --skip-create'
```

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

Restart docker setup after all steps to fully load RT-IR (just run `./restart_prod.sh`).

## Deprecated features

- NGINX: The old setup used nginx for the webserver. If you want to upgrade you need to migrate your nginx config to a Caddy config
- compose profiles: Previously there were compose profile to also include `dozzle` for viewing logs and `pgadmin` to interact with the database. Both tools are now removed and `pgadmin` is only available in dev mode. If you still need pgadmin you can easily spin it up using docker compose.
