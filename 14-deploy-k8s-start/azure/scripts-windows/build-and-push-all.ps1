# Script para construir y subir imágenes a Azure Container Registry
# Requiere: azure-setup.ps1 ejecutado previamente o variables de entorno configuradas

$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$configFile = Join-Path (Split-Path $PSScriptRoot -Parent) "azure-config.ps1"

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

$acrLoginServer = "$ACR_NAME.azurecr.io"

Write-Host "=== Build and Push to ACR ===" -ForegroundColor Cyan
Write-Host "ACR: $acrLoginServer"
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

# Detectar si usar podman o docker
$containerCmd = $null
if (Get-Command podman -ErrorAction SilentlyContinue) {
    $containerCmd = "podman"
    Write-Host "Detectado: Podman" -ForegroundColor Cyan
} elseif (Get-Command docker -ErrorAction SilentlyContinue) {
    $containerCmd = "docker"
    Write-Host "Detectado: Docker" -ForegroundColor Cyan
} else {
    Write-Host "Error: No se encontró ni podman ni docker instalado." -ForegroundColor Red
    exit 1
}

# Login a ACR
Write-Host "=== Login a ACR ===" -ForegroundColor Cyan
if ($containerCmd -eq "podman") {
    # Podman requiere usar token explícito (--expose-token evita usar docker)
    Write-Host "Obteniendo token de ACR para Podman..." -ForegroundColor Cyan
    $acrToken = az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken 2>$null
    if (-not $acrToken) {
        Write-Host "Error: No se pudo obtener el token de ACR." -ForegroundColor Red
        exit 1
    }
    $acrToken | & $containerCmd login $acrLoginServer --username "00000000-0000-0000-0000-000000000000" --password-stdin
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Falló el login a ACR con Podman." -ForegroundColor Red
        exit 1
    }
    Write-Host "Login exitoso con Podman." -ForegroundColor Green
} else {
    # Docker puede usar el método estándar
    az acr login --name $ACR_NAME
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Falló el login a ACR con Docker." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

function Build-AndPush {
    param(
        [string]$Dir,
        [string]$Name,
        [string]$Dockerfile
    )

    Write-Host "=== Building $Name in $Dir ===" -ForegroundColor Cyan
    Push-Location "$rootDir\$Dir"
    
    # Construir con Maven
    mvn -q package
    
    # Construir imagen para arquitectura AMD64 (requerida por AKS)
    $imageTag = "$acrLoginServer/${Name}:latest"
    
    if ($containerCmd -eq "podman") {
        # Podman usa --platform para especificar arquitectura
        Write-Host "Construyendo imagen para plataforma linux/amd64..." -ForegroundColor Cyan
        & $containerCmd build --platform linux/amd64 -f $Dockerfile -t $imageTag .
    } elseif ($containerCmd -eq "docker") {
        # Docker puede usar buildx para multi-arch o --platform
        $buildxAvailable = docker buildx version 2>$null
        if ($buildxAvailable) {
            Write-Host "Usando buildx para construir imagen multi-arch (linux/amd64)..." -ForegroundColor Cyan
            docker buildx build --platform linux/amd64 -f $Dockerfile -t $imageTag --load .
        } else {
            Write-Host "Construyendo imagen para plataforma linux/amd64..." -ForegroundColor Cyan
            docker build --platform linux/amd64 -f $Dockerfile -t $imageTag .
        }
    }
    
    Write-Host "=== Pushing $imageTag to ACR ===" -ForegroundColor Cyan
    & $containerCmd push $imageTag
    
    Write-Host "Imagen $imageTag construida y subida exitosamente." -ForegroundColor Green
    Write-Host ""
    
    Pop-Location
}

Build-AndPush -Dir "expense-service" -Name "expense-service" -Dockerfile "src/main/docker/Dockerfile.jvm"
Build-AndPush -Dir "expense-client" -Name "expense-client" -Dockerfile "src/main/docker/Dockerfile.jvm"

Write-Host "=== Todas las imágenes construidas y subidas a ACR ===" -ForegroundColor Green
Write-Host "ACR: $acrLoginServer"
