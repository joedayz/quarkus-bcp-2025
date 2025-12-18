# Ejercicio: Liveness y Readiness Probes

## ¿Qué son los Probes?

Los **probes** son verificaciones de salud que Kubernetes realiza periódicamente en tus contenedores para determinar su estado. Hay dos tipos principales:

### Readiness Probe
- **Propósito**: Determina si el contenedor está **listo para recibir tráfico**
- **Cuándo se ejecuta**: Continuamente mientras el pod está corriendo
- **Qué hace**: Si falla, Kubernetes **remueve el pod del Service** (no recibe tráfico)
- **Cuándo usar**: Cuando la aplicación necesita tiempo para inicializarse o cuando puede estar temporalmente ocupada

### Liveness Probe
- **Propósito**: Determina si el contenedor está **vivo y funcionando correctamente**
- **Cuándo se ejecuta**: Continuamente mientras el pod está corriendo
- **Qué hace**: Si falla, Kubernetes **reinicia el contenedor**
- **Cuándo usar**: Para detectar deadlocks o estados donde la aplicación está corriendo pero no responde

## ¿Por qué son importantes?

### Sin Probes:
```
┌─────────────┐
│   Service   │
└──────┬──────┘
       │
       ├─── Pod 1 (iniciando...) ← Recibe tráfico aunque no esté listo ❌
       ├─── Pod 2 (muerto)      ← Recibe tráfico aunque esté muerto ❌
       └─── Pod 3 (OK)           ← Funciona correctamente ✓
```

### Con Probes:
```
┌─────────────┐
│   Service   │
└──────┬──────┘
       │
       ├─── Pod 1 (iniciando...) ← NO recibe tráfico hasta estar listo ✓
       ├─── Pod 2 (muerto)      ← Se reinicia automáticamente ✓
       └─── Pod 3 (OK)           ← Recibe tráfico normalmente ✓
```

## Endpoints de Health en Quarkus

Para habilitar los health checks en Quarkus, necesitas agregar la dependencia `quarkus-smallrye-health`:

### Paso 0: Agregar la dependencia de Health Checks

**En `pom.xml` de ambos proyectos (`expense-service` y `expense-client`):**

```xml
<dependency>
  <groupId>io.quarkus</groupId>
  <artifactId>quarkus-smallrye-health</artifactId>
</dependency>
```

**Luego reconstruir las imágenes:**
```bash
cd azure
./scripts/build-and-push-all.sh
```

Una vez agregada la dependencia, Quarkus expone automáticamente estos endpoints:

- **`/q/health`** - Health check general
- **`/q/health/live`** - Liveness check (si está vivo)
- **`/q/health/ready`** - Readiness check (si está listo)

**Nota:** Los endpoints están disponibles automáticamente una vez agregada la dependencia, sin necesidad de código adicional.

## Ejercicio Paso a Paso

### Paso 0: Agregar Health Checks a las aplicaciones

**IMPORTANTE:** Antes de continuar, asegúrate de que las aplicaciones tengan la dependencia de health checks.

1. **Verificar que la dependencia está en los `pom.xml`:**
   ```bash
   grep -A 2 "quarkus-smallrye-health" expense-service/pom.xml
   grep -A 2 "quarkus-smallrye-health" expense-client/pom.xml
   ```

2. **Si no está, agregarla** (ya debería estar agregada en los archivos):
   - `expense-service/pom.xml`
   - `expense-client/pom.xml`

3. **Reconstruir las imágenes:**
   ```bash
   cd azure
   ./scripts/build-and-push-all.sh
   ```

4. **Redesplegar:**
   ```bash
   ./scripts/deploy-all.sh
   ```

### Paso 1: Verificar que los Health Endpoints funcionan

Primero, vamos a verificar que los endpoints de health están disponibles:

```bash
# Obtener la IP del LoadBalancer
kubectl get svc expense-client

# Probar el endpoint de health (desde fuera del cluster)
curl http://<IP>:8080/q/health

# O usar port-forward
kubectl port-forward svc/expense-service 8080:8080
# En otra terminal:
curl http://localhost:8080/q/health
```

**Ejemplo de respuesta:**
```json
{
  "status": "UP",
  "checks": []
}
```

### Paso 2: Ver el estado actual SIN probes

Antes de agregar probes, veamos cómo se comporta el sistema:

```bash
# Ver estado de los pods
kubectl get pods

# Ver detalles de un pod (nota que no hay probes configurados)
kubectl describe pod <nombre-del-pod> | grep -A 10 "Liveness\|Readiness"

# Verificar que el pod recibe tráfico incluso si está iniciando
# (esto es un problema que los probes solucionan)
```

### Paso 3: Agregar Probes a los Deployments

Vamos a actualizar los deployments para incluir probes. Los probes se configuran en el contenedor:

```yaml
containers:
- name: expense-service
  image: ...
  livenessProbe:
    httpGet:
      path: /q/health/live
      port: 8080
    initialDelaySeconds: 30    # Esperar 30s antes de empezar a verificar
    periodSeconds: 10           # Verificar cada 10 segundos
    timeoutSeconds: 5           # Timeout de 5 segundos
    failureThreshold: 3         # Reiniciar después de 3 fallos consecutivos
  readinessProbe:
    httpGet:
      path: /q/health/ready
      port: 8080
    initialDelaySeconds: 10    # Esperar 10s antes de empezar
    periodSeconds: 5            # Verificar cada 5 segundos
    timeoutSeconds: 3           # Timeout de 3 segundos
    failureThreshold: 3         # Remover del servicio después de 3 fallos
```

### Paso 4: Aplicar los cambios

```bash
# Aplicar el deployment actualizado
kubectl apply -f k8s/expenses-all.yaml

# Ver el rollout
kubectl rollout status deployment/expense-service
kubectl rollout status deployment/expense-client

# Verificar que los probes están configurados
kubectl describe pod <nombre-del-pod> | grep -A 15 "Liveness\|Readiness"
```

### Paso 5: Observar el comportamiento

#### Escenario 1: Pod iniciando

```bash
# Eliminar un pod para ver cómo se recrea
kubectl delete pod <nombre-del-pod>

# Observar el estado en tiempo real
watch kubectl get pods

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

**Qué observar:**
- El pod pasa por estados: `Pending` → `ContainerCreating` → `Running`
- Durante el inicio, el **readiness probe** falla (pod no está listo)
- El pod **NO recibe tráfico** hasta que el readiness probe tenga éxito
- Una vez listo, el pod empieza a recibir tráfico

#### Escenario 2: Verificar que el pod no recibe tráfico hasta estar listo

```bash
# Ver los endpoints del servicio
kubectl get endpoints expense-service

# Mientras un pod está iniciando, los endpoints NO incluirán ese pod
# Una vez que el readiness probe tenga éxito, el pod aparecerá en los endpoints
```

#### Escenario 3: Simular un problema (liveness probe)

Para demostrar el liveness probe, podemos simular que la aplicación deja de responder:

```bash
# Ver logs del pod
kubectl logs -f <nombre-del-pod>

# En otra terminal, hacer que la aplicación deje de responder
# (esto requiere modificar el código o usar un comando especial)
# Por ahora, solo observa los eventos cuando un pod falla
```

**Qué observar:**
- Si el liveness probe falla 3 veces consecutivas
- Kubernetes reinicia el contenedor automáticamente
- El pod se reinicia y vuelve a pasar por el proceso de readiness

### Paso 6: Verificar que los probes funcionan correctamente

```bash
# Ver el estado de los probes en un pod
kubectl describe pod <nombre-del-pod>

# Buscar secciones como:
# Liveness:     http-get http://:8080/q/health/live delay=30s timeout=5s period=10s #success=1 #failure=3
# Readiness:    http-get http://:8080/q/health/ready delay=10s timeout=3s period=5s #success=1 #failure=3
```

## Parámetros de los Probes

### Parámetros Comunes

| Parámetro | Descripción | Ejemplo | Recomendación |
|-----------|-------------|---------|---------------|
| `initialDelaySeconds` | Tiempo de espera antes de empezar a verificar | `30` | Tiempo estimado de inicio de la app |
| `periodSeconds` | Frecuencia de verificación | `10` | Cada 10 segundos |
| `timeoutSeconds` | Timeout para cada verificación | `5` | Menor que periodSeconds |
| `successThreshold` | Intentos exitosos necesarios | `1` | Generalmente 1 |
| `failureThreshold` | Intentos fallidos antes de acción | `3` | 3 es un buen balance |

### Recomendaciones

**Readiness Probe:**
- `initialDelaySeconds`: 5-10 segundos (tiempo mínimo para que la app inicie)
- `periodSeconds`: 5 segundos (verificar frecuentemente)
- `timeoutSeconds`: 3 segundos (rápido)
- `failureThreshold`: 3 (dar tiempo para recuperarse)

**Liveness Probe:**
- `initialDelaySeconds`: 30-60 segundos (dar tiempo para que la app inicie completamente)
- `periodSeconds`: 10 segundos (menos frecuente que readiness)
- `timeoutSeconds`: 5 segundos
- `failureThreshold`: 3 (evitar reinicios innecesarios)

## Casos de Uso Prácticos

### Caso 1: Aplicación lenta al iniciar

**Problema:** La aplicación tarda 20 segundos en iniciar completamente.

**Solución:**
```yaml
readinessProbe:
  initialDelaySeconds: 20  # Esperar hasta que la app esté lista
  periodSeconds: 5
```

**Resultado:** El pod no recibe tráfico hasta que esté completamente iniciado.

### Caso 2: Aplicación que puede quedar bloqueada

**Problema:** La aplicación puede entrar en deadlock y dejar de responder.

**Solución:**
```yaml
livenessProbe:
  initialDelaySeconds: 60   # Dar tiempo para iniciar
  periodSeconds: 10          # Verificar cada 10 segundos
  failureThreshold: 3        # Reiniciar después de 30 segundos sin respuesta
```

**Resultado:** Si la app deja de responder, Kubernetes la reinicia automáticamente.

### Caso 3: Aplicación con carga variable

**Problema:** Bajo carga alta, la aplicación puede tardar más en responder.

**Solución:**
```yaml
readinessProbe:
  timeoutSeconds: 5         # Timeout más largo bajo carga
  periodSeconds: 5          # Verificar frecuentemente
  failureThreshold: 2       # Remover rápido si realmente está caída
```

**Resultado:** El pod se remueve del servicio rápidamente si está realmente caído, pero tolera latencia temporal.

## Troubleshooting de Probes

### El pod está en estado "NotReady"

**Diagnóstico:**
```bash
# Ver por qué el readiness probe está fallando
kubectl describe pod <nombre-del-pod> | grep -A 10 "Readiness"

# Ver eventos relacionados
kubectl get events --field-selector involvedObject.name=<nombre-del-pod>

# Probar el endpoint manualmente desde dentro del pod
kubectl exec <nombre-del-pod> -- wget -q -O- http://localhost:8080/q/health/ready
```

**Posibles causas:**
- La aplicación aún está iniciando (normal, esperar)
- El endpoint `/q/health/ready` no está disponible
- La aplicación está fallando al iniciar
- El puerto es incorrecto

### El pod se reinicia constantemente

**Diagnóstico:**
```bash
# Ver cuántas veces se ha reiniciado
kubectl get pods

# Ver logs del contenedor anterior
kubectl logs <nombre-del-pod> --previous

# Ver eventos de reinicio
kubectl describe pod <nombre-del-pod> | grep -A 5 "Liveness"
```

**Posibles causas:**
- El liveness probe es demasiado agresivo
- La aplicación realmente está fallando
- El endpoint `/q/health/live` no está disponible
- `initialDelaySeconds` es muy corto

**Solución:**
```yaml
# Aumentar el initialDelaySeconds
livenessProbe:
  initialDelaySeconds: 60  # Dar más tiempo para iniciar
```

## Ejercicios Prácticos

### Ejercicio 1: Observar el comportamiento sin probes

1. Despliega sin probes
2. Elimina un pod
3. Observa que el pod puede recibir tráfico antes de estar listo
4. Agrega probes
5. Repite el proceso y observa la diferencia

### Ejercicio 2: Ajustar los tiempos

1. Configura `initialDelaySeconds` muy corto (5 segundos)
2. Observa que el probe falla inicialmente
3. Aumenta gradualmente hasta encontrar el valor óptimo

### Ejercicio 3: Simular fallo de liveness

1. Configura un liveness probe agresivo (periodSeconds: 5)
2. Simula que la aplicación deja de responder
3. Observa cómo Kubernetes reinicia el contenedor automáticamente

## Comandos Útiles

```bash
# Ver configuración de probes en un pod
kubectl get pod <nombre> -o yaml | grep -A 20 "livenessProbe\|readinessProbe"

# Ver eventos relacionados con probes
kubectl get events --sort-by='.lastTimestamp' | grep -i probe

# Ver estado de readiness de todos los pods
kubectl get pods -o custom-columns=NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status

# Probar endpoint de health desde dentro del pod
kubectl exec <pod> -- wget -q -O- http://localhost:8080/q/health
kubectl exec <pod> -- wget -q -O- http://localhost:8080/q/health/live
kubectl exec <pod> -- wget -q -O- http://localhost:8080/q/health/ready
```

## Scripts de Demostración

### Test de Probes

Para probar que los probes están configurados correctamente:

**Linux/macOS:**
```bash
./scripts/test-probes.sh
```

**Windows PowerShell:**
```powershell
.\scripts-windows\test-probes.ps1
```

Este script:
- Verifica la configuración de probes en los pods
- Prueba los endpoints de health desde dentro de los pods
- Muestra el estado de readiness
- Muestra los endpoints del servicio

### Demostración de la Diferencia

Para ver la diferencia entre tener y no tener probes:

**Linux/macOS:**
```bash
./scripts/demo-probes-difference.sh
```

Este script:
- Despliega primero sin probes (opcional)
- Despliega con probes
- Simula un reinicio de pod
- Muestra cómo los probes previenen que pods no listos reciban tráfico

## Archivos de Comparación

- **`k8s/expenses-all.yaml`** - Deployment CON probes (producción)
- **`k8s/expenses-all-no-probes.yaml`** - Deployment SIN probes (solo para comparación educativa)

## Resumen

✅ **Readiness Probe**: Determina si el pod está listo para recibir tráfico
✅ **Liveness Probe**: Determina si el contenedor está vivo y funcionando
✅ **Beneficios**: Mejor disponibilidad, detección automática de problemas, reinicio automático
✅ **Quarkus**: Proporciona endpoints `/q/health/live` y `/q/health/ready` automáticamente

Los probes son esenciales para aplicaciones en producción y mejoran significativamente la confiabilidad de tus despliegues.
