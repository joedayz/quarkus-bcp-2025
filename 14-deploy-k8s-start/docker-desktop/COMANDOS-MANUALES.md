# Comandos Manuales - Docker Desktop Kubernetes

Esta guía contiene los comandos para ejecutar manualmente la demo con Docker Desktop y su Kubernetes integrado. Úsala si los scripts no funcionan en tu sistema o prefieres ejecutar los comandos paso a paso.

## Prerrequisitos

- Docker Desktop instalado y ejecutándose
- Kubernetes habilitado en Docker Desktop (Settings > Kubernetes > Enable Kubernetes)
- kubectl instalado (viene con Docker Desktop)
- Maven instalado

## Paso 1: Verificar Docker Desktop Kubernetes

```bash
# Verificar que Docker esté ejecutándose
docker info

# Verificar que Kubernetes esté disponible
kubectl cluster-info

# Ver el contexto actual
kubectl config current-context
```

Si Kubernetes no está disponible, habilítalo en Docker Desktop:
- Settings > Kubernetes > Enable Kubernetes

## Paso 2: Construir imágenes Docker

### Construir expense-service

```bash
# Ir al directorio expense-service
cd expense-service

# Construir con Maven
mvn package

# Construir imagen con Docker
docker build -f src/main/docker/Dockerfile.jvm -t expense-service:latest .

# Verificar que la imagen se creó
docker images | grep expense-service

cd ..
```

### Construir expense-client

```bash
# Ir al directorio expense-client
cd expense-client

# Construir con Maven
mvn package

# Construir imagen con Docker
docker build -f src/main/docker/Dockerfile.jvm -t expense-client:latest .

# Verificar que la imagen se creó
docker images | grep expense-client

cd ..
```

**Nota:** Docker Desktop Kubernetes puede usar imágenes locales automáticamente, no necesitas cargarlas manualmente como con kind.

## Paso 3: Desplegar en Kubernetes

```bash
# Desde el directorio docker-desktop
cd docker-desktop

# Aplicar los manifiestos
kubectl apply -f k8s/expenses-all.yaml

# Esperar a que los deployments estén listos
kubectl rollout status deployment/expense-service -w
kubectl rollout status deployment/expense-client -w
```

## Paso 4: Verificar y probar

```bash
# Ver pods
kubectl get pods

# Ver servicios
kubectl get svc expense-service expense-client

# Obtener la IP del LoadBalancer
kubectl get svc expense-client

# O usar port-forward (más simple)
kubectl port-forward svc/expense-client 8081:8080

# En otra terminal, probar el servicio
curl http://localhost:8081/expenses
```

## Acceso al servicio

Docker Desktop expone servicios LoadBalancer automáticamente. Tienes dos opciones:

### Opción 1: Usar la IP del LoadBalancer

```bash
# Obtener la IP externa
kubectl get svc expense-client

# Usar la EXTERNAL-IP que se muestra (puede tardar unos segundos en aparecer)
curl http://<EXTERNAL-IP>:8080/expenses
```

### Opción 2: Usar port-forward (recomendado)

```bash
# En una terminal, ejecutar port-forward
kubectl port-forward svc/expense-client 8081:8080

# En otra terminal o navegador, acceder a:
# http://localhost:8081/expenses
```

## Limpieza

```bash
# Eliminar los recursos
kubectl delete -f k8s/expenses-all.yaml --ignore-not-found
kubectl delete configmap expense-client-config --ignore-not-found

# Verificar que se eliminaron
kubectl get all -l app=expense-client
kubectl get all -l app=expense-service
```

## Notas

- El servicio `expense-client` está expuesto como LoadBalancer
- Docker Desktop asigna automáticamente una IP para servicios LoadBalancer
- El ConfigMap `expense-client-config` inyecta `EXPENSE_SVC=http://expense-service:8080` en el pod del cliente
- Las imágenes construidas localmente están disponibles automáticamente para Kubernetes

## Solución de problemas

### Kubernetes no está disponible

```bash
# Verificar que Docker Desktop esté ejecutándose
docker ps

# Verificar el contexto de kubectl
kubectl config get-contexts

# Si es necesario, cambiar al contexto de Docker Desktop
kubectl config use-context docker-desktop
```

### Las imágenes no se encuentran

```bash
# Verificar que las imágenes existen
docker images | grep expense

# Si no aparecen, reconstruirlas siguiendo el Paso 2
```

### El servicio no responde

```bash
# Verificar que los pods estén corriendo
kubectl get pods

# Ver logs de los pods
kubectl logs -l app=expense-client
kubectl logs -l app=expense-service

# Verificar los servicios
kubectl describe svc expense-client
```

