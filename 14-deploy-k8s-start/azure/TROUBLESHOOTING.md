# Guía de Troubleshooting - Azure AKS

Esta guía cubre los problemas más comunes al desplegar en Azure AKS y sus soluciones.

## Índice

1. [Herramientas de Diagnóstico](#herramientas-de-diagnóstico)
2. [Problemas de Configuración Inicial](#problemas-de-configuración-inicial)
3. [Problemas con Imágenes Docker](#problemas-con-imágenes-docker)
4. [Problemas con Pods](#problemas-con-pods)
5. [Problemas de Conectividad](#problemas-de-conectividad)
6. [Problemas con Servicios](#problemas-con-servicios)
7. [Problemas de Autenticación](#problemas-de-autenticación)
8. [Problemas de Arquitectura](#problemas-de-arquitectura)

---

## Herramientas de Diagnóstico

### Script de Diagnóstico Automático

El script más útil para diagnosticar problemas:

**Linux/macOS:**
```bash
./scripts/diagnose.sh
```

**Windows PowerShell:**
```powershell
.\scripts-windows\diagnose.ps1
```

Este script muestra:
- Estado de pods y servicios
- Logs recientes
- Configuración de variables de entorno
- Eventos del cluster
- Pruebas de conectividad

### Comandos Útiles de Diagnóstico

```bash
# Ver estado general
kubectl get all

# Ver pods con más detalles
kubectl get pods -o wide

# Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Ver descripción detallada de un pod
kubectl describe pod <nombre-del-pod>

# Ver logs en tiempo real
kubectl logs -f <nombre-del-pod>

# Ver logs de todos los pods de una app
kubectl logs -l app=expense-client --tail=50

# Ver configuración de un servicio
kubectl describe svc expense-service

# Ver endpoints de un servicio (muestra qué pods están conectados)
kubectl get endpoints expense-service
```

---

## Problemas de Configuración Inicial

### Error: "ACR_NAME no está configurado"

**Síntomas:**
```
Error: ACR_NAME no está configurado.
Ejecuta primero: ./scripts/azure-setup.sh
```

**Causa:** El script no encuentra las variables de configuración.

**Solución:**
```bash
# Opción 1: Ejecutar el script de setup primero
./scripts/azure-setup.sh

# Opción 2: Cargar manualmente las variables
source azure-config.env  # Linux/macOS
# o
. azure-config.ps1       # Windows PowerShell

# Opción 3: Verificar que el archivo existe
ls -la azure-config.env
cat azure-config.env
```

---

### Error: "No hay conexión con el cluster"

**Síntomas:**
```
Error: No hay conexión con el cluster de Kubernetes.
```

**Causa:** kubectl no está configurado o las credenciales expiraron.

**Solución:**
```bash
# Cargar configuración
source azure-config.env

# Reconectar con AKS
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Verificar conexión
kubectl cluster-info
kubectl get nodes
```

**Verificación:**
```bash
# Debería mostrar información del cluster
kubectl cluster-info

# Debería mostrar los nodos
kubectl get nodes
```

---

### Error: "Azure CLI no está instalado"

**Síntomas:**
```
Error: Azure CLI no está instalado.
```

**Solución:**

**macOS:**
```bash
brew install azure-cli
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Windows:**
Descargar desde: https://aka.ms/installazurecliwindows

**Verificar instalación:**
```bash
az --version
```

---

## Problemas con Imágenes Docker

### Error: "Failed to pull image"

**Síntomas:**
```
Failed to pull image "expenseacr123.azurecr.io/expense-service:latest"
```

**Causa:** La imagen no existe en ACR o AKS no tiene permisos.

**Diagnóstico:**
```bash
# 1. Verificar que la imagen existe en ACR
az acr repository list --name $ACR_NAME

# 2. Ver tags de la imagen
az acr repository show-tags --name $ACR_NAME --repository expense-service

# 3. Verificar permisos de AKS a ACR
az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "servicePrincipalProfile"

# 4. Ver detalles del error en el pod
kubectl describe pod <nombre-del-pod>
```

**Solución:**
```bash
# Opción 1: Reconstruir y subir las imágenes
./scripts/build-and-push-all.sh

# Opción 2: Conectar AKS con ACR manualmente
az aks update --name $AKS_NAME --resource-group $RESOURCE_GROUP --attach-acr $ACR_NAME

# Opción 3: Verificar el nombre del ACR en el YAML
# Asegúrate de que coincida con el nombre real
kubectl get deployment expense-service -o yaml | grep image
```

---

### Pods en estado ImagePullBackOff

**Síntomas:**
```bash
kubectl get pods
# NAME                              READY   STATUS             RESTARTS   AGE
# expense-service-xxx               0/1     ImagePullBackOff   0          2m
```

**Causa:** Kubernetes no puede descargar la imagen.

**Diagnóstico:**
```bash
# Ver detalles del error
kubectl describe pod <nombre-del-pod>

# Buscar eventos relacionados
kubectl get events --field-selector involvedObject.name=<nombre-del-pod>
```

**Soluciones comunes:**

1. **Imagen no existe:**
   ```bash
   # Verificar imágenes en ACR
   az acr repository list --name $ACR_NAME
   
   # Reconstruir y subir
   ./scripts/build-and-push-all.sh
   ```

2. **Nombre incorrecto en el YAML:**
   ```bash
   # Verificar qué imagen está intentando usar
   kubectl get deployment expense-service -o jsonpath='{.spec.template.spec.containers[0].image}'
   
   # Comparar con el nombre real del ACR
   echo $ACR_NAME
   ```

3. **Permisos insuficientes:**
   ```bash
   # Conectar AKS con ACR
   az aks update --name $AKS_NAME --resource-group $RESOURCE_GROUP --attach-acr $ACR_NAME
   ```

---

## Problemas con Pods

### Pods en CrashLoopBackOff

**Síntomas:**
```bash
kubectl get pods
# NAME                              READY   STATUS             RESTARTS   AGE
# expense-service-xxx               0/1     CrashLoopBackOff   5          5m
```

**Causa:** El contenedor se está iniciando pero falla inmediatamente.

**Diagnóstico:**
```bash
# Ver logs del pod
kubectl logs <nombre-del-pod> --tail=50

# Ver logs de intentos anteriores
kubectl logs <nombre-del-pod> --previous

# Ver descripción completa del pod
kubectl describe pod <nombre-del-pod>

# Ver eventos relacionados
kubectl get events --field-selector involvedObject.name=<nombre-del-pod>
```

**Causas comunes y soluciones:**

1. **Error "exec format error" (problema de arquitectura):**
   - Ver sección [Problemas de Arquitectura](#problemas-de-arquitectura)

2. **Error de aplicación Java:**
   ```bash
   # Ver logs para identificar el error específico
   kubectl logs <nombre-del-pod> --tail=100
   
   # Posibles causas:
   # - Puerto incorrecto
   # - Variable de entorno faltante
   # - Dependencia no disponible
   ```

3. **Problema de permisos:**
   ```bash
   # Verificar securityContext en el pod
   kubectl get pod <nombre-del-pod> -o yaml | grep -A 10 securityContext
   ```

---

### Pods en estado Pending

**Síntomas:**
```bash
kubectl get pods
# NAME                              READY   STATUS    RESTARTS   AGE
# expense-service-xxx               0/1     Pending   0          2m
```

**Causa:** El pod no puede ser programado en un nodo.

**Diagnóstico:**
```bash
# Ver por qué está pendiente
kubectl describe pod <nombre-del-pod>

# Buscar mensajes como:
# - Insufficient CPU/Memory
# - NodeSelector/NodeAffinity issues
# - Taints/Tolerations
```

**Soluciones:**

1. **Recursos insuficientes:**
   ```bash
   # Ver recursos disponibles en los nodos
   kubectl top nodes
   
   # Escalar el cluster si es necesario
   az aks scale --resource-group $RESOURCE_GROUP --name $AKS_NAME --node-count 3
   ```

2. **Eliminar el pod para que se reprograme:**
   ```bash
   kubectl delete pod <nombre-del-pod>
   ```

---

### Pods en estado Error

**Síntomas:**
```bash
kubectl get pods
# NAME                              READY   STATUS   RESTARTS   AGE
# expense-service-xxx               0/1     Error    1          2m
```

**Diagnóstico:**
```bash
# Ver logs del contenedor
kubectl logs <nombre-del-pod>

# Ver descripción del pod
kubectl describe pod <nombre-del-pod>

# Ver eventos
kubectl get events --field-selector involvedObject.name=<nombre-del-pod>
```

**Solución:** Depende del error específico en los logs. Ver secciones anteriores según el tipo de error.

---

## Problemas de Conectividad

### El servicio responde pero no devuelve datos

**Síntomas:**
```bash
curl http://51.8.232.134:8080/expenses
# No devuelve datos o devuelve error
```

**Causa:** `expense-client` no puede conectarse a `expense-service`.

**Diagnóstico paso a paso:**

```bash
# 1. Verificar que ambos pods estén corriendo
kubectl get pods
# Ambos deberían estar en estado "Running"

# 2. Ver logs de expense-client
kubectl logs -l app=expense-client --tail=50
# Buscar errores de conexión

# 3. Ver logs de expense-service
kubectl logs -l app=expense-service --tail=50
# Verificar que el servicio esté escuchando

# 4. Verificar variable EXPENSE_SVC
CLIENT_POD=$(kubectl get pods -l app=expense-client -o jsonpath='{.items[0].metadata.name}')
kubectl exec $CLIENT_POD -- env | grep EXPENSE_SVC
# Debería mostrar: EXPENSE_SVC=http://expense-service:8080

# 5. Probar conectividad desde expense-client a expense-service
kubectl exec $CLIENT_POD -- wget -q -O- http://expense-service:8080/expenses
# Debería devolver JSON (puede estar vacío [])

# 6. Verificar que expense-service tenga endpoints
kubectl get endpoints expense-service
# Debería mostrar la IP del pod de expense-service
```

**Soluciones:**

1. **Si EXPENSE_SVC no está configurada:**
   ```bash
   # Verificar ConfigMap
   kubectl get configmap expense-client-config -o yaml
   
   # Si falta, recrear
   kubectl apply -f k8s/expenses-all.yaml
   ```

2. **Si expense-service no responde:**
   ```bash
   # Verificar que el pod esté corriendo
   kubectl get pods -l app=expense-service
   
   # Ver logs para identificar el problema
   kubectl logs -l app=expense-service --tail=50
   ```

3. **Si hay problemas de DNS:**
   ```bash
   # Probar resolución DNS desde expense-client
   kubectl exec $CLIENT_POD -- nslookup expense-service
   
   # Verificar que el servicio existe
   kubectl get svc expense-service
   ```

4. **Recrear los pods:**
   ```bash
   kubectl delete pods -l app=expense-client
   kubectl delete pods -l app=expense-service
   # Kubernetes los recreará automáticamente
   ```

---

### No se puede conectar desde fuera del cluster

**Síntomas:**
```bash
curl http://<IP>:8080/expenses
# Timeout o conexión rechazada
```

**Diagnóstico:**
```bash
# 1. Verificar que el LoadBalancer tenga IP externa
kubectl get svc expense-client
# EXTERNAL-IP debería mostrar una IP (no <pending>)

# 2. Verificar que el servicio tenga endpoints
kubectl get endpoints expense-client
# Debería mostrar la IP del pod

# 3. Verificar que el pod esté corriendo
kubectl get pods -l app=expense-client
```

**Soluciones:**

1. **Si EXTERNAL-IP está en <pending>:**
   - Esperar unos minutos (puede tardar hasta 5 minutos)
   - Verificar eventos: `kubectl get events`
   - Verificar que el cluster tenga suficientes recursos

2. **Usar port-forward como alternativa:**
   ```bash
   kubectl port-forward svc/expense-client 8081:8080
   # Luego acceder en http://localhost:8081
   ```

---

## Problemas con Servicios

### LoadBalancer no obtiene IP externa

**Síntomas:**
```bash
kubectl get svc expense-client
# EXTERNAL-IP muestra <pending>
```

**Causa:** Azure está creando el LoadBalancer pero puede tardar.

**Solución:**
```bash
# Esperar unos minutos (hasta 5 minutos)
watch kubectl get svc expense-client

# Ver eventos para más información
kubectl get events --sort-by='.lastTimestamp' | grep expense-client

# Ver descripción del servicio
kubectl describe svc expense-client
```

**Alternativa temporal:**
```bash
# Usar port-forward
kubectl port-forward svc/expense-client 8081:8080
```

---

### El servicio no tiene endpoints

**Síntomas:**
```bash
kubectl get endpoints expense-service
# NAME              ENDPOINTS
# expense-service   <none>
```

**Causa:** No hay pods corriendo que coincidan con el selector del servicio.

**Diagnóstico:**
```bash
# Ver selector del servicio
kubectl get svc expense-service -o jsonpath='{.spec.selector}'

# Ver labels de los pods
kubectl get pods -l app=expense-service --show-labels

# Comparar que coincidan
```

**Solución:**
```bash
# Verificar que los pods estén corriendo
kubectl get pods -l app=expense-service

# Si no hay pods, verificar el deployment
kubectl get deployment expense-service
kubectl describe deployment expense-service

# Recrear el deployment si es necesario
kubectl delete deployment expense-service
kubectl apply -f k8s/expenses-all.yaml
```

---

## Problemas de Autenticación

### Error al hacer login a ACR con Podman

**Síntomas:**
```
Error: Falló el login a ACR con Podman.
```

**Causa:** Problema con el token de autenticación.

**Solución:**
```bash
# Obtener token manualmente
ACR_TOKEN=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken)

# Verificar que el token no esté vacío
echo $ACR_TOKEN

# Hacer login manual
echo "$ACR_TOKEN" | podman login $ACR_NAME.azurecr.io --username "00000000-0000-0000-0000-000000000000" --password-stdin
```

---

### Error al hacer login a ACR con Docker

**Síntomas:**
```
Error: Falló el login a ACR con Docker.
```

**Solución:**
```bash
# Verificar que Docker esté corriendo
docker ps

# Intentar login manual
az acr login --name $ACR_NAME

# Si falla, verificar credenciales de Azure
az account show
az login
```

---

## Problemas de Arquitectura

### Error "exec format error"

**Síntomas:**
```bash
kubectl logs <pod>
# exec /opt/jboss/container/java/run/run-java.sh: exec format error

kubectl get pods
# STATUS: CrashLoopBackOff
```

**Causa:** Las imágenes fueron construidas para una arquitectura diferente (ARM64 en Mac M1/M2) pero AKS ejecuta AMD64/x86_64.

**Diagnóstico:**
```bash
# Ver arquitectura de las imágenes en ACR
az acr repository show-tags --name $ACR_NAME --repository expense-service --detail

# Ver arquitectura del nodo
kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.architecture}'
```

**Solución:**

1. **Reconstruir imágenes para AMD64:**
   ```bash
   # El script ahora lo hace automáticamente
   ./scripts/build-and-push-all.sh
   ```

2. **Verificar que las nuevas imágenes sean AMD64:**
   ```bash
   az acr repository show-tags --name $ACR_NAME --repository expense-service --detail
   # Buscar "architecture": "amd64"
   ```

3. **Eliminar pods para que usen las nuevas imágenes:**
   ```bash
   kubectl delete pods -l app=expense-client
   kubectl delete pods -l app=expense-service
   ```

4. **Verificar que los nuevos pods funcionen:**
   ```bash
   kubectl get pods
   # Deberían estar en estado "Running"
   ```

**Prevención:** Los scripts ahora construyen automáticamente para `linux/amd64` usando `--platform linux/amd64`.

---

## Casos de Uso Comunes

### Caso 1: Todo funcionaba pero ahora no responde

**Diagnóstico rápido:**
```bash
# 1. Ver estado de pods
kubectl get pods

# 2. Ver logs recientes
kubectl logs -l app=expense-client --tail=20
kubectl logs -l app=expense-service --tail=20

# 3. Ver eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -10

# 4. Verificar servicios
kubectl get svc
```

**Soluciones comunes:**
- Pods fueron eliminados: `kubectl get pods` mostrará pods nuevos
- Imagen fue actualizada: Los pods pueden estar en ImagePullBackOff
- Cambios en configuración: Verificar ConfigMap y variables de entorno

---

### Caso 2: Primera vez desplegando y nada funciona

**Checklist de verificación:**
```bash
# 1. ¿Estás logueado en Azure?
az account show

# 2. ¿Está configurado el cluster?
source azure-config.env
kubectl cluster-info

# 3. ¿Existen las imágenes en ACR?
az acr repository list --name $ACR_NAME

# 4. ¿Están los pods corriendo?
kubectl get pods

# 5. ¿Tienen los servicios IP externa?
kubectl get svc
```

**Solución paso a paso:**
1. Ejecutar `./scripts/azure-setup.sh` si no lo has hecho
2. Ejecutar `./scripts/build-and-push-all.sh` para construir imágenes
3. Ejecutar `./scripts/deploy-all.sh` para desplegar
4. Ejecutar `./scripts/diagnose.sh` para diagnosticar problemas

---

### Caso 3: Los pods se reinician constantemente

**Diagnóstico:**
```bash
# Ver cuántas veces se han reiniciado
kubectl get pods
# RESTARTS mostrará un número alto

# Ver logs del último intento
kubectl logs <pod-name> --tail=50

# Ver logs de intentos anteriores
kubectl logs <pod-name> --previous
```

**Causas comunes:**
- Error en la aplicación (ver logs)
- Problema de arquitectura (ver sección anterior)
- Límites de recursos (ver `kubectl describe pod`)
- Health checks fallando (ver `kubectl describe pod`)

---

## Recursos Adicionales

### Comandos Útiles de Azure

```bash
# Ver información del cluster
az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP

# Ver logs del cluster
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# Escalar nodos
az aks scale --resource-group $RESOURCE_GROUP --name $AKS_NAME --node-count 3

# Ver información de ACR
az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP

# Ver imágenes en ACR
az acr repository list --name $ACR_NAME
az acr repository show-tags --name $ACR_NAME --repository expense-service
```

### Enlaces Útiles

- [Documentación oficial de AKS](https://docs.microsoft.com/azure/aks/)
- [Troubleshooting de AKS](https://docs.microsoft.com/azure/aks/troubleshooting)
- [Documentación de kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

---

## Obtener Ayuda

Si después de seguir esta guía el problema persiste:

1. **Ejecuta el script de diagnóstico completo:**
   ```bash
   ./scripts/diagnose.sh > diagnostico.txt
   ```

2. **Recopila información adicional:**
   ```bash
   kubectl get all -o yaml > estado-cluster.yaml
   kubectl get events > eventos.txt
   ```

3. **Revisa los logs detallados:**
   ```bash
   kubectl logs -l app=expense-client > logs-client.txt
   kubectl logs -l app=expense-service > logs-service.txt
   ```

Con esta información podrás identificar mejor el problema o pedir ayuda específica.
