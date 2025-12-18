# Script para mostrar información del cluster AKS

$configFile = Join-Path (Split-Path $PSScriptRoot -Parent) "azure-config.ps1"

# Cargar configuración si existe
if (Test-Path $configFile) {
    . $configFile
}

if (-not $AKS_NAME -or -not $RESOURCE_GROUP) {
    Write-Host "Error: Configuración no encontrada." -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts-windows\azure-setup.ps1"
    exit 1
}

Write-Host "=== AKS Cluster Info ===" -ForegroundColor Cyan
Write-Host "Cluster: $AKS_NAME"
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host ""

# Verificar conexión
$clusterInfo = kubectl cluster-info 2>$null
if (-not $clusterInfo) {
    Write-Host "No hay conexión con el cluster." -ForegroundColor Yellow
    Write-Host "Conectando..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing
}

Write-Host "=== Cluster Information ===" -ForegroundColor Cyan
kubectl cluster-info
Write-Host ""

Write-Host "=== Nodes ===" -ForegroundColor Cyan
kubectl get nodes
Write-Host ""

Write-Host "=== Pods ===" -ForegroundColor Cyan
kubectl get pods --all-namespaces
Write-Host ""

Write-Host "=== Services ===" -ForegroundColor Cyan
kubectl get svc --all-namespaces
