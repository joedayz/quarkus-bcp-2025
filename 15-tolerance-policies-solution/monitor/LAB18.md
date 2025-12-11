# LAB 18: QUARKUS TOLERANCE POLICIES

**Autor:** José Díaz

**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Introducción

Este ejercicio requiere que agregues resiliencia a la aplicación monitor. Esta aplicación es un microservicio que brinda información de instancias cloud, como información del sistema o utilización CPU. La aplicación monitor provee datos invocando a otros microservicios, los cuales, son simulados por simplicidad.

## Prerequisitos

- Java 21 o superior
- Maven 3.8+ instalado
- Editor de código favorito
- `curl` instalado (Linux/Mac) o PowerShell (Windows)
- `jq` instalado (opcional, para formatear JSON)

## Paso 1: Abrir el Proyecto

Abre el proyecto `15-tolerance-policies-start` con tu editor favorito.

## Paso 2: Revisar los Endpoints

Revisa los endpoints en `src/main/java/com/bcp/training/MonitorResource.java`. Estos endpoints llaman a otros servicios:

- **`/info`** - Invoca `InfoService` para obtener información del sistema, acerca de la instancia cloud.
- **`/status`** - Invoca `StatusService` para obtener el status de la instancia cloud.
- **`/cpu/stats`** - Invoca `CpuStatsService` para obtener datos de CPU de la instancia cloud.
- **`/cpu/predict`** - Invoca `CpuPredictionService` para predecir el futuro de carga CPU de la instancia cloud.

## Paso 3: Instalar la Extensión SmallRye Fault Tolerance

Instala la extensión `smallrye-fault-tolerance` e inicia la aplicación.

### Linux/Mac:

```bash
cd monitor
mvn quarkus:add-extension -Dextension=smallrye-fault-tolerance
```

### Windows (PowerShell):

```powershell
cd monitor
mvn quarkus:add-extension -Dextension=smallrye-fault-tolerance
```

**Salida esperada:**

```
[INFO] [SUCCESS] ... Extension io.quarkus:quarkus-smallrye-fault-tolerance has been installed
```

### Iniciar la Aplicación en Modo Desarrollo

### Linux/Mac:

```bash
mvn quarkus:dev
```

### Windows (PowerShell):

```powershell
mvn quarkus:dev
```

**Salida esperada:**

```
[io.quarkus] (...) started in 1.312s. Listening on: http://localhost:8080
```

## Paso 4: Usar la Política de Reintentos (Retry)

Hacer que la aplicación sea resiliente a fallas en **InfoService**.

### 4a. Probar el Endpoint sin Resiliencia

Abre una nueva terminal y haz un request al endpoint `/info`. El endpoint falla.

#### Linux/Mac:

```bash
curl localhost:8080/info; echo
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/info" -Method Get
```

**Salida esperada:**

```
{"details":"Error id ...output omitted..."}
```

### 4b. Inspeccionar InfoService

Inspecciona el archivo `src/main/java/com/bcp/training/sysinfo/InfoService.java`. Solo una de las cinco invocaciones al método `getInfo` son exitosas.

### 4c. Agregar la Anotación @Retry

Agrega la anotación `@Retry` al método `getInfo`. Establece `maxRetries` a `5`.

```java
@Retry(maxRetries = 5)
public Info getInfo() {
    ...
}
```

### 4d. Verificar que Funciona

Re-ejecuta el request y verifica que este trabaja.

#### Linux/Mac:

```bash
curl localhost:8080/info; echo
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/info" -Method Get
```

**Salida esperada:**

```json
{"NAME":"Linux","ARCH":"amd64","VERSION":"4.18.0-372.32.1.el8_6.x86_64"}
```

### 4e. Revisar los Logs

Inspecciona los logs de la aplicación y verifica que Quarkus reintentó los requests varias veces.

**Logs esperados:**

```
ERROR [com.bcp.training.sysinfo.InfoService] (...) Request #1 has failed
ERROR [com.bcp.training.sysinfo.InfoService] (...) Request #2 has failed
ERROR [com.bcp.training.sysinfo.InfoService] (...) Request #3 has failed
ERROR [com.bcp.training.sysinfo.InfoService] (...) Request #4 has failed
INFO [com.bcp.training.sysinfo.InfoService] (...) Request #5 has succeeded
```

## Paso 5: Usar la Política de Timeout

Hacer que la aplicación sea resiliente a delays en **StatusService**.

### 5a. Probar el Endpoint sin Timeout

Haz un request al endpoint `/status`. El request toma cerca de 5 segundos para completar.

#### Linux/Mac:

```bash
curl localhost:8080/status; echo
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/status" -Method Get
```

**Salida esperada:**

```
Running
```

### 5b. Revisar los Logs

Inspecciona los logs de la aplicación y verifica que los requests están tomando cerca de 5 segundos en completarse.

**Logs esperados:**

```
WARN [com.bcp.training.status.StatusService] (...) Request #1 is taking too long...
INFO [com.bcp.training.status.StatusService] (...) Request #1 completed in 5001 milliseconds
```

### 5c. Inspeccionar StatusService

Inspecciona el archivo `src/main/java/com/bcp/training/status/StatusService.java`. Observa dos aspectos:

- El método `getStatus` experimenta delays en 4 de 5 invocaciones.
- El método `getStatus` necesita reintentar invocaciones que fallan debido al timeout.

### 5d. Agregar la Anotación @Timeout

Agrega la anotación `@Timeout` al método `getStatus`. Arroja un error timeout después de 200 ms.

```java
@Timeout(200)
@Retry(maxRetries = 5, retryOn = TimeoutException.class)
public String getStatus() {
    ...
}
```

**Nota:** También necesitarás importar `TimeoutException`:

```java
import org.eclipse.microprofile.faulttolerance.exceptions.TimeoutException;
```

### 5e. Verificar que la Respuesta es Rápida

Re-ejecuta el request y verifica que la respuesta es rápida.

#### Linux/Mac:

```bash
curl http://localhost:8080/status; echo
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/status" -Method Get
```

**Salida esperada:**

```
Running
```

### 5f. Revisar los Logs de Timeout

Revisa los logs de la aplicación y verifica que Quarkus ha interrumpido las invocaciones lentas y reintenta de nuevo ellas.

**Logs esperados:**

```
WARN [com.bcp.training.status.StatusService] (...) Request #1 is taking too long...
WARN [com.bcp.training.status.StatusService] (...) Request #1 has been interrupted after 200 milliseconds
WARN [com.bcp.training.status.StatusService] (...) Request #2 is taking too long...
WARN [com.bcp.training.status.StatusService] (...) Request #2 has been interrupted after 200 milliseconds
WARN [com.bcp.training.status.StatusService] (...) Request #3 is taking too long...
WARN [com.bcp.training.status.StatusService] (...) Request #3 has been interrupted after 200 milliseconds
WARN [com.bcp.training.status.StatusService] (...) Request #4 is taking too long...
WARN [com.bcp.training.status.StatusService] (...) Request #4 has been interrupted after 200 milliseconds
INFO [com.bcp.training.status.StatusService] (...) Request #5 completed in 0 milliseconds
```

## Paso 6: Usar una Política Fallback

Hacer la aplicación resiliente cuando hay data faltante en **CpuStatsService**.

### 6a. Probar el Endpoint

Haz un request al endpoint `/cpu/stats`. La respuesta contiene uso de CPU en formato time series. La respuesta también contiene la media y desviación estándar, calculados a partir de la data time series.

#### Linux/Mac:

```bash
curl -s localhost:8080/cpu/stats | jq
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/cpu/stats" -Method Get | ConvertTo-Json -Depth 10
```

**Salida esperada:**

```json
{
    "usageTimeSeries": [
        0.987903386804749,
        0.34275471439780536,
        0.020709840667124446,
        0.35121416539390315,
        0.9863511894860464,
        0.31318722701672885,
        0.7856415790758161,
        0.42147674186562323,
        0.284121753040781
    ],
    "mean": 0.4992622886387308,
    "standardDeviation": 0.319795785721884
}
```

### 6b. Repetir hasta que Ocurra un Error

Repite el request hasta que un error ocurra.

#### Linux/Mac:

```bash
curl -s localhost:8080/cpu/stats | jq
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/cpu/stats" -Method Get | ConvertTo-Json -Depth 10
```

**Salida esperada (error):**

```json
{
  "details": "Error id ..., org.jboss.resteasy.spi.UnhandledException: java.lang.NullPointerException",
  "stack": "...output omitted..."
}
```

### 6c. Revisar los Logs

Inspecciona los logs de la aplicación. El error ocurre cuando el método `getCpuStats` llama a `calculateMean`.

**Logs esperados:**

```
WARN [com.bcp.training.cpu.CpuStatsService] (...) Cpu usage data in request #3 contains null values
ERROR [io.quarkus.verticle.http.run.QuarkusErrorHandler] (...) HTTP Request to /cpu/stats failed, error id: ...: org.jboss.resteasy.spi.UnhandledException: java.lang.NullPointerException
    ...output omitted...
    at com.bcp.training.cpu.CpuStatsService.calculateMean(CpuStatsService.java:55)
    at com.bcp.training.cpu.CpuStatsService.getCpuStats(CpuStatsService.java:21)
```

### 6d. Inspeccionar CpuStatsService

Inspecciona el archivo `src/main/java/com/bcp/training/cpu/CpuStatsService.java`. Una de las tres invocaciones del método `getCpuStats` falla porque la data contiene valores null. Los valores null resultan debido a un error cuando el servicio calcula la media y la desviación estándar.

### 6e. Agregar la Anotación @Fallback

Agrega la anotación `@Fallback` al método `getCpuStats`. Establece el método fallback `getCpuStatsWithMissingValues`.

```java
@Fallback(fallbackMethod = "getCpuStatsWithMissingValues")
public CpuStats getCpuStats() {
    ...
}
```

**Nota:** También necesitarás importar `Fallback`:

```java
import org.eclipse.microprofile.faulttolerance.Fallback;
```

### 6f. Implementar el Método Fallback

Implementa el método fallback. Establece la media y desviación estándar a 0.0.

```java
public CpuStats getCpuStatsWithMissingValues() {
    return new CpuStats(series, 0.0, 0.0);
}
```

### 6g. Verificar el Fallback

Repite el request al endpoint `/cpu/stats` hasta que recibas una respuesta con valores null. El request usa el método fallback y establece las propiedades agregadas a 0.0.

#### Linux/Mac:

```bash
curl -s localhost:8080/cpu/stats | jq
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/cpu/stats" -Method Get | ConvertTo-Json -Depth 10
```

**Salida esperada:**

```json
{
  "usageTimeSeries": [
    0.0965490271728523,
    null,
    0.22910115311828105,
    null,
    0.5527746943344609,
    null,
    0.006881053771782275,
    0.22669714994239298,
    0.3583567119779293
  ],
  "mean": 0.0,
  "standardDeviation": 0.0
}
```

## Paso 7: Usar el Patrón Circuit Breaker

Detener el tráfico que se envía a **CpuPredictionService** cuando este servicio no está disponible.

### 7a. Probar el Endpoint

Haz un request al endpoint `/cpu/predict`. La respuesta es la carga prevista de CPU.

#### Linux/Mac:

```bash
curl localhost:8080/cpu/predict; echo
```

#### Windows (PowerShell):

```powershell
Invoke-RestMethod -Uri "http://localhost:8080/cpu/predict" -Method Get
```

**Salida esperada:**

```
0.9822281195867076
```

### 7b. Ejecutar el Script de Prueba

Ejecuta el script `predict_many.sh` (Linux o macOS) o `predict_many.ps1` (Windows). Este script invoca el endpoint `/cpu/predict` cada segundo. El request comienza fallando.

#### Linux/Mac:

```bash
chmod +x predict_many.sh
./predict_many.sh
```

#### Windows (PowerShell):

```powershell
.\predict_many.ps1
```

**Salida esperada:**

```
0.4997873140920043
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
```

### 7c. Detener el Script

Presiona `Ctrl+C` para detener el script.

### 7d. Revisar CpuPredictionService

Revisa el archivo `src/main/java/com/bcp/training/cpu/CpuPredictionService.java`. El servicio puede solo manejar un request cada dos segundos. Caso contrario, el servicio arrojará un error.

### 7e. Agregar la Anotación @CircuitBreaker

Agrega la anotación `@CircuitBreaker` al método `predictSystemLoad`. Establece la propiedad `requestVolumeThreshold` a `6`, de esta manera, el mecanismo abre el circuito si 3 de los 6 requests fallan. Establece la propiedad `delay` a `3000`, así que el circuito permanece abierto por 3 segundos.

```java
@CircuitBreaker(requestVolumeThreshold = 6, delay = 3000)
public Double predictSystemLoad() {
    callCount++;
    ...
}
```

**Nota:** También necesitarás importar `CircuitBreaker`:

```java
import org.eclipse.microprofile.faulttolerance.CircuitBreaker;
```

### 7f. Ejecutar el Script Nuevamente

Ejecuta el script `predict_many.sh` o `predict_many.ps1`. Después de 6 requests, muchos de ellos fallan, el circuit breaker abre el circuito. En este punto la aplicación retorna la respuesta: "Prediction service is not available at the moment". El circuito permanecerá abierto por 3 segundos, y luego el prediction service retornará una respuesta válida nuevamente.

#### Linux/Mac:

```bash
./predict_many.sh
```

#### Windows (PowerShell):

```powershell
.\predict_many.ps1
```

**Salida esperada:**

```
0.9050798759755502
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
Prediction service is not available at the moment
Prediction service is not available at the moment
0.008288100728291115
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
{"details":"Error id 63a4f993-db90-49fe-8c24-24f33...}
Prediction service is not available at the moment
...output omitted...
```

### 7g. Detener el Script

Presiona `Ctrl+C` para detener el script.

## Paso 8: Detener la Aplicación

Retorna a la terminal donde la aplicación está corriendo en modo desarrollo y presiona `q` para detener la aplicación.

## Construcción y Ejecución con Docker/Podman

Si necesitas construir y ejecutar la aplicación usando contenedores, puedes usar los siguientes comandos:

### Construir la Aplicación

#### Linux/Mac (Docker):

```bash
mvn clean package -DskipTests
docker build -f src/main/docker/Dockerfile.jvm -t monitor:latest .
```

#### Linux/Mac (Podman):

```bash
mvn clean package -DskipTests
podman build -f src/main/docker/Dockerfile.jvm -t monitor:latest .
```

#### Windows (Docker):

```powershell
mvn clean package -DskipTests
docker build -f src/main/docker/Dockerfile.jvm -t monitor:latest .
```

#### Windows (Podman):

```powershell
mvn clean package -DskipTests
podman build -f src/main/docker/Dockerfile.jvm -t monitor:latest .
```

### Ejecutar el Contenedor

#### Linux/Mac (Docker):

```bash
docker run -i --rm -p 8080:8080 monitor:latest
```

#### Linux/Mac (Podman):

```bash
podman run -i --rm -p 8080:8080 monitor:latest
```

#### Windows (Docker):

```powershell
docker run -i --rm -p 8080:8080 monitor:latest
```

#### Windows (Podman):

```powershell
podman run -i --rm -p 8080:8080 monitor:latest
```

### Construcción Nativa (Opcional)

Para construir una imagen nativa:

#### Linux/Mac (Docker):

```bash
mvn clean package -DskipTests -Pnative -Dquarkus.native.container-build=true
docker build -f src/main/docker/Dockerfile.native -t monitor-native:latest .
```

#### Linux/Mac (Podman):

```bash
mvn clean package -DskipTests -Pnative -Dquarkus.native.container-build=true
podman build -f src/main/docker/Dockerfile.native -t monitor-native:latest .
```

#### Windows (Docker):

```powershell
mvn clean package -DskipTests -Pnative -Dquarkus.native.container-build=true
docker build -f src/main/docker/Dockerfile.native -t monitor-native:latest .
```

#### Windows (Podman):

```powershell
mvn clean package -DskipTests -Pnative -Dquarkus.native.container-build=true
podman build -f src/main/docker/Dockerfile.native -t monitor-native:latest .
```

## Resumen

En este laboratorio has implementado las siguientes políticas de tolerancia a fallos:

1. **@Retry** - Reintentos automáticos cuando un servicio falla
2. **@Timeout** - Timeout para evitar esperas prolongadas
3. **@Fallback** - Método alternativo cuando el método principal falla
4. **@CircuitBreaker** - Protección contra sobrecarga de servicios no disponibles

Estas políticas hacen que tu aplicación sea más resiliente y capaz de manejar fallos de manera elegante.

---

**¡Esto concluye el laboratorio!**

**Enjoy!**

**José**

