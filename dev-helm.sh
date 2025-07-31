#!/bin/bash

set -euf -o pipefail

helm uninstall --ignore-not-found rt
helm install rt helm/
