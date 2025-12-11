# LAB 24: QUARKUS MONITOR REVIEW

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

Abre el proyecto `21-monitor-review-start`.

## Instrucciones

La aplicación de conferencia incluye los siguientes microservicios:

- **sessions**: Lista las sesiones, incluyendo información sobre el ponente de cada sesión. Este microservicio depende del servicio de ponentes, usa registro en formato JSON y escucha en el puerto 8081.
- **speakers**: Lista los ponentes. Este microservicio escucha en el puerto 8082.
- **dashboard**: Una aplicación web para acceder a los endpoints HTTP de los microservicios sessions y speakers.

Los microservicios sessions y speakers incluyen todas las extensiones requeridas para este ejercicio.

### 1. Inicia los microservicios

- Para iniciar los microservicios sessions y speakers, usa el modo de desarrollo.
- Para iniciar el dashboard, ejecuta el script `monitoring/dashboard/serve.py`.

### 2. Abre el dashboard

Abre el dashboard en un navegador web y navega a `http://localhost:8083`. En el dashboard, haz clic en Sessions para ver la lista de sesiones. La página tarda varios segundos en mostrar la lista de sesiones. Debes solucionar este problema.

### 3. Activa el rastreo (tracing) en los microservicios sessions y speakers

- Recoge todas las muestras de rastreo, para todas las solicitudes.
- Envía todas las trazas al colector de Jaeger que está corriendo localmente en el puerto 14268.
- Propaga todos los headers b3-* para asegurar full traceabilidad.
- Se puede formatear los logs del microservicio speaker incluyendo tracing information con el siguiente formato:

```properties
quarkus.log.console.format=%d{HH:mm:ss} %-5p traceId=%X{traceId}, spanId=%X{spanId}, parentId=%X{parentId}, sampled=%X{sampled} [%c{2.}] (%t) %s%e%n
```

### 4. Inspecciona los rastreos en Jaeger UI

Recarga la página de sesiones en el frontend del dashboard para generar nuevos rastreos. Luego, inspecciona los rastreos en Jaeger UI para identificar si el problema está en el servicio sessions o speakers. La interfaz de Jaeger está disponible en `http://localhost:16686`.

### 5. Aísla el método que está causando el problema de rendimiento

Modifica el microservicio problemático agregando rastreo (tracing) a la clase que provoca la lentitud.

### 6. Corrige el código lento

Corrige el código lento e inspecciona los rastreos en Jaeger UI para confirmar que el problema ha sido resuelto.

### 7. Agrega métricas

En el microservicio sessions, agrega una métrica llamada `callsToGetSessions` para contar el número de invocaciones recibidas por el endpoint GET /sessions. Luego, abre la interfaz de Grafana, disponible en `http://localhost:3000`, para inspeccionar las métricas. Usa `admin` como nombre de usuario y contraseña para iniciar sesión en Grafana.

### 8. Cambia la configuración de logs

Cambia la configuración de logs en el microservicio sessions para entornos de desarrollo. Aplica la siguiente configuración al perfil de desarrollo:

- No uses formato JSON para los logs. En su lugar, formatea los logs con el patrón: `%d %-5p %m - traceId=%X{traceId}, spanId=%X{spanId}%n`
- El nivel de log debe ser DEBUG solo para las clases dentro del paquete `com.bcp.training`.

### 9. Detén los microservicios

Detén los microservicios sessions y speakers, así como el script serve.py del dashboard.

---

## SOLUCIÓN

### 1. Inicia los microservicios

#### a. Inicia los microservicios sessions y speakers, usa el modo desarrollo

```bash
# Terminal 1 - Sessions (puerto 8081)
cd sessions
./mvnw quarkus:dev

# Terminal 2 - Speakers (puerto 8082)
cd speakers
./mvnw quarkus:dev
```

Sessions levanta en el puerto 8081  
Speakers levanta en el puerto 8082

#### b. Inicia el dashboard ejecutando python3 serve.py

```bash
# Terminal 3 - Dashboard (puerto 8083)
cd monitoring/dashboard
python3 serve.py
```

Dashboard levanta en el puerto 8083

### 2. Abre el dashboard en el navegador

Abre el dashboard en el navegador web navegando a `http://localhost:8083`. En el dashboard clic en Sessions para ver la lista de sessions.

La página toma varios segundos en mostrar la lista de sessions. Tu debes solucionar este problema.

### 3. Activa el tracing en los microservicios sessions y speakers

#### a. Colleciona todos los trace samples, para todos los requests

#### b. Envía todas las trazas al colector de Jaeger que corre localmente en el puerto 14268

#### c. Propaga todos los headers b3-* para asegurar full traceabilidad

#### d. Formatea los logs de los microservicios speakers para incluir tracing information

Formato de logs:

```properties
quarkus.log.console.format=%d{HH:mm:ss} %-5p traceId=%X{traceId}, spanId=%X{spanId}, parentId=%X{parentId}, sampled=%X{sampled} [%c{2.}] (%t) %s%e%n
```

#### e. Agrega al `speakers/src/main/resources/application.properties` las siguientes propiedades

```properties
# Enable Tracing
quarkus.otel.service.name = speakers
quarkus.otel.traces.sampler=traceidratio
quarkus.otel.traces.sampler.arg=1

quarkus.log.console.format=%d{HH:mm:ss} %-5p traceId=%X{traceId}, spanId=%X{spanId}, parentId=%X{parentId}, sampled=%X{sampled} [%c{2.}] (%t) %s%e%n

quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
```

#### f. Agrega a `sessions/src/main/resources/application.properties` las siguientes propiedades

```properties
quarkus.otel.service.name = sessions
quarkus.otel.traces.sampler=traceidratio
quarkus.otel.traces.sampler.arg=1
quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
```

### 4. Inspecciona las trazas en Jaeger UI

Recarga la página de sessions en el dashboard para generar nuevas trazas. Luego, inspecciona las trazas en la consola web de Jaeger para identificar si el problema es el servicio sessions o speakers. La Jaeger UI está en `http://localhost:16686`.

- Retorna al dashboard y recargar la página Sessions para generar trazas.
- Ve a `http://localhost:16686` y abre la Jaeger UI
- En la consola web de Jaeger, selecciona el servicio `sessions` del campo Service en el panel Search. Clic en Find Traces.
- Clic las primeras sessions: `GET:com.bcp.training.SessionResource.getAllSessions` para ver los detalles de traza.
- En la traza, verificar que el `GET:com.bcp.training.SpeakerResource.listAll` span está tomando varios segundos en atender el request.

### 5. Aislar el método que está causando problemas de rendimiento

Modifica el servicio problemático agregando tracing a la clase que causa la lentitud.

#### a. Agregar la anotación @WithSpan

El `SpeakerResource#listAll` maneja todos los requests del GET /speaker endpoint del servicio speaker. Este método usa el `com.bcp.training.SpeakerFinder` bean, el cual obtiene los speakers de una base de datos. Agregar la anotación `@WithSpan` a esta clase.

```java
@WithSpan
public List<Speaker> all() {
    Log.info("Retrieving all speakers from database");
    // ...
}
```

#### b. Genera nuevas trazas

- Retorna al dashboard en el navegador y carga la página de Sessions para generar nuevas trazas.
- Retorna a la consola Jaeger y clic en Search en la barra top de navegación.
- En el panel Search, clic Find Traces para refrescar la lista de trazas.
- Clic en el más reciente trace de la lista.
- Verificar que el `SpeakerFinder#all` está causando cuellos de botella. Este método toma varios segundos en cargar la lista de speakers.

### 6. Repara el código lento

Repara el código lento e inspecciona las trazas en el Jaeger UI para confirmar que el problema ha sido solucionado.

- En el método `SpeakerFinder#all`, elimina o comenta el código que causa el problema.

```java
@WithSpan
public List<Speaker> all() {
    Log.info("Retrieving all speakers from database");
    
    //runSlowAndRedundantOperation();
    
    return Speaker.listAll();
}
```

- Retorna al dashboard frontend en el navegador y carga la página Sessions para generar nuevas trazas.
- Retorna a la consola Jaeger y clic en Search en la barra top de navegación.
- En el panel Search, clic en Find Traces para refrescar la lista de trazas.
- Clic en el más reciente trace de la lista.
- Verifica que el método `SpeakerFinder#all` toma unos cuantos milisegundos para completar el request.

### 7. Agrega métricas al microservicio sessions

En el microservicio sessions, agrega una métrica llamada `callsToGetSessions` para contar el número de invocaciones recibidas por el endpoint GET /sessions. Luego, abre el Grafana UI que está disponible en `http://localhost:3000`, para revisar las métricas. Usa `admin` como username y password para log in a Grafana.

- Abre el `com.bcp.training.SessionResource` y agrega el `@Counted` al método `getAllSessions`.

```java
@GET
@Counted(value = "callsToGetSessions")
public Collection<Session> getAllSessions() throws Exception {
    return sessionStore.findAll();
}
```

- Retorna al dashboard en el navegador y carga la página Sessions para generar valores para la nueva métrica.
- Abre el navegador y ve a `http://localhost:3000/dashboards`.
- Ingresa `admin` como el username y `admin` como el password, luego clic en Log in.
- Clic Skip para omitir el cambio de password de la cuenta.
- Clic en el directorio conference, y luego clic en DO378 Conference Metrics Dashboard.
- Observa el dashboard que colecciona las métricas agregadas a la aplicación.

### 8. Cambiar la configuración de logging en el microservicio sessions

Cambia la configuración de logging en el microservicio sessions para entornos de desarrollo. Aplica la siguiente configuración al profile desarrollo.

- No uses formatting JSON. En su lugar formatea los logs y habilita DEBUG solo para el paquete `com.bcp.training`.

Agrega a `sessions/src/main/resources/application.properties`:

```properties
# Configure Dev Logging
%dev.quarkus.log.console.json=false
%dev.quarkus.log.console.format = %d %-5p %m - traceId=%X{traceId}, spanId=%X{spanId}%n
%dev.quarkus.log.category."com.bcp.training".level = DEBUG
```

- Retorna al dashboard en el navegador y recarga la página Sessions.
- Revisa los logs del microservicio sessions. La consola debe mostrar mensajes de debug y los logs usan el formato personalizado.

### 9. Detén los microservicios

Detén los microservicios sessions y speakers, y luego el script serve.py.

Para detener los servicios:

```bash
# En las terminales donde están corriendo los servicios, presiona Ctrl+C
# O si están corriendo en background, usa:
pkill -f "quarkus:dev"
pkill -f "serve.py"
```

---

## Comandos de Podman (si necesitas iniciar servicios de monitoreo)

Si necesitas iniciar los servicios de monitoreo (Jaeger, Prometheus, Grafana) usando Podman:

### Opción 1: Usar el script proporcionado (recomendado)

```bash
# Desde la raíz del proyecto
./start-monitoring.sh
```

Este script usa `podman compose` para iniciar todos los servicios de monitoreo.

Para detener los servicios:

```bash
podman compose down
```

### Opción 2: Iniciar servicios individualmente con Podman

```bash
# Iniciar Jaeger
podman run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 14268:14268 \
  -p 4317:4317 \
  -p 4318:4318 \
  quay.io/jaegertracing/all-in-one:latest

# Iniciar Prometheus
podman run -d --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:Z \
  quay.io/prometheus/prometheus:latest

# Iniciar Grafana
podman run -d --name grafana \
  -p 3000:3000 \
  -v $(pwd)/monitoring/grafana/provisioning:/etc/grafana/provisioning:Z \
  -v $(pwd)/monitoring/grafana/dashboards:/var/lib/grafana/dashboards:Z \
  quay.io/grafana/grafana:latest
```

Para detener los contenedores:

```bash
podman stop jaeger prometheus grafana
podman rm jaeger prometheus grafana
```

---

¡Felicitaciones! Hemos terminado el laboratorio.

**José**
