# LAB 14: QUARKUS SECURE JWT

Autor: José Díaz

Github Repo: https://github.com/joedayz/quarkus-bcp-2025.git

Este proyecto demuestra cómo implementar autenticación y autorización usando JWT (JSON Web Tokens) en Quarkus con SmallRye JWT.

## Descripción del Proyecto

Este proyecto incluye:
- **JwtResource**: Endpoint `/jwt/{username}` que genera un JWT para un usuario dado
- **UserResource**: Endpoint `/user/expenses` que retorna los expenses del usuario autenticado (requiere rol USER)
- **AdminResource**: Endpoint `/admin/expenses` que lista todos los expenses (requiere rol ADMIN)

## Prerrequisitos

- Java 21 o superior
- Maven 3.8+ o usar el wrapper incluido (`mvnw`)
- Docker o Podman (opcional, para contenedores)

## Configuración Inicial

### 1. Generar las Claves RSA

**IMPORTANTE**: Antes de ejecutar la aplicación, debes generar las claves RSA para firmar y verificar los JWTs.

#### Windows:
```cmd
cd expenses
mvnw.cmd exec:java -Dexec.mainClass="GenerateKeys"
```

#### Linux/Mac:
```bash
cd expenses
./mvnw exec:java -Dexec.mainClass="GenerateKeys"
```

Esto generará los archivos `privateKey.pem` y `publicKey.pem` en:
- **Windows**: `C:\Users\<USERNAME>\DO378\secure-jwt\`
- **Linux/Mac**: `${HOME}/DO378/secure-jwt/`

**Verifica que ambos archivos `.pem` existan antes de continuar.**

### 2. Configurar application.properties

El archivo `src/main/resources/application.properties` debe estar configurado con las rutas correctas a las claves:

#### Windows:
```properties
mp.jwt.verify.issuer = https://example.com/redhattraining
smallrye.jwt.sign.key.location = C:/Users/<USERNAME>/DO378/secure-jwt/privateKey.pem
mp.jwt.verify.publickey.location = C:/Users/<USERNAME>/DO378/secure-jwt/publicKey.pem
```

#### Linux/Mac:
```properties
mp.jwt.verify.issuer = https://example.com/redhattraining
smallrye.jwt.sign.key.location = ${HOME}/DO378/secure-jwt/privateKey.pem
mp.jwt.verify.publickey.location = ${HOME}/DO378/secure-jwt/publicKey.pem
```

## Ejecutar la Aplicación

### Modo Desarrollo

#### Windows:
```cmd
mvnw.cmd quarkus:dev
```

#### Linux/Mac:
```bash
./mvnw quarkus:dev
```

La aplicación estará disponible en: http://localhost:8080

El Dev UI estará disponible en: http://localhost:8080/q/dev/

### Modo Producción

#### Windows:
```cmd
mvnw.cmd package
java -jar target/quarkus-app/quarkus-run.jar
```

#### Linux/Mac:
```bash
./mvnw package
java -jar target/quarkus-app/quarkus-run.jar
```

### Ejecutable Nativo

#### Windows:
```cmd
mvnw.cmd package -Dnative
target\expenses-service-1.0.0-SNAPSHOT-runner.exe
```

#### Linux/Mac:
```bash
./mvnw package -Dnative
./target/expenses-service-1.0.0-SNAPSHOT-runner
```

**Nota**: Para construir el ejecutable nativo sin GraalVM instalado, usa contenedores:

#### Windows:
```cmd
mvnw.cmd package -Dnative -Dquarkus.native.container-build=true
```

#### Linux/Mac:
```bash
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

## Ejecutar Tests

### Todos los Tests

#### Windows:
```cmd
mvnw.cmd test
```

#### Linux/Mac:
```bash
./mvnw test
```

### Test Específico

#### Windows:
```cmd
mvnw.cmd test -Dtest=JwtGeneratorTest
mvnw.cmd test -Dtest=UserResourceTest
mvnw.cmd test -Dtest=AdminResourceTest
```

#### Linux/Mac:
```bash
./mvnw test -Dtest=JwtGeneratorTest
./mvnw test -Dtest=UserResourceTest
./mvnw test -Dtest=AdminResourceTest
```

## Endpoints

### Generar JWT

```bash
# JWT para usuario regular
curl http://localhost:8080/jwt/john

# JWT para administrador
curl http://localhost:8080/jwt/admin
```

### Acceder a Expenses (requiere autenticación)

```bash
# Obtener JWT primero
TOKEN=$(curl -s http://localhost:8080/jwt/john)

# Listar expenses del usuario autenticado
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/user/expenses

# Listar todos los expenses (solo admin)
ADMIN_TOKEN=$(curl -s http://localhost:8080/jwt/admin)
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8080/admin/expenses
```

## Docker / Podman

### Construir Imagen JVM

#### Docker:
```bash
# Construir
./mvnw package
docker build -f src/main/docker/Dockerfile.jvm -t quarkus/expenses-jvm .

# Ejecutar
docker run -i --rm -p 8080:8080 quarkus/expenses-jvm
```

#### Podman:
```bash
# Construir
./mvnw package
podman build -f src/main/docker/Dockerfile.jvm -t quarkus/expenses-jvm .

# Ejecutar
podman run -i --rm -p 8080:8080 quarkus/expenses-jvm
```

### Construir Imagen Nativa

#### Docker:
```bash
# Construir ejecutable nativo
./mvnw package -Dnative

# Construir imagen
docker build -f src/main/docker/Dockerfile.native -t quarkus/expenses-native .

# Ejecutar
docker run -i --rm -p 8080:8080 quarkus/expenses-native
```

#### Podman:
```bash
# Construir ejecutable nativo
./mvnw package -Dnative

# Construir imagen
podman build -f src/main/docker/Dockerfile.native -t quarkus/expenses-native .

# Ejecutar
podman run -i --rm -p 8080:8080 quarkus/expenses-native
```

### Construir con Container Build (sin GraalVM local)

#### Docker:
```bash
# Construir ejecutable nativo usando contenedor
./mvnw package -Dnative -Dquarkus.native.container-build=true

# Construir imagen
docker build -f src/main/docker/Dockerfile.native -t quarkus/expenses-native .

# Ejecutar
docker run -i --rm -p 8080:8080 quarkus/expenses-native
```

#### Podman:
```bash
# Construir ejecutable nativo usando contenedor
./mvnw package -Dnative -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=podman

# Construir imagen
podman build -f src/main/docker/Dockerfile.native -t quarkus/expenses-native .

# Ejecutar
podman run -i --rm -p 8080:8080 quarkus/expenses-native
```

## Instrucciones del Laboratorio

### Paso 1: Revisar el Código

1. Revisa `JwtResource.java` - Endpoint `/jwt/{username}` genera un JWT
2. Revisa `UserResource.java` - Endpoint `/user/expenses` retorna expenses del usuario
3. Revisa `AdminResource.java` - Endpoint `/admin/expenses` lista todos los expenses
4. Revisa `application.properties` - Configuración de JWT

### Paso 2: Ejecutar Tests Iniciales

Ejecuta todos los tests y verifica que 9 de ellos fallan:

#### Windows:
```cmd
mvnw.cmd test
```

#### Linux/Mac:
```bash
./mvnw test
```

Deberías ver errores como:
- `AdminResourceTest.guestsCannotListExpenses` - Esperaba 401 pero obtuvo 200
- `AdminResourceTest.regularUsersCannotListExpenses` - Esperaba 403 pero obtuvo 200
- `UserResourceTest.guestsCannotListExpenses` - Esperaba 401 pero obtuvo 200
- Varios errores en `JwtGeneratorTest` relacionados con claims y grupos

### Paso 3: Completar JwtGenerator

#### 3a. Modificar `generateJwtForRegularUser`

Agrega los claims `sub`, `aud`, `locale` y el grupo `USER`:

```java
public static String generateJwtForRegularUser(String username) {
    return Jwt.issuer(ISSUER)
        .upn(username + "@example.com")
        .subject(username)
        .audience("expenses.example.com")
        .claim("locale", "en_US")
        .groups(new HashSet<>(List.of("USER")))
        .sign();
}
```

#### 3b. Modificar `generateJwtForAdmin`

Agrega los grupos `USER` y `ADMIN`:

```java
public static String generateJwtForAdmin(String username) {
    return Jwt.issuer(ISSUER)
        .upn(username + "@example.com")
        .subject(username)
        .claim("locale", "en_US")
        .groups(new HashSet<>(List.of("USER", "ADMIN")))
        .sign();
}
```

#### 3c. Verificar Tests de JWT

#### Windows:
```cmd
mvnw.cmd test -Dtest=JwtGeneratorTest
```

#### Linux/Mac:
```bash
./mvnw test -Dtest=JwtGeneratorTest
```

Deberías ver: `Tests run: 5, Failures: 0`

### Paso 4: Asegurar UserResource

Anota la clase `UserResource` para restringir acceso al rol `USER`:

```java
@Path("/user")
@RolesAllowed({"USER"})
public class UserResource {
    // ...
}
```

Verifica los tests:

#### Windows:
```cmd
mvnw.cmd test -Dtest=UserResourceTest
```

#### Linux/Mac:
```bash
./mvnw test -Dtest=UserResourceTest
```

Deberías ver: `Tests run: 2, Failures: 0`

### Paso 5: Asegurar AdminResource

Anota la clase `AdminResource` para restringir acceso al rol `ADMIN`:

```java
@Path("/admin")
@RolesAllowed({"ADMIN"})
public class AdminResource {
    // ...
}
```

Verifica los tests:

#### Windows:
```cmd
mvnw.cmd test -Dtest=AdminResourceTest
```

#### Linux/Mac:
```bash
./mvnw test -Dtest=AdminResourceTest
```

Deberías ver: `Tests run: 3, Failures: 0`

### Paso 6: Verificar Todos los Tests

Ejecuta todos los tests:

#### Windows:
```cmd
mvnw.cmd test
```

#### Linux/Mac:
```bash
./mvnw test
```

Deberías ver: `Tests run: 13, Failures: 0, Errors: 0, Skipped: 0`

## Estructura del Proyecto

```
expenses/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/bcp/training/
│   │   │       ├── expense/
│   │   │       │   ├── AdminResource.java
│   │   │       │   ├── UserResource.java
│   │   │       │   ├── Expense.java
│   │   │       │   └── ExpensesService.java
│   │   │       └── jwt/
│   │   │           ├── JwtGenerator.java
│   │   │           └── JwtResource.java
│   │   ├── resources/
│   │   │   └── application.properties
│   │   └── docker/
│   │       ├── Dockerfile.jvm
│   │       └── Dockerfile.native
│   └── test/
│       └── java/
│           └── com/bcp/training/
│               ├── expense/
│               │   ├── AdminResourceTest.java
│               │   └── UserResourceTest.java
│               └── jwt/
│                   └── JwtGeneratorTest.java
└── pom.xml
```

## Dependencias Principales

- `quarkus-rest` - REST API
- `quarkus-rest-jackson` - JSON serialization
- `quarkus-smallrye-jwt` - JWT support
- `quarkus-smallrye-jwt-build` - JWT build-time support
- `quarkus-arc` - Dependency injection

## Notas Importantes

⚠️ **IMPORTANTE**: El endpoint `/jwt/{username}` no requiere password por simplicidad. En producción, **NUNCA** uses JWTs sin autenticación adecuada.

## Solución de Problemas

### Error: No se encuentran las claves PEM

Asegúrate de ejecutar `GenerateKeys` y verificar que los archivos existan en la ruta correcta según tu sistema operativo.

### Error: Tests fallan con 401/403

Verifica que:
1. Las anotaciones `@RolesAllowed` estén correctamente aplicadas
2. Los grupos en los JWTs sean correctos (`USER` y/o `ADMIN`)
3. Los claims requeridos estén presentes en los JWTs

### Error: Docker/Podman build falla

Asegúrate de:
1. Ejecutar `./mvnw package` antes de construir la imagen
2. Para imágenes nativas, ejecutar `./mvnw package -Dnative` primero
3. Verificar que Docker/Podman esté corriendo

## Referencias

- [Quarkus JWT Guide](https://quarkus.io/guides/security-jwt)
- [SmallRye JWT Documentation](https://smallrye.io/smallrye-jwt/)
- [Quarkus Security](https://quarkus.io/guides/security)

---

¡Felicitaciones al completar el laboratorio!

Enjoy!

José

