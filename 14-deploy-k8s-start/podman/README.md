## Kind Demo: expense-service + expense-client

Este directorio contiene una demo para Kind que despliega dos microservicios:
- expense-service: servicio REST de gastos
- expense-client: cliente que consume expense-service

Los scripts crean el cluster, construyen imágenes, las cargan y despliegan ambos componentes. La comunicación interna usa DNS con la variable EXPENSE_SVC.

### Versiones disponibles

Este proyecto incluye dos versiones de la demo:

1. **Versión Podman** (directorio raíz): Usa Podman con kind. Los scripts están en `scripts/`.
   - Requiere Podman instalado y podman machine iniciado (macOS)
   - Usa `KIND_EXPERIMENTAL_PROVIDER=podman`

2. **Versión Docker Desktop** (directorio `docker-desktop/`): Usa el Kubernetes integrado de Docker Desktop.
   - Requiere Docker Desktop instalado y ejecutándose con Kubernetes habilitado
   - Usa Docker para construir imágenes (no requiere kind)
   - Ver [docker-desktop/README.md](../docker-desktop/README.md) para instrucciones

### Versión Podman - Pasos

**Linux/macOS (scripts bash):**
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

**Windows (scripts PowerShell):**
1) Levantar/validar el cluster
```powershell
.\scripts-windows\kind-up.ps1
```
2) Construir y cargar imágenes
```powershell
.\scripts-windows\build-and-load-all.ps1
```
3) Desplegar ambos componentes
```powershell
.\scripts-windows\deploy-all-kind.ps1
```

**Comandos manuales (si los scripts no funcionan):**

Ver [COMANDOS-MANUALES.md](COMANDOS-MANUALES.md) para instrucciones paso a paso con comandos que puedes ejecutar manualmente en cualquier sistema.

4) Verificar y probar (todos los sistemas)
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

**Linux/macOS:**
```bash
scripts/undeploy-all-kind.sh
```

**Windows:**
```powershell
.\scripts-windows\undeploy-all-kind.ps1
```

**Manual:**
Ver [COMANDOS-MANUALES.md](COMANDOS-MANUALES.md) para comandos de limpieza.
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


