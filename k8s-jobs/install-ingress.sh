#!/usr/bin/env bash

set -euf pipefail

helm upgrade --install nginx ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --repo https://kubernetes.github.io/ingress-nginx
