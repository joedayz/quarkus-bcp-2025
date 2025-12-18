# Script para desplegar en AKS
# Requiere: azure-setup.ps1 y build-and-push-all.ps1 ejecutados previamente

$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$configFile = Join-Path (Split-Path $PSScriptRoot -Parent) "azure-config.ps1"
$appManifest = Join-Path (Split-Path $PSScriptRoot -Parent) "k8s\expenses-all.yaml"

# Cargar configuración si existe
if (Test-Path $configFile) {
    Write-Host "Cargando configuración desde $configFile..." -ForegroundColor Cyan
    . $configFile
}

# Verificar variables requeridas
if (-not $ACR_NAME) {
    Write-Host "Error: ACR_NAME no está configurado." -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts-windows\azure-setup.ps1"
    exit 1
}

# Verificar conexión con AKS
$clusterInfo = kubectl cluster-info 2>$null
if (-not $clusterInfo) {
    Write-Host "Error: No hay conexión con el cluster de Kubernetes." -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts-windows\azure-setup.ps1"
    exit 1
}

Write-Host "=== Deploying to AKS ===" -ForegroundColor Cyan
Write-Host "ACR: $ACR_NAME.azurecr.io"
Write-Host ""

# Reemplazar variable en el manifest
$tempManifest = [System.IO.Path]::GetTempFileName()
(Get-Content $appManifest) -replace '\$\{ACR_NAME\}', $ACR_NAME | Set-Content $tempManifest

# Aplicar manifest
kubectl apply -f $tempManifest
Remove-Item $tempManifest

# Esperar a que los deployments estén listos
Write-Host ""
Write-Host "Esperando a que los deployments estén listos..." -ForegroundColor Cyan
kubectl rollout status deployment/expense-service -w --timeout=5m
kubectl rollout status deployment/expense-client -w --timeout=5m

Write-Host ""
Write-Host "=== Despliegue completado ===" -ForegroundColor Green
Write-Host ""
Write-Host "Esperando que el servicio LoadBalancer esté disponible..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Obtener información del servicio
$serviceIp = kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
$serviceHostname = kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
$servicePort = kubectl get svc expense-client -o jsonpath='{.spec.ports[0].port}'

Write-Host ""
Write-Host "=== Estado de los servicios ===" -ForegroundColor Cyan
kubectl get pods
kubectl get svc expense-service expense-client

Write-Host ""
if ($serviceIp) {
    Write-Host "✓ Client disponible en: http://$serviceIp`:$servicePort" -ForegroundColor Green
} elseif ($serviceHostname) {
    Write-Host "✓ Client disponible en: http://$serviceHostname`:$servicePort" -ForegroundColor Green
} else {
    Write-Host "El servicio LoadBalancer está configurándose..." -ForegroundColor Yellow
    Write-Host "Obtén la IP con:"
    Write-Host "  kubectl get svc expense-client"
    Write-Host ""
    Write-Host "O usa port-forward para acceso local:"
    Write-Host "  kubectl port-forward svc/expense-client 8081:8080"
    Write-Host "Luego accede en http://localhost:8081"
}
