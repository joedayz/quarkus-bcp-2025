# PowerShell script para construir imágenes con Docker
$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)

function Build-Image {
    param(
        [string]$dir,
        [string]$name,
        [string]$dockerfile
    )

    Write-Host "`n=== Building ${name} in ${dir} ===" -ForegroundColor Cyan
    Push-Location (Join-Path $ROOT_DIR $dir)
    
    mvn -q package
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir con Maven" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    $tag = "${name}:latest"
    docker build -f $dockerfile -t $tag .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir la imagen" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host "Imagen ${tag} construida exitosamente." -ForegroundColor Green
    Write-Host "Docker Desktop Kubernetes puede usar imágenes locales automáticamente." -ForegroundColor Cyan
    
    Pop-Location
}

Build-Image "expense-service" "expense-service" "src/main/docker/Dockerfile.jvm"
Build-Image "expense-client" "expense-client" "src/main/docker/Dockerfile.jvm"

Write-Host "`nTodas las imágenes construidas. Docker Desktop Kubernetes las encontrará automáticamente." -ForegroundColor Green

