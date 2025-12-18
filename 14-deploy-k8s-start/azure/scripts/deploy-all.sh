#!/bin/sh
set -euo pipefail

# Script para desplegar en AKS
# Requiere: azure-setup.sh y build-and-push-all.sh ejecutados previamente

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/azure-config.env"
APP_MANIFEST="${ROOT_DIR}/k8s/expenses-all.yaml"

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

# Verificar conexión con AKS
if ! kubectl cluster-info &> /dev/null; then
  echo "Error: No hay conexión con el cluster de Kubernetes."
  echo "Ejecuta primero: ./scripts/azure-setup.sh"
  exit 1
fi

echo "=== Deploying to AKS ==="
echo "ACR: ${ACR_NAME}.azurecr.io"
echo ""

# Reemplazar variable en el manifest
TEMP_MANIFEST=$(mktemp)
sed "s/\${ACR_NAME}/${ACR_NAME}/g" "${APP_MANIFEST}" > "${TEMP_MANIFEST}"

# Aplicar manifest
kubectl apply -f "${TEMP_MANIFEST}"
rm "${TEMP_MANIFEST}"

# Esperar a que los deployments estén listos
echo ""
echo "Esperando a que los deployments estén listos..."
kubectl rollout status deployment/expense-service -w --timeout=5m
kubectl rollout status deployment/expense-client -w --timeout=5m

echo ""
echo "=== Despliegue completado ==="
echo ""
echo "Esperando que el servicio LoadBalancer esté disponible..."
sleep 10

# Obtener información del servicio
SERVICE_IP=$(kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
SERVICE_HOSTNAME=$(kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
SERVICE_PORT=$(kubectl get svc expense-client -o jsonpath='{.spec.ports[0].port}')

echo ""
echo "=== Estado de los servicios ==="
kubectl get pods
kubectl get svc expense-service expense-client

echo ""
if [ -n "${SERVICE_IP}" ]; then
  echo "✓ Client disponible en: http://${SERVICE_IP}:${SERVICE_PORT}"
elif [ -n "${SERVICE_HOSTNAME}" ]; then
  echo "✓ Client disponible en: http://${SERVICE_HOSTNAME}:${SERVICE_PORT}"
else
  echo "El servicio LoadBalancer está configurándose..."
  echo "Obtén la IP con:"
  echo "  kubectl get svc expense-client"
  echo ""
  echo "O usa port-forward para acceso local:"
  echo "  kubectl port-forward svc/expense-client 8081:8080"
  echo "Luego accede en http://localhost:8081"
fi
