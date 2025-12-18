# Quick Start - Despliegue en Azure AKS

## Prerrequisitos rápidos

```bash
# Verificar instalaciones
az --version          # Azure CLI
docker --version      # Docker (o podman --version)
kubectl version       # Kubernetes CLI
mvn --version         # Maven

# Nota: Los scripts detectan automáticamente si usas Podman o Docker
```

## Pasos rápidos (Linux/macOS)

```bash
cd azure

# 1. Configurar Azure (crea ACR y AKS) - ~15 minutos
./scripts/azure-setup.sh

# 2. Construir y subir imágenes a ACR
./scripts/build-and-push-all.sh

# 3. Desplegar en AKS
./scripts/deploy-all.sh

# 4. Probar
kubectl get svc expense-client
curl http://[IP_DEL_LOADBALANCER]:8080/expenses
```

## Pasos rápidos (Windows PowerShell)

```powershell
cd azure

# 1. Configurar Azure (crea ACR y AKS) - ~15 minutos
.\scripts-windows\azure-setup.ps1

# 2. Construir y subir imágenes a ACR
.\scripts-windows\build-and-push-all.ps1

# 3. Desplegar en AKS
.\scripts-windows\deploy-all.ps1

# 4. Probar
kubectl get svc expense-client
```

## Limpieza rápida

```bash
# Solo eliminar recursos de Kubernetes (mantiene AKS/ACR)
./scripts/undeploy-all.sh

# Eliminar TODO (ACR, AKS, Resource Group)
source azure-config.env
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## Ver información del cluster

```bash
./scripts/cluster-info.sh
```

## Troubleshooting rápido

```bash
# Script de diagnóstico completo
./scripts/diagnose.sh

# Reconectar con AKS
source azure-config.env
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Ver logs de un pod
kubectl logs -f deployment/expense-service
kubectl logs -f deployment/expense-client

# Ver eventos
kubectl get events --sort-by='.lastTimestamp'

# Verificar estado de pods y servicios
kubectl get pods
kubectl get svc

# Verificar variable EXPENSE_SVC
CLIENT_POD=$(kubectl get pods -l app=expense-client -o jsonpath='{.items[0].metadata.name}')
kubectl exec $CLIENT_POD -- env | grep EXPENSE_SVC

# Probar conectividad desde expense-client a expense-service
kubectl exec $CLIENT_POD -- wget -q -O- http://expense-service:8080/expenses

# Port-forward para acceso local
kubectl port-forward svc/expense-client 8081:8080

# Recrear pods si hay problemas
kubectl delete pods -l app=expense-client
kubectl delete pods -l app=expense-service
```

Para más detalles, ver [README.md](README.md)

Para troubleshooting completo, ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

Para configurar Health Checks en Quarkus, ver [HEALTH-CHECKS-SETUP.md](HEALTH-CHECKS-SETUP.md)

Para aprender sobre Health Checks y Probes, ver [PROBES-EXERCISE.md](PROBES-EXERCISE.md)

Para aprender sobre Azure API Management (APIM), ver [API-MANAGEMENT-EXERCISE.md](API-MANAGEMENT-EXERCISE.md)
