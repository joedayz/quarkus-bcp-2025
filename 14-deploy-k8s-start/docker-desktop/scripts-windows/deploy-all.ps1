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

Write-Host ""
Write-Host "Esperando que el servicio LoadBalancer esté disponible..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$serviceIp = kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
$servicePort = kubectl get svc expense-client -o jsonpath='{.spec.ports[0].port}' 2>$null

if ($serviceIp) {
    Write-Host "Client available on http://${serviceIp}:${servicePort}" -ForegroundColor Green
} else {
    Write-Host "Client service expuesto. Obtén la IP con:" -ForegroundColor Yellow
    Write-Host "  kubectl get svc expense-client" -ForegroundColor Cyan
    Write-Host "O usa port-forward:" -ForegroundColor Yellow
    Write-Host "  kubectl port-forward svc/expense-client 8081:8080" -ForegroundColor Cyan
    Write-Host "Luego accede en http://localhost:8081" -ForegroundColor Cyan
}

