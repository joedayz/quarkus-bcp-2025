# Script para probar y demostrar el funcionamiento de los probes

Write-Host "=== Test de Liveness y Readiness Probes ===" -ForegroundColor Cyan
Write-Host ""

# Obtener nombres de pods
$servicePod = kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}' 2>$null
$clientPod = kubectl get pods -l app=expense-client -o jsonpath='{.items[0].metadata.name}' 2>$null

if (-not $servicePod -or -not $clientPod) {
    Write-Host "Error: No se encontraron pods. Asegúrate de que los deployments estén corriendo." -ForegroundColor Red
    exit 1
}

Write-Host "Pods encontrados:"
Write-Host "  expense-service: $servicePod"
Write-Host "  expense-client: $clientPod"
Write-Host ""

Write-Host "=== 1. Verificar configuración de Probes ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- Liveness y Readiness en expense-service ---" -ForegroundColor Cyan
kubectl describe pod $servicePod | Select-String -Pattern "Liveness|Readiness" -Context 0,5
Write-Host ""

Write-Host "--- Liveness y Readiness en expense-client ---" -ForegroundColor Cyan
kubectl describe pod $clientPod | Select-String -Pattern "Liveness|Readiness" -Context 0,5
Write-Host ""

Write-Host "=== 2. Probar endpoints de Health desde dentro de los pods ===" -ForegroundColor Yellow
Write-Host ""

Write-Host "--- expense-service health endpoints ---" -ForegroundColor Cyan
Write-Host "Testing /q/health:"
kubectl exec $servicePod -- wget -q -O- http://localhost:8080/q/health 2>&1
Write-Host ""

Write-Host "Testing /q/health/live:"
kubectl exec $servicePod -- wget -q -O- http://localhost:8080/q/health/live 2>&1
Write-Host ""

Write-Host "Testing /q/health/ready:"
kubectl exec $servicePod -- wget -q -O- http://localhost:8080/q/health/ready 2>&1
Write-Host ""

Write-Host "--- expense-client health endpoints ---" -ForegroundColor Cyan
Write-Host "Testing /q/health:"
kubectl exec $clientPod -- wget -q -O- http://localhost:8080/q/health 2>&1
Write-Host ""

Write-Host "Testing /q/health/live:"
kubectl exec $clientPod -- wget -q -O- http://localhost:8080/q/health/live 2>&1
Write-Host ""

Write-Host "Testing /q/health/ready:"
kubectl exec $clientPod -- wget -q -O- http://localhost:8080/q/health/ready 2>&1
Write-Host ""

Write-Host "=== 3. Ver estado de Readiness de los pods ===" -ForegroundColor Yellow
Write-Host ""
kubectl get pods -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?\(@.type==\"Ready\"\)].status,STATUS:.status.phase
Write-Host ""

Write-Host "=== 4. Ver Endpoints del servicio expense-service ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Los endpoints muestran qué pods están listos para recibir tráfico:" -ForegroundColor Cyan
kubectl get endpoints expense-service
Write-Host ""

Write-Host "=== 5. Ver eventos relacionados con probes ===" -ForegroundColor Yellow
Write-Host ""
$events = kubectl get events --sort-by='.lastTimestamp' | Select-String -Pattern "probe|readiness|liveness"
if ($events) {
    $events | Select-Object -Last 10
} else {
    Write-Host "No se encontraron eventos recientes de probes"
}
Write-Host ""

Write-Host "=== 6. Observar comportamiento durante reinicio ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para observar el comportamiento de los probes durante un reinicio:" -ForegroundColor Cyan
Write-Host "  1. Ejecuta en otra terminal: kubectl get pods -w"
Write-Host "  2. Ejecuta: kubectl delete pod $servicePod"
Write-Host "  3. Observa cómo el nuevo pod pasa por diferentes estados"
Write-Host "  4. Nota que el pod NO aparece en los endpoints hasta que el readiness probe tenga éxito"
Write-Host ""

Write-Host "=== Test completado ===" -ForegroundColor Green
Write-Host ""
Write-Host "Para más información sobre probes, consulta: PROBES-EXERCISE.md" -ForegroundColor Cyan
