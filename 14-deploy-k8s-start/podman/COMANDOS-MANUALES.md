# Comandos Manuales - Podman con Kind

Esta guía contiene los comandos para ejecutar manualmente la demo con Podman y Kind. Úsala si los scripts no funcionan en tu sistema o prefieres ejecutar los comandos paso a paso.

## Prerrequisitos

- Podman instalado y ejecutándose
- kind instalado
- kubectl instalado
- Maven instalado

## Paso 1: Crear el cluster Kind

```bash
# Desde el directorio raíz del proyecto (14-deploy-k8s-start)
export CLUSTER_NAME="expense-kind"
export CONFIG_DIR="$(pwd)/expense/.kind/kind-config.yaml"

# Verificar que kind y podman estén instalados
kind version
podman version

# Crear el cluster (si no existe)
kind get clusters | grep -q "^${CLUSTER_NAME}$" || \
  KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster \
    --name "${CLUSTER_NAME}" \
    --config "${CONFIG_DIR}"

# Verificar el cluster
kubectl cluster-info
```

## Paso 2: Construir y cargar imágenes

### Construir expense-service

```bash
# Ir al directorio expense-service
cd expense-service

# Construir con Maven
mvn package

# Construir imagen con Podman
podman build -f src/main/docker/Dockerfile.jvm -t expense-service:latest .

# Tag para localhost (requerido por Podman)
podman tag expense-service:latest localhost/expense-service:latest

# Cargar en kind (intentar método directo primero)
KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image localhost/expense-service:latest --name expense-kind

# Si falla, usar método de archivo
if [ $? -ne 0 ]; then
  podman save -o target/expense-service-image.tar localhost/expense-service:latest
  KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive target/expense-service-image.tar --name expense-kind
fi

cd ..
```

### Construir expense-client

```bash
# Ir al directorio expense-client
cd expense-client

# Construir con Maven
mvn package

# Construir imagen con Podman
podman build -f src/main/docker/Dockerfile.jvm -t expense-client:latest .

# Tag para localhost (requerido por Podman)
podman tag expense-client:latest localhost/expense-client:latest

# Cargar en kind (intentar método directo primero)
KIND_EXPERIMENTAL_PROVIDER=podman kind load docker-image localhost/expense-client:latest --name expense-kind

# Si falla, usar método de archivo
if [ $? -ne 0 ]; then
  podman save -o target/expense-client-image.tar localhost/expense-client:latest
  KIND_EXPERIMENTAL_PROVIDER=podman kind load image-archive target/expense-client-image.tar --name expense-kind
fi

cd ..
```

## Paso 3: Desplegar en Kubernetes

```bash
# Desde el directorio podman
cd podman

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

# Probar el servicio (NodePort 30081 mapeado a puerto 8081 en el host)
curl http://localhost:8081/expenses
```

## Limpieza

```bash
# Eliminar los recursos
kubectl delete -f k8s/expenses-all.yaml --ignore-not-found
kubectl delete configmap expense-client-config --ignore-not-found

# (Opcional) Eliminar el cluster completo
kind delete cluster --name expense-kind
```

## Notas

- El servicio `expense-client` está expuesto como NodePort 30081
- El archivo `kind-config.yaml` mapea el puerto 30081 del contenedor al puerto 8081 del host
- El ConfigMap `expense-client-config` inyecta `EXPENSE_SVC=http://expense-service:8080` en el pod del cliente

