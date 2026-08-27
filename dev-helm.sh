#!/bin/bash

set -euf -o pipefail

NAMESPACE="${RT_DEV_NAMESPACE:-rt-dev}"
RELEASE="${RT_DEV_RELEASE:-rt}"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n "${NAMESPACE}" create secret generic "${RELEASE}-request-tracker-db-creds" \
    --from-literal=dbname=rt \
    --from-literal=username=rt \
    --from-literal=password='rt' \
    --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install "${RELEASE}" helm/ --namespace "${NAMESPACE}"
kubectl -n "${NAMESPACE}" rollout status "deployment/${RELEASE}-request-tracker-db" --timeout=180s
kubectl -n "${NAMESPACE}" apply -f k8s-jobs/db-init.yaml
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/db-init-job --timeout=300s
kubectl -n "${NAMESPACE}" get pods
