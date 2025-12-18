#!/bin/sh
set -euo pipefail

# Script para mostrar información del cluster AKS

CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/azure-config.env"

# Cargar configuración si existe
if [ -f "${CONFIG_FILE}" ]; then
  . "${CONFIG_FILE}"
fi

if [ -z "${AKS_NAME:-}" ] || [ -z "${RESOURCE_GROUP:-}" ]; then
  echo "Error: Configuración no encontrada."
  echo "Ejecuta primero: ./scripts/azure-setup.sh"
  exit 1
fi

echo "=== AKS Cluster Info ==="
echo "Cluster: ${AKS_NAME}"
echo "Resource Group: ${RESOURCE_GROUP}"
echo ""

# Verificar conexión
if ! kubectl cluster-info &> /dev/null; then
  echo "No hay conexión con el cluster."
  echo "Conectando..."
  az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${AKS_NAME}" --overwrite-existing
fi

echo "=== Cluster Information ==="
kubectl cluster-info
echo ""

echo "=== Nodes ==="
kubectl get nodes
echo ""

echo "=== Pods ==="
kubectl get pods --all-namespaces
echo ""

echo "=== Services ==="
kubectl get svc --all-namespaces
