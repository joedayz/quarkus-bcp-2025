# LAB 1: SETUP

**Autor:** José Díaz

## 1. Crear un directorio para crear nuestro primer proyecto Quarkus

### Linux/Mac

```bash
mkdir start-setup
```

### Windows (CMD)

```cmd
mkdir start-setup
```

### Windows (PowerShell)

```powershell
New-Item -ItemType Directory -Name start-setup
```

## 2. Crear una aplicación Quarkus usando el comando maven:

### Linux/Mac

```bash
mvn io.quarkus:quarkus-maven-plugin:3.2.9.Final:create \
  -DprojectGroupId=com.bcp.training \
  -DprojectArtifactId=tenther \
  -DplatformVersion=3.2.9.Final \
  -Dextensions="quarkus-resteasy"
```

### Windows (CMD)

```cmd
mvn io.quarkus:quarkus-maven-plugin:3.2.9.Final:create ^
  -DprojectGroupId=com.bcp.training ^
  -DprojectArtifactId=tenther ^
  -DplatformVersion=3.2.9.Final ^
  -Dextensions="quarkus-rest easy"
```

### Windows (PowerShell)

```powershell
mvn io.quarkus:quarkus-maven-plugin:3.2.9.Final:create `
  -DprojectGroupId=com.bcp.training `
  -DprojectArtifactId=tenther `
  -DplatformVersion=3.2.9.Final `
  -Dextensions="quarkus-rest easy"
```

**Alternativa (una sola línea para Windows):**

```cmd
mvn io.quarkus:quarkus-maven-plugin:3.2.9.Final:create -DprojectGroupId=com.bcp.training -DprojectArtifactId=tenther -DplatformVersion=3.2.9.Final -Dextensions="quarkus-rest easy"
```

## 3. Navegar al directorio del proyecto

### Linux/Mac/Windows

```bash
cd tenther
```

## 4. Ejecutar la aplicación en modo desarrollo

### Linux/Mac/Windows

```bash
mvn quarkus:dev
```

**O usando el wrapper de Maven (si está disponible):**

```bash
# Linux/Mac
./mvnw quarkus:dev

# Windows (CMD)
mvnw.cmd quarkus:dev

# Windows (PowerShell)
.\mvnw.cmd quarkus:dev
```

Deberíamos obtener el siguiente resultado:

[La aplicación debería iniciarse correctamente]

## 5. Invocar la aplicación

### Curl

```bash
curl http://localhost:8080/hello
```

### Powershell

```powershell
Invoke-WebRequest http://localhost:8080/hello
```

**Respuesta esperada:**

```
Hello from RESTEasy Reactive
```

## 6. Cambiar el archivo de ejemplo `com.bcp.training.GreetingResource`

**NOTA:** Cambiar el `@Path("/hello")` a `@Path("/tenther")`

### Antes:

```java
@GET
@Produces(MediaType.TEXT_PLAIN)
public String hello() {
    return "Hello from RESTEasy Reactive";
}
```

### Ahora:

```java
@GET
@Path("/{number}")
@Produces(MediaType.TEXT_PLAIN)
public String multiply(
    @PathParam("number") Integer number
) {
    return String.valueOf(number * 10) + "\n";
}
```

## 7. Probar la nueva funcionalidad

```bash
curl http://localhost:8080/tenther/7
```

**Respuesta esperada:**

```
70
```

## 8. Detener la aplicación

Para detener la aplicación, presionar la letra "q" o `Ctrl+c`.

