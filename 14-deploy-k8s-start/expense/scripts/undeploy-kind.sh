#!/bin/sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/k8s/app-kind.yaml"

echo "Undeploying app manifests from current kube-context..."
kubectl delete -f "${APP_MANIFEST}" --ignore-not-found

echo "Done. Verify remaining resources (should be empty):"
kubectl get all -l app=do378-expense || true


