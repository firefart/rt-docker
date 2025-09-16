#!/usr/bin/env bash

helm install --namespace kube-system nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx
