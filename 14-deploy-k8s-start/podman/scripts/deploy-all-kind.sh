#!/bin/sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/k8s/expenses-all.yaml"

kubectl apply -f "${APP_MANIFEST}"
kubectl rollout status deployment/expense-service -w
kubectl rollout status deployment/expense-client -w

echo "Client available on http://localhost:30081 (NodePort)"


