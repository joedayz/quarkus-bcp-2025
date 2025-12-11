# LAB 22: QUARKUS MONITOR METRICS

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

Este laboratorio te guiará paso a paso para agregar métricas de monitoreo a una aplicación Quarkus usando Micrometer con Prometheus, y visualizar estas métricas en Grafana.

## Prerrequisitos

- Java 21 o superior
- Maven instalado
- Docker o Podman instalado
- Editor de código (VS Code, IntelliJ IDEA, etc.)

## Estructura del Proyecto

Abre el proyecto `19-monitor-metrics-start` en tu editor favorito.

### Revisión de la Aplicación

1. **La clase `com.bcp.training.Expense`** implementa una representación básica de un expense (gasto).
2. **La clase `com.bcp.training.ExpenseResource`** implementa una API CRUD que usa `com.bcp.training.ExpenseService` para persistir los datos.
3. **La clase `com.bcp.training.ExpenseService`** es responsable de persistir y administrar instancias de `Expense`.

---

## Paso 1: Incluir la Extensión Quarkus para Micrometer con Prometheus

### Linux/Mac

```bash
cd expense-service
./mvnw quarkus:add-extension -Dextensions=micrometer-registry-prometheus
```

### Windows (PowerShell)

```powershell
cd expense-service
.\mvnw.cmd quarkus:add-extension -Dextensions=micrometer-registry-prometheus
```

### Windows (CMD)

```cmd
cd expense-service
mvnw.cmd quarkus:add-extension -Dextensions=micrometer-registry-prometheus
```

**Salida esperada:**
```
[INFO] [SUCCESS] ... Extension io.quarkus:quarkus-micrometer-registry-prometheus has been installed
```

### Iniciar la Aplicación

#### Linux/Mac

```bash
./mvnw quarkus:dev
```

#### Windows (PowerShell)

```powershell
.\mvnw.cmd quarkus:dev
```

#### Windows (CMD)

```cmd
mvnw.cmd quarkus:dev
```

**Salida esperada:**
```
... INFO [io.quarkus] ... Listening on: http://localhost:8080
```

---

## Paso 2: Agregar Métricas para Contar Invocaciones de Endpoints GET y POST

### 2.1. Inyectar MeterRegistry en ExpenseResource

Abre la clase `ExpenseResource` y agrega la inyección de `MeterRegistry`:

```java
@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {
    
    @Inject
    public ExpenseService expenseService;
    
    @Inject
    public MeterRegistry registry;
    
    // ... resto del código
}
```

### 2.2. Actualizar el Endpoint GET con @Counted

Actualiza el método `list()` para usar la anotación `@Counted`:

```java
@GET
@Counted(value = "callsToGetExpenses")
public Set<Expense> list() {
    return expenseService.list();
}
```

**Nota:** Asegúrate de importar:
```java
import io.micrometer.core.annotation.Counted;
```

### 2.3. Actualizar el Endpoint POST con MeterRegistry

Actualiza el método `create()` para usar `MeterRegistry` directamente:

```java
@POST
public Expense create(Expense expense) {
    registry.counter("callsToPostExpenses").increment();
    return expenseService.create(expense);
}
```

### 2.4. Generar Tráfico de Prueba

Abre una nueva terminal y ejecuta el script de simulación de tráfico:

#### Linux/Mac

```bash
cd expense-service
./scripts/simulate-traffic.sh
```

#### Windows (PowerShell)

```powershell
cd expense-service
.\scripts\simulate-traffice.ps1
```

**Salida esperada:**
```
GET Response Code: 200
GET Response Code: 200
GET Response Code: 200
POST Response Code: 200
```

### 2.5. Verificar las Métricas

#### Linux/Mac

```bash
curl http://localhost:8080/q/metrics | grep Expenses_total
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/q/metrics | Select-Object -ExpandProperty Content | Select-String "Expenses_total"
```

#### Windows (CMD)

```cmd
curl http://localhost:8080/q/metrics | findstr Expenses_total
```

**Salida esperada:**
```
# HELP callsToGetExpenses_total
# TYPE callsToGetExpenses_total counter
callsToGetExpenses_total[class=...] 3.0
# HELP callsToPostExpenses_total
# TYPE callsToPostExpenses_total counter
callsToPostExpenses_total 1.0
```

---

## Paso 3: Agregar Métrica de Tiempo para el Endpoint POST

### 3.1. Actualizar el Endpoint POST con Timer

Actualiza el método `create()` para medir el tiempo de ejecución:

```java
@POST
public Expense create(Expense expense) {
    registry.counter("callsToPostExpenses").increment();
    return registry.timer("expenseCreationTime")
        .wrap((Supplier<Expense>) () -> expenseService.create(expense))
        .get();
}
```

**Nota:** Asegúrate de importar:
```java
import java.util.function.Supplier;
```

### 3.2. Generar Tráfico de Prueba Nuevamente

#### Linux/Mac

```bash
./scripts/simulate-traffic.sh
```

#### Windows (PowerShell)

```powershell
.\scripts\simulate-traffice.ps1
```

### 3.3. Verificar las Métricas del Timer

#### Linux/Mac

```bash
curl http://localhost:8080/q/metrics | grep expenseCreationTime
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/q/metrics | Select-Object -ExpandProperty Content | Select-String "expenseCreationTime"
```

#### Windows (CMD)

```cmd
curl http://localhost:8080/q/metrics | findstr expenseCreationTime
```

**Salida esperada:**
```
# HELP expenseCreationTime_seconds
# TYPE expenseCreationTime_seconds summary
expenseCreationTime_seconds_count 1.0
expenseCreationTime_seconds_sum 4.00032617
# HELP expenseCreationTime_seconds_max
# TYPE expenseCreationTime_seconds_max gauge
expenseCreationTime_seconds_max 4.00032617
```

**Nota:** La aplicación introduce algunos delays aleatorios en el procesamiento del request, por lo que los valores de salida pueden ser distintos.

---

## Paso 4: Agregar Métrica Gauge para Tiempo desde Última Llamada GET

### 4.1. Crear Atributo StopWatch

Abre la clase `ExpenseResource` y crea un atributo `StopWatch`:

```java
@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {
    
    private final StopWatch stopWatch = StopWatch.createStarted();
    
    @Inject
    public ExpenseService expenseService;
    
    @Inject
    public MeterRegistry registry;
    
    // ... resto del código
}
```

**Nota:** Asegúrate de importar:
```java
import org.apache.commons.lang3.time.StopWatch;
```

### 4.2. Inicializar la Métrica Gauge en initMeters

Actualiza el método `initMeters()` para inicializar la métrica gauge:

```java
@PostConstruct
public void initMeters() {
    registry.gauge(
        "timeSinceLastGetExpenses",
        Tags.of("description", "Time since the last call to GET /expenses"),
        stopWatch,
        StopWatch::getTime
    );
}
```

**Nota:** Asegúrate de importar:
```java
import io.micrometer.core.instrument.Tags;
import jakarta.annotation.PostConstruct;
```

### 4.3. Actualizar el Endpoint GET para Resetear el Timer

Actualiza el método `list()` para resetear e iniciar el tiempo de seguimiento:

```java
@GET
@Counted(value = "callsToGetExpenses")
public Set<Expense> list() {
    stopWatch.reset();
    stopWatch.start();
    return expenseService.list();
}
```

### 4.4. Generar Tráfico de Prueba

#### Linux/Mac

```bash
./scripts/simulate-traffic.sh
```

#### Windows (PowerShell)

```powershell
.\scripts\simulate-traffice.ps1
```

### 4.5. Verificar las Métricas Gauge

#### Linux/Mac

```bash
curl http://localhost:8080/q/metrics | grep timeSinceLastGetExpenses
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/q/metrics | Select-Object -ExpandProperty Content | Select-String "timeSinceLastGetExpenses"
```

#### Windows (CMD)

```cmd
curl http://localhost:8080/q/metrics | findstr timeSinceLastGetExpenses
```

**Salida esperada:**
```
# HELP timeSinceLastGetExpenses
# TYPE timeSinceLastGetExpenses gauge
timeSinceLastGetExpenses[description="Time ... GET /expenses",] 9995.0
```

**Nota:** El valor del gauge está en milisegundos, y como la aplicación usa delays aleatorios, la salida puede ser diferente.

---

## Paso 5: Visualizar las Métricas en Grafana

### 5.1. Iniciar Prometheus y Grafana

#### Usando Docker

**Linux/Mac:**
```bash
cd expense-service
docker-compose up -d
```

**Windows (PowerShell):**
```powershell
cd expense-service
docker-compose up -d
```

**Windows (CMD):**
```cmd
cd expense-service
docker-compose up -d
```

#### Usando Podman

**Linux/Mac:**
```bash
cd expense-service
podman-compose up -d
```

**Windows (PowerShell):**
```powershell
cd expense-service
podman-compose up -d
```

**Nota:** Si no tienes `podman-compose`, puedes usar `podman play kube` o crear los contenedores manualmente:

```bash
# Crear red
podman network create monitoring

# Prometheus
podman run -d --name prometheus \
  --network monitoring \
  -p 9090:9090 \
  -v $(pwd)/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus:latest

# Grafana
podman run -d --name grafana \
  --network monitoring \
  -p 3000:3000 \
  -v $(pwd)/grafana/provisioning:/etc/grafana/provisioning:ro \
  -v $(pwd)/grafana/dashboards:/var/lib/grafana/dashboards:ro \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:latest
```

### 5.2. Verificar que los Servicios Están Corriendo

#### Docker

**Linux/Mac:**
```bash
docker-compose ps
```

**Windows (PowerShell):**
```powershell
docker-compose ps
```

**Windows (CMD):**
```cmd
docker-compose ps
```

#### Podman

**Linux/Mac:**
```bash
podman ps
```

**Windows (PowerShell):**
```powershell
podman ps
```

### 5.3. Acceder a Grafana

1. Abre tu navegador web y navega a: **http://localhost:3000**
2. Usa las credenciales:
   - **Username:** `admin`
   - **Password:** `admin`
3. Haz clic en **Log in**
4. Haz clic en **Skip** para omitir cambiar el password de la cuenta
5. Navega a **Dashboards** → **Expenses** → **DO378 Expenses Dashboard**

### 5.4. Observar el Dashboard

El dashboard colecciona todas las métricas agregadas a la aplicación:
- `callsToGetExpenses_total`: Contador de llamadas GET
- `callsToPostExpenses_total`: Contador de llamadas POST
- `expenseCreationTime_seconds`: Tiempo de creación de expenses
- `timeSinceLastGetExpenses`: Tiempo desde la última llamada GET

### 5.5. Detener la Aplicación Quarkus

Retorna a la terminal que ejecuta la aplicación Quarkus y presiona `q` para detener la aplicación.

---

## Paso 6: Detener los Servicios de Monitoreo

### Docker

**Detener sin eliminar datos:**
```bash
# Linux/Mac
docker-compose stop

# Windows (PowerShell/CMD)
docker-compose stop
```

**Detener y eliminar contenedores:**
```bash
# Linux/Mac
docker-compose down

# Windows (PowerShell/CMD)
docker-compose down
```

**Detener, eliminar contenedores y volúmenes (elimina todos los datos):**
```bash
# Linux/Mac
docker-compose down -v

# Windows (PowerShell/CMD)
docker-compose down -v
```

### Podman

**Detener sin eliminar datos:**
```bash
# Linux/Mac
podman-compose stop

# Windows (PowerShell)
podman-compose stop
```

**Detener y eliminar contenedores:**
```bash
# Linux/Mac
podman-compose down

# Windows (PowerShell)
podman-compose down
```

**Detener contenedores manualmente:**
```bash
# Linux/Mac
podman stop prometheus grafana
podman rm prometheus grafana
podman network rm monitoring

# Windows (PowerShell)
podman stop prometheus grafana
podman rm prometheus grafana
podman network rm monitoring
```

---

## Resumen de Métricas Implementadas

### Counters
- **`callsToGetExpenses_total`**: Total de llamadas GET a `/expenses`
- **`callsToPostExpenses_total`**: Total de llamadas POST a `/expenses`

### Timer
- **`expenseCreationTime_seconds`**: Tiempo de creación de expenses
  - `expenseCreationTime_seconds_count`: Contador total
  - `expenseCreationTime_seconds_sum`: Suma total de tiempos
  - `expenseCreationTime_seconds_max`: Tiempo máximo

### Gauge
- **`timeSinceLastGetExpenses`**: Tiempo en milisegundos desde la última llamada GET

---

## Solución de Problemas

### Prometheus no puede conectarse a la aplicación

1. **Verifica que la aplicación esté corriendo:**
   ```bash
   # Linux/Mac
   curl http://localhost:8080/q/metrics
   
   # Windows (PowerShell)
   Invoke-WebRequest -Uri http://localhost:8080/q/metrics
   ```

2. **Ajusta el target en `prometheus/prometheus.yml`:**
   - En macOS/Windows con Docker Desktop: usa `host.docker.internal:8080` (ya configurado)
   - En Linux: usa `172.17.0.1:8080` o la IP de tu host
   - Si la app corre en Docker/Podman: usa el nombre del servicio

3. **Reinicia Prometheus:**
   ```bash
   # Docker
   docker-compose restart prometheus
   
   # Podman
   podman restart prometheus
   ```

### Grafana no muestra datos

1. Verifica que Prometheus tenga datos:
   - Abre http://localhost:9090
   - Ejecuta una query como `callsToPostExpenses_total`

2. Verifica el datasource en Grafana:
   - Ve a Configuration → Data Sources
   - Verifica que "Prometheus" esté configurado y funcione (botón "Test")

3. Verifica el dashboard:
   - Ve a Dashboards → Expense Service Metrics Dashboard
   - Revisa que las queries de Prometheus sean correctas

### Las métricas no aparecen

1. Verifica que las métricas estén habilitadas en `application.properties`
2. Verifica que la aplicación esté usando la dependencia `quarkus-micrometer-registry-prometheus`
3. Reinicia la aplicación Quarkus

---

## Código Final de ExpenseResource

Aquí está el código completo de `ExpenseResource` con todas las métricas implementadas:

```java
package com.bcp.training;

import io.micrometer.core.annotation.Counted;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import org.apache.commons.lang3.time.StopWatch;

import jakarta.annotation.PostConstruct;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Set;
import java.util.UUID;
import java.util.function.Supplier;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {
    
    private final StopWatch stopWatch = StopWatch.createStarted();
    
    @Inject
    public ExpenseService expenseService;
    
    @Inject
    public MeterRegistry registry;
    
    @PostConstruct
    public void initMeters() {
        registry.gauge(
            "timeSinceLastGetExpenses",
            Tags.of("description", "Time since the last call to GET /expenses"),
            stopWatch,
            StopWatch::getTime
        );
    }
    
    @POST
    public Expense create(Expense expense) {
        registry.counter("callsToPostExpenses").increment();
        return registry.timer("expenseCreationTime")
            .wrap((Supplier<Expense>) () -> expenseService.create(expense))
            .get();
    }
    
    @GET
    @Counted(value = "callsToGetExpenses")
    public Set<Expense> list() {
        stopWatch.reset();
        stopWatch.start();
        return expenseService.list();
    }
    
    @DELETE
    @Path("{uuid}")
    public Set<Expense> delete(@PathParam("uuid") UUID uuid) {
        if (!expenseService.delete(uuid)) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
        return expenseService.list();
    }
    
    @PUT
    public void update(Expense expense) {
        expenseService.update(expense);
    }
}
```

---

## Conclusión

¡Felicitaciones! Has completado el laboratorio de monitoreo de métricas en Quarkus. Has aprendido a:

1. ✅ Agregar la extensión Micrometer con Prometheus a Quarkus
2. ✅ Implementar contadores (counters) para rastrear invocaciones de endpoints
3. ✅ Implementar timers para medir tiempos de ejecución
4. ✅ Implementar gauges para monitorear valores que cambian con el tiempo
5. ✅ Visualizar métricas en Grafana

**¡Disfruta!**  
**José**

