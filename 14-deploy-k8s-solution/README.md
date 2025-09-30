## Kind Demo: expense-service + expense-client

Este directorio contiene una demo para Kind (Podman) que despliega dos microservicios:
- expense-service: servicio REST de gastos
- expense-client: cliente que consume expense-service

Los scripts crean el cluster, construyen imágenes, las cargan y despliegan ambos componentes. La comunicación interna usa DNS con la variable EXPENSE_SVC.

### Prerrequisitos
- Kind y kubectl en PATH
- Podman instalado y podman machine iniciado (macOS)

### Pasos
1) Levantar/validar el cluster
```bash
scripts/kind-up.sh
```
2) Construir y cargar imágenes
```bash
scripts/build-and-load-all.sh
```
3) Desplegar ambos componentes
```bash
scripts/deploy-all-kind.sh
```
4) Verificar y probar
```bash
kubectl get pods
kubectl get svc expense-service expense-client
curl http://localhost:8081/expenses
```

Notas:
- expense-client se expone por NodePort 30081 y el kind-config lo publica en el host 8081.
- El ConfigMap expense-client-config inyecta EXPENSE_SVC=http://expense-service:8080 en el pod del cliente.

### Limpieza
Eliminar los componentes de la demo:
```bash
scripts/undeploy-all-kind.sh
```
Reinicio completo (borra y recrea cluster):
```bash
expense/scripts/reset-and-redeploy.sh
```

### Servicio individual `expense`
Para desplegar solo el servicio `expense` (demo inicial):
```bash
expense/scripts/kind-up.sh
expense/scripts/build-and-load.sh
expense/scripts/deploy-kind.sh
```
Probar en `http://localhost:8080`.


