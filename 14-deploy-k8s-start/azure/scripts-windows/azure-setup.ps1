# Script para configurar Azure: login, crear ACR y AKS si no existen
# Uso: .\azure-setup.ps1 [RESOURCE_GROUP] [LOCATION] [ACR_NAME] [AKS_NAME]

param(
    [string]$ResourceGroup = "expense-rg",
    [string]$Location = "eastus",
    [string]$AcrName = "expenseacr$(Get-Random -Maximum 99999)",
    [string]$AksName = "expense-aks"
)

Write-Host "=== Azure Setup ===" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location: $Location"
Write-Host "ACR Name: $AcrName"
Write-Host "AKS Name: $AksName"
Write-Host ""

# Verificar que Azure CLI está instalado
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI no está instalado." -ForegroundColor Red
    Write-Host "Instala desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# Login a Azure
Write-Host "=== Verificando login en Azure ===" -ForegroundColor Cyan
$account = az account show 2>$null
if (-not $account) {
    Write-Host "No estás logueado. Iniciando login..."
    az login
}

$accountName = az account show --query name -o tsv
Write-Host "Logueado como: $accountName"
Write-Host ""

# Crear Resource Group si no existe
Write-Host "=== Creando Resource Group ===" -ForegroundColor Cyan
$rgExists = az group show --name $ResourceGroup 2>$null
if ($rgExists) {
    Write-Host "Resource Group '$ResourceGroup' ya existe."
} else {
    Write-Host "Creando Resource Group '$ResourceGroup' en $Location..."
    az group create --name $ResourceGroup --location $Location
}
Write-Host ""

# Crear ACR si no existe
Write-Host "=== Creando Azure Container Registry (ACR) ===" -ForegroundColor Cyan
$acrExists = az acr show --name $AcrName --resource-group $ResourceGroup 2>$null
if ($acrExists) {
    Write-Host "ACR '$AcrName' ya existe."
} else {
    Write-Host "Creando ACR '$AcrName'..."
    az acr create --resource-group $ResourceGroup --name $AcrName --sku Basic --admin-enabled true
}

$acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroup --query loginServer -o tsv
Write-Host "ACR Login Server: $acrLoginServer"
Write-Host ""

# Crear AKS si no existe
Write-Host "=== Creando Azure Kubernetes Service (AKS) ===" -ForegroundColor Cyan
$aksExists = az aks show --name $AksName --resource-group $ResourceGroup 2>$null
if ($aksExists) {
    Write-Host "AKS '$AksName' ya existe."
} else {
    Write-Host "Creando AKS '$AksName'..."
    Write-Host "Esto puede tardar varios minutos..."
    az aks create `
        --resource-group $ResourceGroup `
        --name $AksName `
        --node-count 2 `
        --enable-addons monitoring `
        --generate-ssh-keys `
        --attach-acr $AcrName
}
Write-Host ""

# Conectar AKS con ACR
Write-Host "=== Conectando AKS con ACR ===" -ForegroundColor Cyan
az aks update --name $AksName --resource-group $ResourceGroup --attach-acr $AcrName 2>$null
Write-Host ""

# Obtener credenciales de AKS
Write-Host "=== Obteniendo credenciales de AKS ===" -ForegroundColor Cyan
az aks get-credentials --resource-group $ResourceGroup --name $AksName --overwrite-existing
Write-Host ""

# Verificar conexión
Write-Host "=== Verificando conexión con AKS ===" -ForegroundColor Cyan
kubectl cluster-info
kubectl get nodes
Write-Host ""

# Guardar configuración en un archivo para otros scripts
$configFile = Join-Path (Split-Path $PSScriptRoot -Parent) "azure-config.ps1"
@"
`$RESOURCE_GROUP = "$ResourceGroup"
`$LOCATION = "$Location"
`$ACR_NAME = "$AcrName"
`$AKS_NAME = "$AksName"
`$ACR_LOGIN_SERVER = "$acrLoginServer"
"@ | Out-File -FilePath $configFile -Encoding utf8

Write-Host "=== Configuración completada ===" -ForegroundColor Green
Write-Host "Configuración guardada en: $configFile"
Write-Host ""
Write-Host "Variables de entorno:"
Write-Host "  RESOURCE_GROUP=$ResourceGroup"
Write-Host "  ACR_NAME=$AcrName"
Write-Host "  AKS_NAME=$AksName"
Write-Host "  ACR_LOGIN_SERVER=$acrLoginServer"
Write-Host ""
Write-Host "Para usar estas variables en otros scripts, ejecuta:"
Write-Host "  . $configFile"
