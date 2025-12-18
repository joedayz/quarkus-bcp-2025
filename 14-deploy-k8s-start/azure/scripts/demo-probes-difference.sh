#!/bin/sh
set -euo pipefail

# Script para demostrar la diferencia entre tener y no tener probes

echo "=== Demostración: Diferencia entre con y sin Probes ==="
echo ""
echo "Este script demuestra cómo los probes mejoran el comportamiento de los pods."
echo ""

CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/azure-config.env"
if [ -f "${CONFIG_FILE}" ]; then
  . "${CONFIG_FILE}"
fi

if [ -z "${ACR_NAME:-}" ]; then
  echo "Error: ACR_NAME no está configurado."
  echo "Ejecuta primero: ./scripts/azure-setup.sh"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST_WITH_PROBES="${ROOT_DIR}/k8s/expenses-all.yaml"
MANIFEST_NO_PROBES="${ROOT_DIR}/k8s/expenses-all-no-probes.yaml"

echo "Paso 1: Desplegar SIN probes (para comparación)"
echo "---"
read -p "¿Deseas desplegar sin probes primero? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
  echo "Desplegando sin probes..."
  TEMP_MANIFEST=$(mktemp)
  sed "s/\${ACR_NAME}/${ACR_NAME}/g" "${MANIFEST_NO_PROBES}" > "${TEMP_MANIFEST}"
  kubectl apply -f "${TEMP_MANIFEST}"
  rm "${TEMP_MANIFEST}"
  
  echo "Esperando a que los pods estén corriendo..."
  sleep 10
  
  echo ""
  echo "Estado de los pods SIN probes:"
  kubectl get pods
  
  echo ""
  echo "Endpoints del servicio expense-service:"
  kubectl get endpoints expense-service
  
  echo ""
  echo "Observa: Los pods pueden aparecer en los endpoints incluso si aún están iniciando."
  echo ""
  
  read -p "Presiona Enter para continuar con el despliegue CON probes..."
fi

echo ""
echo "Paso 2: Desplegar CON probes"
echo "---"
echo "Desplegando con probes..."
TEMP_MANIFEST=$(mktemp)
sed "s/\${ACR_NAME}/${ACR_NAME}/g" "${MANIFEST_WITH_PROBES}" > "${TEMP_MANIFEST}"
kubectl apply -f "${TEMP_MANIFEST}"
rm "${TEMP_MANIFEST}"

echo "Esperando a que los deployments se actualicen..."
kubectl rollout status deployment/expense-service -w --timeout=2m || true
kubectl rollout status deployment/expense-client -w --timeout=2m || true

echo ""
echo "Paso 3: Observar el comportamiento CON probes"
echo "---"

# Esperar un momento
sleep 5

echo "Estado de los pods CON probes:"
kubectl get pods -o wide

echo ""
echo "Verificar configuración de probes:"
SERVICE_POD=$(kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "${SERVICE_POD}" ]; then
  echo "Probes en expense-service:"
  kubectl describe pod "${SERVICE_POD}" | grep -A 3 "Liveness\|Readiness" || echo "No se encontraron probes"
fi

echo ""
echo "Endpoints del servicio expense-service:"
kubectl get endpoints expense-service

echo ""
echo "Paso 4: Simular reinicio de un pod"
echo "---"
if [ -n "${SERVICE_POD}" ]; then
  echo "Eliminando pod ${SERVICE_POD} para observar el comportamiento..."
  kubectl delete pod "${SERVICE_POD}"
  
  echo ""
  echo "Observando el nuevo pod (ejecuta en otra terminal: watch kubectl get pods):"
  sleep 3
  
  echo "Estado actual:"
  kubectl get pods
  
  echo ""
  echo "Endpoints (nota que el nuevo pod NO aparece hasta que el readiness probe tenga éxito):"
  kubectl get endpoints expense-service
  
  echo ""
  echo "Esperando a que el readiness probe tenga éxito..."
  sleep 15
  
  echo "Endpoints después de que el pod esté listo:"
  kubectl get endpoints expense-service
  
  NEW_POD=$(kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [ -n "${NEW_POD}" ]; then
    echo ""
    echo "Estado del nuevo pod:"
    kubectl get pod "${NEW_POD}"
    
    echo ""
    echo "Condiciones del pod (busca Ready=true):"
    kubectl get pod "${NEW_POD}" -o jsonpath='{.status.conditions[?(@.type=="Ready")]}' | jq '.' 2>/dev/null || kubectl get pod "${NEW_POD}" -o yaml | grep -A 5 "type: Ready"
  fi
fi

echo ""
echo "=== Resumen de la demostración ==="
echo ""
echo "✅ CON probes:"
echo "   - Los pods NO reciben tráfico hasta que el readiness probe tenga éxito"
echo "   - Los pods se reinician automáticamente si el liveness probe falla"
echo "   - Mejor experiencia para los usuarios (sin errores durante el inicio)"
echo ""
echo "❌ SIN probes:"
echo "   - Los pods pueden recibir tráfico antes de estar listos"
echo "   - Los pods muertos pueden seguir recibiendo tráfico"
echo "   - Puede causar errores para los usuarios"
echo ""
echo "Para más información, consulta: PROBES-EXERCISE.md"
