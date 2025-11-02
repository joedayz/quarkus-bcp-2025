#!/bin/sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/k8s/expenses-all.yaml"

kubectl delete -f "${APP_MANIFEST}" --ignore-not-found
kubectl delete configmap expense-client-config --ignore-not-found

echo ""
echo "Recursos restantes con label app=expense-* (debería estar vacío):"
kubectl get all -l app=expense-client || true
kubectl get all -l app=expense-service || true

