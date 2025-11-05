#!/bin/sh
set -euo pipefail

CLUSTER_NAME="expense-kind"
CONFIG_DIR="$(cd "$(dirname "$0")/.." && pwd)/expense/.kind"

if ! command -v kind >/dev/null 2>&1; then
  echo "kind not found. Install from https://kind.sigs.k8s.io/docs/user/quick-start/" >&2
  exit 1
fi

if ! command -v podman >/dev/null 2>&1; then
  echo "podman not found. Install Podman first." >&2
  exit 1
fi

if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster ${CLUSTER_NAME} already exists. Skipping create."
else
  KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name "${CLUSTER_NAME}" --config "${CONFIG_DIR}/kind-config.yaml"
fi

kubectl cluster-info


