# Script de diagnóstico para problemas de despliegue en AKS

Write-Host "=== Diagnóstico del despliegue en AKS ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Estado de los pods:" -ForegroundColor Yellow
Write-Host "---"
kubectl get pods -o wide
Write-Host ""

Write-Host "2. Estado de los servicios:" -ForegroundColor Yellow
Write-Host "---"
kubectl get svc
Write-Host ""

Write-Host "3. Descripción del servicio expense-client:" -ForegroundColor Yellow
Write-Host "---"
kubectl describe svc expense-client
Write-Host ""

Write-Host "4. Descripción del servicio expense-service:" -ForegroundColor Yellow
Write-Host "---"
kubectl describe svc expense-service
Write-Host ""

Write-Host "5. Logs de expense-client (últimas 20 líneas):" -ForegroundColor Yellow
Write-Host "---"
$clientPod = kubectl get pods -l app=expense-client -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($clientPod) {
    kubectl logs $clientPod --tail=20
} else {
    Write-Host "No se encontró pod de expense-client" -ForegroundColor Red
}
Write-Host ""

Write-Host "6. Logs de expense-service (últimas 20 líneas):" -ForegroundColor Yellow
Write-Host "---"
$servicePod = kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}' 2>$null
if ($servicePod) {
    kubectl logs $servicePod --tail=20
} else {
    Write-Host "No se encontró pod de expense-service" -ForegroundColor Red
}
Write-Host ""

Write-Host "7. ConfigMap expense-client-config:" -ForegroundColor Yellow
Write-Host "---"
kubectl get configmap expense-client-config -o yaml 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ConfigMap no encontrado" -ForegroundColor Red
}
Write-Host ""

Write-Host "8. Variables de entorno del pod expense-client:" -ForegroundColor Yellow
Write-Host "---"
if ($clientPod) {
    kubectl exec $clientPod -- env | Select-String "EXPENSE" || Write-Host "No se encontró variable EXPENSE_SVC"
} else {
    Write-Host "No se encontró pod de expense-client" -ForegroundColor Red
}
Write-Host ""

Write-Host "9. Eventos recientes:" -ForegroundColor Yellow
Write-Host "---"
kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 10
Write-Host ""

Write-Host "10. Probar conectividad desde expense-client a expense-service:" -ForegroundColor Yellow
Write-Host "---"
if ($clientPod) {
    Write-Host "Probando conexión a expense-service:8080..."
    kubectl exec $clientPod -- wget -q -O- http://expense-service:8080/expenses 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error en la conexión" -ForegroundColor Red
    }
} else {
    Write-Host "No se encontró pod de expense-client" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Fin del diagnóstico ===" -ForegroundColor Cyan
