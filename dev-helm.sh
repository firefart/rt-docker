#!/bin/bash

set -euf -o pipefail

helm uninstall --ignore-not-found rt
sleep 5
helm install rt helm/
