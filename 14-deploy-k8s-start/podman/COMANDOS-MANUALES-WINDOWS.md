## Comandos Manuales - Podman con Kind (Windows / PowerShell)

Esta guía contiene los comandos para ejecutar manualmente la demo con **Podman** y **Kind** en **Windows**, usando **PowerShell**.  
Úsala si los scripts `.ps1` no funcionan en tu sistema o si prefieres ejecutar los comandos paso a paso.

### Prerrequisitos

- **Podman** instalado y ejecutándose
- **kind** instalado y accesible en `PATH`
- **kubectl** instalado y accesible en `PATH`
- **Maven** instalado (`mvn` en `PATH`)
- Estar usando **PowerShell** (no `cmd.exe`)

> **Nota:** Abre *PowerShell* y ejecuta estos comandos desde el directorio raíz del proyecto:  
`C:\...\14-deploy-k8s-start>`

---

### Paso 1: Crear el cluster Kind con Podman

```powershell
# Desde el directorio raíz del proyecto (14-deploy-k8s-start)
$CLUSTER_NAME = "expense-kind"

# Verificar que kind y podman estén instalados
kind version
podman version

# Ruta del archivo de configuración de kind
$configPath = Join-Path (Join-Path (Get-Location) "expense") ".kind\kind-config.yaml"
if (-not (Test-Path $configPath)) {
    Write-Host "Archivo de configuración no encontrado: $configPath" -ForegroundColor Red
    exit 1
}

# Verificar si el cluster ya existe
$existingClusters = kind get clusters 2>$null
if ($existingClusters -and ($existingClusters -split "`n" | Select-String -Pattern "^${CLUSTER_NAME}$")) {
    Write-Host "Cluster $CLUSTER_NAME ya existe. Omitiendo creación."
} else {
    $env:KIND_EXPERIMENTAL_PROVIDER = "podman"
    Write-Host "Creando cluster con configuración: $configPath" -ForegroundColor Cyan
    kind create cluster --name $CLUSTER_NAME --config "$configPath"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al crear el cluster" -ForegroundColor Red
        exit 1
    }
}

# Verificar el cluster
kubectl cluster-info
```

---

### Paso 2: Construir y cargar imágenes con Podman

Vamos a construir las imágenes de `expense-service` y `expense-client` con Maven + Podman y luego cargarlas en el cluster kind.

#### 2.1 Construir y cargar `expense-service`

```powershell
# Ir al directorio expense-service
Set-Location expense-service

# Construir con Maven
mvn -q package
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al construir con Maven" -ForegroundColor Red
    exit 1
}

# Construir imagen con Podman
$shortTag = "expense-service:latest"
$localTag = "localhost/expense-service:latest"

podman build -f "src/main/docker/Dockerfile.jvm" -t $shortTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al construir la imagen" -ForegroundColor Red
    exit 1
}

podman tag $shortTag $localTag

# Cargar en kind (intentar método directo primero)
$env:KIND_EXPERIMENTAL_PROVIDER = "podman"
kind load docker-image $localTag --name "expense-kind"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fallo carga directa, usando archivo..." -ForegroundColor Yellow

    $targetDir = Join-Path (Get-Location) "target"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $archivePath = Join-Path $targetDir "expense-service-image.tar"
    podman save -o $archivePath $localTag
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al exportar la imagen" -ForegroundColor Red
        exit 1
    }

    kind load image-archive $archivePath --name "expense-kind"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al cargar la imagen en kind" -ForegroundColor Red
        exit 1
    }
}

# Volver al root del proyecto
Set-Location ..
```

#### 2.2 Construir y cargar `expense-client`

```powershell
# Ir al directorio expense-client
Set-Location expense-client

# Construir con Maven
mvn -q package
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al construir con Maven" -ForegroundColor Red
    exit 1
}

# Construir imagen con Podman
$shortTag = "expense-client:latest"
$localTag = "localhost/expense-client:latest"

podman build -f "src/main/docker/Dockerfile.jvm" -t $shortTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al construir la imagen" -ForegroundColor Red
    exit 1
}

podman tag $shortTag $localTag

# Cargar en kind (intentar método directo primero)
$env:KIND_EXPERIMENTAL_PROVIDER = "podman"
kind load docker-image $localTag --name "expense-kind"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Fallo carga directa, usando archivo..." -ForegroundColor Yellow

    $targetDir = Join-Path (Get-Location) "target"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $archivePath = Join-Path $targetDir "expense-client-image.tar"
    podman save -o $archivePath $localTag
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al exportar la imagen" -ForegroundColor Red
        exit 1
    }

    kind load image-archive $archivePath --name "expense-kind"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al cargar la imagen en kind" -ForegroundColor Red
        exit 1
    }
}

# Volver al root del proyecto
Set-Location ..
```

---

### Paso 3: Desplegar en Kubernetes

```powershell
# Desde el directorio raíz del proyecto
Set-Location podman

# Aplicar los manifiestos
kubectl apply -f "k8s/expenses-all.yaml"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al aplicar el manifiesto" -ForegroundColor Red
    exit 1
}

# Esperar a que los deployments estén listos
kubectl rollout status deployment/expense-service -w
kubectl rollout status deployment/expense-client -w
```

---

### Paso 4: Verificar y probar

```powershell
# Ver pods
kubectl get pods

# Ver servicios
kubectl get svc expense-service expense-client

# Probar el servicio (NodePort 30081 mapeado a puerto 8081 en el host)
curl http://localhost:8081/expenses
```

> **Nota:** Si `curl` no está disponible en tu PowerShell, puedes probar desde el navegador:  
`http://localhost:8081/expenses`

---

### Limpieza

```powershell
# Desde el directorio podman
Set-Location podman

# Eliminar los recursos de Kubernetes
kubectl delete -f "k8s/expenses-all.yaml" --ignore-not-found
kubectl delete configmap expense-client-config --ignore-not-found

# (Opcional) Eliminar el cluster completo
kind delete cluster --name "expense-kind"
```

---

### Notas

- El servicio `expense-client` está expuesto como **NodePort 30081**.
- El archivo `kind-config.yaml` mapea el puerto 30081 del nodo al puerto **8081** del host.
- El ConfigMap `expense-client-config` inyecta `EXPENSE_SVC=http://expense-service:8080` en el pod del cliente.
- Estos comandos son equivalentes a lo que hacen los scripts de `scripts-windows` (`kind-up.ps1`, `build-and-load-all.ps1`, `deploy-all-kind.ps1`, `undeploy-all-kind.ps1`), pero "desglosados" paso a paso.



