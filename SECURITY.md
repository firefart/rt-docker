# Security Policy

## Reporting a Vulnerability

Do not open a public issue for a suspected vulnerability. Use GitHub's private
security-advisory reporting feature for this repository and include affected
versions, reproduction steps, impact, and any proposed mitigation.

Avoid including production credentials, private keys, customer data, or live
Request Tracker configuration in a report. Maintainers will acknowledge a
report, investigate it, and coordinate disclosure and remediation when the
issue is confirmed.

## Supported Versions

Security fixes are applied to the RT image versions currently built by
`.github/workflows/docker.yml`. Older image tags remain available but should not
be assumed to receive fixes. Prefer a concrete version tag over `latest` and
regularly rebuild or pull the selected tag to receive refreshed dependencies.
