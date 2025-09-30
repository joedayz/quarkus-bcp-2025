#!/bin/sh
set -euo pipefail

CLUSTER_NAME="expense-kind"
IMAGE_NAME_BASE="expense-restful-service:latest"
LOCAL_IMAGE_NAME="localhost/expense-restful-service:latest"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "${ROOT_DIR}"

mvn -q package

podman build -f src/main/docker/Dockerfile.jvm -t "${IMAGE_NAME_BASE}" .
# Ensure the image is also tagged with the localhost registry name used by Podman
podman tag "${IMAGE_NAME_BASE}" "${LOCAL_IMAGE_NAME}" || true

# Load localhost-tag first (Podman default), then try the short tag without failing the script
if KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image "${LOCAL_IMAGE_NAME}" --name "${CLUSTER_NAME}"; then
  echo "Loaded ${LOCAL_IMAGE_NAME} via kind load docker-image"
else
  echo "Falling back to image-archive load for ${LOCAL_IMAGE_NAME}"
  TMP_ARCHIVE="${ROOT_DIR}/target/expense-restful-service-image.tar"
  mkdir -p "$(dirname "${TMP_ARCHIVE}")"
  podman save -o "${TMP_ARCHIVE}" "${LOCAL_IMAGE_NAME}"
  KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive "${TMP_ARCHIVE}" --name "${CLUSTER_NAME}"
  echo "Loaded ${LOCAL_IMAGE_NAME} via kind load image-archive"
fi

# Try loading the short tag as optional (may not exist as a separate local reference)
KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image "${IMAGE_NAME_BASE}" --name "${CLUSTER_NAME}" || echo "Warning: ${IMAGE_NAME_BASE} not present locally; continuing."
echo "Images loaded into kind cluster ${CLUSTER_NAME}: ${LOCAL_IMAGE_NAME} (required), ${IMAGE_NAME_BASE} (optional)"

