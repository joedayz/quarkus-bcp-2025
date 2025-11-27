# LAB 6: QUARKUS TESTING

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

En este laboratorio aprenderás a:
- Escribir pruebas unitarias en Quarkus usando JUnit 5
- Usar la anotación `@QuarkusTest` para pruebas de integración
- Probar endpoints REST usando REST Assured
- Ejecutar pruebas con Maven
- Construir y ejecutar contenedores con Docker y Podman

## 1. Cargar en su IDE el proyecto test-unit

Abre el proyecto `05-demo-test-start/test-unit/expense-restful-service` en tu IDE preferido.

## 2. Examinar la estructura del proyecto

### 2.1. Clases principales

El proyecto contiene:
- `Expense`: Entidad JPA que representa un gasto
- `ExpenseResource`: Recurso REST que expone endpoints para gestionar gastos
- `ExpenseValidator`: Validador que verifica si un gasto es válido
- `ExpenseConfiguration`: Interfaz de configuración que define el monto máximo permitido

### 2.2. Clases de prueba

El proyecto contiene dos clases de prueba:
- `ExpenseCreationTest`: Prueba para crear gastos a través del endpoint REST
- `ExpenseValidationTest`: Prueba unitaria para validar la lógica de validación

## 3. Examinar las pruebas existentes

### 3.1. Abre la clase `ExpenseValidationTest`

Ubicada en: `src/test/java/com/bcp/training/expenses/ExpenseValidationTest.java`

Esta clase contiene pruebas unitarias que verifican la lógica de validación de gastos:
- `testExpenseWithMaxAmountIsValid()`: Verifica que un gasto con el monto máximo es válido
- `testExpenseOverMaxAmountIsInvalid()`: Verifica que un gasto que excede el monto máximo es inválido

### 3.2. Abre la clase `ExpenseCreationTest`

Ubicada en: `src/test/java/com/bcp/training/expenses/ExpenseCreationTest.java`

Esta clase contiene una prueba de integración que actualmente falla intencionalmente.

## 4. Ejecutar las pruebas unitarias

### 4.1. Navega al directorio del proyecto

### Linux/Mac

```bash
cd expense-restful-service
```

### Windows (CMD)

```cmd
cd expense-restful-service
```

### Windows (PowerShell)

```powershell
cd expense-restful-service
```

### 4.2. Ejecuta las pruebas usando Maven

### Linux/Mac

```bash
mvn test
```

### Windows (CMD)

```cmd
mvn test
```

### Windows (PowerShell)

```powershell
mvn test
```

**Resultado esperado:** Deberías ver que `ExpenseValidationTest` pasa y `ExpenseCreationTest` falla (como está diseñado).

## 5. Implementar la prueba de creación de gastos

### 5.1. Abre la clase `ExpenseCreationTest`

### 5.2. Implementa la prueba usando REST Assured

Reemplaza el contenido del método `testCreateExpense()` con:

```java
package com.bcp.training.expenses;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
public class ExpenseCreationTest {

    @Test
    public void testCreateExpense() {
        given()
            .contentType("application/json")
            .body("{\"name\":\"Test Expense\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":\"100.00\"}")
        .when()
            .post("/expenses")
        .then()
            .statusCode(200)
            .body("name", is("Test Expense"))
            .body("paymentMethod", is("CREDIT_CARD"))
            .body("amount", is(100.0f))
            .body("uuid", notNullValue());
    }
}
```

### 5.3. Ejecuta las pruebas nuevamente

### Linux/Mac

```bash
mvn test
```

### Windows (CMD)

```cmd
mvn test
```

### Windows (PowerShell)

```powershell
mvn test
```

**Resultado esperado:** Ambas pruebas deberían pasar ahora.

## 6. Ejecutar la aplicación en modo desarrollo

### 6.1. Inicia la aplicación

### Linux/Mac

```bash
mvn quarkus:dev
```

### Windows (CMD)

```cmd
mvn quarkus:dev
```

### Windows (PowerShell)

```powershell
mvn quarkus:dev
```

### 6.2. Verifica que la aplicación esté corriendo

Abre tu navegador y visita:
- **API REST**: http://localhost:8080/expenses
- **Swagger UI**: http://localhost:8080/q/swagger-ui

## 7. Probar el endpoint manualmente

### 7.1. Listar todos los gastos

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

### 7.2. Crear un nuevo gasto

### Linux/Mac

```bash
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"Training Course","paymentMethod":"CREDIT_CARD","amount":"500.00"}'
```

### Windows (CMD)

```cmd
curl -X POST http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"name\":\"Training Course\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":\"500.00\"}"
```

### Windows (PowerShell)

```powershell
$body = @{
    name = "Training Course"
    paymentMethod = "CREDIT_CARD"
    amount = "500.00"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

## 8. Construir la aplicación

### 8.1. Construir el JAR

### Linux/Mac

```bash
mvn clean package
```

### Windows (CMD)

```cmd
mvn clean package
```

### Windows (PowerShell)

```powershell
mvn clean package
```

### 8.2. Verificar que el JAR se haya creado

El JAR debería estar en: `target/quarkus-app/quarkus-run.jar`

## 9. Construir imagen de contenedor con Docker

### 9.1. Verificar que Docker esté instalado

### Linux/Mac

```bash
docker --version
```

### Windows (CMD)

```cmd
docker --version
```

### Windows (PowerShell)

```powershell
docker --version
```

### 9.2. Construir la imagen JVM

### Linux/Mac

```bash
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### Windows (CMD)

```cmd
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### Windows (PowerShell)

```powershell
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### 9.3. Ejecutar el contenedor Docker

### Linux/Mac

```bash
docker run -i --rm -p 8080:8080 expense-restful-service:jvm
```

### Windows (CMD)

```cmd
docker run -i --rm -p 8080:8080 expense-restful-service:jvm
```

### Windows (PowerShell)

```powershell
docker run -i --rm -p 8080:8080 expense-restful-service:jvm
```

### 9.4. Verificar que el contenedor esté corriendo

En otra terminal, ejecuta:

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

## 10. Construir imagen de contenedor con Podman

### 10.1. Verificar que Podman esté instalado

### Linux/Mac

```bash
podman --version
```

### Windows (CMD)

```cmd
podman --version
```

### Windows (PowerShell)

```powershell
podman --version
```

**Nota:** En Windows, Podman requiere WSL2 o una máquina virtual. Consulta la documentación oficial de Podman para la instalación en Windows.

### 10.2. Construir la imagen JVM con Podman

### Linux/Mac

```bash
podman build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### 10.3. Ejecutar el contenedor Podman

### Linux/Mac

```bash
podman run -i --rm -p 8080:8080 expense-restful-service:jvm
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman run -i --rm -p 8080:8080 expense-restful-service:jvm
```

### 10.4. Verificar que el contenedor esté corriendo

En otra terminal, ejecuta:

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

## 11. Construir imagen nativa (Opcional)

### 11.1. Construir el ejecutable nativo

### Linux/Mac

```bash
mvn clean package -Pnative -Dquarkus.native.container-build=true
```

### Windows (CMD)

```cmd
mvn clean package -Pnative -Dquarkus.native.container-build=true
```

### Windows (PowerShell)

```powershell
mvn clean package -Pnative -Dquarkus.native.container-build=true
```

**Nota:** Esto puede tardar varios minutos ya que construye un ejecutable nativo usando GraalVM.

### 11.2. Construir la imagen nativa con Docker

### Linux/Mac

```bash
docker build -f src/main/docker/Dockerfile.native -t expense-restful-service:native .
```

### Windows (CMD)

```cmd
docker build -f src/main/docker/Dockerfile.native -t expense-restful-service:native .
```

### Windows (PowerShell)

```powershell
docker build -f src/main/docker/Dockerfile.native -t expense-restful-service:native .
```

### 11.3. Construir la imagen nativa con Podman

### Linux/Mac

```bash
podman build -f src/main/docker/Dockerfile.native -t expense-restful-service:native .
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman build -f src/main/docker/Dockerfile.native -t expense-restful-service:native .
```

### 11.4. Ejecutar el contenedor nativo

### Docker - Linux/Mac

```bash
docker run -i --rm -p 8080:8080 expense-restful-service:native
```

### Docker - Windows (CMD)

```cmd
docker run -i --rm -p 8080:8080 expense-restful-service:native
```

### Docker - Windows (PowerShell)

```powershell
docker run -i --rm -p 8080:8080 expense-restful-service:native
```

### Podman - Linux/Mac

```bash
podman run -i --rm -p 8080:8080 expense-restful-service:native
```

### Podman - Windows (PowerShell con WSL2)

```powershell
wsl podman run -i --rm -p 8080:8080 expense-restful-service:native
```

## 12. Ejecutar pruebas en contenedor

### 12.1. Construir imagen de prueba con Docker

### Linux/Mac

```bash
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:test .
docker run -i --rm expense-restful-service:test mvn test
```

### Windows (CMD)

```cmd
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:test .
docker run -i --rm expense-restful-service:test mvn test
```

### Windows (PowerShell)

```powershell
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:test .
docker run -i --rm expense-restful-service:test mvn test
```

### 12.2. Construir imagen de prueba con Podman

### Linux/Mac

```bash
podman build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:test .
podman run -i --rm expense-restful-service:test mvn test
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:test .
wsl podman run -i --rm expense-restful-service:test mvn test
```

## 13. Ver reportes de pruebas

### 13.1. Abrir reportes de pruebas

Después de ejecutar `mvn test`, los reportes se generan en:

- **Reportes XML**: `target/surefire-reports/TEST-*.xml`
- **Reportes de texto**: `target/surefire-reports/*.txt`

### 13.2. Ver reportes en el navegador (Opcional)

Puedes usar herramientas como `maven-surefire-report-plugin` para generar reportes HTML:

### Linux/Mac

```bash
mvn surefire-report:report
```

### Windows (CMD)

```cmd
mvn surefire-report:report
```

### Windows (PowerShell)

```powershell
mvn surefire-report:report
```

Luego abre: `target/site/surefire-report.html` en tu navegador.

## Resumen

En este laboratorio has aprendido a:
- ✅ Escribir pruebas unitarias usando JUnit 5
- ✅ Usar la anotación `@QuarkusTest` para pruebas de integración
- ✅ Probar endpoints REST usando REST Assured
- ✅ Ejecutar pruebas con Maven
- ✅ Construir imágenes de contenedor con Docker
- ✅ Construir imágenes de contenedor con Podman
- ✅ Ejecutar aplicaciones en contenedores
- ✅ Construir ejecutables nativos

## Próximos pasos

- Explora más funcionalidades de REST Assured (filtros, autenticación, etc.)
- Implementa pruebas de integración más complejas
- Agrega pruebas de rendimiento usando JMeter o Gatling
- Implementa pruebas de mutación usando Pitest
- Configura CI/CD para ejecutar pruebas automáticamente

## Comandos de referencia rápida

### Ejecutar pruebas

```bash
# Linux/Mac/Windows
mvn test
```

### Ejecutar en modo desarrollo

```bash
# Linux/Mac/Windows
mvn quarkus:dev
```

### Construir aplicación

```bash
# Linux/Mac/Windows
mvn clean package
```

### Construir imagen Docker

```bash
# Linux/Mac/Windows
docker build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### Construir imagen Podman

```bash
# Linux/Mac
podman build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .

# Windows (WSL2)
wsl podman build -f src/main/docker/Dockerfile.jvm -t expense-restful-service:jvm .
```

### Ejecutar contenedor Docker

```bash
# Linux/Mac/Windows
docker run -i --rm -p 8080:8080 expense-restful-service:jvm
```

### Ejecutar contenedor Podman

```bash
# Linux/Mac
podman run -i --rm -p 8080:8080 expense-restful-service:jvm

# Windows (WSL2)
wsl podman run -i --rm -p 8080:8080 expense-restful-service:jvm
```

---

**Enjoy!**

**Joe**

