#!/bin/sh
set -euo pipefail

# Script para construir y subir imágenes a Azure Container Registry
# Requiere: azure-setup.sh ejecutado previamente o variables de entorno configuradas

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/azure-config.env"

# Cargar configuración si existe
if [ -f "${CONFIG_FILE}" ]; then
  echo "Cargando configuración desde ${CONFIG_FILE}..."
  . "${CONFIG_FILE}"
fi

# Verificar variables requeridas
if [ -z "${ACR_NAME:-}" ]; then
  echo "Error: ACR_NAME no está configurado."
  echo "Ejecuta primero: ./scripts/azure-setup.sh"
  exit 1
fi

ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"

echo "=== Build and Push to ACR ==="
echo "ACR: ${ACR_LOGIN_SERVER}"
echo ""

# Verificar que Azure CLI está instalado y logueado
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI no está instalado."
  exit 1
fi

if ! az account show &> /dev/null; then
  echo "Error: No estás logueado en Azure."
  echo "Ejecuta: az login"
  exit 1
fi

# Detectar si usar podman o docker
CONTAINER_CMD=""
if command -v podman &> /dev/null; then
  CONTAINER_CMD="podman"
  echo "Detectado: Podman"
elif command -v docker &> /dev/null; then
  CONTAINER_CMD="docker"
  echo "Detectado: Docker"
else
  echo "Error: No se encontró ni podman ni docker instalado."
  exit 1
fi

# Login a ACR
echo "=== Login a ACR ==="
if [ "${CONTAINER_CMD}" = "podman" ]; then
  # Podman requiere usar token explícito (--expose-token evita usar docker)
  echo "Obteniendo token de ACR para Podman..."
  ACR_TOKEN=$(az acr login --name "${ACR_NAME}" --expose-token --output tsv --query accessToken 2>/dev/null)
  if [ -z "${ACR_TOKEN}" ]; then
    echo "Error: No se pudo obtener el token de ACR."
    exit 1
  fi
  echo "${ACR_TOKEN}" | "${CONTAINER_CMD}" login "${ACR_LOGIN_SERVER}" --username "00000000-0000-0000-0000-000000000000" --password-stdin
  if [ $? -ne 0 ]; then
    echo "Error: Falló el login a ACR con Podman."
    exit 1
  fi
  echo "Login exitoso con Podman."
else
  # Docker puede usar el método estándar
  az acr login --name "${ACR_NAME}"
  if [ $? -ne 0 ]; then
    echo "Error: Falló el login a ACR con Docker."
    exit 1
  fi
fi
echo ""

build_and_push() {
  local dir="$1"
  local name="$2"
  local dockerfile="$3"

  echo "=== Building ${name} in ${dir} ==="
  cd "${ROOT_DIR}/${dir}"
  
  # Construir con Maven
  mvn -q package
  
  # Construir imagen para arquitectura AMD64 (requerida por AKS)
  local image_tag="${ACR_LOGIN_SERVER}/${name}:latest"
  
  if [ "${CONTAINER_CMD}" = "podman" ]; then
    # Podman usa --platform para especificar arquitectura
    echo "Construyendo imagen para plataforma linux/amd64..."
    "${CONTAINER_CMD}" build --platform linux/amd64 -f "${dockerfile}" -t "${image_tag}" .
  elif [ "${CONTAINER_CMD}" = "docker" ]; then
    # Docker puede usar buildx para multi-arch o --platform
    if docker buildx version &> /dev/null; then
      echo "Usando buildx para construir imagen multi-arch (linux/amd64)..."
      docker buildx build --platform linux/amd64 -f "${dockerfile}" -t "${image_tag}" --load .
    else
      echo "Construyendo imagen para plataforma linux/amd64..."
      docker build --platform linux/amd64 -f "${dockerfile}" -t "${image_tag}" .
    fi
  fi
  
  echo "=== Pushing ${image_tag} to ACR ==="
  "${CONTAINER_CMD}" push "${image_tag}"
  
  echo "Imagen ${image_tag} construida y subida exitosamente."
  echo ""
}

build_and_push expense-service expense-service src/main/docker/Dockerfile.jvm
build_and_push expense-client expense-client src/main/docker/Dockerfile.jvm

echo "=== Todas las imágenes construidas y subidas a ACR ==="
echo "ACR: ${ACR_LOGIN_SERVER}"
