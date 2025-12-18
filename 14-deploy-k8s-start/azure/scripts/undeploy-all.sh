#!/bin/sh
set -euo pipefail

# Script para eliminar los recursos desplegados en AKS
# Uso: ./undeploy-all.sh [--delete-all]
#   --delete-all: También elimina ACR y AKS de Azure

DELETE_AZURE_RESOURCES=false
if [ "${1:-}" = "--delete-all" ]; then
  DELETE_AZURE_RESOURCES=true
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/k8s/expenses-all.yaml"
CONFIG_FILE="${ROOT_DIR}/azure-config.env"

# Cargar configuración si existe
if [ -f "${CONFIG_FILE}" ]; then
  . "${CONFIG_FILE}"
fi

if [ -z "${ACR_NAME:-}" ]; then
  echo "Error: ACR_NAME no está configurado."
  echo "Ejecuta primero: ./scripts/azure-setup.sh"
  exit 1
fi

echo "=== Undeploying from AKS ==="

# Reemplazar variable en el manifest
TEMP_MANIFEST=$(mktemp)
sed "s/\${ACR_NAME}/${ACR_NAME}/g" "${APP_MANIFEST}" > "${TEMP_MANIFEST}"

# Eliminar recursos de Kubernetes
kubectl delete -f "${TEMP_MANIFEST}" --ignore-not-found=true
rm "${TEMP_MANIFEST}"

echo ""
echo "Recursos de Kubernetes eliminados."

# Eliminar recursos de Azure si se solicita
if [ "${DELETE_AZURE_RESOURCES}" = "true" ]; then
  echo ""
  echo "=== Eliminando recursos de Azure ==="
  
  RESOURCE_GROUP="${RESOURCE_GROUP:-expense-rg}"
  AKS_NAME="${AKS_NAME:-expense-aks}"
  
  # Verificar que Azure CLI está instalado
  if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI no está instalado."
    echo "No se pueden eliminar los recursos de Azure."
    exit 1
  fi
  
  # Verificar login
  if ! az account show &> /dev/null; then
    echo "Error: No estás logueado en Azure."
    echo "Ejecuta: az login"
    exit 1
  fi
  
  # Eliminar AKS primero
  if az aks show --name "${AKS_NAME}" --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
    echo "Eliminando AKS '${AKS_NAME}'..."
    az aks delete --name "${AKS_NAME}" --resource-group "${RESOURCE_GROUP}" --yes --no-wait
    echo "AKS '${AKS_NAME}' en proceso de eliminación."
  else
    echo "AKS '${AKS_NAME}' no existe o ya fue eliminado."
  fi
  
  # Eliminar ACR
  if az acr show --name "${ACR_NAME}" --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
    echo "Eliminando ACR '${ACR_NAME}'..."
    az acr delete --name "${ACR_NAME}" --resource-group "${RESOURCE_GROUP}" --yes
    echo "ACR '${ACR_NAME}' eliminado."
  else
    echo "ACR '${ACR_NAME}' no existe o ya fue eliminado."
  fi
  
  echo ""
  echo "Recursos de Azure eliminados."
  echo ""
  echo "Nota: El Resource Group '${RESOURCE_GROUP}' aún existe."
  echo "Para eliminarlo completamente, ejecuta:"
  echo "  az group delete --name ${RESOURCE_GROUP} --yes --no-wait"
else
  echo ""
  echo "Nota: Los recursos de Azure (ACR, AKS, Resource Group) NO se eliminaron."
  echo "Para eliminarlos también, ejecuta:"
  echo "  ./scripts/undeploy-all.sh --delete-all"
fi
