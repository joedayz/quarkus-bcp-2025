## Demo Kubernetes: expense-service + expense-client (Docker Desktop)

Este directorio contiene una demo para Docker Desktop que despliega dos microservicios en Kubernetes:
- expense-service: servicio REST de gastos
- expense-client: cliente que consume expense-service

Los scripts construyen las imágenes Docker y las despliegan usando el Kubernetes integrado de Docker Desktop. La comunicación interna usa DNS con la variable EXPENSE_SVC.

### Prerrequisitos
- Docker Desktop instalado y ejecutándose
- Kubernetes habilitado en Docker Desktop (Settings > Kubernetes > Enable Kubernetes)
- kubectl en PATH (viene con Docker Desktop)
- Maven instalado (para construir las imágenes)

**Nota**: No necesitas instalar kind - Docker Desktop incluye Kubernetes.

### Pasos
1) Verificar que Docker Desktop Kubernetes esté disponible
```bash
scripts/cluster-up.sh
```
2) Construir las imágenes Docker
```bash
scripts/build-and-load-all.sh
```
3) Desplegar ambos componentes
```bash
scripts/deploy-all.sh
```
4) Verificar y probar
```bash
kubectl get pods
kubectl get svc expense-service expense-client

# Obtener la IP del servicio
kubectl get svc expense-client

# O usar port-forward
kubectl port-forward svc/expense-client 8081:8080
# Luego acceder en http://localhost:8081/expenses
```

Notas:
- expense-client se expone como LoadBalancer para facilitar el acceso desde Docker Desktop
- El ConfigMap expense-client-config inyecta EXPENSE_SVC=http://expense-service:8080 en el pod del cliente
- Docker Desktop Kubernetes puede usar imágenes locales directamente, sin necesidad de cargarlas manualmente

### Limpieza
Eliminar los componentes de la demo:
```bash
scripts/undeploy-all.sh
```

### Acceso al servicio

Docker Desktop expone servicios LoadBalancer automáticamente. Para acceder:

**Opción 1: Usar la IP del LoadBalancer**
```bash
kubectl get svc expense-client
# Usa la EXTERNAL-IP que se muestra
```

**Opción 2: Usar port-forward (más simple)**
```bash
kubectl port-forward svc/expense-client 8081:8080
# Luego accede en http://localhost:8081
```

### Diferencias con la versión Podman
- Usa el Kubernetes integrado de Docker Desktop (no requiere kind)
- Usa `docker` en lugar de `podman` para construir imágenes
- Las imágenes se construyen localmente y Docker Desktop Kubernetes las encuentra automáticamente
- Usa LoadBalancer en lugar de NodePort para exponer el servicio
