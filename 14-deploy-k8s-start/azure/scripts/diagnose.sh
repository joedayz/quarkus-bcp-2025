#!/bin/sh
set -euo pipefail

# Script de diagnóstico para problemas de despliegue en AKS

echo "=== Diagnóstico del despliegue en AKS ==="
echo ""

echo "1. Estado de los pods:"
echo "---"
kubectl get pods -o wide
echo ""

echo "2. Estado de los servicios:"
echo "---"
kubectl get svc
echo ""

echo "3. Descripción del servicio expense-client:"
echo "---"
kubectl describe svc expense-client
echo ""

echo "4. Descripción del servicio expense-service:"
echo "---"
kubectl describe svc expense-service
echo ""

echo "5. Logs de expense-client (últimas 20 líneas):"
echo "---"
CLIENT_POD=$(kubectl get pods -l app=expense-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "${CLIENT_POD}" ]; then
  kubectl logs "${CLIENT_POD}" --tail=20
else
  echo "No se encontró pod de expense-client"
fi
echo ""

echo "6. Logs de expense-service (últimas 20 líneas):"
echo "---"
SERVICE_POD=$(kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "${SERVICE_POD}" ]; then
  kubectl logs "${SERVICE_POD}" --tail=20
else
  echo "No se encontró pod de expense-service"
fi
echo ""

echo "7. ConfigMap expense-client-config:"
echo "---"
kubectl get configmap expense-client-config -o yaml 2>/dev/null || echo "ConfigMap no encontrado"
echo ""

echo "8. Variables de entorno del pod expense-client:"
echo "---"
if [ -n "${CLIENT_POD}" ]; then
  kubectl exec "${CLIENT_POD}" -- env | grep EXPENSE || echo "No se encontró variable EXPENSE_SVC"
else
  echo "No se encontró pod de expense-client"
fi
echo ""

echo "9. Eventos recientes:"
echo "---"
kubectl get events --sort-by='.lastTimestamp' | tail -10
echo ""

echo "10. Probar conectividad desde expense-client a expense-service:"
echo "---"
if [ -n "${CLIENT_POD}" ]; then
  echo "Probando conexión a expense-service:8080..."
  kubectl exec "${CLIENT_POD}" -- wget -q -O- http://expense-service:8080/expenses 2>&1 || echo "Error en la conexión"
else
  echo "No se encontró pod de expense-client"
fi
echo ""

echo "=== Fin del diagnóstico ==="
