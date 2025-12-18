#!/bin/sh
set -euo pipefail

# Script para probar y demostrar el funcionamiento de los probes

echo "=== Test de Liveness y Readiness Probes ==="
echo ""

# Obtener nombres de pods
SERVICE_POD=$(kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
CLIENT_POD=$(kubectl get pods -l app=expense-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "${SERVICE_POD}" ] || [ -z "${CLIENT_POD}" ]; then
  echo "Error: No se encontraron pods. Asegúrate de que los deployments estén corriendo."
  exit 1
fi

echo "Pods encontrados:"
echo "  expense-service: ${SERVICE_POD}"
echo "  expense-client: ${CLIENT_POD}"
echo ""

echo "=== 1. Verificar configuración de Probes ==="
echo ""
echo "--- Liveness y Readiness en expense-service ---"
kubectl describe pod "${SERVICE_POD}" | grep -A 5 "Liveness\|Readiness" || echo "No se encontraron probes configurados"
echo ""

echo "--- Liveness y Readiness en expense-client ---"
kubectl describe pod "${CLIENT_POD}" | grep -A 5 "Liveness\|Readiness" || echo "No se encontraron probes configurados"
echo ""

echo "=== 2. Probar endpoints de Health desde dentro de los pods ==="
echo ""

echo "--- expense-service health endpoints ---"
echo "Testing /q/health:"
kubectl exec "${SERVICE_POD}" -- wget -q -O- http://localhost:8080/q/health 2>&1 || echo "Error"
echo ""

echo "Testing /q/health/live:"
kubectl exec "${SERVICE_POD}" -- wget -q -O- http://localhost:8080/q/health/live 2>&1 || echo "Error"
echo ""

echo "Testing /q/health/ready:"
kubectl exec "${SERVICE_POD}" -- wget -q -O- http://localhost:8080/q/health/ready 2>&1 || echo "Error"
echo ""

echo "--- expense-client health endpoints ---"
echo "Testing /q/health:"
kubectl exec "${CLIENT_POD}" -- wget -q -O- http://localhost:8080/q/health 2>&1 || echo "Error"
echo ""

echo "Testing /q/health/live:"
kubectl exec "${CLIENT_POD}" -- wget -q -O- http://localhost:8080/q/health/live 2>&1 || echo "Error"
echo ""

echo "Testing /q/health/ready:"
kubectl exec "${CLIENT_POD}" -- wget -q -O- http://localhost:8080/q/health/ready 2>&1 || echo "Error"
echo ""

echo "=== 3. Ver estado de Readiness de los pods ==="
echo ""
kubectl get pods -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?\(@.type==\"Ready\"\)].status,STATUS:.status.phase
echo ""

echo "=== 4. Ver Endpoints del servicio expense-service ==="
echo ""
echo "Los endpoints muestran qué pods están listos para recibir tráfico:"
kubectl get endpoints expense-service
echo ""

echo "=== 5. Ver eventos relacionados con probes ==="
echo ""
kubectl get events --sort-by='.lastTimestamp' | grep -i "probe\|readiness\|liveness" | tail -10 || echo "No se encontraron eventos recientes de probes"
echo ""

echo "=== 6. Observar comportamiento durante reinicio ==="
echo ""
echo "Para observar el comportamiento de los probes durante un reinicio:"
echo "  1. Ejecuta en otra terminal: watch kubectl get pods"
echo "  2. Ejecuta: kubectl delete pod ${SERVICE_POD}"
echo "  3. Observa cómo el nuevo pod pasa por diferentes estados"
echo "  4. Nota que el pod NO aparece en los endpoints hasta que el readiness probe tenga éxito"
echo ""

echo "=== Test completado ==="
echo ""
echo "Para más información sobre probes, consulta: PROBES-EXERCISE.md"
