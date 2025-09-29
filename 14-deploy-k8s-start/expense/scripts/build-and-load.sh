#!/bin/sh
set -euo pipefail

CLUSTER_NAME="expense-kind"
IMAGE_NAME="expense-restful-service:latest"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "${ROOT_DIR}"

./mvnw -q package

podman build -f src/main/docker/Dockerfile.jvm -t "${IMAGE_NAME}" .

KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image "${IMAGE_NAME}" --name "${CLUSTER_NAME}"
echo "Image ${IMAGE_NAME} loaded into kind cluster ${CLUSTER_NAME}"

