# Repository Guidelines

## Project Structure & Module Organization

This repository packages Request Tracker (RT) and RTIR for Docker and Kubernetes. `Dockerfile` builds the image; `docker-compose.yml` defines production services, while `docker-compose.dev.yml` adds PostgreSQL and pgAdmin. Root shell scripts manage startup and logs. The Helm chart lives in `helm/`; database jobs are in `k8s-jobs/`. Files ending in `.example` are configuration templates.

## Build, Test, and Development Commands

- `./dev.sh` validates configuration, builds the image, and starts the development stack.
- `./prod.sh` pulls published images and recreates the production stack; use `./restart_prod.sh` to restart without pulling.
- `./logs_prod.sh` follows production service logs.
- `docker compose -f docker-compose.yml -f docker-compose.dev.yml config` validates the merged development configuration.
- `helm lint helm/` and `helm template rt helm/` validate and render the chart without modifying a cluster.

Before running the stack, copy the required templates to `RT_SiteConfig.pm`, `Caddyfile`, `msmtp/msmtp.conf`, `crontab`, and `getmail/getmailrc`. See `Readme.md` for development-only certificates and secrets.

## Coding Style & Naming Conventions

Shell scripts use Bash, `set -euf -o pipefail`, quoted expansions, four-space indentation, and `snake_case` functions. Use two-space indentation for YAML and preserve existing Helm Go-template conventions. Run `yamllint .`, `hadolint Dockerfile`, and `kube-linter lint helm/` when available. Keep version mappings synchronized between `Dockerfile`, `helm/Chart.yaml`, and CI workflows.

## Testing Guidelines

There is no standalone unit-test suite. Required checks are linting, image builds, Compose validation, and Helm rendering. For service changes, start the dev stack and inspect container health and logs. Test database initialization manifests in a disposable cluster.

## Commit & Pull Request Guidelines

History favors short subjects such as `Update Dockerfile` or `Fix RTIR version mapping`; dependency updates use `Bump <dependency> from <old> to <new>`. Keep commits focused. Pull requests should explain deployment impact, list validation performed, link issues, and call out configuration, port, image-tag, or migration changes. Include screenshots only for visible UI behavior.

## Security & Configuration

Never commit credentials, private keys, generated certificates, or live RT/mail configuration. Preserve the Caddy rule that blocks the unauthenticated mail-gateway endpoint on the public RT virtual host. Review volume permissions carefully: runtime data is expected to be owned by UID 1000 with restrictive modes.
