# LAB 3: QUARKUS REST - SOLUCIÓN

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

Este documento contiene la solución completa del LAB 3: QUARKUS REST. Aquí encontrarás el código final implementado y los comandos para ejecutar y probar la solución.

## Estructura de la Solución

### Módulo expense-service

#### ExpenseResource.java

```java
package com.bcp.training;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Set;
import java.util.UUID;

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

#### ExpenseService.java

```java
package com.bcp.training;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Collections;
import java.util.HashMap;
import java.util.Set;
import java.util.UUID;

@ApplicationScoped
public class ExpenseService {
    private Set<Expense> expenses = Collections.newSetFromMap(Collections.synchronizedMap(new HashMap<>()));

    @PostConstruct
    void init(){
        expenses.add(new Expense("Quarkus for Spring Developers", Expense.PaymentMethod.DEBIT_CARD, "10.00"));
        expenses.add(new Expense("OpenShift for Developers", Expense.PaymentMethod.CREDIT_CARD, "15.00"));
    }

    public Set<Expense> list() {
        return expenses;
    }

    public Expense create(Expense expense) {
        expenses.add(expense);
        return expense;
    }

    public boolean delete(UUID uuid) {
        return expenses.removeIf(expense -> expense.getUuid().equals(uuid));
    }

    public void update(Expense expense) {
        delete(expense.getUuid());
        create(expense);
    }

    public boolean exists(UUID uuid) {
        return expenses.stream().anyMatch(exp -> exp.getUuid().equals(uuid));
    }
}
```

#### application.properties

```properties
quarkus.swagger-ui.always-include=true

quarkus.container-image.build=true
quarkus.container-image.group=quay.io
quarkus.container-image.name=expense-service
```

### Módulo expense-client

#### ExpenseServiceClient.java

```java
package com.bcp.training.client;

import com.bcp.training.model.Expense;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.Set;

@Path("/expenses")
@RegisterRestClient(configKey = "expense-service")
public interface ExpenseServiceClient {

    @GET
    Set<Expense> getAll();

    @POST
    Expense create(Expense expense);
}
```

#### ClientResource.java

```java
package com.bcp.training.service;

import com.bcp.training.client.ExpenseServiceClient;
import com.bcp.training.model.Expense;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.util.Set;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ClientResource {

    @Inject
    @RestClient
    ExpenseServiceClient service;

    @GET
    public Set<Expense> getAll() {
        return service.getAll();
    }

    @POST
    public Expense create(Expense expense) {
        return service.create(expense);
    }
}
```

#### application.properties

```properties
quarkus.http.port=8090
quarkus.rest-client.expense-service.url=http://localhost:8080

quarkus.container-image.build=true
quarkus.container-image.group=quay.io
quarkus.container-image.name=expense-client
```

## Ejecutar la Solución

### 1. Iniciar el servicio expense-service

#### Linux/Mac

```bash
cd expense-service
mvn quarkus:dev
```

#### Windows (CMD)

```cmd
cd expense-service
mvn quarkus:dev
```

#### Windows (PowerShell)

```powershell
cd expense-service
mvn quarkus:dev
```

El servicio estará disponible en: http://localhost:8080

### 2. Iniciar el cliente expense-client (en otra terminal)

#### Linux/Mac

```bash
cd expense-client
mvn quarkus:dev
```

#### Windows (CMD)

```cmd
cd expense-client
mvn quarkus:dev
```

#### Windows (PowerShell)

```powershell
cd expense-client
mvn quarkus:dev
```

El cliente estará disponible en: http://localhost:8090

## Probar la Solución

### 1. Acceder a Swagger UI del servicio

Abre tu navegador y visita:
- **Swagger UI**: http://localhost:8080/q/swagger-ui
- **OpenAPI JSON**: http://localhost:8080/q/openapi

### 2. Listar todos los gastos (servicio)

#### Linux/Mac

```bash
curl http://localhost:8080/expenses
```

#### Windows (CMD)

```cmd
curl http://localhost:8080/expenses
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/expenses -Method GET | Select-Object -ExpandProperty Content
```

**Resultado esperado:**

```json
[
  {
    "uuid": "...",
    "name": "Quarkus for Spring Developers",
    "creationDate": "...",
    "paymentMethod": "DEBIT_CARD",
    "amount": 10.00
  },
  {
    "uuid": "...",
    "name": "OpenShift for Developers",
    "creationDate": "...",
    "paymentMethod": "CREDIT_CARD",
    "amount": 15.00
  }
]
```

### 3. Crear un nuevo gasto (servicio)

#### Linux/Mac

```bash
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"New Book","paymentMethod":"CASH","amount":"25.50"}'
```

#### Windows (CMD)

```cmd
curl -X POST http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"name\":\"New Book\",\"paymentMethod\":\"CASH\",\"amount\":\"25.50\"}"
```

#### Windows (PowerShell)

```powershell
$body = @{
    name = "New Book"
    paymentMethod = "CASH"
    amount = "25.50"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

### 4. Actualizar un gasto (servicio)

Primero, obtén el UUID de un gasto existente. Luego:

#### Linux/Mac

```bash
curl -X PUT http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"uuid":"<UUID>","name":"Updated Book","paymentMethod":"CREDIT_CARD","amount":"30.00"}'
```

#### Windows (CMD)

```cmd
curl -X PUT http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"uuid\":\"<UUID>\",\"name\":\"Updated Book\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":\"30.00\"}"
```

#### Windows (PowerShell)

```powershell
$body = @{
    uuid = "<UUID>"
    name = "Updated Book"
    paymentMethod = "CREDIT_CARD"
    amount = "30.00"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method PUT -Body $body -ContentType "application/json"
```

### 5. Eliminar un gasto (servicio)

#### Linux/Mac

```bash
curl -X DELETE http://localhost:8080/expenses/<UUID>
```

#### Windows (CMD)

```cmd
curl -X DELETE http://localhost:8080/expenses/<UUID>
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8080/expenses/<UUID> -Method DELETE
```

### 6. Listar gastos a través del cliente

#### Linux/Mac

```bash
curl http://localhost:8090/expenses
```

#### Windows (CMD)

```cmd
curl http://localhost:8090/expenses
```

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri http://localhost:8090/expenses -Method GET | Select-Object -ExpandProperty Content
```

### 7. Crear un gasto a través del cliente

#### Linux/Mac

```bash
curl -X POST http://localhost:8090/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"Training Course","paymentMethod":"CREDIT_CARD","amount":"99.99"}'
```

#### Windows (CMD)

```cmd
curl -X POST http://localhost:8090/expenses -H "Content-Type: application/json" -d "{\"name\":\"Training Course\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":\"99.99\"}"
```

#### Windows (PowerShell)

```powershell
$body = @{
    name = "Training Course"
    paymentMethod = "CREDIT_CARD"
    amount = "99.99"
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8090/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

## Construir Imágenes de Contenedor

### Construir imagen del servicio

#### Linux/Mac

```bash
cd expense-service
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (CMD)

```cmd
cd expense-service
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (PowerShell)

```powershell
cd expense-service
mvn clean package -Dquarkus.container-image.build=true
```

### Construir imagen del cliente

#### Linux/Mac

```bash
cd expense-client
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (CMD)

```cmd
cd expense-client
mvn clean package -Dquarkus.container-image.build=true
```

#### Windows (PowerShell)

```powershell
cd expense-client
mvn clean package -Dquarkus.container-image.build=true
```

## Puntos Clave de la Solución

### 1. Anotaciones JAX-RS

- `@Path`: Define la ruta base del recurso
- `@GET`, `@POST`, `@PUT`, `@DELETE`: Métodos HTTP
- `@Consumes`: Tipo de contenido que acepta el recurso
- `@Produces`: Tipo de contenido que produce el recurso
- `@Path("/{uuid}")`: Parámetro de ruta

### 2. Inyección de Dependencias

- `@Inject`: Inyecta dependencias usando CDI
- `@ApplicationScoped`: Bean con alcance de aplicación
- `@PostConstruct`: Método ejecutado después de la construcción

### 3. Cliente REST

- `@RegisterRestClient`: Registra la interfaz como cliente REST
- `@RestClient`: Inyecta el cliente REST
- `configKey`: Clave de configuración para la URL del servicio

### 4. Manejo de Errores

- `WebApplicationException`: Excepción para errores HTTP
- `Response.Status.NOT_FOUND`: Código de estado 404

## Verificación

Para verificar que la solución está correcta:

1. ✅ El servicio expone endpoints REST en `/expenses`
2. ✅ El servicio inicializa con 2 gastos de ejemplo
3. ✅ El cliente puede consumir el servicio correctamente
4. ✅ Swagger UI muestra todos los endpoints
5. ✅ Las propiedades de imagen de contenedor están configuradas

## Troubleshooting

### El servicio no inicia

- Verifica que el puerto 8080 esté disponible
- Revisa los logs para errores de compilación
- Asegúrate de tener Java 21 instalado

### El cliente no puede conectar al servicio

- Verifica que el servicio esté corriendo en el puerto 8080
- Revisa la configuración en `application.properties`
- Verifica que la URL sea correcta: `http://localhost:8080`

### Error 404 en los endpoints

- Verifica que las rutas en `@Path` sean correctas
- Asegúrate de que los métodos HTTP coincidan
- Revisa que el contenido sea `application/json`

---

**Enjoy!**

**Joe**

