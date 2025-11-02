#!/bin/sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PARENT_DIR="$(cd "${ROOT_DIR}/.." && pwd)"

build_image() {
  local dir="$1"
  local name="$2"
  local dockerfile="$3"

  echo "\n=== Building ${name} in ${dir} ==="
  cd "${PARENT_DIR}/${dir}"
  mvn -q package
  local tag="${name}:latest"
  docker build -f "${dockerfile}" -t "${tag}" .
  
  echo "Imagen ${tag} construida exitosamente."
  echo "Docker Desktop Kubernetes puede usar imágenes locales automáticamente."
}

build_image expense-service expense-service src/main/docker/Dockerfile.jvm
build_image expense-client expense-client src/main/docker/Dockerfile.jvm

echo ""
echo "Todas las imágenes construidas. Docker Desktop Kubernetes las encontrará automáticamente."
