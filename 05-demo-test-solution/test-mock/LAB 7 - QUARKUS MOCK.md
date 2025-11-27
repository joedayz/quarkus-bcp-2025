# LAB 7: QUARKUS MOCK

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

En este laboratorio aprenderás a:
- Usar `@InjectMock` para mockear servicios en Quarkus
- Mockear entidades Panache usando `PanacheMock`
- Mockear REST Clients en pruebas
- Usar Spies para verificar comportamiento
- Ejecutar pruebas con Maven
- Construir y ejecutar contenedores con Docker y Podman

## 1. Cargar en su IDE el proyecto test-mock

Abre el proyecto `05-demo-test-start/test-mock/expenses-service` en tu IDE preferido.

## 2. Examinar la estructura del proyecto

### 2.1. Clases principales

El proyecto contiene:
- `Expense`: Entidad Panache que representa un gasto
- `ExpenseResource`: Recurso REST que expone endpoints para gestionar gastos
- `ExpenseService`: Servicio que contiene la lógica de negocio
- `FraudScoreService`: Interfaz REST Client que consume un servicio externo de fraude
- `FraudScore`: Clase que representa el score de fraude

### 2.2. Clases de prueba

El proyecto contiene cinco clases de prueba:
- `CrudTest`: Pruebas CRUD completas (ya implementadas)
- `ServiceMockTest`: Pruebas usando `@InjectMock` para mockear servicios
- `PanacheMockTest`: Pruebas usando `PanacheMock` para mockear entidades Panache
- `RestClientMockTest`: Pruebas mockeando REST Clients
- `SpyTest`: Pruebas usando Spies para verificar comportamiento

## 3. Examinar las pruebas existentes

### 3.1. Abre la clase `CrudTest`

Ubicada en: `src/test/java/com/bcp/training/expense/CrudTest.java`

Esta clase contiene pruebas de integración completas que verifican las operaciones CRUD:
- `initialListOfExpensesIsEmpty()`: Verifica que la lista inicial esté vacía
- `creatingAnExpenseReturns201WithHeaders()`: Verifica la creación de un gasto
- `updateNonExistingExpenseReturns404()`: Verifica el error al actualizar un gasto inexistente
- `updateExistingExpenseReturns200()`: Verifica la actualización exitosa
- `deleteNonExistingExpenseReturns404()`: Verifica el error al eliminar un gasto inexistente
- `deleteExistingExpenseReturns204()`: Verifica la eliminación exitosa

### 3.2. Ejecuta las pruebas existentes

### Linux/Mac

```bash
cd expenses-service
mvn test
```

### Windows (CMD)

```cmd
cd expenses-service
mvn test
```

### Windows (PowerShell)

```powershell
cd expenses-service
mvn test
```

**Resultado esperado:** `CrudTest` debería pasar exitosamente.

## 4. Implementar pruebas con @InjectMock

### 4.1. Abre la clase `ServiceMockTest`

Ubicada en: `src/test/java/com/bcp/training/expense/ServiceMockTest.java`

### 4.2. Implementa la prueba mockeando `ExpenseService`

Reemplaza el contenido de la clase con:

```java
package com.bcp.training.expense;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.InjectMock;
import io.restassured.http.ContentType;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.ArrayList;
import java.util.List;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class ServiceMockTest {

    @InjectMock
    ExpenseService expenseService;

    @Test
    public void testListExpensesWithMock() {
        // Arrange
        List<Expense> mockExpenses = new ArrayList<>();
        Expense expense1 = new Expense("Expense 1", Expense.PaymentMethod.CASH, 1000.0);
        Expense expense2 = new Expense("Expense 2", Expense.PaymentMethod.CREDIT_CARD, 2000.0);
        mockExpenses.add(expense1);
        mockExpenses.add(expense2);

        Mockito.when(expenseService.list()).thenReturn(mockExpenses);

        // Act & Assert
        given()
            .when()
            .get("/expenses")
            .then()
            .statusCode(200)
            .body("$.size()", is(2))
            .body("[0].name", is("Expense 1"))
            .body("[1].name", is("Expense 2"));
    }

    @Test
    public void testCreateExpenseWithMock() {
        // Arrange
        Expense mockExpense = new Expense("Mock Expense", Expense.PaymentMethod.CASH, 1000.0);
        Mockito.when(expenseService.meetsMinimumAmount(Mockito.anyDouble())).thenReturn(true);
        Mockito.when(expenseService.create(Mockito.any(Expense.class))).thenReturn(mockExpense);

        // Act & Assert
        given()
            .contentType(ContentType.JSON)
            .body("{\"name\":\"Test Expense\",\"paymentMethod\":\"CASH\",\"amount\":1000.0}")
            .when()
            .post("/expenses")
            .then()
            .statusCode(201);

        // Verify
        Mockito.verify(expenseService).meetsMinimumAmount(1000.0);
        Mockito.verify(expenseService).create(Mockito.any(Expense.class));
    }
}
```

### 4.3. Ejecuta las pruebas

### Linux/Mac

```bash
mvn test -Dtest=ServiceMockTest
```

### Windows (CMD)

```cmd
mvn test -Dtest=ServiceMockTest
```

### Windows (PowerShell)

```powershell
mvn test -Dtest=ServiceMockTest
```

**Resultado esperado:** Las pruebas deberían pasar exitosamente.

## 5. Implementar pruebas con PanacheMock

### 5.1. Abre la clase `PanacheMockTest`

Ubicada en: `src/test/java/com/bcp/training/expense/PanacheMockTest.java`

### 5.2. Implementa la prueba mockeando entidades Panache

Reemplaza el contenido de la clase con:

```java
package com.bcp.training.expense;

import io.quarkus.panache.mock.PanacheMock;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.Collections;
import java.util.List;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class PanacheMockTest {

    @BeforeEach
    public void setup() {
        PanacheMock.mock(Expense.class);
    }

    @Test
    public void testListExpensesWithPanacheMock() {
        // Arrange
        List<Expense> mockExpenses = Collections.emptyList();
        Mockito.when(Expense.listAll()).thenReturn(mockExpenses);

        // Act & Assert
        given()
            .when()
            .get("/expenses")
            .then()
            .statusCode(200)
            .body("$.size()", is(0));
    }

    @Test
    public void testListExpensesWithData() {
        // Arrange
        Expense expense1 = new Expense("Expense 1", Expense.PaymentMethod.CASH, 1000.0);
        Expense expense2 = new Expense("Expense 2", Expense.PaymentMethod.CREDIT_CARD, 2000.0);
        List<Expense> mockExpenses = List.of(expense1, expense2);
        
        Mockito.when(Expense.listAll()).thenReturn(mockExpenses);

        // Act & Assert
        given()
            .when()
            .get("/expenses")
            .then()
            .statusCode(200)
            .body("$.size()", is(2));
    }
}
```

### 5.3. Ejecuta las pruebas

### Linux/Mac

```bash
mvn test -Dtest=PanacheMockTest
```

### Windows (CMD)

```cmd
mvn test -Dtest=PanacheMockTest
```

### Windows (PowerShell)

```powershell
mvn test -Dtest=PanacheMockTest
```

**Resultado esperado:** Las pruebas deberían pasar exitosamente.

## 6. Implementar pruebas mockeando REST Clients

### 6.1. Abre la clase `RestClientMockTest`

Ubicada en: `src/test/java/com/bcp/training/expense/RestClientMockTest.java`

### 6.2. Implementa la prueba mockeando `FraudScoreService`

Reemplaza el contenido de la clase con:

```java
package com.bcp.training.expense;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.InjectMock;
import io.restassured.http.ContentType;

import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static io.restassured.RestAssured.given;

@QuarkusTest
public class RestClientMockTest {

    @InjectMock
    @RestClient
    FraudScoreService fraudScoreService;

    @Test
    public void testFraudScoreWithLowScore() {
        // Arrange
        FraudScore lowScore = new FraudScore(50);
        Mockito.when(fraudScoreService.getByAmount(Mockito.anyDouble())).thenReturn(lowScore);

        // Act & Assert
        given()
            .contentType(ContentType.JSON)
            .body("{\"name\":\"Test Expense\",\"paymentMethod\":\"CASH\",\"amount\":1000.0}")
            .when()
            .post("/expenses/score")
            .then()
            .statusCode(200);

        // Verify
        Mockito.verify(fraudScoreService).getByAmount(1000.0);
    }

    @Test
    public void testFraudScoreWithHighScore() {
        // Arrange
        FraudScore highScore = new FraudScore(250);
        Mockito.when(fraudScoreService.getByAmount(Mockito.anyDouble())).thenReturn(highScore);

        // Act & Assert
        given()
            .contentType(ContentType.JSON)
            .body("{\"name\":\"Test Expense\",\"paymentMethod\":\"CASH\",\"amount\":1000.0}")
            .when()
            .post("/expenses/score")
            .then()
            .statusCode(400);

        // Verify
        Mockito.verify(fraudScoreService).getByAmount(1000.0);
    }
}
```

### 6.3. Ejecuta las pruebas

### Linux/Mac

```bash
mvn test -Dtest=RestClientMockTest
```

### Windows (CMD)

```cmd
mvn test -Dtest=RestClientMockTest
```

### Windows (PowerShell)

```powershell
mvn test -Dtest=RestClientMockTest
```

**Resultado esperado:** Las pruebas deberían pasar exitosamente.

## 7. Implementar pruebas con Spies

### 7.1. Abre la clase `SpyTest`

Ubicada en: `src/test/java/com/bcp/training/expense/SpyTest.java`

### 7.2. Implementa la prueba usando Spies

Reemplaza el contenido de la clase con:

```java
package com.bcp.training.expense;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class SpyTest {

    @InjectSpy
    ExpenseService expenseService;

    @Test
    public void testListExpensesWithSpy() {
        // Act
        given()
            .when()
            .get("/expenses")
            .then()
            .statusCode(200)
            .body("$.size()", is(0));

        // Verify - El spy permite verificar que se llamó el método real
        Mockito.verify(expenseService).list();
    }

    @Test
    public void testCreateExpenseWithSpy() {
        // Act
        given()
            .contentType("application/json")
            .body("{\"name\":\"Test Expense\",\"paymentMethod\":\"CASH\",\"amount\":1000.0}")
            .when()
            .post("/expenses")
            .then()
            .statusCode(201);

        // Verify - Verificamos que se llamaron los métodos reales
        Mockito.verify(expenseService).meetsMinimumAmount(1000.0);
        Mockito.verify(expenseService).create(Mockito.any(Expense.class));
    }
}
```

### 7.3. Ejecuta las pruebas

### Linux/Mac

```bash
mvn test -Dtest=SpyTest
```

### Windows (CMD)

```cmd
mvn test -Dtest=SpyTest
```

### Windows (PowerShell)

```powershell
mvn test -Dtest=SpyTest
```

**Resultado esperado:** Las pruebas deberían pasar exitosamente.

## 8. Ejecutar todas las pruebas

### 8.1. Ejecuta todas las pruebas del proyecto

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

**Resultado esperado:** Todas las pruebas deberían pasar exitosamente.

## 9. Ejecutar la aplicación en modo desarrollo

### 9.1. Inicia la aplicación

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

### 9.2. Verifica que la aplicación esté corriendo

Abre tu navegador y visita:
- **API REST**: http://localhost:8080/expenses
- **Swagger UI**: http://localhost:8080/q/swagger-ui

## 10. Probar el endpoint manualmente

### 10.1. Listar todos los gastos

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

### 10.2. Crear un nuevo gasto

### Linux/Mac

```bash
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"Training Course","paymentMethod":"CREDIT_CARD","amount":1000.0}'
```

### Windows (CMD)

```cmd
curl -X POST http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"name\":\"Training Course\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":1000.0}"
```

### Windows (PowerShell)

```powershell
$body = @{
    name = "Training Course"
    paymentMethod = "CREDIT_CARD"
    amount = 1000.0
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

## 11. Construir la aplicación

### 11.1. Construir el JAR

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

### 11.2. Verificar que el JAR se haya creado

El JAR debería estar en: `target/quarkus-app/quarkus-run.jar`

## 12. Construir imagen de contenedor con Docker

### 12.1. Verificar que Docker esté instalado

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

### 12.2. Construir la imagen JVM

### Linux/Mac

```bash
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### Windows (CMD)

```cmd
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### Windows (PowerShell)

```powershell
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### 12.3. Ejecutar el contenedor Docker

### Linux/Mac

```bash
docker run -i --rm -p 8080:8080 expenses-service:jvm
```

### Windows (CMD)

```cmd
docker run -i --rm -p 8080:8080 expenses-service:jvm
```

### Windows (PowerShell)

```powershell
docker run -i --rm -p 8080:8080 expenses-service:jvm
```

### 12.4. Verificar que el contenedor esté corriendo

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

## 13. Construir imagen de contenedor con Podman

### 13.1. Verificar que Podman esté instalado

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

### 13.2. Construir la imagen JVM con Podman

### Linux/Mac

```bash
podman build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### 13.3. Ejecutar el contenedor Podman

### Linux/Mac

```bash
podman run -i --rm -p 8080:8080 expenses-service:jvm
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman run -i --rm -p 8080:8080 expenses-service:jvm
```

### 13.4. Verificar que el contenedor esté corriendo

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

## 14. Construir imagen nativa (Opcional)

### 14.1. Construir el ejecutable nativo

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

### 14.2. Construir la imagen nativa con Docker

### Linux/Mac

```bash
docker build -f src/main/docker/Dockerfile.native -t expenses-service:native .
```

### Windows (CMD)

```cmd
docker build -f src/main/docker/Dockerfile.native -t expenses-service:native .
```

### Windows (PowerShell)

```powershell
docker build -f src/main/docker/Dockerfile.native -t expenses-service:native .
```

### 14.3. Construir la imagen nativa con Podman

### Linux/Mac

```bash
podman build -f src/main/docker/Dockerfile.native -t expenses-service:native .
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman build -f src/main/docker/Dockerfile.native -t expenses-service:native .
```

### 14.4. Ejecutar el contenedor nativo

### Docker - Linux/Mac

```bash
docker run -i --rm -p 8080:8080 expenses-service:native
```

### Docker - Windows (CMD)

```cmd
docker run -i --rm -p 8080:8080 expenses-service:native
```

### Docker - Windows (PowerShell)

```powershell
docker run -i --rm -p 8080:8080 expenses-service:native
```

### Podman - Linux/Mac

```bash
podman run -i --rm -p 8080:8080 expenses-service:native
```

### Podman - Windows (PowerShell con WSL2)

```powershell
wsl podman run -i --rm -p 8080:8080 expenses-service:native
```

## 15. Ejecutar pruebas en contenedor

### 15.1. Construir imagen de prueba con Docker

### Linux/Mac

```bash
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:test .
docker run -i --rm expenses-service:test mvn test
```

### Windows (CMD)

```cmd
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:test .
docker run -i --rm expenses-service:test mvn test
```

### Windows (PowerShell)

```powershell
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:test .
docker run -i --rm expenses-service:test mvn test
```

### 15.2. Construir imagen de prueba con Podman

### Linux/Mac

```bash
podman build -f src/main/docker/Dockerfile.jvm -t expenses-service:test .
podman run -i --rm expenses-service:test mvn test
```

### Windows (PowerShell con WSL2)

```powershell
wsl podman build -f src/main/docker/Dockerfile.jvm -t expenses-service:test .
wsl podman run -i --rm expenses-service:test mvn test
```

## 16. Ver reportes de pruebas

### 16.1. Abrir reportes de pruebas

Después de ejecutar `mvn test`, los reportes se generan en:

- **Reportes XML**: `target/surefire-reports/TEST-*.xml`
- **Reportes de texto**: `target/surefire-reports/*.txt`

### 16.2. Ver reportes en el navegador (Opcional)

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
- ✅ Usar `@InjectMock` para mockear servicios en Quarkus
- ✅ Mockear entidades Panache usando `PanacheMock`
- ✅ Mockear REST Clients en pruebas
- ✅ Usar Spies para verificar comportamiento
- ✅ Ejecutar pruebas con Maven
- ✅ Construir imágenes de contenedor con Docker
- ✅ Construir imágenes de contenedor con Podman
- ✅ Ejecutar aplicaciones en contenedores
- ✅ Construir ejecutables nativos

## Diferencias entre Mock y Spy

### Mock
- Reemplaza completamente el objeto
- No ejecuta el código real
- Útil para aislar dependencias
- Se usa con `@InjectMock`

### Spy
- Envuelve el objeto real
- Ejecuta el código real por defecto
- Permite verificar llamadas a métodos
- Útil para verificar comportamiento
- Se usa con `@InjectSpy`

## Próximos pasos

- Explora más funcionalidades de Mockito (argument matchers, captors, etc.)
- Implementa pruebas más complejas con múltiples mocks
- Agrega pruebas de rendimiento usando JMeter o Gatling
- Implementa pruebas de mutación usando Pitest
- Configura CI/CD para ejecutar pruebas automáticamente
- Aprende sobre `@QuarkusMock` para mockear beans en tiempo de ejecución

## Comandos de referencia rápida

### Ejecutar pruebas

```bash
# Linux/Mac/Windows
mvn test

# Ejecutar una clase específica
mvn test -Dtest=ServiceMockTest
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
docker build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### Construir imagen Podman

```bash
# Linux/Mac
podman build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .

# Windows (WSL2)
wsl podman build -f src/main/docker/Dockerfile.jvm -t expenses-service:jvm .
```

### Ejecutar contenedor Docker

```bash
# Linux/Mac/Windows
docker run -i --rm -p 8080:8080 expenses-service:jvm
```

### Ejecutar contenedor Podman

```bash
# Linux/Mac
podman run -i --rm -p 8080:8080 expenses-service:jvm

# Windows (WSL2)
wsl podman run -i --rm -p 8080:8080 expenses-service:jvm
```

---

**Enjoy!**

**Joe**

