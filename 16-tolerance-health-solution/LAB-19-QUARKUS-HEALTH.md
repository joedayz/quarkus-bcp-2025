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

## Próximos Pasos

- Integrar estos health checks en un despliegue de Kubernetes
- Configurar probes de liveness y readiness en los manifiestos de Kubernetes
- Explorar health checks más complejos con métricas personalizadas

---

**¡Enjoy!**  
**José Díaz**
