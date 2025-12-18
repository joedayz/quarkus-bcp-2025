# Script para crear y configurar Azure API Management (APIM)

$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$configFile = Join-Path $rootDir "azure-config.ps1"

# Cargar configuración si existe
if (Test-Path $configFile) {
    Write-Host "Cargando configuración desde $configFile..." -ForegroundColor Cyan
    . $configFile
}

# Valores por defecto
$resourceGroup = if ($RESOURCE_GROUP) { $RESOURCE_GROUP } else { "expense-rg" }
$location = if ($LOCATION) { $LOCATION } else { "eastus" }
$apimName = if ($APIM_NAME) { $APIM_NAME } else { "expense-apim" }
$publisherEmail = if ($PUBLISHER_EMAIL) { $PUBLISHER_EMAIL } else { "admin@example.com" }
$publisherName = if ($PUBLISHER_NAME) { $PUBLISHER_NAME } else { "BCP Training" }
$sku = if ($SKU) { $SKU } else { "Developer" }

Write-Host "=== Configuración de Azure API Management ===" -ForegroundColor Cyan
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "APIM Name: $apimName"
Write-Host "SKU: $sku"
Write-Host ""

# Verificar que Azure CLI está instalado y logueado
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI no está instalado." -ForegroundColor Red
    exit 1
}

$account = az account show 2>$null
if (-not $account) {
    Write-Host "Error: No estás logueado en Azure." -ForegroundColor Red
    Write-Host "Ejecuta: az login"
    exit 1
}

# Verificar que el Resource Group existe
$rgExists = az group show --name $resourceGroup 2>$null
if (-not $rgExists) {
    Write-Host "Error: Resource Group '$resourceGroup' no existe." -ForegroundColor Red
    Write-Host "Crea primero el Resource Group o ejecuta: .\scripts-windows\azure-setup.ps1"
    exit 1
}

Write-Host "=== Paso 1: Crear Azure API Management ===" -ForegroundColor Yellow
Write-Host "Esto puede tardar 30-45 minutos..." -ForegroundColor Cyan
Write-Host ""

# Verificar si APIM ya existe
$apimExists = az apim show --resource-group $resourceGroup --name $apimName 2>$null
if ($apimExists) {
    Write-Host "APIM '$apimName' ya existe." -ForegroundColor Green
} else {
    Write-Host "Creando Azure APIM..." -ForegroundColor Yellow
    az apim create `
        --resource-group $resourceGroup `
        --name $apimName `
        --publisher-email $publisherEmail `
        --publisher-name $publisherName `
        --sku-name $sku `
        --location $location
}

Write-Host ""
Write-Host "=== Paso 2: Obtener información del APIM ===" -ForegroundColor Yellow
$gatewayUrl = az apim show `
    --resource-group $resourceGroup `
    --name $apimName `
    --query "gatewayUrl" -o tsv

Write-Host "Gateway URL: $gatewayUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Paso 3: Obtener IPs de los servicios en AKS ===" -ForegroundColor Yellow
# Verificar conexión con AKS
$clusterInfo = kubectl cluster-info 2>$null
if (-not $clusterInfo) {
    Write-Host "Advertencia: No hay conexión con AKS." -ForegroundColor Yellow
    Write-Host "Conecta primero con: az aks get-credentials --resource-group $resourceGroup --name expense-aks"
    Write-Host ""
    Write-Host "Puedes continuar configurando APIM manualmente desde el portal de Azure."
    exit 0
}

$serviceIp = kubectl get svc expense-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
$clientIp = kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null

if (-not $serviceIp -and -not $clientIp) {
    Write-Host "Advertencia: No se encontraron IPs de LoadBalancer para los servicios." -ForegroundColor Yellow
    Write-Host "Los servicios pueden ser ClusterIP. Para APIM necesitas:"
    Write-Host "  1. Cambiar los servicios a LoadBalancer, o"
    Write-Host "  2. Configurar Private Endpoint, o"
    Write-Host "  3. Usar un Ingress Controller interno"
    Write-Host ""
    Write-Host "Puedes configurar APIM manualmente desde el portal de Azure:"
    Write-Host "  https://portal.azure.com"
    exit 0
}

Write-Host "IPs encontradas:" -ForegroundColor Cyan
if ($serviceIp) { Write-Host "  expense-service: $serviceIp" }
if ($clientIp) { Write-Host "  expense-client: $clientIp" }
Write-Host ""

Write-Host "=== Paso 4: Configurar Backends en APIM ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para configurar los backends y APIs, puedes:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Usar el portal de Azure:"
Write-Host "   https://portal.azure.com -> $apimName"
Write-Host ""
Write-Host "2. Usar Azure CLI (ver API-MANAGEMENT-EXERCISE.md para comandos detallados)"
Write-Host ""
Write-Host "3. Importar desde OpenAPI/Swagger si tus servicios lo exponen"
Write-Host ""

Write-Host "=== Información importante ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Gateway URL: $gatewayUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para probar las APIs, necesitarás:" -ForegroundColor Cyan
Write-Host "1. Crear backends que apunten a tus servicios"
Write-Host "2. Crear APIs en APIM"
Write-Host "3. Agregar operaciones (endpoints)"
Write-Host "4. Publicar las APIs en un producto"
Write-Host "5. Obtener subscription key"
Write-Host ""
Write-Host "Ver API-MANAGEMENT-EXERCISE.md para instrucciones detalladas."
Write-Host ""
Write-Host "⚠️  IMPORTANTE: Azure APIM tiene costos asociados (~`$50/mes para Developer SKU)" -ForegroundColor Yellow
Write-Host "   Elimina el servicio cuando no lo uses:"
Write-Host "   az apim delete --resource-group $resourceGroup --name $apimName --yes"
