# LAB 5.5: QUARKUS DEVELOP REVIEW - SOLUCIÓN

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

Este documento contiene la solución completa del laboratorio de desarrollo y revisión de Quarkus. Aquí encontrarás:
- La implementación completa de todas las funcionalidades
- Explicaciones detalladas de cada paso
- Mejores prácticas y recomendaciones

## Estructura de la Solución

### 1. Dependencias en pom.xml

El archivo `pom.xml` incluye todas las dependencias necesarias:

```xml
<dependencies>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-rest</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-rest-jsonb</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-smallrye-openapi</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-arc</artifactId>
    </dependency>
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
    <!-- Dependencias de test -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-jdbc-h2</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-junit5</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 2. Configuración de application.properties

```properties
%dev.quarkus.datasource.jdbc.url = jdbc:postgresql://localhost:5432/testing
%dev.quarkus.datasource.username = developer
%dev.quarkus.datasource.password = developer
%dev.quarkus.hibernate-orm.database.generation = drop-and-create
```

**Explicación:**
- `%dev` indica que estas propiedades solo se aplican en modo desarrollo
- `drop-and-create` recrea el esquema de base de datos en cada inicio (útil para desarrollo)
- En producción, usar `none` o `validate`

### 3. Entidad Talk

**Archivo:** `src/main/java/com/bcp/training/speaker/Talk.java`

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

**Características:**
- Extiende `PanacheEntity` para obtener funcionalidad de Panache
- `@Entity` marca la clase como entidad JPA
- `PanacheEntity` proporciona automáticamente un campo `id` de tipo `Long`

### 4. Entidad Speaker

**Archivo:** `src/main/java/com/bcp/training/speaker/Speaker.java`

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

**Características:**
- Relación `@OneToMany` con `Talk`
- `CascadeType.ALL` permite que las operaciones se propaguen a los Talks relacionados
- Cuando se elimina un Speaker, se eliminan automáticamente sus Talks

### 5. SpeakerResource Completo

**Archivo:** `src/main/java/com/bcp/training/speaker/SpeakerResource.java`

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

**Explicación de métodos:**

#### getSpeakers()
- Usa `Speaker.findAll()` para obtener todos los speakers
- `Sort.by()` crea un objeto de ordenamiento
- `.page(pageIndex, pageSize)` implementa paginación
- `.list()` ejecuta la query y retorna los resultados

#### createSpeaker()
- `@Transactional` es necesario para operaciones de escritura
- `persist()` guarda la entidad en la base de datos
- Retorna un `201 Created` con headers `id` y `location`

#### deleteSpeaker()
- `deleteById()` retorna `true` si se eliminó, `false` si no existe
- Lanza `NotFoundException` (404) si el recurso no existe
- `@Transactional` asegura que la operación sea atómica

## Configuración de PostgreSQL

### Iniciar PostgreSQL con Docker

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

### Iniciar PostgreSQL con Podman

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

### Verificar que PostgreSQL esté corriendo

#### Docker - Linux/Mac/Windows (CMD)

```bash
docker ps | grep postgres
```

#### Docker - Windows (PowerShell)

```powershell
docker ps | Select-String postgres
```

#### Podman - Linux/Mac/Windows (CMD)

```bash
podman ps | grep postgres
```

#### Podman - Windows (PowerShell)

```powershell
podman ps | Select-String postgres
```

### Detener y eliminar el contenedor (si es necesario)

#### Docker - Linux/Mac

```bash
docker stop dev-postgres
docker rm dev-postgres
```

#### Docker - Windows (CMD)

```cmd
docker stop dev-postgres
docker rm dev-postgres
```

#### Docker - Windows (PowerShell)

```powershell
docker stop dev-postgres
docker rm dev-postgres
```

#### Podman - Linux/Mac

```bash
podman stop dev-postgres
podman rm dev-postgres
```

#### Podman - Windows (CMD)

```cmd
podman stop dev-postgres
podman rm dev-postgres
```

#### Podman - Windows (PowerShell)

```powershell
podman stop dev-postgres
podman rm dev-postgres
```

## Ejecutar la Aplicación

### Modo Desarrollo

#### Linux/Mac

```bash
cd develop-review
mvn quarkus:dev
```

#### Windows (CMD)

```cmd
cd develop-review
mvn quarkus:dev
```

#### Windows (PowerShell)

```powershell
cd develop-review
mvn quarkus:dev
```

**O usando el wrapper de Maven:**

#### Linux/Mac

```bash
cd develop-review
./mvnw quarkus:dev
```

#### Windows (CMD)

```cmd
cd develop-review
mvnw.cmd quarkus:dev
```

#### Windows (PowerShell)

```powershell
cd develop-review
.\mvnw.cmd quarkus:dev
```

### Ejecutar Tests

#### Linux/Mac/Windows (CMD)

```bash
mvn test
```

#### Windows (PowerShell)

```powershell
mvn test
```

**O usando el wrapper:**

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

## Probar los Endpoints

### 1. Crear un Speaker

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

### 2. Listar Speakers (ordenamiento por defecto - id)

#### Linux/Mac/Windows (CMD)

```bash
curl http://localhost:8080/speakers
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/speakers -Method GET | Select-Object -ExpandProperty Content
```

### 3. Listar Speakers ordenados por nombre

#### Linux/Mac/Windows (CMD)

```bash
curl "http://localhost:8080/speakers?sortBy=name"
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/speakers?sortBy=name" -Method GET | Select-Object -ExpandProperty Content
```

### 4. Listar Speakers con paginación

#### Linux/Mac/Windows (CMD)

```bash
curl "http://localhost:8080/speakers?pageSize=1&pageIndex=0"
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/speakers?pageSize=1&pageIndex=0" -Method GET | Select-Object -ExpandProperty Content
```

### 5. Eliminar un Speaker

#### Linux/Mac/Windows (CMD)

```bash
curl -X DELETE http://localhost:8080/speakers/1
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/speakers/1 -Method DELETE
```

## Construir y Ejecutar

### Construir la aplicación

#### Linux/Mac/Windows (CMD)

```bash
mvn clean package
```

#### Windows (PowerShell)

```powershell
mvn clean package
```

### Ejecutar la aplicación empaquetada

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

## Construir Imagen de Contenedor

### Construir imagen JVM

#### Linux/Mac/Windows (CMD)

```bash
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (PowerShell)

```powershell
mvn clean package -Dquarkus.container-image.build=true
```

### Ejecutar contenedor con Docker

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

### Ejecutar contenedor con Podman

#### Linux/Mac

```bash
podman run -i --rm -p 8080:8080 \
  -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://host.containers.internal:5432/testing \
  -e QUARKUS_DATASOURCE_USERNAME=developer \
  -e QUARKUS_DATASOURCE_PASSWORD=developer \
  quarkus/develop-review-jvm:1.0.0-SNAPSHOT
```

#### Windows (CMD)

```cmd
podman run -i --rm -p 8080:8080 -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://host.containers.internal:5432/testing -e QUARKUS_DATASOURCE_USERNAME=developer -e QUARKUS_DATASOURCE_PASSWORD=developer quarkus/develop-review-jvm:1.0.0-SNAPSHOT
```

#### Windows (PowerShell)

```powershell
podman run -i --rm -p 8080:8080 `
  -e QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://host.containers.internal:5432/testing `
  -e QUARKUS_DATASOURCE_USERNAME=developer `
  -e QUARKUS_DATASOURCE_PASSWORD=developer `
  quarkus/develop-review-jvm:1.0.0-SNAPSHOT
```

**NOTA:** 
- En Docker, usa `host.docker.internal` para acceder al host desde el contenedor
- En Podman, usa `host.containers.internal` (o la IP del host en Linux)
- Asegúrate de que PostgreSQL esté accesible desde el contenedor

## Mejores Prácticas Implementadas

1. **Uso de Panache**: Simplifica el acceso a datos y reduce código boilerplate
2. **Transacciones**: Todas las operaciones de escritura están marcadas con `@Transactional`
3. **Validación de entrada**: El método `filterSortBy()` valida y sanitiza los parámetros de ordenamiento
4. **Códigos HTTP apropiados**: 
   - `201 Created` para creación exitosa
   - `204 No Content` para eliminación exitosa
   - `404 Not Found` para recursos no encontrados
5. **Documentación OpenAPI**: Los endpoints están documentados con anotaciones de MicroProfile OpenAPI
6. **Paginación**: Implementada para evitar cargar grandes cantidades de datos
7. **Relaciones JPA**: Uso correcto de `@OneToMany` con cascadas apropiadas

## Puntos Clave de Aprendizaje

1. **PanacheEntity vs PanacheEntityBase**: 
   - `PanacheEntity` proporciona un `id` de tipo `Long` automáticamente
   - `PanacheEntityBase` requiere definir tu propio `id`

2. **Paginación en Panache**:
   - `.page(pageIndex, pageSize)` implementa paginación
   - El índice de página comienza en 0

3. **Ordenamiento en Panache**:
   - `Sort.by("fieldName")` ordena ascendente
   - `Sort.by("fieldName", Sort.Direction.Descending)` ordena descendente

4. **Transacciones**:
   - `@Transactional` es necesario para `persist()`, `delete()`, `update()`
   - Las operaciones de lectura no requieren transacciones

5. **Relaciones JPA**:
   - `CascadeType.ALL` propaga todas las operaciones
   - Útil cuando los objetos hijos no tienen sentido sin el padre

## Troubleshooting

### Error: "No suitable driver found"

**Solución:** Verifica que la dependencia `quarkus-jdbc-postgresql` esté en el `pom.xml`

### Error: "Connection refused"

**Solución:** 
- Verifica que PostgreSQL esté corriendo: `docker ps | grep postgres` o `podman ps | grep postgres`
- Verifica que el puerto 5432 esté disponible
- Verifica las credenciales en `application.properties`

### Error: "Table does not exist"

**Solución:** 
- Verifica que `quarkus.hibernate-orm.database.generation = drop-and-create` esté configurado
- Reinicia la aplicación para que Hibernate cree las tablas

### Tests fallan

**Solución:**
- Los tests usan H2 en memoria, no PostgreSQL
- Verifica que la dependencia `quarkus-jdbc-h2` esté en el scope `test`
- Los tests deberían pasar sin necesidad de PostgreSQL corriendo

---

**Enjoy!**

**Joe**

