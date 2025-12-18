## Demo Kubernetes: expense-service + expense-client (Azure AKS)

Este directorio contiene una demo para desplegar los microservicios en **Azure Kubernetes Service (AKS)**:
- expense-service: servicio REST de gastos
- expense-client: cliente que consume expense-service

Los scripts construyen las imágenes Docker, las suben a **Azure Container Registry (ACR)** y las despliegan en AKS. La comunicación interna usa DNS con la variable EXPENSE_SVC.

### Prerrequisitos

1. **Azure CLI** instalado y configurado
   - Instalación: https://docs.microsoft.com/cli/azure/install-azure-cli
   - Verificar: `az --version`

2. **Docker o Podman** instalado y ejecutándose
   - Necesario para construir las imágenes localmente antes de subirlas a ACR
   - Los scripts detectan automáticamente cuál está disponible
   - Si usas Podman, el script usará el método de autenticación con token

3. **kubectl** instalado
   - Se instala automáticamente con Azure CLI o puedes instalarlo por separado
   - Verificar: `kubectl version --client`

4. **Maven** instalado
   - Para construir los proyectos Java antes de crear las imágenes Docker

5. **Cuenta de Azure** con suscripción activa
   - Puedes crear una cuenta gratuita en: https://azure.microsoft.com/free/

### Costos

⚠️ **Importante**: AKS y ACR son servicios de pago en Azure. Aunque hay niveles gratuitos limitados, asegúrate de:
- Revisar los costos antes de crear recursos
- Eliminar los recursos cuando termines para evitar cargos
- Usar el nivel "Basic" de ACR (más económico)

### Pasos para desplegar en AKS

#### Paso 1: Configurar Azure (crear ACR y AKS)

Este script:
- Verifica tu login en Azure
- Crea un Resource Group (si no existe)
- Crea un Azure Container Registry (ACR) con nivel Basic
- Crea un cluster AKS con 2 nodos
- Conecta AKS con ACR para acceso automático a las imágenes
- Obtiene las credenciales de kubectl

**Linux/macOS:**
```bash
cd azure
./scripts/azure-setup.sh
```

**Windows (PowerShell):**
```powershell
cd azure
.\scripts-windows\azure-setup.ps1
```

**Parámetros opcionales:**
```bash
# Especificar nombres personalizados
./scripts/azure-setup.sh [RESOURCE_GROUP] [LOCATION] [ACR_NAME] [AKS_NAME]

# Ejemplo:
./scripts/azure-setup.sh my-rg westeurope myacr123 my-aks-cluster
```

**Notas:**
- El script genera un nombre único para ACR si no lo especificas (requisito de Azure: nombres globalmente únicos)
- La creación del cluster AKS puede tardar **10-15 minutos**
- El script guarda la configuración en `azure-config.env` (bash) o `azure-config.ps1` (PowerShell)

#### Paso 2: Construir y subir imágenes a ACR

Este script:
- Detecta automáticamente si tienes Podman o Docker instalado
- Construye los proyectos con Maven
- Crea las imágenes de contenedor para arquitectura **linux/amd64** (requerida por AKS)
- Las sube a Azure Container Registry
- Si usas Podman, maneja automáticamente la autenticación con token

**⚠️ Importante**: Si estás en una Mac con chip Apple Silicon (M1/M2/M3), las imágenes se construyen automáticamente para AMD64 usando `--platform linux/amd64` para que funcionen en AKS.

**Linux/macOS:**
```bash
./scripts/build-and-push-all.sh
```

**Windows (PowerShell):**
```powershell
.\scripts-windows\build-and-push-all.ps1
```

**Notas:**
- Las imágenes se etiquetan como `[ACR_NAME].azurecr.io/[nombre]:latest`
- El script hace login automático a ACR antes de subir

#### Paso 3: Desplegar en AKS

Este script:
- Aplica los manifiestos de Kubernetes
- Espera a que los pods estén listos
- Muestra la información del servicio LoadBalancer

**Linux/macOS:**
```bash
./scripts/deploy-all.sh
```

**Windows (PowerShell):**
```powershell
.\scripts-windows\deploy-all.ps1
```

**Notas:**
- El servicio `expense-client` se expone como LoadBalancer
- Azure crea automáticamente una IP pública para el LoadBalancer
- Puede tardar unos minutos en asignar la IP

#### Paso 4: Verificar y probar

```bash
# Ver estado de los pods
kubectl get pods

# Ver servicios
kubectl get svc expense-service expense-client

# Obtener la IP del LoadBalancer
kubectl get svc expense-client

# Probar el servicio (reemplaza [IP] con la IP del LoadBalancer)
curl http://[IP]:8080/expenses

# O usar port-forward para acceso local
kubectl port-forward svc/expense-client 8081:8080
# Luego acceder en http://localhost:8081/expenses
```

### Información del cluster

Para ver información detallada del cluster:

**Linux/macOS:**
```bash
./scripts/cluster-info.sh
```

**Windows (PowerShell):**
```powershell
.\scripts-windows\cluster-info.ps1
```

### Limpieza

#### Eliminar solo los recursos de Kubernetes (mantiene AKS y ACR)

**Linux/macOS:**
```bash
./scripts/undeploy-all.sh
```

**Windows (PowerShell):**
```powershell
.\scripts-windows\undeploy-all.ps1
```

#### Eliminar completamente todos los recursos de Azure (ACR, AKS, Resource Group)

⚠️ **CUIDADO**: Esto elimina todo y puede tardar varios minutos.

```bash
# Cargar configuración primero
source azure-config.env  # Linux/macOS
# o
. azure-config.ps1       # Windows PowerShell

# Eliminar Resource Group (elimina todo dentro)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

O manualmente desde Azure Portal:
1. Ve a Resource Groups
2. Selecciona tu Resource Group
3. Click en "Delete"

### Comandos manuales (si los scripts no funcionan)

Si prefieres ejecutar los comandos manualmente:

#### 1. Login y configuración inicial

```bash
# Login a Azure
az login

# Crear Resource Group
az group create --name expense-rg --location eastus

# Crear ACR
az acr create --resource-group expense-rg --name [TU_ACR_NAME] --sku Basic --admin-enabled true

# Crear AKS
az aks create \
  --resource-group expense-rg \
  --name expense-aks \
  --node-count 2 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --attach-acr [TU_ACR_NAME]

# Obtener credenciales
az aks get-credentials --resource-group expense-rg --name expense-aks
```

#### 2. Construir y subir imágenes

```bash
# Login a ACR
# Si usas Docker:
az acr login --name [TU_ACR_NAME]

# Si usas Podman:
ACR_TOKEN=$(az acr login --name [TU_ACR_NAME] --expose-token --output tsv --query accessToken)
echo "$ACR_TOKEN" | podman login [TU_ACR_NAME].azurecr.io --username "00000000-0000-0000-0000-000000000000" --password-stdin

# Construir y subir expense-service
cd ../expense-service
mvn package
# Usa 'docker' o 'podman' según tu instalación:
docker build -f src/main/docker/Dockerfile.jvm -t [TU_ACR_NAME].azurecr.io/expense-service:latest .
docker push [TU_ACR_NAME].azurecr.io/expense-service:latest
# O con podman:
# podman build -f src/main/docker/Dockerfile.jvm -t [TU_ACR_NAME].azurecr.io/expense-service:latest .
# podman push [TU_ACR_NAME].azurecr.io/expense-service:latest

# Construir y subir expense-client
cd ../expense-client
mvn package
docker build -f src/main/docker/Dockerfile.jvm -t [TU_ACR_NAME].azurecr.io/expense-client:latest .
docker push [TU_ACR_NAME].azurecr.io/expense-client:latest
```

#### 3. Desplegar

```bash
# Editar el archivo YAML para reemplazar ${ACR_NAME} con tu nombre de ACR
# Luego aplicar:
kubectl apply -f k8s/expenses-all.yaml

# Verificar
kubectl get pods
kubectl get svc
```

### Troubleshooting

Para una guía completa de troubleshooting con casos prácticos y soluciones detalladas, consulta:

📖 **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Guía completa de troubleshooting

#### Problemas Comunes Rápidos

**Script de diagnóstico automático:**
```bash
./scripts/diagnose.sh  # Linux/macOS
.\scripts-windows\diagnose.ps1  # Windows
```

**Problemas más frecuentes:**

1. **Error "exec format error" o pods en CrashLoopBackOff**
   - Causa: Imágenes construidas para arquitectura incorrecta (ARM64 vs AMD64)
   - Solución: Reconstruir con `./scripts/build-and-push-all.sh` (ahora usa `--platform linux/amd64` automáticamente)

2. **El servicio responde pero no devuelve datos**
   - Causa: `expense-client` no puede conectarse a `expense-service`
   - Solución: Verificar logs, variables de entorno y conectividad (ver TROUBLESHOOTING.md)

3. **Pods en ImagePullBackOff**
   - Causa: Imagen no existe en ACR o problemas de permisos
   - Solución: Verificar imágenes en ACR y permisos de AKS

4. **LoadBalancer sin IP externa**
   - Causa: Puede tardar varios minutos en asignarse
   - Solución: Esperar o usar `port-forward` como alternativa

Para más detalles y casos específicos, consulta [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

### Diferencias con Kind/Docker Desktop

- **Imágenes remotas**: Las imágenes se almacenan en ACR (Azure), no localmente
- **LoadBalancer real**: Azure crea una IP pública real (no solo localhost)
- **Costos**: AKS y ACR tienen costos asociados
- **Tiempo de creación**: El cluster AKS tarda varios minutos en crearse
- **Escalabilidad**: AKS puede escalar automáticamente según la carga
- **Soporte Podman/Docker**: Los scripts detectan automáticamente y funcionan con ambos

### Health Checks y Probes

Los deployments incluyen **Liveness y Readiness Probes** configurados para mejorar la confiabilidad:

- **Readiness Probe**: Verifica que el pod esté listo para recibir tráfico (`/q/health/ready`)
- **Liveness Probe**: Verifica que el contenedor esté vivo (`/q/health/live`)

**⚠️ IMPORTANTE:** Las aplicaciones necesitan tener la dependencia `quarkus-smallrye-health` para que los health checks funcionen.

📖 **[HEALTH-CHECKS-SETUP.md](HEALTH-CHECKS-SETUP.md)** - Cómo agregar health checks a las aplicaciones Quarkus

📖 **[PROBES-EXERCISE.md](PROBES-EXERCISE.md)** - Ejercicio completo sobre Liveness y Readiness Probes

**Probar los probes:**
```bash
./scripts/test-probes.sh  # Linux/macOS
.\scripts-windows\test-probes.ps1  # Windows
```

### Azure API Management (APIM)

Para configurar Azure API Management como API Gateway donde los clientes acceden a través de APIM:

📖 **[API-MANAGEMENT-EXERCISE.md](API-MANAGEMENT-EXERCISE.md)** - Ejercicio completo sobre Azure API Management

**Crear y configurar Azure APIM:**
```bash
# Crear Azure API Management (tarda 30-45 minutos)
./scripts/setup-apim.sh
```

**Arquitectura:**
```
Cliente → Azure APIM → expense-service / expense-client (en AKS)
```

**Beneficios:**
- ✅ Punto de entrada único y seguro
- ✅ Control centralizado (autenticación, rate limiting, logging)
- ✅ Developer Portal para documentar APIs
- ✅ Analytics y métricas avanzadas
- ✅ Integración con Azure AD
- ✅ Versionado de APIs
- ✅ Políticas avanzadas (transformación, caching, etc.)

**⚠️ IMPORTANTE:** Azure APIM tiene costos asociados (~$50/mes para Developer SKU). Elimina el servicio cuando no lo uses.

### Recursos adicionales

- [Documentación de AKS](https://docs.microsoft.com/azure/aks/)
- [Documentación de ACR](https://docs.microsoft.com/azure/container-registry/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Kubernetes Probes Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
