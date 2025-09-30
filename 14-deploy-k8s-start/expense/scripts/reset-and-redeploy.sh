#!/bin/sh
set -euo pipefail

CLUSTER_NAME="expense-kind"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Deleting cluster ${CLUSTER_NAME} if it exists..."
KIND_EXPERIMENTAL_PROVIDER=podman kind delete cluster --name "${CLUSTER_NAME}" || true

echo "Recreating cluster ${CLUSTER_NAME}..."
"${ROOT_DIR}/scripts/kind-up.sh"

echo "Building image and loading into cluster..."
"${ROOT_DIR}/scripts/build-and-load.sh"

echo "Deploying manifests..."
"${ROOT_DIR}/scripts/deploy-kind.sh"

echo "Waiting for rollout..."
kubectl rollout status deployment/do378-expense -w

echo "All set. Test: curl http://localhost:8080/q/health"


