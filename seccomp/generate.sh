#!/bin/bash

# Generates seccomp/chrome.json from the upstream Docker default seccomp profile.
#
# Chromium (used by WWW::Mechanize::Chrome to render dashboard charts in
# emails) needs to create user namespaces for its sandbox. The Docker default
# profile only allows clone/unshare/setns with namespace flags when the
# container has CAP_SYS_ADMIN. Instead of granting that capability or running
# with seccomp=unconfined, we take the default profile and only allow these
# syscalls unconditionally.
#
# This script is run by .github/workflows/seccomp.yml to keep the profile in
# sync with upstream.

set -euf -o pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://raw.githubusercontent.com/moby/profiles/main/seccomp/default.json}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${DIR}/chrome.json"

TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

curl -fsSL --retry 3 -o "${TMP}" "${UPSTREAM_URL}"

jq '.syscalls += [{
  "names": ["clone", "setns", "unshare"],
  "action": "SCMP_ACT_ALLOW",
  "comment": "rt-docker: allow chromium to create user namespaces for its sandbox"
}]' "${TMP}" >"${OUT}"

echo "wrote ${OUT}"
