# Proyecto Final - Desarrollo de Microservicios Cloud-native con Quarkus

Actualizar una aplicación basada en microservicios existente, crear un nuevo microservicio y agregar capacidades de tolerancia a fallos, seguridad, reactividad y trazabilidad.

## Objetivos

- Crear un nuevo microservicio Quarkus con capacidades REST y ORM.
- Verificar el microservicio mediante pruebas automatizadas y Quarkus Dev Services.
- Proporcionar especificaciones OpenAPI y una interfaz Swagger UI para la API REST del microservicio.
- Integrar dos microservicios usando el protocolo REST, aplicando tolerancia a fallos para mejorar la resiliencia.
- Proteger endpoints REST usando tokens web JSON (JWTs).
- Desarrollar características dirigidas por eventos usando el modelo Reactivo.
- Usar la biblioteca de métricas Micrometer para definir métricas integradas.

## Antes de Comenzar

Asegúrate de tener instalado:
- Java 21 o superior
- Maven 3.8 o superior
- Python 3 (para ejecutar el frontend)
- Docker o Podman (para contenedores)
- OpenSSL (para generar claves JWT)

### Checklist de Extensiones Requeridas

Asegúrate de que el proyecto incluya todas estas extensiones:

**Extensiones Core:**
- `quarkus-hibernate-orm-panache` - ORM con Panache
- `quarkus-jdbc-postgresql` - Driver PostgreSQL
- `quarkus-rest` - Framework REST
- `quarkus-rest-jackson` - Serialización JSON (servidor)
- `quarkus-rest-client` - Cliente REST
- `quarkus-rest-client-jackson` - **IMPORTANTE:** Serialización JSON (cliente REST)

**Extensiones de Seguridad y Salud:**
- `quarkus-smallrye-openapi` - OpenAPI/Swagger
- `quarkus-smallrye-health` - Health checks
- `quarkus-smallrye-jwt-build` - Generación JWT
- `quarkus-smallrye-jwt` - Verificación JWT

**Extensiones de Mensajería y Resiliencia:**
- `quarkus-messaging-kafka` - Integración Kafka
- `quarkus-smallrye-fault-tolerance` - Tolerancia a fallos

**Extensiones de Métricas:**
- `quarkus-micrometer-registry-prometheus` - Métricas Prometheus

### Configuraciones Críticas

Antes de ejecutar, verifica:

1. **Claves JWT:** Los archivos `privateKey.pem` y `publicKey.pem` deben existir en `src/main/resources/`
2. **Base de Datos:** El archivo `import.sql` debe tener `status = 0` para parques abiertos
3. **Entidad Park:** Debe incluir el campo `size` de tipo `Integer`
4. **Cliente REST:** Debe tener `quarkus-rest-client-jackson` en las dependencias
5. **Timeouts:** Deben estar en milisegundos (números), no en formato de duración

## Preparación del Entorno

1. Navega al directorio del proyecto:

**Linux/Mac:**
```bash
cd ~/comprehensive-review-start
```

**Windows (PowerShell):**
```powershell
cd comprehensive-review-start
```

2. Debes ejecutar dos servicios para este ejercicio: `parks-dashboard` y `weather`.

### Ejecutar el servicio Weather

Abre una terminal, navega al directorio principal del servicio weather y ejecuta el siguiente comando Maven:

**Linux/Mac:**
```bash
cd weather
./mvnw install && java -jar target/quarkus-app/quarkus-run.jar
```

**Windows (PowerShell):**
```powershell
cd weather
.\mvnw.cmd install; java -jar target/quarkus-app/quarkus-run.jar
```

**Windows (CMD):**
```cmd
cd weather
mvnw.cmd install && java -jar target/quarkus-app/quarkus-run.jar
```

### Ejecutar el frontend Parks Dashboard

Abre otra terminal y ejecuta el siguiente comando:

**Linux/Mac:**
```bash
cd parks-dashboard
python3 serve.py
```

**Windows:**
```powershell
cd parks-dashboard
python serve.py
```

Mantén estas terminales ejecutándose durante el laboratorio.

## Especificaciones

Asume que tu equipo está trabajando en una plataforma de ciudades inteligentes. La plataforma está compuesta por múltiples microservicios y, en particular, te han asignado la implementación de servicios municipales de parques inteligentes. Debes crear un servicio de parques responsable de abrir y cerrar parques por seguridad, basándose en alertas meteorológicas, entre otras características.

La aplicación está diseñada como muestra el siguiente diagrama:

```
┌─────────────────┐
│ Parks Dashboard │  (Frontend React - Puerto 9000)
│   (Frontend)    │
└────────┬────────┘
         │
         │ HTTP REST
         │
┌────────▼────────┐         ┌──────────────┐
│   Parks Service │◄────────┤ Weather      │
│   (Puerto 8080) │  REST   │ Service      │
│                 │         │ (Puerto 8090)│
└────────┬────────┘         └──────────────┘
         │
         │ Kafka
         │
└────────▼────────┘
│   Kafka Topic   │
│ weather-warnings│
└─────────────────┘
```

**Nota:** Las buenas prácticas de arquitectura sugieren el uso de un servicio gateway para integrar el acceso a los servicios backend en una sola API. Este ejercicio, sin embargo, omite la implementación de un servicio gateway por simplicidad.

- Inicialmente, el servicio parks no existe. Debes crear un proyecto Quarkus llamado `parks` e implementar este servicio.
- **No cambies el código fuente de los otros dos servicios.**
- El frontend `parks-dashboard` es una aplicación React que monitorea y controla parques. La aplicación se ejecuta en `http://localhost:9000`. Usando esta aplicación, puedes ver los parques registrados en el servicio parks, y abrir y cerrar estos parques. También puedes usar este frontend para simular alertas meteorológicas en el servicio weather y verificar cómo reaccionan los estados de los parques a las alertas meteorológicas severas.
- El frontend `parks-dashboard` no se carga completamente hasta que el endpoint `/q/health` del servicio parks reporte que el servicio está activo.
- El servicio weather emite alertas meteorológicas y está disponible en `http://localhost:8090`. Este servicio proporciona dos interfaces para leer alertas meteorológicas: un endpoint HTTP GET y un tópico Kafka.

Debes desarrollar la lógica requerida en el servicio parks para leer alertas de forma síncrona desde el endpoint HTTP GET del servicio weather. Posteriormente, debes actualizar el servicio parks para poder leer las mismas alertas de forma asíncrona desde un tópico Kafka.

- La interfaz REST del servicio weather proporciona los siguientes endpoints:

| Endpoint | Descripción |
|----------|-------------|
| `GET /warnings` | Lista alertas meteorológicas activas en JSON. |
| `GET /warnings/{city}` | Lista alertas meteorológicas activas para una ciudad dada en JSON. |
| `POST /warnings/simulation` | Simula la activación de alertas meteorológicas aleatorias |

- El tópico Kafka donde el servicio weather publica alertas meteorológicas es `weather-warnings`.
- Una alerta meteorológica incluye la ciudad para la cual se emite la alerta, el tipo de evento meteorológico y la severidad de la alerta. El servicio weather usa el mismo modelo de datos tanto para la interfaz REST como para el tópico Kafka. Este modelo de datos está definido en la clase POJO `WeatherWarning`.
- El ejercicio te proporciona el código fuente de la clase `WeatherWarning`. No necesitas desarrollar esta clase desde cero en el servicio parks para consumir alertas meteorológicas. En su lugar, copia el contenido del directorio `~/comprehensive-review-start/materials/weather/` al servicio parks.
- Al crear el proyecto Quarkus para el servicio parks, asegúrate de que el proyecto use las extensiones requeridas para ORM, PostgreSQL, APIs HTTP Reactivas, clientes HTTP Reactivos y soporte JSON.
- Usa la siguiente versión de Red Hat build of Quarkus: **3.26.0** (o la versión más reciente disponible).
- Agrupa el código de tu proyecto Quarkus parks bajo un paquete Java llamado `com.redhat.smartcity`. Esto es necesario para que los scripts de evaluación pasen.
- El servicio parks debe escuchar en el puerto **8080**.
- El servicio parks debe tener acceso a una base de datos PostgreSQL llamada `parks` que contiene entidades `Park`. Debes definir una entidad `Park` de la siguiente manera:

### Entidad Park

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | `Long` | ID del parque autogenerado. |
| `name` | `String` | El nombre del parque. |
| `city` | `String` | La ciudad donde se encuentra el parque. |
| `status` | `Status` | Uno de los valores del enum `Status {CLOSED, OPEN}`. Debes definir este enum. |

- El servicio parks debe usar Quarkus Dev Services para proporcionar una base de datos. Debes establecer `registry.ocp4.example.com:8443/redhattraining/do378-postgres:14.1` como la imagen de Dev Services para PostgreSQL.

**Nota:** Si no tienes acceso a ese registro, puedes usar la imagen estándar de PostgreSQL:
```
quarkus.datasource.devservices.image-name=postgres:14
```

- El ejercicio te proporciona el archivo `~/comprehensive-review-start/materials/import.sql` con datos de muestra para poblar la base de datos parks. Puedes copiar este archivo al servicio parks para poblar la base de datos parks.

- Debes crear una API REST JSON en el servicio parks que exponga los siguientes endpoints:

| Endpoint | Descripción |
|----------|-------------|
| `GET /parks` | Lista entidades Park en JSON. |
| `PUT /parks` | Actualiza un parque. El cuerpo de la solicitud debe contener el parque a actualizar, en JSON. |
| `POST /parks/{id}/weathercheck` | Verifica si hay alertas meteorológicas activas para el parque identificado por `id`, y cierra el parque si es necesario. |

El frontend `parks-dashboard` usa estos endpoints.

- El servicio parks debe habilitar acceso cross-origin para permitir solicitudes desde el frontend `parks-dashboard`.
- El servicio parks debe exponer la especificación OpenAPI y los endpoints de Swagger UI. El servicio debe exponer el endpoint `/q/openapi`.
- La especificación OpenAPI del servicio parks debe incluir anotaciones. Al menos, establece el título de la API, y el resumen y descripción para cada endpoint REST.
- El servicio parks debe incluir una prueba que verifique que el endpoint `GET /parks` devuelve una lista no vacía de parques. Crea la prueba en la clase `com.redhat.smartcity.ParksResourceTest`. Puedes usar matchers de Hamcrest, como `not` y `emptyArray` para validar esta condición.

Asegúrate de ejecutar `mvn test`. El script de evaluación verifica que el informe de pruebas de Maven Surefire no contenga errores o fallos.

- El servicio parks debe exponer el endpoint `/q/health`, que debe incluir una verificación de salud por defecto.
- El servicio parks debe restringir el acceso al endpoint `PUT /parks`. Usa autenticación y autorización basada en JWT para permitir solo a usuarios con el rol `Admin` actualizar parques.
- No necesitas desarrollar el flujo de autenticación y endpoints desde cero. En su lugar, usa los archivos proporcionados `AuthResource.java` y `UserService.java` del directorio `~/comprehensive-review-start/materials/auth/`. El `AuthResource` requiere que implementes un bean `JWTGenerator` que incluya un método `generateForUser(String username)`.

**Nota:** Si el ejercicio proporciona archivos `.pem` para JWT, cópialos al servicio parks y actualiza el archivo `application.properties` para activar la generación de JSON Web Token (JWT).

- Asume que solo existe un usuario. El nombre de usuario es `admin` y la contraseña es `redhat`. El JWT generado debe contener, al menos, el claim `upn`, que incluye el nombre de usuario. Este usuario debe ser parte de los grupos de roles `User` y `Admin`.
- El endpoint `POST /parks/{id}/weathercheck` del servicio parks debe verificar si hay alertas meteorológicas activas para el parque identificado por `id`. Si hay alertas meteorológicas severas (nivel Orange o Red) de tipo Storm, Rain, Snow o Wind, el servicio debe cerrar el parque automáticamente. El ejercicio te proporciona la clase `ParkGuard.java` en el directorio `~/comprehensive-review-start/materials/` que contiene la lógica para evaluar alertas meteorológicas.

## Pasos del Laboratorio

### Paso 1: Crear el Proyecto Quarkus Parks

1.1. Crea un nuevo proyecto Quarkus usando el Quarkus CLI o el sitio web de Quarkus.

**Usando Quarkus CLI (Linux/Mac):**
```bash
quarkus create app com.redhat.smartcity:parks \
  --extension=quarkus-hibernate-orm-panache,quarkus-jdbc-postgresql,quarkus-rest,quarkus-rest-jackson,quarkus-smallrye-openapi,quarkus-smallrye-health,quarkus-messaging-kafka,quarkus-rest-client,quarkus-rest-client-jackson,quarkus-smallrye-jwt-build,quarkus-smallrye-jwt,quarkus-smallrye-fault-tolerance \
  --no-code
```

**Usando Quarkus CLI (Windows PowerShell):**
```powershell
quarkus create app com.redhat.smartcity:parks `
  --extension=quarkus-hibernate-orm-panache,quarkus-jdbc-postgresql,quarkus-rest,quarkus-rest-jackson,quarkus-smallrye-openapi,quarkus-smallrye-health,quarkus-messaging-kafka,quarkus-rest-client,quarkus-rest-client-jackson,quarkus-smallrye-jwt-build,quarkus-smallrye-jwt,quarkus-smallrye-fault-tolerance `
  --no-code
```

**Usando Maven (Linux/Mac/Windows):**
```bash
mvn io.quarkus.platform:quarkus-maven-plugin:3.26.0:create \
  -DprojectGroupId=com.redhat.smartcity \
  -DprojectArtifactId=parks \
  -Dextensions="quarkus-hibernate-orm-panache,quarkus-jdbc-postgresql,quarkus-rest,quarkus-rest-jackson,quarkus-smallrye-openapi,quarkus-smallrye-health,quarkus-messaging-kafka,quarkus-rest-client,quarkus-rest-client-jackson,quarkus-smallrye-jwt-build,quarkus-smallrye-jwt,quarkus-smallrye-fault-tolerance" \
  -DnoCode
```

**Nota importante:** La extensión `quarkus-rest-client-jackson` es necesaria para que el cliente REST pueda deserializar respuestas JSON. La extensión `quarkus-smallrye-fault-tolerance` también se incluye desde el inicio.

1.2. Navega al directorio del proyecto:

**Linux/Mac:**
```bash
cd parks
```

**Windows:**
```powershell
cd parks
```

### Paso 2: Configurar la Base de Datos

2.1. Configura Quarkus Dev Services para PostgreSQL. Edita el archivo `src/main/resources/application.properties` y agrega:

```properties
# Database Configuration
quarkus.datasource.db-kind=postgresql
quarkus.datasource.devservices.enabled=true
quarkus.datasource.devservices.image-name=postgres:14
quarkus.hibernate-orm.database.generation=drop-and-create
quarkus.hibernate-orm.log.sql=true

# Si tienes acceso al registro de Red Hat:
# quarkus.datasource.devservices.image-name=registry.ocp4.example.com:8443/redhattraining/do378-postgres:14.1
```

2.2. Copia el archivo `import.sql` al proyecto:

**Linux/Mac:**
```bash
cp ../materials/import.sql src/main/resources/
```

**Windows (PowerShell):**
```powershell
Copy-Item ..\materials\import.sql src\main\resources\
```

**Windows (CMD):**
```cmd
copy ..\materials\import.sql src\main\resources\
```

2.3. **IMPORTANTE:** Verifica que el archivo `import.sql` tenga el campo `size` y que el `status` use `0` para OPEN (no `1`):

El archivo debe verse así:
```sql
INSERT INTO
    park(id, name, city, status, size)
VALUES
    (1, 'Vondelpark', 'Amsterdam', 0, 800),
    (2, 'Parc du Cinquantenaire', 'Brussels', 0, 700),
    (3, 'Parque Ibirapuera', 'São Paulo', 0, 1000),
    (4, 'Parc Güell', 'Barcelona', 0, 500);
```

**Nota:** El valor `0` corresponde a `OPEN` y `1` corresponde a `CLOSED` porque Hibernate mapea los enums por ordinal.

### Paso 3: Crear la Entidad Park

3.1. Crea la entidad `Park` en `src/main/java/com/redhat/smartcity/Park.java`:

```java
package com.redhat.smartcity;

import jakarta.persistence.Entity;
import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
public class Park extends PanacheEntity {
    public String name;
    public String city;
    public Status status;
    public Integer size;

    public enum Status {
        OPEN, CLOSED
    }
}
```

### Paso 4: Copiar las Clases de Weather

4.1. Copia las clases de weather al proyecto:

**Linux/Mac:**
```bash
mkdir -p src/main/java/com/redhat/smartcity/weather
cp ../materials/weather/*.java src/main/java/com/redhat/smartcity/weather/
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path src\main\java\com\redhat\smartcity\weather
Copy-Item ..\materials\weather\*.java src\main\java\com\redhat\smartcity\weather\
```

**Windows (CMD):**
```cmd
mkdir src\main\java\com\redhat\smartcity\weather
copy ..\materials\weather\*.java src\main\java\com\redhat\smartcity\weather\
```

### Paso 5: Crear el Recurso REST ParksResource

5.1. Crea el recurso REST `ParksResource` en `src/main/java/com/redhat/smartcity/ParksResource.java`:

```java
package com.redhat.smartcity;

import jakarta.annotation.security.RolesAllowed;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.List;

@Path("/parks")
@Tag(name = "Parks", description = "Operaciones para gestionar parques")
public class ParksResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Listar todos los parques", description = "Obtiene una lista de todos los parques registrados")
    public List<Park> getAllParks() {
        return Park.listAll();
    }

    @PUT
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @RolesAllowed("Admin")
    @Operation(summary = "Actualizar un parque", description = "Actualiza la información de un parque existente. Requiere rol Admin.")
    @Transactional
    public Park updatePark(Park park) {
        Park entity = Park.findById(park.id);
        if (entity == null) {
            throw new NotFoundException();
        }
        entity.name = park.name;
        entity.city = park.city;
        entity.status = park.status;
        return entity;
    }

    @POST
    @Path("/{id}/weathercheck")
    @Operation(summary = "Verificar clima para un parque", description = "Verifica alertas meteorológicas y cierra el parque si es necesario")
    @Transactional
    public Response checkWeather(@PathParam("id") Long id) {
        Park park = Park.findById(id);
        if (park == null) {
            throw new NotFoundException();
        }
        // La lógica de verificación se implementará más adelante
        return Response.ok().build();
    }
}
```

5.2. Configura CORS en `application.properties`:

```properties
# CORS Configuration
quarkus.http.cors.enabled =true
quarkus.http.cors.origins=http://localhost:9000
```

### Paso 6: Configurar OpenAPI

6.1. Configura OpenAPI en `application.properties`:

```properties
# OpenAPI Configuration
quarkus.smallrye-openapi.info-title=Parks Service API
quarkus.smallrye-openapi.info-version=1.0.0
```

### Paso 7: Crear el Cliente REST WeatherService

7.1. Crea la interfaz del cliente REST `WeatherService` en `src/main/java/com/redhat/smartcity/weather/WeatherService.java`:

```java
package com.redhat.smartcity.weather;

import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.List;

@Path("/warnings")
@RegisterRestClient(configKey = "weather-api")
public interface WeatherService {
    
    @GET
    @Path("/{city}")
    @Produces(MediaType.APPLICATION_JSON)
    Uni<List<WeatherWarning>> getWarningsByCity(@PathParam("city") String city);
}
```

**Nota importante:** 
- El método devuelve `Uni<List<WeatherWarning>>` para soportar programación reactiva
- Se agrega `@Produces(MediaType.APPLICATION_JSON)` para especificar el tipo de contenido

7.2. Configura el cliente REST en `application.properties`:

```properties
# Weather Service REST Client Configuration
# URL del servicio weather (por defecto localhost:8090)
# Puedes sobrescribir con variables de entorno: WEATHER_ENDPOINT y WEATHER_PORT
quarkus.rest-client.weather-api.url=http://${WEATHER_ENDPOINT:localhost}:${WEATHER_PORT:8090}
# Timeouts en milisegundos (5000ms = 5 segundos, 10000ms = 10 segundos)
quarkus.rest-client.weather-api.connect-timeout=5000
quarkus.rest-client.weather-api.read-timeout=10000
```

**Nota importante:** Los timeouts deben estar en milisegundos (números), no en formato de duración como "5s".

### Paso 8: Implementar ParkGuard

8.1. Copia la clase `ParkGuard` al proyecto:

**Linux/Mac:**
```bash
cp ../materials/ParkGuard.java src/main/java/com/redhat/smartcity/
```

**Windows (PowerShell):**
```powershell
Copy-Item ..\materials\ParkGuard.java src\main\java\com\redhat\smartcity\
```

**Windows (CMD):**
```cmd
copy ..\materials\ParkGuard.java src\main\java\com\redhat\smartcity\
```

8.2. Actualiza `ParksResource` para usar `ParkGuard`:

```java
@Inject
ParkGuard guard;

@POST
@Path("/{id}/weathercheck")
@Operation(summary = "Verificar clima para un parque", description = "Verifica alertas meteorológicas y cierra el parque si es necesario")
@Transactional
public Response checkWeather(@PathParam("id") Long id) {
    Park park = Park.findById(id);
    if (park == null) {
        throw new NotFoundException();
    }
    guard.checkWeatherForPark(park);
    return Response.ok().build();
}
```

### Paso 9: Implementar Autenticación JWT

9.1. Copia los archivos de autenticación:

**Linux/Mac:**
```bash
cp ../materials/auth/*.java src/main/java/com/redhat/smartcity/
```

**Windows (PowerShell):**
```powershell
Copy-Item ..\materials\auth\*.java src\main\java\com\redhat\smartcity\
```

**Windows (CMD):**
```cmd
copy ..\materials\auth\*.java src\main\java\com\redhat\smartcity\
```

9.2. Crea el bean `JwtGenerator` en `src/main/java/com/redhat/smartcity/JwtGenerator.java`:

```java
package com.redhat.smartcity;

import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.jwt.Claims;
import org.jose4j.jwt.JwtClaims;

import io.smallrye.jwt.build.Jwt;

@ApplicationScoped
public class JwtGenerator {

    public String generateForUser(String username) {
        return Jwt.claims()
            .claim(Claims.upn.name(), username)
            .claim(Claims.groups.name(), java.util.List.of("User", "Admin"))
            .sign();
    }
}
```

9.3. Genera las claves JWT necesarias:

**Linux/Mac:**
```bash
cd parks
./generate-jwt-keys.sh
```

**Windows:**
```cmd
cd parks
generate-jwt-keys.bat
```

**Nota:** Si los scripts no están disponibles, genera las claves manualmente:
```bash
cd src/main/resources
openssl genpkey -algorithm RSA -out privateKey.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in privateKey.pem -out publicKey.pem
```

9.4. Configura JWT en `application.properties`:

```properties
# JWT Configuration
mp.jwt.verify.publickey.location=publicKey.pem
mp.jwt.verify.issuer=https://example.com/issuer
mp.jwt.verify.publickey.algorithm=RS256
smallrye.jwt.sign.key.location=privateKey.pem
smallrye.jwt.encrypt.key.location=publicKey.pem
```

**Nota importante:** 
- `mp.jwt.verify.publickey.location` debe ser `publicKey.pem` (NO `NONE`) para que la verificación de JWT funcione
- Se agrega `mp.jwt.verify.publickey.algorithm=RS256` para especificar el algoritmo
- Los archivos `privateKey.pem` y `publicKey.pem` deben estar en `src/main/resources/`

9.5. Actualiza el `JwtGenerator` para incluir el issuer:

```java
public String generateForUser(String username) {
    return Jwt.claims()
            .issuer("https://example.com/issuer")
            .claim(Claims.upn.name(), username)
            .claim(Claims.groups.name(), java.util.List.of("User", "Admin"))
            .sign();
}
```

### Paso 10: Agregar Tolerancia a Fallos

10.1. Agrega la extensión de tolerancia a fallos:

**Linux/Mac:**
```bash
./mvnw quarkus:add-extension -Dextension=smallrye-fault-tolerance
```

**Windows (PowerShell):**
```powershell
.\mvnw.cmd quarkus:add-extension -Dextension=smallrye-fault-tolerance
```

**Windows (CMD):**
```cmd
mvnw.cmd quarkus:add-extension -Dextension=smallrye-fault-tolerance
```

10.2. Modifica la clase `ParkGuard` para usar un método de fallback cuando el servicio weather no esté disponible. Usa un timeout de 5 segundos y maneja la respuesta reactiva:

```java
import java.time.temporal.ChronoUnit;
import io.smallrye.mutiny.Uni;
import org.eclipse.microprofile.faulttolerance.Fallback;
import org.eclipse.microprofile.faulttolerance.Timeout;

@Fallback(fallbackMethod = "assumeNoWarnings")
@Timeout(value = 5, unit = ChronoUnit.SECONDS)
public Uni<Void> checkWeatherForPark(Park park) {
    Log.info("Checking weather for park " + park.id + " (" + park.name + ") in city: " + park.city);
    var warningsStream = weatherService.getWarningsByCity(park.city);

    return warningsStream
            .onItem()
            .invoke(warnings -> {
                Log.info("Received " + warnings.size() + " weather warnings for " + park.city);
                for (WeatherWarning warning : warnings) {
                    var parkClosed = updateParkBasedOnWarning(park, warning);
                    if (parkClosed) {
                        return;
                    }
                }
            })
            .onFailure()
            .invoke(throwable -> {
                Log.error("Error calling weather service for park " + park.id + " (" + park.name + "): " + throwable.getMessage(), throwable);
            })
            .replaceWithVoid();
}

public Uni<Void> assumeNoWarnings(Park park) {
    Log.warn(
        "Weather service is not reachable. " +
        "Assuming no weather warnings are active for park " +
        park.id + " (" + park.name + ")."
    );
    return Uni.createFrom().voidItem();
}
```

**Nota importante:**
- El método ahora devuelve `Uni<Void>` para soportar programación reactiva
- El timeout se establece explícitamente a 5 segundos
- Se agrega logging para facilitar el diagnóstico

10.3. Valida que el servicio parks sea resiliente a fallos del servicio weather. Detén el servicio weather presionando `Ctrl+C` en la terminal donde se está ejecutando.

10.4. Regresa al navegador. Haz clic en "Run park weather checks".

10.5. Regresa a la terminal donde se está ejecutando el servicio parks. Verifica que los logs muestren advertencias como:

```
Weather service is not reachable. Assuming no weather warnings are active for park 4 (Parc Güell).
```

10.6. Vuelve a ejecutar el servicio weather.

**Linux/Mac:**
```bash
cd weather
java -jar target/quarkus-app/quarkus-run.jar
```

**Windows:**
```powershell
cd weather
java -jar target/quarkus-app/quarkus-run.jar
```

### Paso 11: Hacer el Servicio Parks Reactivo a Alertas Meteorológicas

Después de recibir una nueva alerta del canal `weather-warnings`, el servicio parks debe actualizar los parques de la ciudad afectada por la alerta.

Al actualizar el parque, considera que el acceso al administrador de entidades Park, requerido para actualizar un parque, es una operación bloqueante.

Debes deshabilitar el Kafka Dev Service para el perfil de prueba. De lo contrario, las pruebas fallarán porque la imagen del contenedor Kafka no es accesible.

11.1. Agrega la extensión `smallrye-reactive-messaging-kafka`:

**Linux/Mac:**
```bash
./mvnw quarkus:add-extension -Dextension=quarkus-messaging-kafka
```

**Windows (PowerShell):**
```powershell
.\mvnw.cmd quarkus:add-extension -Dextension=quarkus-messaging-kafka
```

**Windows (CMD):**
```cmd
mvnw.cmd quarkus:add-extension -Dextension=quarkus-messaging-kafka
```

11.2. Crea la clase `WeatherWarningsProcessor` para consumir alertas meteorológicas del canal entrante `weather-warnings`:

```java
package com.redhat.smartcity;

import java.util.List;
import java.util.concurrent.CompletionStage;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.databind.DeserializationFeature;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import com.redhat.smartcity.weather.WeatherWarning;
import io.quarkus.logging.Log;

@jakarta.enterprise.context.ApplicationScoped
public class WeatherWarningsProcessor {
    
    @Inject
    ParkGuard guard;

    @Channel("parks-under-warning")
    Emitter<List<Park>> emitter;

    private final ObjectMapper objectMapper;

    public WeatherWarningsProcessor() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
        this.objectMapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
    }

    @Incoming("weather-warnings")
    @Transactional
    public CompletionStage<Void> processWeatherWarning(Message<String> message) {
        try {
            String jsonString = message.getPayload();
            Log.info("[EVENT Received JSON] " + jsonString);
            
            WeatherWarning warning = objectMapper.readValue(jsonString, WeatherWarning.class);
            Log.info("[EVENT Received] " + warning);

            List<Park> parks = Park.find("city = ?1", warning.city).list();

            parks.forEach(park -> {
                guard.updateParkBasedOnWarning(park, warning);
            });

            return message.ack();
        } catch (Exception e) {
            Log.error("Error processing weather warning message: " + e.getMessage(), e);
            return message.nack(e);
        }
    }
}
```

**Nota importante:**
- El método recibe `Message<String>` porque Kafka usa `StringDeserializer`
- Se deserializa manualmente el JSON usando Jackson `ObjectMapper`
- Se registra `JavaTimeModule` para manejar `LocalDateTime`
- Se agrega `@ApplicationScoped` para que sea un bean CDI
- La anotación `@Transactional` marca el método `processWeatherWarning` como bloqueante

11.3. Deshabilita Kafka Dev Services para el perfil de prueba. Agrega la siguiente línea al archivo `src/main/resources/application.properties`:

```properties
%test.quarkus.kafka.devservices.enabled=false
```

11.4. Configura Kafka en `application.properties`:

```properties
# Kafka Configuration
kafka.bootstrap.servers=localhost:9092
mp.messaging.incoming.weather-warnings.connector=smallrye-kafka
mp.messaging.incoming.weather-warnings.topic=weather-warnings
mp.messaging.incoming.weather-warnings.value.deserializer=org.apache.kafka.common.serialization.StringDeserializer
```

11.5. Regresa a la pestaña del navegador y haz clic en "Simulate weather warnings" múltiples veces. Verifica cómo los parques cambian su estado cuando el servicio weather emite nuevas alertas.

### Paso 12: Actualizar el Endpoint `/parks/{id}/weathercheck` para que sea Asíncrono

Este endpoint depende internamente del servicio weather, por lo que debes declarar el método `WeatherService#getWarningsByCity` como asíncrono también.

**Nota:** Por brevedad, no actualices la consulta de base de datos del endpoint `/parks/{id}/weathercheck` a reactivo. En producción, sin embargo, deberías usar acceso a base de datos reactivo para evitar bloquear el bucle de eventos.

12.1. Actualiza el método `WeatherService#getWarningsByCity` para devolver un stream:

```java
import io.smallrye.mutiny.Uni;

@Path("/warnings")
@RegisterRestClient(configKey="weather-api")
public interface WeatherService {

    @GET
    @Path("/{city}")
    Uni<List<WeatherWarning>> getWarningsByCity(@PathParam("city") String city);
}
```

12.2. Actualiza el método `ParkGuard#checkWeatherForPark` para manejar el stream del cliente REST y devolver un stream `Uni<Void>`. También debes actualizar el método de fallback `assumeNoWarnings`:

```java
import io.smallrye.mutiny.Uni;

@Fallback(fallbackMethod = "assumeNoWarnings")
@Timeout
public Uni<Void> checkWeatherForPark(Park park) {
    var warningsStream = weatherService.getWarningsByCity(park.city);
    
    return warningsStream
        .onItem()
        .invoke(warnings -> {
            for (WeatherWarning warning : warnings) {
                var parkClosed = updateParkBasedOnWarning(park, warning);
                if (parkClosed) {
                    return;
                }
            }
        })
        .replaceWithVoid();
}

public Uni<Void> assumeNoWarnings(Park park) {
    Log.warn(
        "Weather service is not reachable. " +
        "Assuming no weather warnings are active for park " +
        park.id + " (" + park.name + ")."
    );
    return Uni.createFrom().voidItem();
}
```

12.3. Actualiza el método `ParksResource#checkWeather` para devolver un stream `Uni<Void>`:

```java
import io.smallrye.mutiny.Uni;

@POST
@Path("/{id}/weathercheck")
@Operation(summary = "Verificar clima para un parque", description = "Verifica alertas meteorológicas y cierra el parque si es necesario")
@Transactional
public Uni<Void> checkWeather(@PathParam("id") Long id) {
    Park park = Park.findById(id);
    if (park == null) {
        throw new NotFoundException();
    }
    return guard.checkWeatherForPark(park);
}
```

**Nota:** El ejemplo anterior todavía contiene operaciones bloqueantes, porque el acceso a la base de datos no es reactivo.

12.4. Regresa al navegador y verifica que la aplicación funcione como se espera.

### Paso 13: Generar una Métrica Personalizada

Genera una métrica personalizada en el servicio parks. La métrica debe contar cuántas veces un parque es afectado por alertas meteorológicas. Expone la métrica en formato Prometheus.

13.1. Agrega la extensión `micrometer-registry-prometheus`:

**Linux/Mac:**
```bash
./mvnw quarkus:add-extension -Dextension=micrometer-registry-prometheus
```

**Windows (PowerShell):**
```powershell
.\mvnw.cmd quarkus:add-extension -Dextension=micrometer-registry-prometheus
```

**Windows (CMD):**
```cmd
mvnw.cmd quarkus:add-extension -Dextension=micrometer-registry-prometheus
```

**Importante:** Es posible que necesites reiniciar el servicio parks en este punto. De lo contrario, Quarkus podría no poder resolver el paquete `io.micrometer.core.instrument`.

13.2. Inyecta el bean `MeterRegistry` de Micrometer en la clase `ParkGuard`. En el método `updateParkBasedOnWarning`, usa el recurso para obtener e incrementar un contador llamado `parksAffected.count`:

```java
public class ParkGuard {
    @Inject
    io.micrometer.core.instrument.MeterRegistry registry;
    
    // ... código existente ...
    
    public boolean updateParkBasedOnWarning(Park park, WeatherWarning warning) {
        if (mustCloseParkDueTo(warning)) {
            // ... código existente ...
            registry.counter("parksAffected.count").increment();
            return true;
        }
        // ... código existente ...
    }
}
```

13.3. Valida la generación de métricas.

Desde el frontend, simula algunas alertas meteorológicas. Luego ejecuta el siguiente comando en tu terminal para ver las métricas generadas:

**Linux/Mac:**
```bash
curl localhost:8080/q/metrics | grep parksAffected_count_total
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri http://localhost:8080/q/metrics | Select-String "parksAffected_count_total"
```

**Windows (CMD):**
```cmd
curl http://localhost:8080/q/metrics | findstr parksAffected_count_total
```

Deberías ver algo como:

```
# HELP parksAffected_count_total
# TYPE parksAffected_count_total counter
parksAffected_count_total 5.0
```

### Paso 14: Crear Pruebas

14.1. Crea la clase de prueba `ParksResourceTest` en `src/test/java/com/redhat/smartcity/ParksResourceTest.java`:

```java
package com.redhat.smartcity;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.RestAssured;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;

@QuarkusTest
public class ParksResourceTest {

    @Test
    public void testGetParks() {
        RestAssured.given()
            .when().get("/parks")
            .then()
            .statusCode(200)
            .body("$", Matchers.not(Matchers.emptyArray()));
    }
}
```

14.2. Ejecuta las pruebas:

**Linux/Mac:**
```bash
./mvnw test
```

**Windows (PowerShell):**
```powershell
.\mvnw.cmd test
```

**Windows (CMD):**
```cmd
mvnw.cmd test
```

## Ejecutar el Proyecto Completo

### Iniciar Kafka (si no está usando Dev Services)

**Usando Docker:**

**Linux/Mac:**
```bash
docker run -d --name kafka -p 9092:9092 apache/kafka:latest
```

**Windows (PowerShell):**
```powershell
docker run -d --name kafka -p 9092:9092 apache/kafka:latest
```

**Usando Podman:**

**Linux/Mac:**
```bash
podman run -d --name kafka -p 9092:9092 apache/kafka:latest
```

**Windows (PowerShell):**
```powershell
podman run -d --name kafka -p 9092:9092 apache/kafka:latest
```

### Iniciar los Servicios

1. **Servicio Weather** (Terminal 1):
   - Puerto: 8090

**Linux/Mac:**
```bash
cd weather
./mvnw install && java -jar target/quarkus-app/quarkus-run.jar
```

**Windows (PowerShell):**
```powershell
cd weather
.\mvnw.cmd install; java -jar target/quarkus-app/quarkus-run.jar
```

2. **Servicio Parks** (Terminal 2):
   - Puerto: 8080

**Linux/Mac:**
```bash
cd parks
./mvnw quarkus:dev
```

**Windows (PowerShell):**
```powershell
cd parks
.\mvnw.cmd quarkus:dev
```

3. **Frontend Parks Dashboard** (Terminal 3):
   - Puerto: 9000

**Linux/Mac:**
```bash
cd parks-dashboard
python3 serve.py
```

**Windows:**
```powershell
cd parks-dashboard
python serve.py
```

## Verificación Final

1. Abre el navegador en `http://localhost:9000`
2. Verifica que puedas ver los parques
3. Prueba abrir/cerrar parques (requiere autenticación)
4. Simula alertas meteorológicas y verifica que los parques se cierren automáticamente
5. Verifica que las métricas estén disponibles en `http://localhost:8080/q/metrics`
6. Verifica que OpenAPI esté disponible en `http://localhost:8080/q/openapi`
7. Verifica que Swagger UI esté disponible en `http://localhost:8080/q/swagger-ui`

## Solución de Problemas

### El servicio parks no se inicia

- Verifica que PostgreSQL Dev Services esté funcionando
- Verifica los logs para errores de conexión a la base de datos
- Asegúrate de que el puerto 8080 esté libre
- Verifica que los archivos `.pem` existan en `src/main/resources/`

### Error: "column size does not exist"

**Problema:** La entidad `Park` no tiene el campo `size` definido.

**Solución:** Asegúrate de que la entidad `Park` incluya:
```java
public Integer size;
```

### Error: "401 Unauthorized" al cambiar estado de parques

**Problema:** La configuración JWT no está correcta o las claves no existen.

**Solución:**
1. Verifica que los archivos `privateKey.pem` y `publicKey.pem` existan en `src/main/resources/`
2. Verifica que `application.properties` tenga:
   ```properties
   mp.jwt.verify.publickey.location=publicKey.pem
   mp.jwt.verify.publickey.algorithm=RS256
   ```
3. Haz logout y login de nuevo para obtener un nuevo token JWT

### Error: "Response could not be mapped to type"

**Problema:** Falta la extensión `quarkus-rest-client-jackson`.

**Solución:** Agrega la dependencia al `pom.xml`:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-rest-client-jackson</artifactId>
</dependency>
```

### Error: "Expected a long value, got '5s'"

**Problema:** Los timeouts del cliente REST están en formato incorrecto.

**Solución:** Usa milisegundos (números) en lugar de formato de duración:
```properties
quarkus.rest-client.weather-api.connect-timeout=5000
quarkus.rest-client.weather-api.read-timeout=10000
```

### Error: "ClassCastException: String cannot be cast to WeatherWarning"

**Problema:** El procesador de Kafka está intentando recibir `WeatherWarning` directamente, pero Kafka usa `StringDeserializer`.

**Solución:** El procesador debe recibir `Message<String>` y deserializar manualmente:
```java
@Incoming("weather-warnings")
public CompletionStage<Void> processWeatherWarning(Message<String> message) {
    String jsonString = message.getPayload();
    WeatherWarning warning = objectMapper.readValue(jsonString, WeatherWarning.class);
    // ... procesar warning
    return message.ack();
}
```

### Error: "LocalDateTime not supported by default"

**Problema:** El `ObjectMapper` no tiene el módulo JSR310 registrado.

**Solución:** Registra `JavaTimeModule` en el constructor:
```java
public WeatherWarningsProcessor() {
    this.objectMapper = new ObjectMapper();
    this.objectMapper.registerModule(new JavaTimeModule());
}
```

### Warning: "Weather service is not reachable"

**Problema:** El servicio weather no está corriendo o hay un timeout.

**Solución:**
1. Verifica que el servicio weather esté ejecutándose en el puerto 8090
2. Prueba con: `curl http://localhost:8090/warnings`
3. Verifica la configuración del cliente REST en `application.properties`
4. Aumenta el timeout si es necesario

### El frontend no carga

- Verifica que el servicio parks esté ejecutándose
- Verifica que el endpoint `/q/health` responda correctamente
- Verifica la consola del navegador para errores CORS
- Verifica que las claves JWT existan (el frontend espera que `/q/health` funcione)

### Las alertas meteorológicas no funcionan

- Verifica que el servicio weather esté ejecutándose en el puerto 8090
- Verifica que Kafka esté ejecutándose (si usas Kafka)
- Verifica la configuración del cliente REST en `application.properties`
- Verifica los logs para ver si hay errores de conexión o deserialización

### Las pruebas fallan

- Asegúrate de que Kafka Dev Services esté deshabilitado para el perfil de prueba
- Verifica que la base de datos de prueba esté configurada correctamente
- Verifica que `import.sql` tenga el formato correcto (status = 0 para OPEN)

## Conclusión

Este proyecto final integra múltiples conceptos de Quarkus:
- REST APIs
- Persistencia con Hibernate ORM y Panache
- Integración de microservicios con REST clients
- Tolerancia a fallos
- Seguridad con JWT
- Programación reactiva
- Mensajería con Kafka
- Métricas con Micrometer
- OpenAPI y Swagger UI

¡Felicitaciones por completar el proyecto final!

