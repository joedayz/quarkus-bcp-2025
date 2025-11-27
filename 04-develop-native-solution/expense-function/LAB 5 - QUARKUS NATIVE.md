# LAB 5: QUARKUS NATIVE

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

En este laboratorio aprenderás a:
- Construir ejecutables nativos con Quarkus y GraalVM
- Usar container-build para crear ejecutables nativos sin instalar GraalVM
- Crear imágenes de contenedor para aplicaciones nativas
- Comparar el rendimiento y tamaño entre aplicaciones JVM y nativas

## 1. Cargar el proyecto en tu IDE

Abre el proyecto `04-develop-native-solution` en tu IDE preferido. El proyecto contiene:
- `expense-function`: Aplicación Quarkus con funciones para gestionar gastos (versión completa)

## 2. Examinar la estructura del proyecto

### 2.1. Revisar el módulo expense-function

El módulo `expense-function` contiene:
- `Expense`: Modelo de datos que representa un gasto
- `ExpenseFunctions`: Funciones Funqy HTTP para gestionar gastos
- `ExpenseRepository`: Repositorio en memoria para almacenar gastos

### 2.2. Revisar la configuración

Abre el archivo `expense-function/src/main/resources/application.properties`:

```properties
quarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21
quarkus.jib.base-native-image=quay.io/quarkus/quarkus-micro-image:2.0

quarkus.native.container-build=true
quarkus.native.container-runtime=podman
quarkus.container-image.build=false
```

## 3. Ejecutar la aplicación en modo desarrollo

### 3.1. Navegar al directorio expense-function

### Linux/Mac

```bash
cd expense-function
```

### Windows (CMD)

```cmd
cd expense-function
```

### Windows (PowerShell)

```powershell
cd expense-function
```

### 3.2. Iniciar la aplicación en modo desarrollo

### Linux/Mac

```bash
./mvnw quarkus:dev
```

### Windows (CMD)

```cmd
mvnw.cmd quarkus:dev
```

### Windows (PowerShell)

```powershell
.\mvnw.cmd quarkus:dev
```

### 3.3. Probar la aplicación

Abre tu navegador y visita:
- **API**: http://localhost:8080/expenses
- **Dev UI**: http://localhost:8080/q/dev/

O usa curl:

### Linux/Mac

```bash
curl http://localhost:8080/expenses
```

### Windows (CMD)

```cmd
curl http://localhost:8080/expenses
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/expenses -Method GET | Select-Object -ExpandProperty Content
```

## 4. Construir el ejecutable nativo usando container-build

### 4.1. Verificar la configuración

La configuración en `application.properties` ya está lista:

```properties
quarkus.native.container-build=true
quarkus.native.container-runtime=podman
```

**Nota:** 
- `quarkus.native.container-build=true`: Usa una imagen de contenedor para construir el ejecutable nativo (no requiere GraalVM instalado)
- `quarkus.native.container-runtime=podman`: Especifica usar podman en lugar de docker

### 4.2. Construir el ejecutable nativo

### Linux/Mac

```bash
./mvnw clean package -Dnative
```

### Windows (CMD)

```cmd
mvnw.cmd clean package -Dnative
```

### Windows (PowerShell)

```powershell
.\mvnw.cmd clean package -Dnative
```

**Nota:** Este proceso puede tardar varios minutos (5-10 minutos) ya que está construyendo un ejecutable nativo completo.

### 4.3. Verificar el ejecutable nativo

Una vez completado, deberías ver un archivo ejecutable en el directorio `target`:

### Linux/Mac

```bash
ls -lh target/*-runner
```

### Windows (CMD)

```cmd
dir target\*-runner
```

### Windows (PowerShell)

```powershell
Get-ChildItem target\*-runner
```

Deberías ver un archivo como `expense-function-1.0.0-SNAPSHOT-runner` (aproximadamente 60-80 MB).

## 5. Ejecutar el ejecutable nativo

### 5.1. Ejecutar directamente

### Linux/Mac

```bash
./target/expense-function-1.0.0-SNAPSHOT-runner
```

### Windows (CMD)

```cmd
target\expense-function-1.0.0-SNAPSHOT-runner.exe
```

### Windows (PowerShell)

```powershell
.\target\expense-function-1.0.0-SNAPSHOT-runner.exe
```

### 5.2. Probar la aplicación nativa

Una vez que la aplicación esté corriendo, prueba el endpoint:

### Linux/Mac

```bash
curl http://localhost:8080/expenses
```

### Windows (CMD)

```cmd
curl http://localhost:8080/expenses
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/expenses -Method GET | Select-Object -ExpandProperty Content
```

**Observación:** Nota el tiempo de inicio de la aplicación nativa. Debería ser mucho más rápido que la versión JVM.

## 6. Crear una imagen de contenedor para el ejecutable nativo

### 6.1. Revisar el Dockerfile.native

El archivo `expense-function/src/main/docker/Dockerfile.native` contiene:

```dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.5
WORKDIR /work/
RUN chown 1001 /work \
    && chmod "g+rwX" /work \
    && chown 1001:root /work
COPY --chown=1001:root --chmod=0755 target/*-runner /work/application

EXPOSE 8080
USER 1001

ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
```

### 6.2. Construir la imagen de contenedor

Asegúrate de estar en el directorio `expense-function` y que el ejecutable nativo ya esté construido.

### Linux/Mac (usando podman)

```bash
podman build -f src/main/docker/Dockerfile.native -t expense-function-native .
```

### Linux/Mac (usando docker)

```bash
docker build -f src/main/docker/Dockerfile.native -t expense-function-native .
```

### Windows (CMD - usando podman)

```cmd
podman build -f src/main/docker/Dockerfile.native -t expense-function-native .
```

### Windows (CMD - usando docker)

```cmd
docker build -f src/main/docker/Dockerfile.native -t expense-function-native .
```

### Windows (PowerShell - usando podman)

```powershell
podman build -f src/main/docker/Dockerfile.native -t expense-function-native .
```

### Windows (PowerShell - usando docker)

```powershell
docker build -f src/main/docker/Dockerfile.native -t expense-function-native .
```

### 6.3. Verificar la imagen creada

### Linux/Mac (podman)

```bash
podman images expense-function-native
```

### Linux/Mac (docker)

```bash
docker images expense-function-native
```

### Windows (CMD - podman)

```cmd
podman images expense-function-native
```

### Windows (CMD - docker)

```cmd
docker images expense-function-native
```

### Windows (PowerShell - podman)

```powershell
podman images expense-function-native
```

### Windows (PowerShell - docker)

```powershell
docker images expense-function-native
```

## 7. Ejecutar el contenedor

### 7.1. Ejecutar el contenedor

### Linux/Mac (podman)

```bash
podman run -i --rm -p 8080:8080 expense-function-native
```

### Linux/Mac (docker)

```bash
docker run -i --rm -p 8080:8080 expense-function-native
```

### Windows (CMD - podman)

```cmd
podman run -i --rm -p 8080:8080 expense-function-native
```

### Windows (CMD - docker)

```cmd
docker run -i --rm -p 8080:8080 expense-function-native
```

### Windows (PowerShell - podman)

```powershell
podman run -i --rm -p 8080:8080 expense-function-native
```

### Windows (PowerShell - docker)

```powershell
docker run -i --rm -p 8080:8080 expense-function-native
```

### 7.2. Probar el contenedor

En otra terminal, prueba el endpoint:

### Linux/Mac

```bash
curl http://localhost:8080/expenses
```

### Windows (CMD)

```cmd
curl http://localhost:8080/expenses
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/expenses -Method GET | Select-Object -ExpandProperty Content
```

## 8. Comparar tamaños de imagen

### 8.1. Construir imagen JVM para comparación

Primero, construye una imagen JVM:

### Linux/Mac (podman)

```bash
podman build -f src/main/docker/Dockerfile.jvm -t expense-function-jvm .
```

### Linux/Mac (docker)

```bash
docker build -f src/main/docker/Dockerfile.jvm -t expense-function-jvm .
```

### Windows (CMD - podman)

```cmd
podman build -f src/main/docker/Dockerfile.jvm -t expense-function-jvm .
```

### Windows (CMD - docker)

```cmd
docker build -f src/main/docker/Dockerfile.jvm -t expense-function-jvm .
```

### Windows (PowerShell - podman)

```powershell
podman build -f src/main/docker/Dockerfile.jvm -t expense-function-jvm .
```

### Windows (PowerShell - docker)

```powershell
docker build -f src/main/docker/Dockerfile.jvm -t expense-function-jvm .
```

### 8.2. Comparar tamaños

### Linux/Mac (podman)

```bash
podman images | grep expense-function
```

### Linux/Mac (docker)

```bash
docker images | grep expense-function
```

### Windows (CMD - podman)

```cmd
podman images | findstr expense-function
```

### Windows (CMD - docker)

```cmd
docker images | findstr expense-function
```

### Windows (PowerShell - podman)

```powershell
podman images | Select-String expense-function
```

### Windows (PowerShell - docker)

```powershell
docker images | Select-String expense-function
```

**Observación:** La imagen nativa debería ser significativamente más pequeña que la imagen JVM.

**Ejemplo de salida esperada:**
```
REPOSITORY                  TAG       IMAGE ID       CREATED         SIZE
expense-function-native     latest    abc123def456   2 minutes ago   150 MB
expense-function-jvm        latest    def456ghi789   3 minutes ago   450 MB
```

## 9. Usar Dockerfile.native-micro

Quarkus también proporciona un Dockerfile optimizado para imágenes más pequeñas:

### 9.1. Construir con Dockerfile.native-micro

### Linux/Mac (podman)

```bash
podman build -f src/main/docker/Dockerfile.native-micro -t expense-function-native-micro .
```

### Linux/Mac (docker)

```bash
docker build -f src/main/docker/Dockerfile.native-micro -t expense-function-native-micro .
```

### Windows (CMD - podman)

```cmd
podman build -f src/main/docker/Dockerfile.native-micro -t expense-function-native-micro .
```

### Windows (CMD - docker)

```cmd
docker build -f src/main/docker/Dockerfile.native-micro -t expense-function-native-micro .
```

### Windows (PowerShell - podman)

```powershell
podman build -f src/main/docker/Dockerfile.native-micro -t expense-function-native-micro .
```

### Windows (PowerShell - docker)

```powershell
docker build -f src/main/docker/Dockerfile.native-micro -t expense-function-native-micro .
```

### 9.2. Comparar tamaños

Compara el tamaño de las tres imágenes para ver las diferencias:

### Linux/Mac (podman)

```bash
podman images | grep expense-function
```

### Linux/Mac (docker)

```bash
docker images | grep expense-function
```

### Windows (CMD - podman)

```cmd
podman images | findstr expense-function
```

### Windows (CMD - docker)

```cmd
docker images | findstr expense-function
```

### Windows (PowerShell - podman)

```powershell
podman images | Select-String expense-function
```

### Windows (PowerShell - docker)

```powershell
docker images | Select-String expense-function
```

**Observación:** La imagen `native-micro` debería ser la más pequeña de las tres.

## 10. Medir tiempos de inicio (Opcional)

### 10.1. Medir tiempo de inicio JVM

Ejecuta la aplicación JVM y mide el tiempo de inicio:

### Linux/Mac

```bash
time java -jar target/quarkus-app/quarkus-run.jar
```

### Windows (PowerShell)

```powershell
Measure-Command { java -jar target/quarkus-app/quarkus-run.jar }
```

### 10.2. Medir tiempo de inicio nativo

Ejecuta la aplicación nativa y mide el tiempo de inicio:

### Linux/Mac

```bash
time ./target/expense-function-1.0.0-SNAPSHOT-runner
```

### Windows (PowerShell)

```powershell
Measure-Command { .\target\expense-function-1.0.0-SNAPSHOT-runner.exe }
```

**Observación:** La aplicación nativa debería iniciar en milisegundos, mientras que la JVM puede tardar varios segundos.

## Resumen

En este laboratorio has aprendido a:
- ✅ Construir ejecutables nativos con Quarkus usando container-build
- ✅ Configurar Quarkus para usar podman o docker
- ✅ Crear imágenes de contenedor para aplicaciones nativas
- ✅ Ejecutar aplicaciones nativas en contenedores
- ✅ Comparar tamaños entre imágenes JVM y nativas
- ✅ Usar diferentes Dockerfiles para optimizar el tamaño de las imágenes

## Ventajas de las aplicaciones nativas

- **Tiempo de inicio rápido**: Las aplicaciones nativas inician en milisegundos (típicamente < 100ms)
- **Menor consumo de memoria**: Usan menos memoria en tiempo de ejecución (típicamente 50-70% menos)
- **Imágenes más pequeñas**: Las imágenes de contenedor son más pequeñas (típicamente 60-70% más pequeñas)
- **Mejor densidad**: Puedes ejecutar más instancias en el mismo hardware
- **Mejor para serverless**: Ideal para funciones serverless donde el tiempo de inicio es crítico

## Consideraciones

- **Tiempo de compilación**: La compilación nativa toma más tiempo (5-10 minutos vs segundos)
- **Limitaciones de reflexión**: Algunas librerías que usan reflexión pueden requerir configuración adicional
- **Debugging**: El debugging de aplicaciones nativas es más complejo
- **Compatibilidad**: No todas las librerías Java son compatibles con GraalVM Native Image

## Próximos pasos

- Explora las opciones de optimización de imágenes nativas
- Compara el rendimiento entre aplicaciones JVM y nativas bajo carga
- Investiga sobre GraalVM Native Image y sus limitaciones
- Prueba diferentes perfiles de construcción nativa
- Experimenta con la configuración de reflexión para librerías específicas
- Explora el uso de aplicaciones nativas en entornos serverless (AWS Lambda, Azure Functions, etc.)

---

**Enjoy!**

**Joe**

