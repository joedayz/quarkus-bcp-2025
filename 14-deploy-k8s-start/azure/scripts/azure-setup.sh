#!/bin/sh
set -euo pipefail

# Script para configurar Azure: login, crear ACR y AKS si no existen
# Uso: ./azure-setup.sh [RESOURCE_GROUP] [LOCATION] [ACR_NAME] [AKS_NAME]

RESOURCE_GROUP="${1:-expense-rg}"
LOCATION="${2:-eastus}"
ACR_NAME="${3:-expenseacr$(date +%s | tail -c 6)}"
AKS_NAME="${4:-expense-aks}"

echo "=== Azure Setup ==="
echo "Resource Group: ${RESOURCE_GROUP}"
echo "Location: ${LOCATION}"
echo "ACR Name: ${ACR_NAME}"
echo "AKS Name: ${AKS_NAME}"
echo ""

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
  echo "Error: Azure CLI no está instalado."
  echo "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
  exit 1
fi

# Login a Azure
echo "=== Verificando login en Azure ==="
if ! az account show &> /dev/null; then
  echo "No estás logueado. Iniciando login..."
  az login
fi

ACCOUNT=$(az account show --query name -o tsv)
echo "Logueado como: ${ACCOUNT}"
echo ""

# Crear Resource Group si no existe
echo "=== Creando Resource Group ==="
if az group show --name "${RESOURCE_GROUP}" &> /dev/null; then
  echo "Resource Group '${RESOURCE_GROUP}' ya existe."
else
  echo "Creando Resource Group '${RESOURCE_GROUP}' en ${LOCATION}..."
  az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"
fi
echo ""

# Crear ACR si no existe
echo "=== Creando Azure Container Registry (ACR) ==="
if az acr show --name "${ACR_NAME}" --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
  echo "ACR '${ACR_NAME}' ya existe."
else
  echo "Creando ACR '${ACR_NAME}'..."
  az acr create --resource-group "${RESOURCE_GROUP}" --name "${ACR_NAME}" --sku Basic --admin-enabled true
fi

ACR_LOGIN_SERVER=$(az acr show --name "${ACR_NAME}" --resource-group "${RESOURCE_GROUP}" --query loginServer -o tsv)
echo "ACR Login Server: ${ACR_LOGIN_SERVER}"
echo ""

# Crear AKS si no existe
echo "=== Creando Azure Kubernetes Service (AKS) ==="
if az aks show --name "${AKS_NAME}" --resource-group "${RESOURCE_GROUP}" &> /dev/null; then
  echo "AKS '${AKS_NAME}' ya existe."
else
  echo "Creando AKS '${AKS_NAME}'..."
  echo "Esto puede tardar varios minutos..."
  az aks create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${AKS_NAME}" \
    --node-count 2 \
    --enable-addons monitoring \
    --generate-ssh-keys \
    --attach-acr "${ACR_NAME}"
fi
echo ""

# Conectar AKS con ACR
echo "=== Conectando AKS con ACR ==="
az aks update --name "${AKS_NAME}" --resource-group "${RESOURCE_GROUP}" --attach-acr "${ACR_NAME}" 2>/dev/null || true
echo ""

# Obtener credenciales de AKS
echo "=== Obteniendo credenciales de AKS ==="
az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${AKS_NAME}" --overwrite-existing
echo ""

# Verificar conexión
echo "=== Verificando conexión con AKS ==="
kubectl cluster-info
kubectl get nodes
echo ""

# Guardar configuración en un archivo para otros scripts
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/azure-config.env"
cat > "${CONFIG_FILE}" <<EOF
export RESOURCE_GROUP="${RESOURCE_GROUP}"
export LOCATION="${LOCATION}"
export ACR_NAME="${ACR_NAME}"
export AKS_NAME="${AKS_NAME}"
export ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER}"
EOF

echo "=== Configuración completada ==="
echo "Configuración guardada en: ${CONFIG_FILE}"
echo ""
echo "Variables de entorno:"
echo "  RESOURCE_GROUP=${RESOURCE_GROUP}"
echo "  ACR_NAME=${ACR_NAME}"
echo "  AKS_NAME=${AKS_NAME}"
echo "  ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}"
echo ""
echo "Para usar estas variables en otros scripts, ejecuta:"
echo "  source ${CONFIG_FILE}"
