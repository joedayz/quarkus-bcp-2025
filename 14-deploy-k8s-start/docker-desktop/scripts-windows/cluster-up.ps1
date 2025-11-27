# PowerShell script para verificar Docker Desktop Kubernetes
$ErrorActionPreference = "Stop"

# Verificar que docker esté instalado
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "docker no encontrado. Instala Docker Desktop primero." -ForegroundColor Red
    exit 1
}

# Verificar que kubectl esté instalado
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl no encontrado. Instala kubectl primero." -ForegroundColor Red
    exit 1
}

# Verificar que Docker Desktop esté ejecutándose
try {
    $dockerInfo = docker info *>$null
} catch {
    $errorMsg = $_.Exception.Message
    if ($errorMsg -like "*DOCKER_INSECURE_NO_IPTABLES_RAW*") {
        Write-Host "Warning detectado, Docker sigue corriendo." -ForegroundColor Yellow
    } else {
        Write-Host "Docker Desktop no está ejecutándose. Por favor, inicia Docker Desktop." -ForegroundColor Red
        exit 1
    }
}

# Verificar que Kubernetes esté habilitado en Docker Desktop
$clusterInfo = kubectl cluster-info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Kubernetes no está disponible en Docker Desktop." -ForegroundColor Red
    Write-Host "Por favor, habilita Kubernetes en Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  Settings > Kubernetes > Enable Kubernetes" -ForegroundColor Yellow
    exit 1
}

Write-Host "Docker Desktop Kubernetes está disponible." -ForegroundColor Green
kubectl cluster-info
Write-Host ""
$context = kubectl config current-context
Write-Host "Contexto actual: $context" -ForegroundColor Cyan