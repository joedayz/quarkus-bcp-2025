#!/bin/sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_MANIFEST="${ROOT_DIR}/k8s/expenses-all.yaml"

kubectl apply -f "${APP_MANIFEST}"
kubectl rollout status deployment/expense-service -w
kubectl rollout status deployment/expense-client -w

echo ""
echo "Esperando que el servicio LoadBalancer esté disponible..."
sleep 5

SERVICE_IP=$(kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
SERVICE_PORT=$(kubectl get svc expense-client -o jsonpath='{.spec.ports[0].port}')

if [ -n "${SERVICE_IP}" ]; then
  echo "Client available on http://${SERVICE_IP}:${SERVICE_PORT}"
else
  echo "Client service expuesto. Obtén la IP con:"
  echo "  kubectl get svc expense-client"
  echo "O usa port-forward:"
  echo "  kubectl port-forward svc/expense-client 8081:8080"
  echo "Luego accede en http://localhost:8081"
fi

