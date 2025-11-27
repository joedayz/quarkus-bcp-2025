# LAB 5.5: QUARKUS DEVELOP REVIEW

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

En este laboratorio aprenderás a:
- Convertir una aplicación REST simple a una aplicación con persistencia usando Hibernate ORM con Panache
- Implementar paginación y ordenamiento en endpoints REST
- Configurar y usar PostgreSQL como base de datos
- Implementar operaciones CRUD completas con Panache
- Usar transacciones en operaciones de escritura

## 1. Cargar en su IDE el proyecto 04-develop-review-start

Abre el proyecto en tu IDE preferido. El proyecto contiene:
- `Speaker`: Modelo de datos simple (sin persistencia)
- `SpeakerResource`: Recurso REST básico (sin paginación ni persistencia)
- `SpeakerResourceTest`: Tests que definen el comportamiento esperado

## 2. Examinar la estructura del proyecto

### 2.1. Clase Speaker

La clase `Speaker` actualmente es un POJO simple sin persistencia:

```java
public class Speaker {
    public String id = UUID.randomUUID().toString();
    public String name;
    public String organization;
}
```

### 2.2. Clase SpeakerResource

El `SpeakerResource` tiene métodos básicos pero no implementa:
- Paginación
- Ordenamiento
- Persistencia en base de datos
- Endpoint DELETE

## 3. Agregar dependencias de Hibernate ORM con Panache

### 3.1. Abre el archivo `pom.xml`

Ubicado en: `develop-review/pom.xml`

### 3.2. Agrega las dependencias necesarias

Agrega las siguientes dependencias dentro de la sección `<dependencies>`:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-orm-panache</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-jdbc-postgresql</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-orm</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-smallrye-openapi</artifactId>
</dependency>
```

**NOTA:** Asegúrate de que las dependencias estén dentro de la sección `<dependencies>` y no dentro de `<dependencyManagement>`.

## 4. Configurar PostgreSQL

### 4.1. Iniciar PostgreSQL usando Docker

#### Linux/Mac

```bash
docker run -d \
  --name dev-postgres \
  -e POSTGRES_USER=developer \
  -e POSTGRES_PASSWORD=developer \
  -e POSTGRES_DB=testing \
  -p 5432:5432 \
  postgres:15
```

#### Windows (CMD)

```cmd
docker run -d --name dev-postgres -e POSTGRES_USER=developer -e POSTGRES_PASSWORD=developer -e POSTGRES_DB=testing -p 5432:5432 postgres:15
```

#### Windows (PowerShell)

```powershell
docker run -d `
  --name dev-postgres `
  -e POSTGRES_USER=developer `
  -e POSTGRES_PASSWORD=developer `
  -e POSTGRES_DB=testing `
  -p 5432:5432 `
  postgres:15
```

### 4.2. Alternativa usando Podman

#### Linux/Mac

```bash
podman run -d \
  --name dev-postgres \
  -e POSTGRES_USER=developer \
  -e POSTGRES_PASSWORD=developer \
  -e POSTGRES_DB=testing \
  -p 5432:5432 \
  postgres:15
```

#### Windows (CMD)

```cmd
podman run -d --name dev-postgres -e POSTGRES_USER=developer -e POSTGRES_PASSWORD=developer -e POSTGRES_DB=testing -p 5432:5432 postgres:15
```

#### Windows (PowerShell)

```powershell
podman run -d `
  --name dev-postgres `
  -e POSTGRES_USER=developer `
  -e POSTGRES_PASSWORD=developer `
  -e POSTGRES_DB=testing `
  -p 5432:5432 `
  postgres:15
```

### 4.3. Verificar que PostgreSQL esté corriendo

#### Linux/Mac/Windows (CMD)

```bash
docker ps | grep postgres
```

#### Windows (PowerShell)

```powershell
docker ps | Select-String postgres
```

O usando Podman:

#### Linux/Mac/Windows (CMD)

```bash
podman ps | grep postgres
```

#### Windows (PowerShell)

```powershell
podman ps | Select-String postgres
```

## 5. Configurar application.properties

### 5.1. Abre el archivo `application.properties`

Ubicado en: `develop-review/src/main/resources/application.properties`

### 5.2. Agrega la configuración de PostgreSQL

Agrega las siguientes propiedades:

```properties
%dev.quarkus.datasource.jdbc.url = jdbc:postgresql://localhost:5432/testing
%dev.quarkus.datasource.username = developer
%dev.quarkus.datasource.password = developer
%dev.quarkus.hibernate-orm.database.generation = drop-and-create
```

**NOTA:** El prefijo `%dev` indica que estas propiedades solo se aplican en el perfil de desarrollo.

## 6. Crear la entidad Talk

### 6.1. Crea la clase `Talk.java`

Crea un nuevo archivo en: `develop-review/src/main/java/com/bcp/training/speaker/Talk.java`

### 6.2. Implementa la entidad Talk

```java
package com.bcp.training.speaker;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

import jakarta.persistence.Entity;

@Entity
public class Talk extends PanacheEntity {
    public String title;
    public int duration;
}
```

## 7. Convertir Speaker a entidad JPA con Panache

### 7.1. Abre la clase `Speaker.java`

Ubicada en: `develop-review/src/main/java/com/bcp/training/speaker/Speaker.java`

### 7.2. Convierte Speaker a entidad JPA

Reemplaza el contenido completo con:

```java
package com.bcp.training.speaker;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import java.util.List;

@Entity
public class Speaker extends PanacheEntity {
    public String name;
    public String organization;

    @OneToMany(cascade = CascadeType.ALL)
    public List<Talk> talks;
}
```

**NOTA:** 
- `PanacheEntity` proporciona automáticamente un campo `id` de tipo `Long`
- La relación `@OneToMany` permite que un Speaker tenga múltiples Talks
- `CascadeType.ALL` permite que las operaciones se propaguen a los Talks relacionados

## 8. Actualizar SpeakerResource para usar Panache

### 8.1. Abre la clase `SpeakerResource.java`

Ubicada en: `develop-review/src/main/java/com/bcp/training/speaker/SpeakerResource.java`

### 8.2. Actualiza los imports

Agrega los siguientes imports:

```java
import io.quarkus.panache.common.Sort;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.headers.Header;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
```

### 8.3. Actualiza el método `getSpeakers()`

Reemplaza el método `getSpeakers()` con:

```java
@GET
@Operation(summary = "Retrieves the list of speakers")
@APIResponse(responseCode = "200")
public List<Speaker> getSpeakers(
        @DefaultValue("id") @QueryParam("sortBy") String sortBy,
        @DefaultValue("0") @QueryParam("pageIndex") int pageIndex,
        @DefaultValue("25") @QueryParam("pageSize") int pageSize
) {
    return Speaker
            .findAll(Sort.by(filterSortBy(sortBy)))
            .page(pageIndex, pageSize)
            .list();
}
```

**NOTA:** 
- `@QueryParam` permite recibir parámetros de consulta desde la URL
- `@DefaultValue` establece valores por defecto si no se proporcionan
- `Sort.by()` crea un objeto de ordenamiento para Panache
- `.page()` implementa la paginación

### 8.4. Actualiza el método `createSpeaker()`

Agrega las anotaciones `@Transactional` y `@Operation`, y actualiza el método:

```java
@POST
@Transactional
@Operation(summary = "Adds a speaker")
@APIResponse(
        responseCode = "201",
        headers = {
                @Header(
                        name = "id",
                        description = "ID of the created entity",
                        schema = @Schema(implementation = Integer.class)
                ),
                @Header(
                        name = "location",
                        description = "URI of the created entity",
                        schema = @Schema(implementation = String.class)
                ),
        },
        description = "Entity successfully created"
)
public Response createSpeaker(Speaker newSpeaker, @Context UriInfo uriInfo) {
    newSpeaker.persist();

    return Response.created(generateUriForSpeaker(newSpeaker, uriInfo))
            .header("id", newSpeaker.id)
            .build();
}
```

**NOTA:** 
- `@Transactional` es necesario para operaciones de escritura
- `persist()` es un método de Panache que guarda la entidad en la base de datos
- El `id` ahora es de tipo `Long` (proporcionado por `PanacheEntity`)

### 8.5. Actualiza el método `generateUriForSpeaker()`

Actualiza el método para usar el nuevo tipo de `id`:

```java
private URI generateUriForSpeaker(Speaker speaker, UriInfo uriInfo) {
    return uriInfo.getAbsolutePathBuilder().path("/{id}").build(speaker.id);
}
```

### 8.6. Implementa el método `deleteSpeaker()`

Agrega el siguiente método después de `createSpeaker()`:

```java
@DELETE
@Path("/{id}")
@Transactional
public void deleteSpeaker(@PathParam("id") Long id) {
    if (!Speaker.deleteById(id)) {
        throw new NotFoundException();
    }
}
```

**NOTA:** 
- `@Path("/{id}")` define el parámetro de ruta
- `@PathParam("id")` inyecta el valor del parámetro de ruta
- `deleteById()` retorna `true` si se eliminó, `false` si no existe
- `NotFoundException` retorna un 404 si el recurso no existe

### 8.7. Elimina el campo `speakers`

Elimina la línea:
```java
List<Speaker> speakers = new ArrayList<>();
```

Ya no es necesaria porque Panache maneja la persistencia.

## 9. Verificar la implementación completa

Tu `SpeakerResource` debería verse así:

```java
package com.bcp.training.speaker;

import io.quarkus.panache.common.Sort;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.headers.Header;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import java.net.URI;
import java.util.List;

@Path("/speakers")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class SpeakerResource {

    @GET
    @Operation(summary = "Retrieves the list of speakers")
    @APIResponse(responseCode = "200")
    public List<Speaker> getSpeakers(
            @DefaultValue("id") @QueryParam("sortBy") String sortBy,
            @DefaultValue("0") @QueryParam("pageIndex") int pageIndex,
            @DefaultValue("25") @QueryParam("pageSize") int pageSize
    ) {
        return Speaker
                .findAll(Sort.by(filterSortBy(sortBy)))
                .page(pageIndex, pageSize)
                .list();
    }

    @POST
    @Transactional
    @Operation(summary = "Adds a speaker")
    @APIResponse(
            responseCode = "201",
            headers = {
                    @Header(
                            name = "id",
                            description = "ID of the created entity",
                            schema = @Schema(implementation = Integer.class)
                    ),
                    @Header(
                            name = "location",
                            description = "URI of the created entity",
                            schema = @Schema(implementation = String.class)
                    ),
            },
            description = "Entity successfully created"
    )
    public Response createSpeaker(Speaker newSpeaker, @Context UriInfo uriInfo) {
        newSpeaker.persist();

        return Response.created(generateUriForSpeaker(newSpeaker, uriInfo))
                .header("id", newSpeaker.id)
                .build();
    }

    @DELETE
    @Path("/{id}")
    @Transactional
    public void deleteSpeaker(@PathParam("id") Long id) {
        if (!Speaker.deleteById(id)) {
            throw new NotFoundException();
        }
    }

    private URI generateUriForSpeaker(Speaker speaker, UriInfo uriInfo) {
        return uriInfo.getAbsolutePathBuilder().path("/{id}").build(speaker.id);
    }

    private String filterSortBy(String sortBy) {
        if (!sortBy.equals("id") && !sortBy.equals("name")){
            return "id";
        }

        return sortBy;
    }
}
```

## 10. Ejecutar los tests

### 10.1. Navega al directorio del proyecto

#### Linux/Mac

```bash
cd develop-review
```

#### Windows (CMD)

```cmd
cd develop-review
```

#### Windows (PowerShell)

```powershell
cd develop-review
```

### 10.2. Ejecuta los tests

#### Linux/Mac/Windows (CMD)

```bash
mvn test
```

#### Windows (PowerShell)

```powershell
mvn test
```

**O usando el wrapper de Maven:**

#### Linux/Mac

```bash
./mvnw test
```

#### Windows (CMD)

```cmd
mvnw.cmd test
```

#### Windows (PowerShell)

```powershell
.\mvnw.cmd test
```

**Resultado esperado:** Todos los tests deberían pasar.

## 11. Ejecutar la aplicación en modo desarrollo

### 11.1. Inicia la aplicación

#### Linux/Mac

```bash
mvn quarkus:dev
```

#### Windows (CMD)

```cmd
mvn quarkus:dev
```

#### Windows (PowerShell)

```powershell
mvn quarkus:dev
```

**O usando el wrapper de Maven:**

#### Linux/Mac

```bash
./mvnw quarkus:dev
```

#### Windows (CMD)

```cmd
mvnw.cmd quarkus:dev
```

#### Windows (PowerShell)

```powershell
.\mvnw.cmd quarkus:dev
```

### 11.2. Verifica que la aplicación esté corriendo

Abre tu navegador y visita:
- **Swagger UI**: http://localhost:8080/q/swagger-ui
- **OpenAPI JSON**: http://localhost:8080/q/openapi
- **Dev UI**: http://localhost:8080/q/dev/

## 12. Probar los endpoints

### 12.1. Crear un speaker

#### Linux/Mac

```bash
curl -X POST http://localhost:8080/speakers \
  -H "Content-Type: application/json" \
  -d '{"name":"Pablo","organization":"Red Hat","talks":[{"title":"Lorem ipsum dolor sit amet","duration":15}]}'
```

#### Windows (CMD)

```cmd
curl -X POST http://localhost:8080/speakers -H "Content-Type: application/json" -d "{\"name\":\"Pablo\",\"organization\":\"Red Hat\",\"talks\":[{\"title\":\"Lorem ipsum dolor sit amet\",\"duration\":15}]}"
```

#### Windows (PowerShell)

```powershell
$body = @{
    name = "Pablo"
    organization = "Red Hat"
    talks = @(
        @{
            title = "Lorem ipsum dolor sit amet"
            duration = 15
        }
    )
} | ConvertTo-Json -Depth 3

Invoke-WebRequest -Uri http://localhost:8080/speakers -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

### 12.2. Listar speakers con ordenamiento

#### Linux/Mac

```bash
curl "http://localhost:8080/speakers?sortBy=name"
```

#### Windows (CMD)

```cmd
curl "http://localhost:8080/speakers?sortBy=name"
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/speakers?sortBy=name" -Method GET | Select-Object -ExpandProperty Content
```

### 12.3. Listar speakers con paginación

#### Linux/Mac

```bash
curl "http://localhost:8080/speakers?pageSize=1&pageIndex=0"
```

#### Windows (CMD)

```cmd
curl "http://localhost:8080/speakers?pageSize=1&pageIndex=0"
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/speakers?pageSize=1&pageIndex=0" -Method GET | Select-Object -ExpandProperty Content
```

### 12.4. Eliminar un speaker

#### Linux/Mac

```bash
curl -X DELETE http://localhost:8080/speakers/1
```

#### Windows (CMD)

```cmd
curl -X DELETE http://localhost:8080/speakers/1
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/speakers/1 -Method DELETE
```

## 13. Construir y ejecutar la aplicación empaquetada (Opcional)

### 13.1. Construir la aplicación

#### Linux/Mac

```bash
mvn clean package
```

#### Windows (CMD)

```cmd
mvn clean package
```

#### Windows (PowerShell)

```powershell
mvn clean package
```

### 13.2. Ejecutar la aplicación empaquetada

#### Linux/Mac

```bash
java -jar target/quarkus-app/quarkus-run.jar
```

#### Windows (CMD)

```cmd
java -jar target\quarkus-app\quarkus-run.jar
```

#### Windows (PowerShell)

```powershell
java -jar target\quarkus-app\quarkus-run.jar
```

## 14. Construir imagen de contenedor (Opcional)

### 14.1. Construir la imagen JVM

#### Linux/Mac

```bash
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (CMD)

```cmd
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (PowerShell)

```powershell
mvn clean package -Dquarkus.container-image.build=true
```

### 14.2. Ejecutar el contenedor

#### Linux/Mac

```bash
docker run -i --rm -p 8080:8080 \
  -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://host.docker.internal:5432/testing \
  -e QUARKUS_DATASOURCE_USERNAME=developer \
  -e QUARKUS_DATASOURCE_PASSWORD=developer \
  quarkus/develop-review-jvm:1.0.0-SNAPSHOT
```

#### Windows (CMD)

```cmd
docker run -i --rm -p 8080:8080 -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://host.docker.internal:5432/testing -e QUARKUS_DATASOURCE_USERNAME=developer -e QUARKUS_DATASOURCE_PASSWORD=developer quarkus/develop-review-jvm:1.0.0-SNAPSHOT
```

#### Windows (PowerShell)

```powershell
docker run -i --rm -p 8080:8080 `
  -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://host.docker.internal:5432/testing `
  -e QUARKUS_DATASOURCE_USERNAME=developer `
  -e QUARKUS_DATASOURCE_PASSWORD=developer `
  quarkus/develop-review-jvm:1.0.0-SNAPSHOT
```

**NOTA:** Asegúrate de que PostgreSQL esté accesible desde el contenedor. En Windows/Mac, `host.docker.internal` apunta al host. En Linux, puede que necesites usar la IP del host o una red compartida.

## Resumen

En este laboratorio has aprendido a:
- ✅ Convertir un POJO simple a una entidad JPA usando Panache
- ✅ Configurar PostgreSQL como base de datos
- ✅ Implementar paginación y ordenamiento en endpoints REST
- ✅ Usar transacciones para operaciones de escritura
- ✅ Implementar operaciones CRUD completas con Panache
- ✅ Crear relaciones entre entidades JPA
- ✅ Usar anotaciones de OpenAPI para documentar la API

## Próximos pasos

- Explora más características de Panache como queries personalizadas
- Implementa validación usando Bean Validation
- Agrega manejo de excepciones personalizado
- Implementa filtros y búsqueda avanzada
- Explora las características de Hibernate ORM

---

**Enjoy!**

**Joe**

