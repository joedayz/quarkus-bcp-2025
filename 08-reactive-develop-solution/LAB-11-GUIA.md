# LAB 11 - Quarkus Reactive Develop - Guía Paso a Paso

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Configuración Inicial del Proyecto](#configuración-inicial-del-proyecto)
3. [Agregar Extensiones de Quarkus](#agregar-extensiones-de-quarkus)
4. [Configurar Base de Datos](#configurar-base-de-datos)
5. [Implementar Endpoints Reactivos](#implementar-endpoints-reactivos)
6. [Ejecutar la Aplicación](#ejecutar-la-aplicación)
7. [Probar los Endpoints](#probar-los-endpoints)
8. [Ejecutar Tests](#ejecutar-tests)
9. [Construir y Ejecutar con Docker](#construir-y-ejecutar-con-docker)
10. [Construir y Ejecutar con Podman](#construir-y-ejecutar-con-podman)
11. [Solución de Problemas](#solución-de-problemas)

---

## 📦 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- **Java 21** o superior
- **Maven 3.8+** (o usar el wrapper incluido)
- **Docker** o **Podman** (para ejecutar PostgreSQL)
- **Git** (opcional, para clonar el repositorio)

### Verificar Instalaciones

#### Linux / macOS:
```bash
java -version
mvn -version
docker --version
# o
podman --version
```

#### Windows (PowerShell):
```powershell
java -version
mvn -version
docker --version
# o
podman --version
```

#### Windows (CMD):
```cmd
java -version
mvn -version
docker --version
# o
podman --version
```

---

## 🚀 Configuración Inicial del Proyecto

### Paso 1: Navegar al Directorio del Proyecto

#### Linux / macOS:
```bash
cd ~/08-reactive-develop-start/suggestions
```

#### Windows (PowerShell):
```powershell
cd 08-reactive-develop-start\suggestions
```

#### Windows (CMD):
```cmd
cd 08-reactive-develop-start\suggestions
```

### Paso 2: Verificar Estructura del Proyecto

#### Linux / macOS / Windows (PowerShell):
```bash
ls -la
# o en PowerShell:
Get-ChildItem
```

#### Windows (CMD):
```cmd
dir
```

Deberías ver archivos como `pom.xml`, `mvnw`, `mvnw.cmd`, y el directorio `src/`.

---

## 🔌 Agregar Extensiones de Quarkus

Necesitamos agregar las extensiones de Hibernate Reactive Panache y el cliente reactivo de PostgreSQL.

### Paso 3: Agregar Extensiones

#### Linux / macOS:
```bash
./mvnw quarkus:add-extension -Dextensions="hibernate-reactive-panache,reactive-pg-client"
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd quarkus:add-extension -Dextensions="hibernate-reactive-panache,reactive-pg-client"
```

#### Windows (CMD):
```cmd
mvnw.cmd quarkus:add-extension -Dextensions="hibernate-reactive-panache,reactive-pg-client"
```

**Nota:** Si tienes Maven instalado globalmente, puedes usar `mvn` en lugar de `./mvnw` o `.\mvnw.cmd`.

**Salida esperada:**
```
[INFO] ✅ Extension io.quarkus:quarkus-hibernate-reactive-panache has been installed
[INFO] ✅ Extension io.quarkus:quarkus-reactive-pg-client has been installed
```

### Paso 4: Verificar que las Extensiones se Agregaron

Abre el archivo `pom.xml` y verifica que se agregaron las dependencias:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-reactive-panache</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-reactive-pg-client</artifactId>
</dependency>
```

---

## 🗄️ Configurar Base de Datos

### Paso 5: Configurar PostgreSQL en application.properties

Edita el archivo `src/main/resources/application.properties`:

#### Opción 1: Usar imagen pública de PostgreSQL

```properties
quarkus.datasource.devservices.image-name=postgres:14.1
```


**Nota:** Si estás en un entorno corporativo con registro privado, usa la Opción 2. De lo contrario, usa la Opción 1.

### Paso 6: Verificar Configuración

#### Linux / macOS:
```bash
cat src/main/resources/application.properties
```

#### Windows (PowerShell):
```powershell
Get-Content src/main/resources/application.properties
```

#### Windows (CMD):
```cmd
type src/main/resources/application.properties
```

---

## 💻 Implementar Endpoints Reactivos

### Paso 7: Revisar la Entidad Suggestion

Abre el archivo `src/main/java/com/bcp/training/Suggestion.java` y verifica que tenga la siguiente estructura:

```java
package com.bcp.training;

import io.quarkus.hibernate.reactive.panache.PanacheEntity;
import jakarta.persistence.Entity;

@Entity
public class Suggestion extends PanacheEntity {
    public Long clientId;
    public Long itemId;

    public Suggestion() {
    }

    public Suggestion(Long clientId, Long itemId) {
        this.clientId = clientId;
        this.itemId = itemId;
    }
}
```

**Nota:** Asegúrate de que la clase extienda `PanacheEntity` y tenga la anotación `@Entity`.

### Paso 8: Implementar Endpoints en SuggestionResource

Abre el archivo `src/main/java/com/bcp/training/SuggestionResource.java` y agrega los siguientes métodos:

#### 8.1: Agregar Imports Necesarios

Al inicio del archivo, agrega estos imports:

```java
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.Multi;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import io.quarkus.hibernate.reactive.panache.Panache;
```

#### 8.2: Implementar Endpoint POST (Crear Sugerencia)

Agrega este método dentro de la clase `SuggestionResource`:

```java
@POST
public Uni<Suggestion> create(Suggestion newSuggestion) {
    return Panache.withTransaction(newSuggestion::persist);
}
```

#### 8.3: Implementar Endpoint GET por ID

Agrega este método:

```java
@GET
@Path("/{id}")
public Uni<Suggestion> get(Long id) {
    return Suggestion.findById(id);
}
```

#### 8.4: Implementar Endpoint GET para Listar Todas

Agrega este método:

```java
@GET
public Multi<Suggestion> list() {
    return Suggestion.streamAll();
}
```

### Paso 9: Verificar el Código Completo

El archivo `SuggestionResource.java` completo debería verse así:

```java
package com.bcp.training;

import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.Multi;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import io.quarkus.hibernate.reactive.panache.Panache;

@Path("/suggestion")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SuggestionResource {

    @POST
    public Uni<Suggestion> create(Suggestion newSuggestion) {
        return Panache.withTransaction(newSuggestion::persist);
    }

    @GET
    @Path("/{id}")
    public Uni<Suggestion> get(Long id) {
        return Suggestion.findById(id);
    }

    @GET
    public Multi<Suggestion> list() {
        return Suggestion.streamAll();
    }

    @DELETE
    public Uni<Long> deleteAll() {
        return Suggestion.deleteAll();
    }
}
```

---

## 🏃 Ejecutar la Aplicación

### Paso 10: Iniciar la Aplicación en Modo Desarrollo

El modo desarrollo incluye recarga automática de código y Dev Services que automáticamente inicia PostgreSQL en un contenedor.

#### Linux / macOS:
```bash
./mvnw quarkus:dev
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd quarkus:dev
```

#### Windows (CMD):
```cmd
mvnw.cmd quarkus:dev
```

**Salida esperada:**
```
__  ____  __  _____   ___  __ ____  ______ 
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/ 
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \   
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/   
2024-XX-XX XX:XX:XX,XXX INFO  [io.quarkus] (main) suggestions 1.0.0-SNAPSHOT on JVM
...
Listening on: http://localhost:8080
```

**Nota:** La primera vez que ejecutes, Quarkus descargará la imagen de PostgreSQL y creará el contenedor automáticamente.

### Paso 11: Verificar que la Aplicación Está Corriendo

Abre tu navegador o usa curl:

#### Linux / macOS:
```bash
curl http://localhost:8080/suggestion
```

#### Windows (PowerShell):
```powershell
Invoke-WebRequest -Uri http://localhost:8080/suggestion -Method GET
```

#### Windows (CMD):
```cmd
curl http://localhost:8080/suggestion
```

Deberías recibir una respuesta vacía `[]` o un array vacío, lo cual es correcto si no hay sugerencias.

---

## 🧪 Probar los Endpoints

### Paso 12: Crear una Sugerencia

#### Linux / macOS:
```bash
curl -X POST http://localhost:8080/suggestion \
  -H "Content-Type: application/json" \
  -d '{"clientId": 1, "itemId": 103}'
```

#### Windows (PowerShell):
```powershell
$body = @{
    clientId = 1
    itemId = 103
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/suggestion `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

#### Windows (CMD):
```cmd
curl -X POST http://localhost:8080/suggestion -H "Content-Type: application/json" -d "{\"clientId\": 1, \"itemId\": 103}"
```

**Respuesta esperada:**
```json
{
  "id": 1,
  "clientId": 1,
  "itemId": 103
}
```

### Paso 13: Obtener una Sugerencia por ID

#### Linux / macOS:
```bash
curl http://localhost:8080/suggestion/1
```

#### Windows (PowerShell):
```powershell
Invoke-WebRequest -Uri http://localhost:8080/suggestion/1 -Method GET
```

#### Windows (CMD):
```cmd
curl http://localhost:8080/suggestion/1
```

**Respuesta esperada:**
```json
{
  "id": 1,
  "clientId": 1,
  "itemId": 103
}
```

### Paso 14: Listar Todas las Sugerencias

#### Linux / macOS:
```bash
curl http://localhost:8080/suggestion
```

#### Windows (PowerShell):
```powershell
Invoke-WebRequest -Uri http://localhost:8080/suggestion -Method GET
```

#### Windows (CMD):
```cmd
curl http://localhost:8080/suggestion
```

**Respuesta esperada:**
```json
[
  {
    "id": 1,
    "clientId": 1,
    "itemId": 103
  }
]
```

### Paso 15: Eliminar Todas las Sugerencias

#### Linux / macOS:
```bash
curl -X DELETE http://localhost:8080/suggestion
```

#### Windows (PowerShell):
```powershell
Invoke-WebRequest -Uri http://localhost:8080/suggestion -Method DELETE
```

#### Windows (CMD):
```cmd
curl -X DELETE http://localhost:8080/suggestion
```

**Respuesta esperada:** Un número que indica cuántas sugerencias se eliminaron.

---

## ✅ Ejecutar Tests

### Paso 16: Ejecutar Tests Unitarios

#### Linux / macOS:
```bash
./mvnw test
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd test
```

#### Windows (CMD):
```cmd
mvnw.cmd test
```

**Salida esperada:**
```
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

### Paso 17: Ejecutar Tests en Modo Continuo

#### Linux / macOS:
```bash
./mvnw quarkus:test
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd quarkus:test
```

#### Windows (CMD):
```cmd
mvnw.cmd quarkus:test
```

Este modo ejecuta los tests automáticamente cuando detecta cambios en el código. Presiona `q` para salir.

---

## 🐳 Construir y Ejecutar con Docker

### Paso 18: Construir la Aplicación

Primero, detén la aplicación en modo desarrollo (Ctrl+C) y construye el proyecto:

#### Linux / macOS:
```bash
./mvnw clean package
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd clean package
```

#### Windows (CMD):
```cmd
mvnw.cmd clean package
```

**Nota:** Esto generará el JAR en `target/quarkus-app/`.

### Paso 19: Construir Imagen Docker (JVM)

#### Linux / macOS / Windows (PowerShell / CMD):
```bash
docker build -f src/main/docker/Dockerfile.jvm -t quarkus/suggestions-jvm .
```

**Salida esperada:**
```
[+] Building XX.XXs (XX/XX) FINISHED
 => => naming to docker.io/quarkus/suggestions-jvm
```

### Paso 20: Ejecutar Contenedor Docker

#### Linux / macOS / Windows (PowerShell / CMD):
```bash
docker run -i --rm -p 8080:8080 quarkus/suggestions-jvm
```

**Nota:** 
- `-i` = modo interactivo
- `--rm` = elimina el contenedor al detenerlo
- `-p 8080:8080` = mapea el puerto 8080 del contenedor al puerto 8080 del host

### Paso 21: Probar la Aplicación en Docker

En otra terminal, prueba los endpoints como en los Pasos 12-15.

### Paso 22: Construir Imagen Docker (Legacy JAR)

Si prefieres usar el formato legacy JAR:

#### Paso 22.1: Construir con Legacy JAR

#### Linux / macOS:
```bash
./mvnw clean package -Dquarkus.package.jar.type=legacy-jar
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd clean package -Dquarkus.package.jar.type=legacy-jar
```

#### Windows (CMD):
```cmd
mvnw.cmd clean package -Dquarkus.package.jar.type=legacy-jar
```

#### Paso 22.2: Construir Imagen

```bash
docker build -f src/main/docker/Dockerfile.legacy-jar -t quarkus/suggestions-legacy-jar .
```

#### Paso 22.3: Ejecutar Contenedor

```bash
docker run -i --rm -p 8080:8080 quarkus/suggestions-legacy-jar
```

### Paso 23: Construir Imagen Docker Nativa (Opcional)

**Advertencia:** La compilación nativa requiere más tiempo y recursos.

#### Paso 23.1: Construir Aplicación Nativa

#### Linux / macOS:
```bash
./mvnw clean package -Dnative -Dquarkus.native.container-build=true
```

#### Windows (PowerShell):
```powershell
.\mvnw.cmd clean package -Dnative -Dquarkus.native.container-build=true
```

#### Windows (CMD):
```cmd
mvnw.cmd clean package -Dnative -Dquarkus.native.container-build=true
```

**Nota:** Esto puede tardar varios minutos. La compilación nativa se ejecuta dentro de un contenedor Docker.

#### Paso 23.2: Construir Imagen Nativa

```bash
docker build -f src/main/docker/Dockerfile.native -t quarkus/suggestions-native .
```

#### Paso 23.3: Ejecutar Contenedor Nativo

```bash
docker run -i --rm -p 8080:8080 quarkus/suggestions-native
```

**Ventajas de la imagen nativa:**
- Tiempo de inicio más rápido
- Menor uso de memoria
- Imagen más pequeña

### Paso 24: Construir Imagen Docker Nativa Micro (Opcional)

Para una imagen aún más pequeña:

#### Paso 24.1: Construir Aplicación Nativa (igual que Paso 23.1)

#### Paso 24.2: Construir Imagen Micro

```bash
docker build -f src/main/docker/Dockerfile.native-micro -t quarkus/suggestions-native-micro .
```

#### Paso 24.3: Ejecutar Contenedor Micro

```bash
docker run -i --rm -p 8080:8080 quarkus/suggestions-native-micro
```

---

## 🦫 Construir y Ejecutar con Podman

Podman es una alternativa a Docker que no requiere un daemon. Los comandos son muy similares.

### Paso 25: Construir la Aplicación (igual que Paso 18)

### Paso 26: Construir Imagen Podman (JVM)

#### Linux / macOS / Windows:
```bash
podman build -f src/main/docker/Dockerfile.jvm -t quarkus/suggestions-jvm .
```

### Paso 27: Ejecutar Contenedor Podman

#### Linux / macOS / Windows:
```bash
podman run -i --rm -p 8080:8080 quarkus/suggestions-jvm
```

**Nota:** En algunos sistemas, Podman puede requerir `sudo` o configuración de rootless containers.

### Paso 28: Construir Imagen Podman Nativa

#### Paso 28.1: Construir Aplicación Nativa (igual que Paso 23.1)

#### Paso 28.2: Construir Imagen

```bash
podman build -f src/main/docker/Dockerfile.native -t quarkus/suggestions-native .
```

#### Paso 28.3: Ejecutar Contenedor

```bash
podman run -i --rm -p 8080:8080 quarkus/suggestions-native
```

### Paso 29: Verificar Contenedores Podman

#### Listar contenedores en ejecución:
```bash
podman ps
```

#### Listar imágenes:
```bash
podman images
```

#### Detener un contenedor:
```bash
podman stop <container-id>
```

#### Eliminar una imagen:
```bash
podman rmi <image-id>
```

---

## 🔧 Solución de Problemas

### Problema 1: Error "Cannot find Maven"

**Solución:** Usa el wrapper incluido (`mvnw` o `mvnw.cmd`).

#### Linux / macOS:
```bash
chmod +x mvnw
./mvnw --version
```

#### Windows:
El archivo `mvnw.cmd` debería funcionar directamente.

### Problema 2: Puerto 8080 ya está en uso

**Solución:** Cambia el puerto en `application.properties`:

```properties
quarkus.http.port=8081
```

Luego actualiza las URLs de los endpoints a `http://localhost:8081`.

### Problema 3: Error de conexión a la base de datos

**Solución 1:** Verifica que Docker/Podman esté ejecutándose:

#### Docker:
```bash
docker ps
```

#### Podman:
```bash
podman ps
```

**Solución 2:** Verifica la configuración en `application.properties`:

```properties
quarkus.datasource.devservices.image-name=postgres:14.1
```

**Solución 3:** Si estás usando un registro privado, asegúrate de estar autenticado:

#### Docker:
```bash
docker login registry.ocp4.example.com:8443
```

#### Podman:
```bash
podman login registry.ocp4.example.com:8443
```

### Problema 4: Error al compilar nativo

**Solución 1:** Asegúrate de tener suficiente memoria (recomendado: 4GB+).

**Solución 2:** Usa la compilación en contenedor:

```bash
./mvnw clean package -Dnative -Dquarkus.native.container-build=true
```

### Problema 5: Problemas con Docker en Windows

**Solución 1:** Asegúrate de que Docker Desktop esté ejecutándose.

**Solución 2:** Habilita WSL2 si es necesario:
- Abre Docker Desktop
- Ve a Settings > General
- Marca "Use the WSL 2 based engine"

**Solución 3:** Verifica que WSL2 esté instalado:
```powershell
wsl --list --verbose
```

### Problema 6: Tests fallan

**Solución 1:** Asegúrate de que la aplicación esté corriendo en modo desarrollo o que los tests de integración estén configurados correctamente.

**Solución 2:** Verifica que todos los endpoints estén implementados correctamente.

**Solución 3:** Revisa los logs de error:

#### Linux / macOS:
```bash
./mvnw test -X
```

#### Windows:
```cmd
mvnw.cmd test -X
```

### Problema 7: Error "PanacheEntity not found"

**Solución:** Verifica que la extensión `hibernate-reactive-panache` esté agregada:

```bash
./mvnw quarkus:add-extension -Dextensions="hibernate-reactive-panache"
```

### Problema 8: Error al construir imagen Docker/Podman

**Solución 1:** Asegúrate de haber construido la aplicación primero:

```bash
./mvnw clean package
```

**Solución 2:** Verifica que el Dockerfile esté en la ruta correcta:

```bash
ls -la src/main/docker/
```

**Solución 3:** Construye desde el directorio correcto (debe ser el directorio `suggestions/`):

```bash
pwd
# Debe mostrar: .../suggestions
```

---

## 📚 Recursos Adicionales

- [Documentación de Quarkus](https://quarkus.io/guides/)
- [Hibernate Reactive](https://quarkus.io/guides/hibernate-reactive)
- [Mutiny Documentation](https://smallrye.io/smallrye-mutiny/)
- [Quarkus Dev Services](https://quarkus.io/guides/dev-services)
- [Docker Documentation](https://docs.docker.com/)
- [Podman Documentation](https://podman.io/getting-started/)

---

## ✅ Checklist de Verificación

Antes de considerar el laboratorio completo, verifica:

- [ ] Extensiones de Quarkus agregadas correctamente
- [ ] Base de datos configurada en `application.properties`
- [ ] Entidad `Suggestion` extiende `PanacheEntity`
- [ ] Endpoint POST implementado
- [ ] Endpoint GET por ID implementado
- [ ] Endpoint GET para listar todas implementado
- [ ] Endpoint DELETE implementado (ya estaba)
- [ ] Aplicación inicia correctamente en modo desarrollo
- [ ] Todos los endpoints funcionan correctamente
- [ ] Tests unitarios pasan
- [ ] Imagen Docker/Podman se construye correctamente
- [ ] Contenedor se ejecuta correctamente

---

## 🎓 Resumen del Laboratorio

En este laboratorio has aprendido a:

1. ✅ Configurar un proyecto Quarkus Reactivo
2. ✅ Agregar extensiones de Hibernate Reactive
3. ✅ Configurar PostgreSQL con Dev Services
4. ✅ Implementar endpoints REST reactivos usando Mutiny (`Uni` y `Multi`)
5. ✅ Usar Hibernate Reactive Panache para operaciones de base de datos
6. ✅ Probar endpoints con curl o PowerShell
7. ✅ Ejecutar tests unitarios
8. ✅ Construir y ejecutar aplicaciones en contenedores Docker/Podman
9. ✅ Construir imágenes nativas para mejor rendimiento

---

## 📝 Notas Finales

- **Modo Desarrollo:** Usa `quarkus:dev` para desarrollo con recarga automática
- **Dev Services:** Quarkus automáticamente inicia PostgreSQL en un contenedor cuando detecta la extensión
- **Mutiny:** `Uni` representa un valor único asíncrono, `Multi` representa un stream de valores
- **Panache:** Simplifica las operaciones de base de datos con métodos como `persist()`, `findById()`, `streamAll()`
- **Contenedores:** Las imágenes nativas ofrecen mejor rendimiento pero requieren más tiempo de compilación

---

**¡Felicitaciones por completar el LAB 11 - Quarkus Reactive Develop!** 🎉
