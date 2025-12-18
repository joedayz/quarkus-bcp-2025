#!/bin/sh
set -euo pipefail

# Script para crear y configurar Azure API Management (APIM)

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/azure-config.env"

# Cargar configuración si existe
if [ -f "${CONFIG_FILE}" ]; then
  echo "Cargando configuración desde ${CONFIG_FILE}..."
  . "${CONFIG_FILE}"
fi

# Valores por defecto
RESOURCE_GROUP="${RESOURCE_GROUP:-expense-rg}"
LOCATION="${LOCATION:-eastus}"
APIM_NAME="${APIM_NAME:-expense-apim}"
PUBLISHER_EMAIL="${PUBLISHER_EMAIL:-admin@example.com}"
PUBLISHER_NAME="${PUBLISHER_NAME:-BCP Training}"
SKU="${SKU:-Developer}"

echo "=== Configuración de Azure API Management ==="
echo "Resource Group: ${RESOURCE_GROUP}"
echo "Location: ${LOCATION}"
echo "APIM Name: ${APIM_NAME}"
echo "SKU: ${SKU}"
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

# Verificar que el Resource Group existe
if ! az group show --name "${RESOURCE_GROUP}" &> /dev/null; then
  echo "Error: Resource Group '${RESOURCE_GROUP}' no existe."
  echo "Crea primero el Resource Group o ejecuta: ./scripts/azure-setup.sh"
  exit 1
fi

echo "=== Paso 1: Crear Azure API Management ==="
echo "Esto puede tardar 30-45 minutos..."
echo ""

# Verificar si APIM ya existe
if az apim show --resource-group "${RESOURCE_GROUP}" --name "${APIM_NAME}" &> /dev/null; then
  echo "APIM '${APIM_NAME}' ya existe."
else
  echo "Creando Azure APIM..."
  az apim create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${APIM_NAME}" \
    --publisher-email "${PUBLISHER_EMAIL}" \
    --publisher-name "${PUBLISHER_NAME}" \
    --sku-name "${SKU}" \
    --location "${LOCATION}"
fi

echo ""
echo "=== Paso 2: Obtener información del APIM ==="
GATEWAY_URL=$(az apim show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${APIM_NAME}" \
  --query "gatewayUrl" -o tsv)

echo "Gateway URL: ${GATEWAY_URL}"
echo ""

echo "=== Paso 3: Obtener IPs de los servicios en AKS ==="
# Verificar conexión con AKS
if ! kubectl cluster-info &> /dev/null; then
  echo "Advertencia: No hay conexión con AKS."
  echo "Conecta primero con: az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_NAME:-expense-aks}"
  echo ""
  echo "Puedes continuar configurando APIM manualmente desde el portal de Azure."
  exit 0
fi

SERVICE_IP=$(kubectl get svc expense-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
CLIENT_IP=$(kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "${SERVICE_IP}" ] && [ -z "${CLIENT_IP}" ]; then
  echo "Advertencia: No se encontraron IPs de LoadBalancer para los servicios."
  echo "Los servicios pueden ser ClusterIP. Para APIM necesitas:"
  echo "  1. Cambiar los servicios a LoadBalancer, o"
  echo "  2. Configurar Private Endpoint, o"
  echo "  3. Usar un Ingress Controller interno"
  echo ""
  echo "Puedes configurar APIM manualmente desde el portal de Azure:"
  echo "  https://portal.azure.com"
  exit 0
fi

echo "IPs encontradas:"
[ -n "${SERVICE_IP}" ] && echo "  expense-service: ${SERVICE_IP}"
[ -n "${CLIENT_IP}" ] && echo "  expense-client: ${CLIENT_IP}"
echo ""

echo "=== Paso 4: Configurar Backends en APIM ==="
echo ""
echo "Para configurar los backends y APIs, puedes:"
echo ""
echo "1. Usar el portal de Azure:"
echo "   https://portal.azure.com -> ${APIM_NAME}"
echo ""
echo "2. Usar Azure CLI (ver API-MANAGEMENT-EXERCISE.md para comandos detallados)"
echo ""
echo "3. Importar desde OpenAPI/Swagger si tus servicios lo exponen"
echo ""

echo "=== Información importante ==="
echo ""
echo "Gateway URL: ${GATEWAY_URL}"
echo ""
echo "Para probar las APIs, necesitarás:"
echo "1. Crear backends que apunten a tus servicios"
echo "2. Crear APIs en APIM"
echo "3. Agregar operaciones (endpoints)"
echo "4. Publicar las APIs en un producto"
echo "5. Obtener subscription key"
echo ""
echo "Ver API-MANAGEMENT-EXERCISE.md para instrucciones detalladas."
echo ""
echo "⚠️  IMPORTANTE: Azure APIM tiene costos asociados (~\$50/mes para Developer SKU)"
echo "   Elimina el servicio cuando no lo uses:"
echo "   az apim delete --resource-group ${RESOURCE_GROUP} --name ${APIM_NAME} --yes"
