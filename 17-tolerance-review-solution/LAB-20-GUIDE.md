# LAB 20: QUARKUS TOLERANCE REVIEW

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Descripción del Proyecto

Este laboratorio utiliza dos servicios:

### session
Un servicio que mantiene una lista de sesiones de speaking. Este contiene un cache local de speakers en cada sesión. Adicionalmente, este enriquece la información de cada speaker utilizando el servicio speaker.

Los speakers contienen información como first name y surname. Los speakers cacheados solo contienen el first name.

### speaker
Un servicio que mantiene un registro completo de speakers. Puedes usar este servicio para opcionalmente probar el servicio session.

## Objetivo

Para completar este laboratorio hay que asegurarnos que el servicio session pase las pruebas.

## Requisitos Previos

- Java 21 o superior
- Maven 3.8+ instalado o usar el wrapper incluido (`mvnw` o `mvnw.cmd`)
- Acceso al proyecto `17-tolerance-review-start`

## Comandos Multiplataforma

### Windows (PowerShell/CMD)
```powershell
# Usar Maven wrapper
.\mvnw.cmd <comando>

# Ejemplo: ejecutar tests
.\mvnw.cmd clean test
```

### Linux/Mac (Bash/Zsh)
```bash
# Usar Maven wrapper
./mvnw <comando>

# Ejemplo: ejecutar tests
./mvnw clean test
```

### Docker vs Podman

**Docker:**
```bash
docker build -f src/main/docker/Dockerfile.jvm -t session:latest .
docker run -i --rm -p 8080:8080 session:latest
```

**Podman:**
```bash
podman build -f src/main/docker/Dockerfile.jvm -t session:latest .
podman run -i --rm -p 8080:8080 session:latest
```

---

## Tarea 1: Agregar Liveness y Readiness Probes

### Objetivo
Agregar los liveness y readiness probes al microservicio session.

Retorna las siguientes respuestas:
- **Liveness probe:** Service is alive
- **Readiness probe:** Service is ready

### Pasos

#### 1.1 Implementar LivenessCheck

Abre el archivo `src/main/java/com/bcp/training/conference/session/LivenessCheck.java` e implementa la interface `HealthCheck`. Agrega la anotación `@Liveness`.

**Código a implementar:**

```java
package com.bcp.training.conference.session;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import jakarta.enterprise.context.ApplicationScoped;

@Liveness
@ApplicationScoped
public class LivenessCheck implements HealthCheck {
    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.up("Service is alive");
    }
}
```

#### 1.2 Implementar ReadinessCheck

Abre el archivo `src/main/java/com/bcp/training/conference/session/ReadinessCheck.java` e implementa la interface `HealthCheck`. Agrega la anotación `@Readiness`.

**Código a implementar:**

```java
package com.bcp.training.conference.session;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;

import jakarta.enterprise.context.ApplicationScoped;

@Readiness
@ApplicationScoped
public class ReadinessCheck implements HealthCheck {
    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.up("Service is ready");
    }
}
```

#### 1.3 Verificar las Pruebas

**Windows:**
```powershell
.\mvnw.cmd clean test -Dtest=SessionResourceTest#testLivenessProbe,SessionResourceTest#testReadinessProbe
```

**Linux/Mac:**
```bash
./mvnw clean test -Dtest=SessionResourceTest#testLivenessProbe,SessionResourceTest#testReadinessProbe
```

**Resultado esperado:**
```
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
```

---

## Tarea 2: Implementar Fallback para GET /sessions

### Objetivo
El endpoint `GET /sessions` del servicio session llama al servicio speaker para enriquecer la data del speaker.

Implementar el método `SessionResource#allSessionsFallback` para usar el método `SessionStore#findAllWithoutEnrichment` para retornar las sessions sin enviar requests al servicio speaker.

Luego configurar el endpoint para responder sin enviar requests al servicio speaker cuando el servicio speaker no esté disponible.

### Pasos

#### 2.1 Implementar allSessionsFallback

Abre el archivo `src/main/java/com/bcp/training/conference/session/SessionResource.java`.

Implementa el método `allSessionsFallback`:

```java
public Collection<Session> allSessionsFallback() throws Exception {
    logger.warn("Fallback for GET /sessions");
    return sessionStore.findAllWithoutEnrichment();
}
```

#### 2.2 Configurar Fallback en allSessions

Usa la anotación `@Fallback` para configurar que el método `allSessions` use el método `allSessionsFallback` durante las fallas.

**Código actualizado:**

```java
@GET
@Fallback(fallbackMethod="allSessionsFallback")
public Collection<Session> allSessions() throws Exception {
    return sessionStore.findAll();
}
```

#### 2.3 Verificar la Prueba

**Windows:**
```powershell
.\mvnw.cmd clean test -Dtest=SessionResourceTest#testAllSessionsFallback
```

**Linux/Mac:**
```bash
./mvnw clean test -Dtest=SessionResourceTest#testAllSessionsFallback
```

**Resultado esperado:**
```
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

---

## Tarea 3: Implementar Política de Reintento

### Objetivo
El endpoint `PUT /sessions/{sessionId}/speakers/{speakerName}` debe completarse.

Implementar una política de reintento para solicitar una vez por segundo por 60 segundos en caso de una excepción `InternalServerErrorException`.

### Pasos

#### 3.1 Agregar Anotación @Retry

Agrega la anotación `@Retry` al método endpoint. Usa `maxRetries` y `delay` para configurar un reintento por segundo por 60 segundos.

**Código actualizado:**

```java
@PUT
@Path("/{sessionId}/speakers/{speakerName}")
@Transactional
@Retry(maxRetries=60, delay=1_000, retryOn=InternalServerErrorException.class)
public Response addSessionSpeaker(@PathParam("sessionId") final String sessionId,
                                  @PathParam("speakerName") final String speakerName) {
    final Optional<Session> result = sessionStore.findByIdWithoutEnrichmentMaybeFail(sessionId);
    if (result.isPresent()) {
        final Session session = result.get();
        sessionStore.addSpeakerToSession(speakerName, session);
        return Response.ok(session).build();
    }
    throw new NotFoundException();
}
```

#### 3.2 Verificar la Prueba

**Windows:**
```powershell
.\mvnw.cmd clean test -Dtest=SessionResourceTest#testAddSpeakerToSession
```

**Linux/Mac:**
```bash
./mvnw clean test -Dtest=SessionResourceTest#testAddSpeakerToSession
```

**Resultado esperado:**
```
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

---

## Tarea 4: Implementar Circuit Breaker para GET /session/{sessionId}

### Objetivo
El endpoint `GET /session/{sessionId}` del servicio session usa el servicio speaker para enriquecer la data de los speakers.

Implementar el método `SessionResource#retrieveSessionFallback` para usar el `SessionStore#findByIdWithoutEnrichment` para retornar un objeto `Response` que contenga la session sin enviar requests al servicio speakers.

Luego configurar el endpoint para responder sin enviar requests al servicio speaker cuando el servicio speaker no esté disponible.

Adicionalmente, cuando dos requests consecutivos al método `retrieveSession` fallen, retornar respuestas fallback en los siguientes 30 segundos.

### Pasos

#### 4.1 Implementar retrieveSessionFallback

Implementa el método `retrieveSessionFallback`:

```java
public Response retrieveSessionFallback(final String sessionId) {
    logger.warn("Fallback for GET /sessions/"+sessionId);
    return sessionStore.findByIdWithoutEnrichment(sessionId)
        .map(s -> Response.ok(s).build())
        .orElseThrow(NotFoundException::new);
}
```

#### 4.2 Configurar Fallback y Circuit Breaker

Usa la anotación `@Fallback` para configurar el método `retrieveSession` y usar el método `retrieveSessionFallback` durante las fallas.

Adicionalmente, usa la anotación `@CircuitBreaker` para usar el método fallback después de 2 fallas.

**Código actualizado:**

```java
@GET
@Path("/{sessionId}")
@Fallback(fallbackMethod="retrieveSessionFallback")
@CircuitBreaker(requestVolumeThreshold = 2, failureRatio = 1, delay = 30_000)
public Response retrieveSession(@PathParam("sessionId") final String sessionId) {
    final Optional<Session> result = sessionStore.findById(sessionId);
    return result.map(s -> Response.ok(s).build()).orElseThrow(NotFoundException::new);
}
```

#### 4.3 Verificar la Prueba

**Windows:**
```powershell
.\mvnw.cmd clean test -Dtest=SessionResourceTest#testSessionCircuitBreaker
```

**Linux/Mac:**
```bash
./mvnw clean test -Dtest=SessionResourceTest#testSessionCircuitBreaker
```

**Resultado esperado:**
```
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

---

## Tarea 5: Implementar Timeout para GET /sessions/{sessionId}/speakers

### Objetivo
El endpoint `GET /sessions/{sessionId}/speakers` debe responder en no más de un segundo. El endpoint usa el método `findSessionSpeakers` que llama al servicio speaker.

Configurar el método para arrojar una excepción si el servicio speaker toma más de un segundo en responder.

### Pasos

#### 5.1 Agregar Anotación @Timeout

Usa la anotación `@Timeout` en el método `findSessionSpeakers`. Usa un valor de parámetro de 1000 ms.

**Código actualizado:**

```java
@Timeout(1000)
public Optional<Session> findSessionSpeakers(String sessionId) {
    return sessionStore.findById(sessionId);
}
```

#### 5.2 Verificar la Prueba

**Windows:**
```powershell
.\mvnw.cmd clean test -Dtest=SessionResourceTest#testSessionSpeakerFallback
```

**Linux/Mac:**
```bash
./mvnw clean test -Dtest=SessionResourceTest#testSessionSpeakerFallback
```

**Resultado esperado:**
```
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

---

## Verificación Final

Para ejecutar todas las pruebas del proyecto:

**Windows:**
```powershell
.\mvnw.cmd clean test
```

**Linux/Mac:**
```bash
./mvnw clean test
```

**Resultado esperado:**
```
[INFO] Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
```

---

## Ejecutar la Aplicación

### Modo Desarrollo

**Windows:**
```powershell
.\mvnw.cmd quarkus:dev
```

**Linux/Mac:**
```bash
./mvnw quarkus:dev
```

La aplicación estará disponible en: `http://localhost:8080`

### Health Checks

Una vez que la aplicación esté corriendo, puedes verificar los health checks:

- **Liveness:** http://localhost:8080/q/health/live
- **Readiness:** http://localhost:8080/q/health/ready

### Endpoints Disponibles

- `GET /sessions` - Lista todas las sesiones
- `GET /sessions/{sessionId}` - Obtiene una sesión específica
- `GET /sessions/{sessionId}/speakers` - Obtiene los speakers de una sesión
- `POST /sessions` - Crea una nueva sesión
- `PUT /sessions/{sessionId}` - Actualiza una sesión
- `PUT /sessions/{sessionId}/speakers/{speakerName}` - Agrega un speaker a una sesión
- `DELETE /sessions/{sessionId}` - Elimina una sesión
- `DELETE /sessions/{sessionId}/speakers/{speakerName}` - Elimina un speaker de una sesión

---

## Construir y Ejecutar con Docker/Podman

### Construir la Imagen

**Docker:**
```bash
docker build -f src/main/docker/Dockerfile.jvm -t session:latest .
```

**Podman:**
```bash
podman build -f src/main/docker/Dockerfile.jvm -t session:latest .
```

### Ejecutar el Contenedor

**Docker:**
```bash
docker run -i --rm -p 8080:8080 session:latest
```

**Podman:**
```bash
podman run -i --rm -p 8080:8080 session:latest
```

### Ejecutar con Docker Compose (si está disponible)

Si tienes un archivo `docker-compose.yml`:

**Docker:**
```bash
docker-compose up
```

**Podman Compose:**
```bash
podman-compose up
```

---

## Resumen de Anotaciones Utilizadas

### @Liveness
Indica que el health check es un liveness probe. Se usa para determinar si la aplicación está viva.

### @Readiness
Indica que el health check es un readiness probe. Se usa para determinar si la aplicación está lista para recibir tráfico.

### @Fallback
Especifica un método fallback que se ejecutará cuando el método principal falle.

**Parámetros:**
- `fallbackMethod`: Nombre del método fallback

### @Retry
Configura una política de reintento para un método.

**Parámetros:**
- `maxRetries`: Número máximo de reintentos (default: 3)
- `delay`: Tiempo de espera entre reintentos en milisegundos (default: 200)
- `retryOn`: Array de excepciones que activan el reintento

### @CircuitBreaker
Implementa un circuit breaker pattern para prevenir fallas en cascada.

**Parámetros:**
- `requestVolumeThreshold`: Número de requests antes de evaluar el estado del circuit breaker (default: 20)
- `failureRatio`: Ratio de fallas que abre el circuit breaker (default: 0.5)
- `delay`: Tiempo en milisegundos antes de intentar cerrar el circuit breaker (default: 5000)

### @Timeout
Especifica un timeout máximo para la ejecución de un método.

**Parámetros:**
- `value`: Tiempo máximo en milisegundos

---

## Solución de Problemas

### Las pruebas fallan

1. Verifica que todas las dependencias estén instaladas:
   ```bash
   ./mvnw dependency:resolve
   ```

2. Limpia y recompila el proyecto:
   ```bash
   ./mvnw clean compile
   ```

3. Verifica que el servicio speaker esté disponible (si es necesario)

### Error de compilación

Asegúrate de tener Java 21 instalado:
```bash
java -version
```

### Problemas con Docker/Podman

1. Verifica que Docker/Podman esté corriendo:
   ```bash
   docker ps
   # o
   podman ps
   ```

2. Verifica que tengas permisos para ejecutar Docker/Podman

---

## Referencias

- [Quarkus SmallRye Health Guide](https://quarkus.io/guides/smallrye-health)
- [Quarkus SmallRye Fault Tolerance Guide](https://quarkus.io/guides/smallrye-fault-tolerance)
- [Eclipse MicroProfile Fault Tolerance Specification](https://download.eclipse.org/microprofile/microprofile-fault-tolerance-4.0/microprofile-fault-tolerance-spec-4.0.html)

---

¡Disfruta del laboratorio!

José Díaz

