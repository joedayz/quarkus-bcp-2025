# Script para eliminar los recursos desplegados en AKS
# Uso: .\undeploy-all.ps1 [-DeleteAll]
#   -DeleteAll: También elimina ACR y AKS de Azure

param(
    [switch]$DeleteAll
)

$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$appManifest = Join-Path (Split-Path $PSScriptRoot -Parent) "k8s\expenses-all.yaml"
$configFilePs1 = Join-Path (Split-Path $PSScriptRoot -Parent) "azure-config.ps1"
$configFileEnv = Join-Path (Split-Path $PSScriptRoot -Parent) "azure-config.env"

# Cargar configuración si existe
if (Test-Path $configFilePs1) {
    # Cargar archivo PowerShell
    . $configFilePs1
} elseif (Test-Path $configFileEnv) {
    # Cargar archivo .env (formato bash)
    Get-Content $configFileEnv | ForEach-Object {
        if ($_ -match '^export\s+(\w+)="(.+)"$') {
            $name = $matches[1]
            $value = $matches[2]
            Set-Variable -Name $name -Value $value -Scope Script
        }
    }
}

if (-not $ACR_NAME) {
    Write-Host "Error: ACR_NAME no está configurado." -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts-windows\azure-setup.ps1"
    exit 1
}

Write-Host "=== Undeploying from AKS ===" -ForegroundColor Cyan

# Reemplazar variable en el manifest
$tempManifest = [System.IO.Path]::GetTempFileName()
(Get-Content $appManifest) -replace '\$\{ACR_NAME\}', $ACR_NAME | Set-Content $tempManifest

# Eliminar recursos de Kubernetes
kubectl delete -f $tempManifest --ignore-not-found=true
Remove-Item $tempManifest

Write-Host ""
Write-Host "Recursos de Kubernetes eliminados." -ForegroundColor Green

# Eliminar recursos de Azure si se solicita
if ($DeleteAll) {
    Write-Host ""
    Write-Host "=== Eliminando recursos de Azure ===" -ForegroundColor Cyan
    
    $resourceGroup = if ($RESOURCE_GROUP) { $RESOURCE_GROUP } else { "expense-rg" }
    $aksName = if ($AKS_NAME) { $AKS_NAME } else { "expense-aks" }
    
    # Verificar que Azure CLI está instalado
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Host "Error: Azure CLI no está instalado." -ForegroundColor Red
        Write-Host "No se pueden eliminar los recursos de Azure."
        exit 1
    }
    
    # Verificar login
    $account = az account show 2>$null
    if (-not $account) {
        Write-Host "Error: No estás logueado en Azure." -ForegroundColor Red
        Write-Host "Ejecuta: az login"
        exit 1
    }
    
    # Eliminar AKS primero
    $aksExists = az aks show --name $aksName --resource-group $resourceGroup 2>$null
    if ($aksExists) {
        Write-Host "Eliminando AKS '$aksName'..." -ForegroundColor Yellow
        az aks delete --name $aksName --resource-group $resourceGroup --yes --no-wait
        Write-Host "AKS '$aksName' en proceso de eliminación." -ForegroundColor Green
    } else {
        Write-Host "AKS '$aksName' no existe o ya fue eliminado." -ForegroundColor Yellow
    }
    
    # Eliminar ACR
    $acrExists = az acr show --name $ACR_NAME --resource-group $resourceGroup 2>$null
    if ($acrExists) {
        Write-Host "Eliminando ACR '$ACR_NAME'..." -ForegroundColor Yellow
        az acr delete --name $ACR_NAME --resource-group $resourceGroup --yes
        Write-Host "ACR '$ACR_NAME' eliminado." -ForegroundColor Green
    } else {
        Write-Host "ACR '$ACR_NAME' no existe o ya fue eliminado." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Recursos de Azure eliminados." -ForegroundColor Green
    Write-Host ""
    Write-Host "Nota: El Resource Group '$resourceGroup' aún existe." -ForegroundColor Yellow
    Write-Host "Para eliminarlo completamente, ejecuta:"
    Write-Host "  az group delete --name $resourceGroup --yes --no-wait"
} else {
    Write-Host ""
    Write-Host "Nota: Los recursos de Azure (ACR, AKS, Resource Group) NO se eliminaron." -ForegroundColor Yellow
    Write-Host "Para eliminarlos también, ejecuta:"
    Write-Host "  .\scripts-windows\undeploy-all.ps1 -DeleteAll"
}
