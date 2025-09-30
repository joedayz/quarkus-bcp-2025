#!/bin/sh
set -euo pipefail

CLUSTER_NAME="expense-kind"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

build_and_load() {
  local dir="$1"
  local name="$2"
  local dockerfile="$3"

  echo "\n=== Building ${name} in ${dir} ==="
  cd "${ROOT_DIR}/${dir}"
  mvn -q package
  local short_tag="${name}:latest"
  local local_tag="localhost/${name}:latest"
  podman build -f "${dockerfile}" -t "${short_tag}" .
  podman tag "${short_tag}" "${local_tag}" || true

  echo "Loading ${local_tag} into kind..."
  if KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image "${local_tag}" --name "${CLUSTER_NAME}"; then
    echo "Loaded ${local_tag} via docker-image"
  else
    echo "Falling back to image-archive for ${local_tag}"
    mkdir -p "${ROOT_DIR}/${dir}/target"
    local archive_path="${ROOT_DIR}/${dir}/target/${name}-image.tar"
    podman save -o "${archive_path}" "${local_tag}"
    KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive "${archive_path}" --name "${CLUSTER_NAME}"
  fi
}

build_and_load expense-service expense-service src/main/docker/Dockerfile.jvm
build_and_load expense-client expense-client src/main/docker/Dockerfile.jvm

echo "All images loaded."


