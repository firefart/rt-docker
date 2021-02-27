# RT

This is a complete setup for Request Tracker. The production version assumes you have an external postgres database and an external SMTP server for outgoing emails. Only in the dev configuration a local database server is started.

## Configuration

The following configuration files need to be present before starting:

- `RT_SiteConfig.pm` : RTs main configuration file. This needs to be present in the root of the dir. See `RT_SiteConfig.pm.example` for an example configration and the needed paths and settings for this configuration.
- `./msmtp/msmtp.conf` : config for mstmp (outgoing email). See msmtp.conf for an example. Be sure to set the logfile to `/dev/stderr` so these logs are viewable via `docker logs`
- `./nginx/certs/pub.pem` : Public TLS certficate for nginx
- `./nginx/certs/priv.pem` : Private key for nginx' TLS certficate
- `crontab` : Crontab file that will be run as the RT user. See contab.example for an example

## Development

### Create Certificate

```bash
openssl req -x509 -newkey rsa:4096 -keyout ./nginx/certs/priv.pem -out ./nginx/certs/pub.pem -days 3650 -nodes
```

## Init database

```bash
docker-compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action init'
```

Hint: Add `--skip-create` in dev as the database is created by docker

## Updgrade steps

### Upgrade Database

```bash
docker-compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4' | tee output.txt
```

### Fix data inconsitencies

Run multiple times with the `--resolve` switch until no errors occur

```bash
docker-compose -f docker-compose.yml run --rm rt bash -c 'cd /opt/rt5 && perl ./sbin/rt-validator --check' | tee output.txt
```

## TODO:

chown nobody:nobody on RT_SiteConfig.pm and gpg data files
