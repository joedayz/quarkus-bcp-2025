# Reactive API - E-commerce Purchase Suggestions

Este proyecto implementa una API reactiva para un sistema de sugerencias de compra en e-commerce. Utiliza Hibernate Reactive Panache y PostgreSQL para almacenar las sugerencias en una base de datos reactiva, mejorando el rendimiento y reduciendo la latencia.

## 📋 Requisitos Previos

- **Java 21** o superior
- **Maven 3.8+** o usar el wrapper incluido (`mvnw` / `mvnw.cmd`)
- **Docker** o **Podman** (para ejecutar la base de datos PostgreSQL)
- **Git** (opcional)

## 🚀 Configuración del Proyecto

### Paso 1: Navegar al directorio del proyecto

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

### Paso 2: Agregar extensiones de Quarkus

Agrega las extensiones necesarias para desarrollo reactivo:

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

### Paso 3: Configurar la base de datos

Edita el archivo `src/main/resources/application.properties` y configura la imagen de PostgreSQL:

```properties
quarkus.datasource.devservices.image-name=postgres:14.1
```

O si estás usando un registro privado:

```properties
quarkus.datasource.devservices.image-name=registry.ocp4.example.com:8443/redhattraining/do378-postgres:14.1
```

## 🏃 Ejecutar la Aplicación

### Modo Desarrollo (con recarga automática)

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

La aplicación estará disponible en: `http://localhost:8080`

### Modo de Pruebas Continuas

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

Para detener el modo de pruebas continuas, presiona `q` en la terminal.

### Ejecutar Pruebas Unitarias

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

## 🐳 Ejecutar con Docker

### Requisitos
- Docker instalado y en ejecución

### Construir la aplicación

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

### Construir la imagen Docker (JVM)

#### Linux / macOS / Windows:
```bash
docker build -f src/main/docker/Dockerfile.jvm -t quarkus/suggestions-jvm .
```

### Ejecutar el contenedor

#### Linux / macOS / Windows:
```bash
docker run -i --rm -p 8080:8080 quarkus/suggestions-jvm
```

### Construir imagen nativa (requiere más tiempo)

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

Luego construir la imagen:

```bash
docker build -f src/main/docker/Dockerfile.native -t quarkus/suggestions-native .
```

Y ejecutar:

```bash
docker run -i --rm -p 8080:8080 quarkus/suggestions-native
```

## 🦫 Ejecutar con Podman

### Requisitos
- Podman instalado y en ejecución

### Construir la aplicación

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

### Construir la imagen con Podman (JVM)

#### Linux / macOS / Windows:
```bash
podman build -f src/main/docker/Dockerfile.jvm -t quarkus/suggestions-jvm .
```

### Ejecutar el contenedor

#### Linux / macOS / Windows:
```bash
podman run -i --rm -p 8080:8080 quarkus/suggestions-jvm
```

### Construir imagen nativa con Podman

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

Luego construir la imagen:

```bash
podman build -f src/main/docker/Dockerfile.native -t quarkus/suggestions-native .
```

Y ejecutar:

```bash
podman run -i --rm -p 8080:8080 quarkus/suggestions-native
```

## 📝 Implementación de Endpoints

### 1. Endpoint para crear sugerencias

Agrega el siguiente método en `SuggestionResource.java`:

```java
@POST
public Uni<Suggestion> create(Suggestion newSuggestion) {
    return Panache.withTransaction(newSuggestion::persist);
}
```

### 2. Endpoint para obtener sugerencia por ID

```java
@GET
@Path("/{id}")
public Uni<Suggestion> get(Long id) {
    return Suggestion.findById(id);
}
```

### 3. Endpoint para listar todas las sugerencias

```java
@GET
public Multi<Suggestion> list() {
    return Suggestion.streamAll();
}
```

**Nota:** Asegúrate de importar las clases necesarias:
- `io.smallrye.mutiny.Uni`
- `io.smallrye.mutiny.Multi`
- `jakarta.ws.rs.POST`
- `jakarta.ws.rs.GET`
- `jakarta.ws.rs.Path`
- `io.quarkus.hibernate.reactive.panache.Panache`

## 🔌 Endpoints de la API

Una vez implementados los endpoints, la API expone:

- **POST** `/suggestion` - Crea una nueva sugerencia
- **GET** `/suggestion/{id}` - Obtiene una sugerencia por ID
- **GET** `/suggestion` - Lista todas las sugerencias
- **DELETE** `/suggestion` - Elimina todas las sugerencias

### Ejemplos de uso

#### Crear una sugerencia:
```bash
curl -X POST http://localhost:8080/suggestion \
  -H "Content-Type: application/json" \
  -d '{"clientId": 1, "itemId": 103}'
```

#### Obtener una sugerencia por ID:
```bash
curl http://localhost:8080/suggestion/1
```

#### Listar todas las sugerencias:
```bash
curl http://localhost:8080/suggestion
```

#### Eliminar todas las sugerencias:
```bash
curl -X DELETE http://localhost:8080/suggestion
```

## 🧪 Verificación

El proyecto incluye tests que verifican el comportamiento de la aplicación. Ejecuta los tests para verificar que todo funciona correctamente:

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

Todos los tests deben pasar después de implementar los endpoints correctamente.

## 📦 Estructura del Proyecto

```
suggestions/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/bcp/training/
│   │   │       ├── Suggestion.java          # Entidad Panache
│   │   │       └── SuggestionResource.java  # Recurso REST
│   │   ├── resources/
│   │   │   └── application.properties       # Configuración
│   │   └── docker/
│   │       ├── Dockerfile.jvm               # Dockerfile para JVM
│   │       └── Dockerfile.native            # Dockerfile para nativo
│   └── test/
│       └── java/
│           └── com/bcp/training/
│               └── SuggestionResourceTest.java  # Tests
├── pom.xml
├── mvnw                                    # Maven wrapper (Unix)
└── mvnw.cmd                                # Maven wrapper (Windows)
```

## 🔧 Solución de Problemas

### Error: "Cannot find Maven"
Si no tienes Maven instalado, usa el wrapper incluido (`mvnw` o `mvnw.cmd`).

### Error: "Port 8080 already in use"
Cambia el puerto en `application.properties`:
```properties
quarkus.http.port=8081
```

### Error: "Database connection failed"
Asegúrate de que Docker o Podman estén ejecutándose y que la imagen de PostgreSQL esté configurada correctamente en `application.properties`.

### Problemas con Docker en Windows
Asegúrate de que Docker Desktop esté ejecutándose y que WSL2 esté habilitado si es necesario.

## 📚 Recursos Adicionales

- [Quarkus Documentation](https://quarkus.io/guides/)
- [Hibernate Reactive](https://quarkus.io/guides/hibernate-reactive)
- [Mutiny Documentation](https://smallrye.io/smallrye-mutiny/)

## 📄 Licencia

Este proyecto es parte de un curso de entrenamiento BCP.
