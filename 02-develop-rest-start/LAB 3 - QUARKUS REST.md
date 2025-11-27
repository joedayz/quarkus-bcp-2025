# LAB 3: QUARKUS REST

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

En este laboratorio aprenderás a:
- Crear endpoints REST usando Jakarta REST (JAX-RS)
- Implementar un servicio de aplicación con CDI
- Configurar un cliente REST usando MicroProfile REST Client
- Probar los endpoints usando Swagger UI

## 1. Cargar en su IDE el proyecto 02-develop-rest-start

Abre el proyecto en tu IDE preferido. El proyecto contiene dos módulos:
- `expense-service`: Servicio REST que gestiona gastos
- `expense-client`: Cliente que consume el servicio REST

## 2. Examinar la estructura del proyecto

### 2.1. Módulo expense-service

El módulo `expense-service` contiene:
- `Expense`: Modelo de datos que representa un gasto
- `ExpenseService`: Servicio de aplicación que gestiona los gastos
- `ExpenseResource`: Recurso REST (actualmente incompleto)

### 2.2. Módulo expense-client

El módulo `expense-client` contiene:
- `ExpenseServiceClient`: Interfaz del cliente REST (incompleta)
- `ClientResource`: Recurso REST que consume el servicio

## 3. Implementar el ExpenseResource

### 3.1. Abre la clase `ExpenseResource`

Ubicada en: `expense-service/src/main/java/com/bcp/training/ExpenseResource.java`

### 3.2. Agrega las anotaciones JAX-RS necesarias

Agrega las siguientes anotaciones a la clase:

```java
@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {
```

### 3.3. Inyecta el ExpenseService

Agrega la anotación `@Inject` al campo `expenseService`:

```java
@Inject
public ExpenseService expenseService;
```

### 3.4. Anota los métodos HTTP

Agrega las anotaciones HTTP correspondientes a cada método:

- `list()` → `@GET`
- `create(Expense expense)` → `@POST`
- `delete(UUID uuid)` → `@DELETE` y `@Path("/{uuid}")`
- `update(Expense expense)` → `@PUT`

**Resultado esperado:**

```java
@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {

    @Inject
    public ExpenseService expenseService;

    @GET
    public Set<Expense> list() {
        return expenseService.list();
    }

    @POST
    public Expense create(Expense expense) {
        return expenseService.create(expense);
    }

    @DELETE
    @Path("/{uuid}")
    public Set<Expense> delete(UUID uuid) {
        if (!expenseService.delete(uuid)) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
        return expenseService.list();
    }

    @PUT
    public void update(Expense expense) {
        expenseService.update(expense);
    }
}
```

## 4. Configurar el ExpenseService como bean CDI

### 4.1. Abre la clase `ExpenseService`

Ubicada en: `expense-service/src/main/java/com/bcp/training/ExpenseService.java`

### 4.2. Agrega la anotación `@ApplicationScoped`

```java
@ApplicationScoped
public class ExpenseService {
```

### 4.3. Agrega un método de inicialización

Agrega un método `init()` anotado con `@PostConstruct` para inicializar algunos gastos de ejemplo:

```java
@PostConstruct
void init(){
    expenses.add(new Expense("Quarkus for Spring Developers", Expense.PaymentMethod.DEBIT_CARD, "10.00"));
    expenses.add(new Expense("OpenShift for Developers", Expense.PaymentMethod.CREDIT_CARD, "15.00"));
}
```

## 5. Iniciar el servicio expense-service

### 5.1. Navega al directorio expense-service

### Linux/Mac

```bash
cd expense-service
```

### Windows (CMD)

```cmd
cd expense-service
```

### Windows (PowerShell)

```powershell
cd expense-service
```

### 5.2. Inicia la aplicación en modo desarrollo

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

### 5.3. Verifica que la aplicación esté corriendo

Abre tu navegador y visita:
- **Swagger UI**: http://localhost:8080/q/swagger-ui
- **OpenAPI JSON**: http://localhost:8080/q/openapi

Deberías ver los endpoints disponibles en Swagger UI.

## 6. Probar los endpoints del servicio

### 6.1. Listar todos los gastos

Usa curl o Swagger UI para hacer una petición GET:

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

**Resultado esperado:** Deberías ver un array JSON con los gastos inicializados.

### 6.2. Crear un nuevo gasto

### Linux/Mac

```bash
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"New Book","paymentMethod":"CASH","amount":"25.50"}'
```

### Windows (CMD)

```cmd
curl -X POST http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"name\":\"New Book\",\"paymentMethod\":\"CASH\",\"amount\":\"25.50\"}"
```

### Windows (PowerShell)

```powershell
$body = @{
    name = "New Book"
    paymentMethod = "CASH"
    amount = "25.50"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

## 7. Implementar el cliente REST

### 7.1. Abre la interfaz `ExpenseServiceClient`

Ubicada en: `expense-client/src/main/java/com/bcp/training/client/ExpenseServiceClient.java`

### 7.2. Agrega las anotaciones necesarias

```java
@Path("/expenses")
@RegisterRestClient(configKey = "expense-service")
public interface ExpenseServiceClient {
```

### 7.3. Abre la clase `ClientResource`

Ubicada en: `expense-client/src/main/java/com/bcp/training/service/ClientResource.java`

### 7.4. Inyecta el cliente REST

Agrega las anotaciones `@Inject` y `@RestClient`:

```java
@Inject
@RestClient
ExpenseServiceClient service;
```

## 8. Configurar el cliente REST

### 8.1. Abre el archivo `application.properties`

Ubicado en: `expense-client/src/main/resources/application.properties`

### 8.2. Verifica la configuración

El archivo debe contener:

```properties
quarkus.http.port=8090
quarkus.rest-client.expense-service.url=http://localhost:8080
```

## 9. Iniciar el cliente expense-client

### 9.1. Abre una nueva terminal

Mantén el servicio `expense-service` corriendo en la primera terminal.

### 9.2. Navega al directorio expense-client

### Linux/Mac

```bash
cd expense-client
```

### Windows (CMD)

```cmd
cd expense-client
```

### Windows (PowerShell)

```powershell
cd expense-client
```

### 9.3. Inicia la aplicación cliente

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

### 9.4. Verifica que el cliente esté corriendo

Abre tu navegador y visita:
- **Cliente REST**: http://localhost:8090/expenses
- **Swagger UI**: http://localhost:8090/q/swagger-ui

## 10. Probar el cliente REST

### 10.1. Listar gastos a través del cliente

### Linux/Mac

```bash
curl http://localhost:8090/expenses
```

### Windows (CMD)

```cmd
curl http://localhost:8090/expenses
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8090/expenses -Method GET | Select-Object -ExpandProperty Content
```

**Resultado esperado:** Deberías ver los mismos gastos que se muestran en el servicio.

### 10.2. Crear un gasto a través del cliente

### Linux/Mac

```bash
curl -X POST http://localhost:8090/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"Training Course","paymentMethod":"CREDIT_CARD","amount":"99.99"}'
```

### Windows (CMD)

```cmd
curl -X POST http://localhost:8090/expenses -H "Content-Type: application/json" -d "{\"name\":\"Training Course\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":\"99.99\"}"
```

### Windows (PowerShell)

```powershell
$body = @{
    name = "Training Course"
    paymentMethod = "CREDIT_CARD"
    amount = "99.99"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8090/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

## 11. Configurar las propiedades de imagen de contenedor

### 11.1. Actualiza expense-service/application.properties

Abre `expense-service/src/main/resources/application.properties` y reemplaza los valores `TODO`:

```properties
quarkus.swagger-ui.always-include=true

quarkus.container-image.build=true
quarkus.container-image.group=quay.io
quarkus.container-image.name=expense-service
```

### 11.2. Actualiza expense-client/application.properties

Abre `expense-client/src/main/resources/application.properties` y reemplaza los valores `TODO`:

```properties
quarkus.http.port=8090
quarkus.rest-client.expense-service.url=http://localhost:8080

quarkus.container-image.build=true
quarkus.container-image.group=quay.io
quarkus.container-image.name=expense-client
```

## 12. Construir las imágenes de contenedor (Opcional)

### 12.1. Construir la imagen del servicio

Navega al directorio `expense-service` y ejecuta:

### Linux/Mac

```bash
mvn clean package -Dquarkus.container-image.build=true
```

### Windows (CMD)

```cmd
mvn clean package -Dquarkus.container-image.build=true
```

### Windows (PowerShell)

```powershell
mvn clean package -Dquarkus.container-image.build=true
```

### 12.2. Construir la imagen del cliente

Navega al directorio `expense-client` y ejecuta:

### Linux/Mac

```bash
mvn clean package -Dquarkus.container-image.build=true
```

### Windows (CMD)

```cmd
mvn clean package -Dquarkus.container-image.build=true
```

### Windows (PowerShell)

```powershell
mvn clean package -Dquarkus.container-image.build=true
```

## Resumen

En este laboratorio has aprendido a:
- ✅ Crear endpoints REST usando anotaciones JAX-RS
- ✅ Inyectar dependencias con CDI usando `@Inject`
- ✅ Configurar beans CDI con `@ApplicationScoped`
- ✅ Implementar un cliente REST con MicroProfile REST Client
- ✅ Configurar y usar Swagger UI para probar APIs
- ✅ Configurar propiedades de imagen de contenedor

## Próximos pasos

- Explora más anotaciones JAX-RS como `@QueryParam`, `@PathParam`, `@HeaderParam`
- Implementa validación usando Bean Validation
- Agrega manejo de excepciones personalizado
- Implementa paginación y filtrado

---

**Enjoy!**

**Joe**

