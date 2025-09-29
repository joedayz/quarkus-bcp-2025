#!/bin/sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/k8s/app-kind.yaml"

kubectl apply -f "${APP_MANIFEST}"

kubectl rollout status deployment/do378-expense -w

echo "App available on http://localhost:8080"

