# Request Tracker with Docker

This is a complete setup for [Request Tracker](https://bestpractical.com/request-tracker) with docker and docker compose. The production setup assumes you have an external postgres database and an external SMTP server for outgoing emails. A local database server is only started in the dev configuration.

The prebuilt image is available from [https://hub.docker.com/r/firefart/requesttracker](https://hub.docker.com/r/firefart/requesttracker). The image is rebuilt on a daily basis.

The [Request Tracker for Incident Response (RT-IR)](https://bestpractical.com/rtir) extension is also installed among various others. Look at the [Dockerfile](Dockerfile) to see the available extensions.

## docker based installation

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with the `compose` plugin
- an external SMTP server to send emails
- an external IMAP server to receive emails from
- an external Postgres database

### Instruction

To start use either `./dev.sh` which builds the images locally or `./prod.sh` which uses the prebuilt ones from docker hub. Before running this you also need to add the required configuration files (see Configuration).

### Configuration

The following configuration files need to be present before starting:

- `RT_SiteConfig.pm` : RTs main configuration file. This needs to be present in the root of the dir. See `RT_SiteConfig.pm.example` for an example configration and the needed paths and settings for this configuration. For a full config reference have a look at the [official documentation](https://docs.bestpractical.com/rt/latest/RT_Config.html).
- `Caddyfile`: The webserver config. See `Caddyfile.example` for an example and the [official Caddy doc](https://caddyserver.com/docs/caddyfile) for a reference.
- `./msmtp/msmtp.conf` : config for msmtp (outgoing email). See `msmtp.conf.example` for an example. The `./msmtp` folder is also mounted to `/msmtp/` in the container so you can load certificates from the config file. [MSMTP Configuration Guide](https://marlam.de/msmtp/msmtp.html)
- `crontab` : Crontab file that will be run as the RT user. See contab.example for an example. Crontab output will be sent to the MAILTO address (it uses the msmtp config). You can use [crontab guru](https://crontab.guru/) for help with the format.
- `./getmail/getmailrc`: This file configures your E-Mail fetching. See `getmailrc.example` for an example. `getmail` configuration docs are available under [https://getmail6.org/configuration.html](https://getmail6.org/configuration.html). The configuration options for `rt-mailgate` which is used to store the emails in request tracker can be viewed under [https://docs.bestpractical.com/rt/latest/rt-mailgate.html](https://docs.bestpractical.com/rt/latest/rt-mailgate.html).

Additional configs:

- `./certs/`: This folder should contain all optional certificates needed for caddy
- `./gpg/` : This folder should contain the gpg keyring if used in rt. Be sure to chmod the files to user 1000 with 0600 so RT will not complain. You can also put a `dirmngr.conf` here to configure dirmngr. For available options see [here](https://www.gnupg.org/documentation/manuals/gnupg/Dirmngr-Configuration.html) and [here](https://www.gnupg.org/documentation/manuals/gnupg/Dirmngr-Options.html).
- `./smime/` : This folder should contain the SMIME certificate if configured in RT
- `./shredder/` : This directory will be used by the shredder functionality [https://docs.bestpractical.com/rt/latest/RT/Shredder.html](https://docs.bestpractical.com/rt/latest/RT/Shredder.html) so the backups are stored on the host

For output of your crontabs you can use the `/cron` directory so the output will be available on the host.

In the default configuration all output from RT, caddy, getmail and msmtp is available via `docker logs` (or `docker compose -f ... logs`).

### Webserver

The setup uses Caddy as a webserver. You can find an example configuration in [Caddyfile.example](Caddyfile.example). Caddy provides features like auto https with lets encrypt and more stuff that makes it easy to set up. You can find the Caddy documentation here [https://caddyserver.com/docs/caddyfile](https://caddyserver.com/docs/caddyfile).

Feel free to modify the config to your needs like auto https, certificate based authentication, basic authentication and so on. Just be sure the mailgateway host under port `:8080` is untouched and the main host contains a block for the unauth API path, otherwise everyone with access to your RT instance can create emails without the need to log in first.

#### Create Certificate

If you don't want to use the auto https feature (for example in dev) you can provide your own certificates.

Create a self signed certificate:

```bash
openssl req -x509 -newkey rsa:4096 -keyout ./certs/priv.pem -out ./certs/pub.pem -days 3650 -nodes
```

#### Example Caddy Configurations

<details>
<summary>Caddy on a domain with lets encrypt certificates</summary>

```
{
  admin off
}

# healthchecks
:1337 {
  respond "OK" 200
}

# mailgate
:8080 {
  log
  reverse_proxy rt:9000 {
    transport fastcgi
  }
}

# request tracker
rt.domain.com:443 {
  log
  tls user@email.com

  # Block access to the unauth mail gateway endpoint
  # we have a seperate mailgate server for that
  @blocked path /REST/1.0/NoAuth/mail-gateway
  respond @blocked "Nope" 403

  reverse_proxy rt:9000 {
    transport fastcgi
  }
}
```

</details>

<details>
<summary>Caddy behind a reverse proxy server with a self signed certificate</summary>

`pub.pem` and `priv.pem` need to be inside the `./certs` folder and will be mounted automatically.

```
{
  admin off
  auto_https off

  servers {
    trusted_proxies static 10.0.0.0/22
    client_ip_headers X-Orig-Addr
    trusted_proxies_strict
  }
}

# healthchecks
:1337 {
  respond "OK" 200
}

# mailgate
:8080 {
  log
  reverse_proxy rt:9000 {
    transport fastcgi
  }
}

# request tracker
:443 {
  log

  tls /certs/pub.pem /certs/priv.pem

  # Block access to the unauth mail gateway endpoint
  # we have a seperate mailgate server for that
  @blocked path /REST/1.0/NoAuth/mail-gateway
  respond @blocked "Nope" 403

  reverse_proxy rt:9000 {
    transport fastcgi {
      env SERVER_NAME {http.request.header.X-Orig-HostHeader}
    }
  }
}
```

</details>

<details>
<summary>Caddy behind a reverse proxy server with a self signed certificate and client certificate validation</summary>

`pub.pem`, `priv.pem` and `root-ca.pem` need to be inside the `./certs` folder and will be mounted automatically.

```
{
  admin off
  auto_https off

  servers {
    trusted_proxies static 10.0.0.0/22
    client_ip_headers X-Orig-Addr
    trusted_proxies_strict
  }
}

# healthchecks
:1337 {
  respond "OK" 200
}

# mailgate
:8080 {
  log
  reverse_proxy rt:9000 {
    transport fastcgi
  }
}

# request tracker
:443 {
  log

  tls /certs/pub.pem /certs/priv.pem {
    protocols tls1.3
    client_auth {
      mode require_and_verify
      trust_pool file /certs/root-ca.pem
    }
  }

  # Block access to the unauth mail gateway endpoint
  # we have a seperate mailgate server for that
  @blocked path /REST/1.0/NoAuth/mail-gateway
  respond @blocked "Nope" 403

  reverse_proxy rt:9000 {
    transport fastcgi {
      env SERVER_NAME {http.request.header.X-Orig-HostHeader}
    }
  }
}
```

</details>

<details>
<summary>Caddy behind a reverse proxy server with a self signed certificate and client certificate validation with subject validation</summary>

`pub.pem`, `priv.pem` and `root-ca.pem` need to be inside the `./certs` folder and will be mounted automatically.

```
{
  admin off
  auto_https off

  servers {
    trusted_proxies static 10.0.0.0/22
    client_ip_headers X-Orig-Addr
    trusted_proxies_strict
  }
}

# healthchecks
:1337 {
  respond "OK" 200
}

# mailgate
:8080 {
  log
  reverse_proxy rt:9000 {
    transport fastcgi
  }
}

# request tracker
:443 {
  @cert-auth {
    expression {http.request.tls.client.subject} == "CN=Subject,OU=example,O=com,C=xxx"
  }

  log

  tls /certs/pub.pem /certs/priv.pem {
    protocols tls1.3
    client_auth {
      mode require_and_verify
      trust_pool file /certs/root-ca.pem
    }
  }

  # block everything that is not from a trusted ip range
  @blocked_trusted not remote_ip 10.0.0.0/22
  respond @blocked_trusted "Nope" 403

  # Block access to the unauth mail gateway endpoint
  # we have a seperate mailgate server for that
  @blocked path /REST/1.0/NoAuth/mail-gateway
  respond @blocked "Nope" 403

  reverse_proxy @cert-auth rt:9000 {
    transport fastcgi {
      env SERVER_NAME {http.request.header.X-Orig-HostHeader}
    }
  }
}
```

</details>

<details>
<summary>Caddy behind a reverse proxy server with a self signed certificate and client certificate validation with subject validation and on a subpath</summary>

`pub.pem`, `priv.pem` and `root-ca.pem` need to be inside the `./certs` folder and will be mounted automatically. The reverse proxy needs to point to `servername/rt` otherwise you will end up with wrong paths in the cookies which will lead to file uploads not working correctly.
We will also set the REMOTE_USER to a custom header sent from the upstream proxy.

```
{
  admin off
  auto_https off

  servers {
    trusted_proxies static 10.0.0.0/22
    client_ip_headers X-Orig-Addr
    trusted_proxies_strict
  }
}

# healthchecks
:1337 {
  respond "OK" 200
}

# mailgate
:8080 {
  log
  reverse_proxy rt:9000 {
    transport fastcgi
  }
}

# request tracker
:443 {
  @cert-auth {
    expression {http.request.tls.client.subject} == "CN=Subject,OU=example,O=com,C=xxx"
  }

  log
  tls /certs/pub.pem /certs/priv.pem {
    protocols tls1.3
    client_auth {
      mode require_and_verify
      trust_pool file /certs/root-ca.pem
    }
  }

  # block everything that is not from a trusted ip range
  @blocked_trusted not remote_ip 10.0.0.0/22
  respond @blocked_trusted "Nope" 403

  handle_path /rt/* {
    # Block access to the unauth mail gateway endpoint
    # we have a seperate mailgate server for that
    @blocked path /REST/1.0/NoAuth/mail-gateway
    respond @blocked "Nope" 403

    reverse_proxy @cert-auth rt:9000 {
      transport fastcgi {
        env REMOTE_USER {http.request.header.X-Auth-Username}
        env SERVER_NAME {http.request.header.X-Orig-HostHeader}
        env REQUEST_URI {uri}
      }
    }
  }
}
```

</details>

### Init database

This initializes a fresh database. This is needed on the first run.

```bash
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action init'
```

You need to restart the rt service after this step as it crashes if the database is not initialized.

#### DEV

Hint: Add `--skip-create` in dev as the database is created by docker

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action init --skip-create'
```

### Upgrade steps

#### Upgrade Database

```bash
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4'
```

#### Fix data inconsistencies

Run multiple times with the `--resolve` switch until no errors occur

```bash
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-validator --check --resolve'
```

### RT-IR

You can simply enable RT-IR in your `RT_SiteConfig.pm` by including `Plugin('RT::IR');`. Please refer to the [docs](https://docs.bestpractical.com/rtir/latest/index.html) for additional install or upgrade steps.

To initialize the database (ONLY ON THE FIRST RUN!!!! and only after rt is fully set up)

```bash
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action insert --skip-create --datafile /opt/rtir/initialdata'
```

To upgrade

```bash
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action upgrade --skip-create --datadir /opt/rtir/upgrade --package RT::IR --ext-version 5.0.4'
```

Restart docker setup after all steps to fully load RT-IR (just run `./restart_prod.sh`).

### Extending

To include additional containers in this setup like pgadmin or change a default config, you can create a `docker-compose.override.yml` file in the projects root and it will automatically picked up and merged with the default config. Run `docker compose config` to view the merged config.

### Deprecated features

- NGINX: The old setup used nginx for the webserver. If you want to upgrade you need to migrate your nginx config to a Caddy config. See the example Caddy Configuration section for some ideas.
- compose profiles: Previously there were compose profile to also include `dozzle` for viewing logs and `pgadmin` to interact with the database. Both tools are now removed and `pgadmin` is only available in dev mode. If you still need pgadmin you can easily spin it up using docker compose.

## Kubernetes setup

```bash
helm install rt helm/
```

### Setup database

```bash
kubectl apply -f k8s-jobs/db-init.yaml
```

### Upgrade database

```bash
kubectl apply -f k8s-jobs/db-update.yaml
```
