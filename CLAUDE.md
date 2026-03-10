# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based deployment setup for [Request Tracker](https://bestpractical.com/request-tracker) (RT) with the RT-IR (Incident Response) extension. The prebuilt image is published to Docker Hub as `firefart/requesttracker`.

## Running the Stack

**Development** (builds image locally, includes local Postgres and pgadmin):
```bash
./dev.sh
```

**Production** (uses prebuilt Docker Hub image):
```bash
./prod.sh        # pull new images and restart
./restart_prod.sh  # restart without pulling new images
```

**Kubernetes**:
```bash
./dev-helm.sh    # dev setup: wipe and reinstall
helm install rt helm/
```

## Required Configuration Files

These must exist before running the stack (checked by `bash_functions.sh`):

| File | Source |
|---|---|
| `RT_SiteConfig.pm` | Copy from `RT_SiteConfig.pm.example` |
| `Caddyfile` | Copy from `Caddyfile.example` |
| `msmtp/msmtp.conf` | Copy from `msmtp.conf.example` |
| `crontab` | Copy from `crontab.example` |
| `getmail/getmailrc` | Copy from `getmailrc.example` |

Dev additionally requires `pgadmin_password.secret`, `certs/pub.pem`, and `certs/priv.pem`.

Generate self-signed certs for dev:
```bash
openssl req -x509 -newkey rsa:4096 -keyout ./certs/priv.pem -out ./certs/pub.pem -days 3650 -nodes
```

## Database Operations

**Initialize (first run only)**:
```bash
# Production (external DB)
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action init'

# Dev (local DB, add --skip-create)
docker compose -f docker-compose.yml -f docker-compose.dev.yml run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action init --skip-create'
```

**Upgrade**:
```bash
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-setup-database --action upgrade --upgrade-from 4.4.4'
docker compose run --rm rt bash -c 'cd /opt/rt && perl ./sbin/rt-validator --check --resolve'
```

## Architecture

### Docker Image (Multi-stage Dockerfile)

1. **`msmtp-builder`** stage: Compiles msmtp from source with GPG verification against the upstream signing key.
2. **`builder`** stage (perl:5.42.1): Downloads and builds RT + RT-IR with GPG signature verification, installs CPAN dependencies, and installs all RT extensions. Build args: `RT_VERSION` (default 6.0.2) and `RTIR_VERSION` (default 6.0.1). The `ADDITIONAL_CPANM_ARGS` build arg is used in dev to pass `-n` (skip tests).
3. **Final image** (perl:5.42.1-slim): Copies compiled artifacts from builder stages, installs `getmail6` via `uv`, runs RT via `spawn-fcgi` on port 9000 (FastCGI).

The container exposes port 9000 (FastCGI) and uses a healthcheck via `cgi-fcgi`.

### Services (docker-compose.yml)

- **`rt`**: The RT FastCGI server (5 replicas in production). Mounts config files, gpg/smime/shredder directories.
- **`cron`**: Same image as `rt`, runs the crontab via `cron_entrypoint.sh` as root. Depends on `rt` and `caddy` being healthy (uses `rt-mailgate` through caddy port 8080).
- **`caddy`**: Reverse proxy in front of RT. Exposes port 443 (HTTPS) and port 8080 (mailgate, only to localhost). Routes FastCGI to the `rt` service on port 9000. Health endpoint on port 1337.

**Dev additions** (`docker-compose.dev.yml`): Adds `db` (PostgreSQL) and `pgadmin` (port 8888) services.

### Caddy / Webserver

The mailgate endpoint (`/REST/1.0/NoAuth/mail-gateway`) must be blocked on the main RT vhost and only accessible via the separate `:8080` vhost. See `Caddyfile.example` for multiple deployment patterns (Let's Encrypt, self-signed, client certificates, subpath).

### File Permissions

The `fix_file_perms` function in `bash_functions.sh` must be called before starting — it sets UID 1000 ownership (the `rt` user) and restrictive permissions (0700/0600) on `./cron`, `./gpg`, `./smime`, and `./shredder` directories.

### CI/CD

- **Docker builds** (`.github/workflows/docker.yml`): Builds multi-platform images (amd64/arm64) for all supported RT versions (5.0.8, 5.0.9, 6.0.0, 6.0.1, 6.0.2) on push to `main` and daily schedule. Only pushes to Docker Hub from `main`. Tags include full version, major version, and `latest` (pointing to 6.0.2).
- **Linting**: `hadolint` for Dockerfile, `yamllint` for YAML files, `kube-linter` for Kubernetes manifests.
- **Dependabot**: Daily updates for GitHub Actions and Docker base images.

### Kubernetes

Helm chart in `helm/`, one-off jobs in `k8s-jobs/` for DB init and upgrade.
