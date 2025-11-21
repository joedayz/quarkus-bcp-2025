# PowerShell script para desplegar todos los componentes
$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent $SCRIPT_DIR
$APP_MANIFEST = Join-Path $ROOT_DIR "k8s\expenses-all.yaml"

kubectl apply -f $APP_MANIFEST
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al aplicar el manifiesto" -ForegroundColor Red
    exit 1
}

kubectl rollout status deployment/expense-service -w
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en el rollout de expense-service" -ForegroundColor Red
    exit 1
}

kubectl rollout status deployment/expense-client -w
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error en el rollout de expense-client" -ForegroundColor Red
    exit 1
}

Write-Host "Client available on http://localhost:8081 (NodePort)" -ForegroundColor Green

