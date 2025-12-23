# LAB 19: QUARKUS HEALTH

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

Este laboratorio te guiará en la implementación de health checks (liveness y readiness) en una aplicación Quarkus, que son esenciales para el despliegue en Kubernetes.

## Prerequisitos

- Proyecto `16-tolerance-health-start` abierto en tu editor favorito
- Terminal disponible (PowerShell en Windows, Terminal en Linux/Mac)
- Maven instalado y configurado
- Java JDK instalado

## Pasos del Laboratorio

### 1. Abre el Proyecto

Abre el proyecto `16-tolerance-health-start` con tu editor favorito.

### 2. Revisa los Archivos del Proyecto

Revisa los siguientes archivos para entender la estructura del proyecto:

- **`com.bcp.training.service.StateService`**: Es un bean que controla si la aplicación está viva.
- **`com.bcp.training.SolverResource`**: Es una clase que expone un endpoint REST que soluciona ecuaciones matemáticas.

### 3. Instalar la Extensión Quarkus Health

Incluye las extensiones Quarkus requeridas para integrar health checks en la aplicación.

**Nota:** Asegúrate de estar en el directorio `quarkus-calculator` antes de ejecutar los comandos Maven.

##### Windows (PowerShell)
```powershell
cd quarkus-calculator
mvn quarkus:add-extension -Dextensions=smallrye-health
```

##### Linux/Mac
```bash
cd quarkus-calculator
mvn quarkus:add-extension -Dextensions=smallrye-health
```

### 4. Crear un Liveness Health Check Endpoint

El liveness check indica si la aplicación está funcionando. Si falla, Kubernetes reiniciará el contenedor.

1. Abre la clase `LivenessHealthResource.java`
2. Anota la clase con la anotación `@Liveness` e implementa la interfaz `HealthCheck`
3. Sobrescribe el método `call()` usando `StateService` para determinar si la aplicación está viva (up) o no (down)

**Implementación esperada:**

```java
@Liveness
@ApplicationScoped
public class LivenessHealthResource implements HealthCheck {

    private final String HEALTH_CHECK_NAME = "Liveness";

    @Inject
    StateService applicationState;

    @Override
    public HealthCheckResponse call() {
        return applicationState.isAlive()
                ? HealthCheckResponse.up(HEALTH_CHECK_NAME)
                : HealthCheckResponse.down(HEALTH_CHECK_NAME);
    }
}
```

### 5. Crear un Readiness Health Check Endpoint

El readiness check indica si la aplicación está lista para recibir tráfico. Si falla, Kubernetes dejará de enviar tráfico al pod.

1. Abre la clase `ReadinessHealthResource.java`
2. Anota la clase con la anotación `@Readiness`, implementa la interfaz `HealthCheck` sobrescribiendo el método `call()`
3. Las primeras 10 llamadas del endpoint readiness deben retornar una respuesta `DOWN` health check

**Implementación esperada:**

```java
@Readiness
@ApplicationScoped
public class ReadinessHealthResource implements HealthCheck {

    private final String HEALTH_CHECK_NAME = "Readiness";

    private int counter = 0;

    @Override
    public HealthCheckResponse call() {
        return ++counter >= 10
                ? HealthCheckResponse.up(HEALTH_CHECK_NAME)
                : HealthCheckResponse.down(HEALTH_CHECK_NAME);
    }
}
```

### 6. Verificar la Implementación de los Health Checks

Los primeros 10 requests al endpoint health deben retornar el estatus `DOWN`.

#### 6.1. Iniciar la Aplicación en Modo Desarrollo

Navega al directorio del proyecto `quarkus-calculator` antes de ejecutar los comandos:

##### Windows (PowerShell)
```powershell
cd quarkus-calculator
mvn quarkus:dev
```

##### Linux/Mac
```bash
cd quarkus-calculator
mvn quarkus:dev
```

#### 6.2. Verificar el Endpoint de Health Checks

Abre una nueva terminal y usa los siguientes comandos para verificar que el endpoint `/q/health` retorna `DOWN` como el status actual de la aplicación.

##### Windows (PowerShell)
```powershell
# Asegúrate de estar en el directorio quarkus-calculator
cd quarkus-calculator

# Opción 1: Usando el script watch-health.ps1 (recomendado)
.\watch-health.ps1

# Opción 2: Usando un bucle while manual
while ($true) {
    Invoke-RestMethod -Uri http://localhost:8080/q/health | ConvertTo-Json
    Start-Sleep -Seconds 2
}
```

##### Linux/Mac
```bash
# Opción 1: Usando watch (disponible en Linux y la mayoría de distribuciones Mac)
watch -d -n 2 curl -s http://localhost:8080/q/health

# Opción 2: Si watch no está instalado en Mac, puedes instalarlo con:
# brew install watch
# O usar un bucle alternativo:
while true; do 
    echo "=== $(date) ==="
    curl -s http://localhost:8080/q/health | jq . 2>/dev/null || curl -s http://localhost:8080/q/health
    sleep 2
done
```

**Nota:** Espera hasta que el contador del readiness llegue al límite especificado en la lógica de la aplicación (10 llamadas), y reporte `UP`.

#### 6.3. Probar el Endpoint Crash

Abre una nueva terminal y usa el comando curl para llamar al endpoint `/crash`.

##### Windows (PowerShell)
```powershell
curl.exe http://localhost:8080/crash
# O usando Invoke-RestMethod
Invoke-RestMethod -Uri http://localhost:8080/crash
```

##### Linux/Mac
```bash
curl http://localhost:8080/crash
```

#### 6.4. Verificar el Estado Después del Crash

1. Cierra la terminal donde se ejecutó el comando curl
2. Reejecuta el comando watch/curl y verifica la respuesta a los health checks
3. El status de los liveness checks deben ser `DOWN` después del crash

##### Windows (PowerShell)
```powershell
# Opción 1: Usando el script watch-health.ps1 (recomendado)
.\watch-health.ps1

# Opción 2: Usando un bucle while manual
while ($true) {
    Invoke-RestMethod -Uri http://localhost:8080/q/health | ConvertTo-Json
    Start-Sleep -Seconds 2
}
```

##### Linux/Mac
```bash
# Opción 1: Usando watch
watch -d -n 2 curl -s http://localhost:8080/q/health

# Opción 2: Bucle alternativo si watch no está disponible
while true; do 
    echo "=== $(date) ==="
    curl -s http://localhost:8080/q/health | jq . 2>/dev/null || curl -s http://localhost:8080/q/health
    sleep 2
done
```

#### 6.5. Detener el Monitoreo

1. Detén el comando watch/curl presionando `CTRL+C`
2. Cierra la terminal

#### 6.6. ¿Qué Pasa con el Liveness Check en Kubernetes?

**⚠️ Observación Importante:**

Cuando ejecutas `curl http://localhost:8080/crash` y luego monitoreas el health check, notarás que el liveness check queda en estado `DOWN` permanentemente. Esto es el comportamiento esperado en tu entorno local.

**¿Por qué no se recupera automáticamente?**

En tu entorno local, cuando el liveness check falla, simplemente queda en `DOWN` porque no hay ningún sistema que reinicie la aplicación. Sin embargo, **en Kubernetes el comportamiento es completamente diferente**:

1. **Kubernetes monitorea el liveness probe** cada `period` segundos (configurado en `quarkus.openshift.liveness-probe.period=2s`)
2. Si el liveness probe falla continuamente, Kubernetes considera que el contenedor está en un estado "muerto" o "bloqueado"
3. **Kubernetes automáticamente reinicia el contenedor** (kill y restart)
4. Al reiniciarse, el contenedor vuelve a su estado inicial (`alive = true`), por lo que el liveness check vuelve a `UP`

**En resumen:**
- **Localmente**: El liveness check queda en `DOWN` hasta que reinicies manualmente la aplicación
- **En Kubernetes**: El liveness check en `DOWN` provoca el reinicio automático del pod, restaurando el estado inicial

## ¿Por Qué Son Importantes los Health Checks para Kubernetes?

Los health checks (liveness y readiness) son fundamentales para el funcionamiento correcto de aplicaciones en Kubernetes. Aquí te explicamos por qué:

### 🔴 Liveness Probe (Sonda de Vida)

**¿Qué es?**
El liveness probe indica si la aplicación está **funcionando correctamente**. Es como preguntar: "¿Está viva la aplicación?"

**¿Por qué es importante?**
- **Detección de deadlocks y bloqueos**: Si tu aplicación se bloquea pero el proceso sigue corriendo, Kubernetes lo detecta y reinicia el contenedor
- **Recuperación automática**: Kubernetes puede recuperar automáticamente aplicaciones que entran en estados inválidos sin intervención manual
- **Prevención de servicios "zombie"**: Evita que contenedores que parecen estar corriendo pero no responden correctamente sigan recibiendo tráfico

**¿Qué pasa cuando falla?**
```
Liveness DOWN → Kubernetes detecta el problema → 
Kubernetes mata el contenedor → Kubernetes crea un nuevo contenedor → 
Nuevo contenedor inicia con estado limpio → Liveness vuelve a UP
```

**Ejemplo práctico:**
En este laboratorio, cuando llamas a `/crash`, el liveness check pasa a `DOWN`. En Kubernetes:
- Kubernetes detecta que el liveness probe falla
- Espera el tiempo configurado (`failureThreshold`)
- Si continúa fallando, **reinicia el pod automáticamente**
- El nuevo pod inicia con `StateService.alive = true` (estado inicial)
- El servicio se recupera automáticamente sin intervención manual

### 🟡 Readiness Probe (Sonda de Preparación)

**¿Qué es?**
El readiness probe indica si la aplicación está **lista para recibir tráfico**. Es como preguntar: "¿Puedo enviar requests a esta aplicación?"

**¿Por qué es importante?**
- **Evita tráfico durante el inicio**: Kubernetes no envía tráfico hasta que la aplicación esté completamente lista
- **Evita tráfico durante mantenimiento**: Si la aplicación entra en modo mantenimiento, Kubernetes deja de enviar tráfico
- **Rolling updates más seguros**: Durante actualizaciones, Kubernetes espera a que el nuevo pod esté listo antes de enviar tráfico

**¿Qué pasa cuando falla?**
```
Readiness DOWN → Kubernetes remueve el pod del Service → 
No se envía tráfico al pod → Pod puede recuperarse sin afectar usuarios → 
Readiness vuelve a UP → Kubernetes vuelve a agregar el pod al Service
```

**Ejemplo práctico:**
En este laboratorio, las primeras 10 llamadas al readiness check retornan `DOWN`. En Kubernetes:
- Durante el inicio, Kubernetes espera hasta que el readiness check pase a `UP`
- Solo después de que el readiness esté `UP`, Kubernetes comienza a enviar tráfico al pod
- Esto evita que los usuarios reciban errores durante el arranque de la aplicación

### 📊 Comparación: Liveness vs Readiness

| Aspecto | Liveness Probe | Readiness Probe |
|---------|---------------|-----------------|
| **Propósito** | ¿Está la aplicación funcionando? | ¿Está la aplicación lista para tráfico? |
| **Acción si falla** | Reinicia el contenedor | Remueve del Service (no reinicia) |
| **Cuándo usar** | Para detectar estados bloqueados | Para detectar si está lista para recibir requests |
| **Frecuencia** | Cada `period` segundos | Cada `period` segundos |
| **Impacto** | Más severo (reinicio) | Menos severo (solo remueve tráfico) |

### 🎯 Configuración en Kubernetes

Las propiedades que configuraste en `application.properties`:

```properties
quarkus.openshift.readiness-probe.period=2s
quarkus.openshift.liveness-probe.period=2s
```

Se traducen automáticamente a la configuración de probes en Kubernetes:

```yaml
livenessProbe:
  httpGet:
    path: /q/health/live
    port: 8080
  periodSeconds: 2
  initialDelaySeconds: 0
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /q/health/ready
    port: 8080
  periodSeconds: 2
  initialDelaySeconds: 0
  failureThreshold: 3
```

### 🚀 Beneficios en Producción

1. **Alta Disponibilidad**: Los pods se recuperan automáticamente de fallos
2. **Mejor Experiencia de Usuario**: Los usuarios no reciben errores durante el inicio o mantenimiento
3. **Menos Intervención Manual**: Kubernetes maneja la recuperación automáticamente
4. **Rolling Updates Seguros**: Las actualizaciones son más seguras y sin downtime
5. **Detección Temprana de Problemas**: Los problemas se detectan y resuelven automáticamente

### ⚠️ Mejores Prácticas

1. **Liveness debe ser ligero**: No debe hacer operaciones pesadas que puedan afectar el rendimiento
2. **Readiness debe verificar dependencias**: Debe verificar que las conexiones a bases de datos, APIs externas, etc., estén funcionando
3. **Configura tiempos apropiados**: `period`, `timeout`, y `failureThreshold` deben ajustarse según tu aplicación
4. **No uses el mismo endpoint**: Liveness y readiness deben verificar cosas diferentes
5. **Considera startup probes**: Para aplicaciones que tardan mucho en iniciar, usa startup probes además de liveness

## Endpoints de Health Checks

Una vez implementados los health checks, Quarkus expone automáticamente los siguientes endpoints:

- **`/q/health`**: Endpoint principal que muestra el estado general de todos los health checks
- **`/q/health/live`**: Endpoint específico para liveness checks
- **`/q/health/ready`**: Endpoint específico para readiness checks

### Ejemplo de Respuesta del Endpoint `/q/health`

Cuando todos los checks están `UP`:
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "Liveness",
      "status": "UP"
    },
    {
      "name": "Readiness",
      "status": "UP"
    }
  ]
}
```

Cuando algún check está `DOWN`:
```json
{
  "status": "DOWN",
  "checks": [
    {
      "name": "Liveness",
      "status": "DOWN"
    },
    {
      "name": "Readiness",
      "status": "UP"
    }
  ]
}
```

## Comandos Docker/Podman (Opcional)

Si necesitas ejecutar la aplicación en un contenedor, puedes usar los siguientes comandos:

**Nota:** Asegúrate de estar en el directorio `quarkus-calculator` antes de ejecutar los comandos de construcción.

### Construir la Imagen

Primero, construye la aplicación JAR:

##### Windows (PowerShell)
```powershell
cd quarkus-calculator
mvn clean package
```

##### Linux/Mac
```bash
cd quarkus-calculator
mvn clean package
```

Luego construye la imagen del contenedor:

##### Docker
```bash
# Desde el directorio quarkus-calculator
docker build -f src/main/docker/Dockerfile.jvm -t quarkus-calculator:jvm .
```

##### Podman
```bash
# Desde el directorio quarkus-calculator
podman build -f src/main/docker/Dockerfile.jvm -t quarkus-calculator:jvm .
```

### Ejecutar el Contenedor

##### Docker
```bash
docker run -i --rm -p 8080:8080 quarkus-calculator:jvm
```

##### Podman
```bash
podman run -i --rm -p 8080:8080 quarkus-calculator:jvm
```

### Verificar Health Checks en el Contenedor

##### Windows (PowerShell)
```powershell
# Desde otra terminal
Invoke-RestMethod -Uri http://localhost:8080/q/health | ConvertTo-Json
# O usando curl
curl.exe http://localhost:8080/q/health
```

##### Linux/Mac
```bash
# Desde otra terminal
curl http://localhost:8080/q/health
```

## Resumen

En este laboratorio has aprendido a:

1. ✅ Instalar la extensión `smallrye-health` de Quarkus
2. ✅ Implementar un **Liveness Health Check** que verifica si la aplicación está viva
3. ✅ Implementar un **Readiness Health Check** que verifica si la aplicación está lista para recibir tráfico
4. ✅ Verificar el funcionamiento de los health checks usando curl
5. ✅ Entender cómo los health checks responden cuando la aplicación falla
6. ✅ Comprender la **importancia crítica** de los health checks para Kubernetes y cómo Kubernetes los utiliza para:
   - Reiniciar automáticamente contenedores con problemas (liveness)
   - Gestionar el tráfico durante el inicio y mantenimiento (readiness)
   - Mantener alta disponibilidad sin intervención manual

## Próximos Pasos

- Integrar estos health checks en un despliegue de Kubernetes
- Configurar probes de liveness y readiness en los manifiestos de Kubernetes
- Explorar health checks más complejos con métricas personalizadas

---

**¡Enjoy!**  
**José Díaz**
