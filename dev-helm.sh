#!/bin/bash

set -euf -o pipefail

echo "uninstalling old stuff"
kubectl delete job --all --ignore-not-found
helm uninstall --ignore-not-found rt
echo "sleeping 15 seconds to let things settle"
sleep 15
echo "installing new stuff"
helm install rt helm/
echo "sleeping 2 minutes to let the database come up"
sleep 120
echo "initializing the database"
kubectl apply -f k8s-jobs/db-init.yaml
echo "done"
kubectl get pods
