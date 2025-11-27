# LAB 4: QUARKUS PERSISTENT - SOLUCIÓN

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

Este documento contiene la solución completa del laboratorio 4 sobre persistencia con Hibernate ORM y Panache en Quarkus.

## Solución Completa

### 1. Dependencias en `pom.xml`

El archivo `pom.xml` incluye las siguientes dependencias:

```xml
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
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-validator</artifactId>
</dependency>
```

### 2. Configuración en `application.properties`

```properties
quarkus.swagger-ui.always-include=true
quarkus.swagger-ui.enable=true

quarkus.datasource.devservices.image-name=postgres:14.1
quarkus.hibernate-orm.database.generation=drop-and-create
```

### 3. Clase `Associate.java` - Solución Completa

```java
package com.bcp.training.model;

import java.util.List;
import java.util.ArrayList;

import jakarta.json.bind.annotation.JsonbCreator;
import jakarta.json.bind.annotation.JsonbTransient;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.OneToMany;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
public class Associate extends PanacheEntity {
    public String name;

    @JsonbTransient
    @OneToMany(mappedBy = "associate", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    public List<Expense> expenses = new ArrayList<>();

    public Associate() {
    }

    public Associate(String name) {
        this.name = name;
    }

    @JsonbCreator
    public static Associate of(String name) {
        return new Associate(name);
    }
}
```

**Puntos clave:**
- Extiende `PanacheEntity` para obtener métodos CRUD automáticos
- `@Entity` marca la clase como entidad JPA
- `@OneToMany` establece la relación uno-a-muchos con `Expense`
- `@JsonbTransient` evita la serialización circular en JSON
- Constructor sin argumentos requerido por JPA

### 4. Clase `Expense.java` - Solución Completa

```java
package com.bcp.training.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.Optional;

import jakarta.json.bind.annotation.JsonbCreator;
import jakarta.json.bind.annotation.JsonbDateFormat;
import jakarta.json.bind.annotation.JsonbTransient;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;

import io.quarkus.hibernate.orm.panache.PanacheEntity;

@Entity
public class Expense extends PanacheEntity {

    public enum PaymentMethod {
        CASH, CREDIT_CARD, DEBIT_CARD,
    }

    @NotNull
    public UUID uuid;
    public String name;

    @JsonbDateFormat(value = "yyyy-MM-dd HH:mm:ss")
    public LocalDateTime creationDate;
    public PaymentMethod paymentMethod;
    public BigDecimal amount;

    @JsonbTransient
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "associate_id", insertable = false, updatable = false)
    public Associate associate;

    @Column(name = "associate_id")
    public Long associateId;

    public Expense() {
    }

    public Expense(UUID uuid, String name, LocalDateTime creationDate,
                   PaymentMethod paymentMethod, String amount, Associate associate) {
        this.uuid = uuid;
        this.name = name;
        this.creationDate = creationDate;
        this.paymentMethod = paymentMethod;
        this.amount = new BigDecimal(amount);
        this.associate = associate;
        this.associateId = associate.id;
    }

    public Expense(String name, PaymentMethod paymentMethod, String amount, Associate associate) {
        this(UUID.randomUUID(), name, LocalDateTime.now(), paymentMethod, amount, associate);
    }

    @JsonbCreator
    public static Expense of(String name, PaymentMethod paymentMethod, String amount, Long associateId) {
        return Associate.<Associate>findByIdOptional(associateId)
                .map(associate -> new Expense(name, paymentMethod, amount, associate))
                .orElseThrow(RuntimeException::new);
    }

    public static void update(final Expense expense) throws RuntimeException {
        Optional<Expense> previousExpense = Expense.findByIdOptional(expense.id);

        previousExpense.ifPresentOrElse( updatedExpense -> {
            updatedExpense.uuid = expense.uuid;
            updatedExpense.name = expense.name;
            updatedExpense.amount = expense.amount;
            updatedExpense.paymentMethod = expense.paymentMethod;
            updatedExpense.persist();
        }, () -> {
            throw new WebApplicationException( Response.Status.NOT_FOUND );
        });
    }
}
```

**Puntos clave:**
- Extiende `PanacheEntity` para obtener métodos CRUD automáticos
- `@Entity` marca la clase como entidad JPA
- `@ManyToOne` establece la relación muchos-a-uno con `Associate`
- `@Column(name = "associate_id")` mapea el campo a la columna de la base de datos
- `@JoinColumn` configura la columna de unión (solo lectura)
- Método estático `update()` para actualizar entidades existentes
- Método `of()` busca el `Associate` antes de crear el `Expense`

### 5. Clase `ExpenseResource.java` - Solución Completa

```java
package com.bcp.training.rest;

import java.util.List;
import java.util.UUID;

import com.bcp.training.model.Expense;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.DefaultValue;

import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import io.quarkus.panache.common.Sort;

@Path("/expenses")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ExpenseResource {

    @GET
    public List<Expense> list(@DefaultValue("5") @QueryParam("pageSize") int pageSize,
                              @DefaultValue("1") @QueryParam("pageNum") int pageNum) {
        PanacheQuery<Expense> expenseQuery = Expense.findAll(
                Sort.by("amount").and("associateId"));

        return expenseQuery.page(Page.of(pageNum - 1, pageSize)).list();
    }

    @POST
    @Transactional
    public Expense create(final Expense expense) {
        Expense newExpense = Expense.of(expense.name, expense.paymentMethod,
                expense.amount.toString(), expense.associateId);
        newExpense.persist();

        return newExpense;
    }

    @DELETE
    @Path("{uuid}")
    @Transactional
    public void delete(@PathParam("uuid") final UUID uuid) {
        long numExpensesDeleted = Expense.delete("uuid", uuid);

        if (numExpensesDeleted == 0) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
    }

    @PUT
    @Transactional
    public void update(final Expense expense) {
        try {
            Expense.update(expense);
        } catch (RuntimeException e) {
            throw new WebApplicationException(Response.Status.NOT_FOUND);
        }
    }
}
```

**Puntos clave:**
- `@Transactional` en métodos que modifican datos (POST, PUT, DELETE)
- `Expense.findAll()` con `Sort` para ordenamiento
- `PanacheQuery.page()` para paginación
- `Expense.persist()` para crear nuevas entidades
- `Expense.delete()` para eliminar por campo
- `Expense.update()` método estático personalizado

## Probar la Solución

### 1. Iniciar la aplicación

### Linux/Mac

```bash
cd expense-service
./mvnw quarkus:dev
```

### Windows (CMD)

```cmd
cd expense-service
mvnw.cmd quarkus:dev
```

### Windows (PowerShell)

```powershell
cd expense-service
.\mvnw.cmd quarkus:dev
```

### 2. Listar gastos con paginación

### Linux/Mac

```bash
curl "http://localhost:8080/expenses?pageSize=5&pageNum=1"
```

### Windows (CMD)

```cmd
curl "http://localhost:8080/expenses?pageSize=5&pageNum=1"
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/expenses?pageSize=5&pageNum=1" -Method GET | Select-Object -ExpandProperty Content
```

### 3. Crear un nuevo gasto

### Linux/Mac

```bash
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"name":"New Book","paymentMethod":"CASH","amount":"25.50","associateId":1}'
```

### Windows (CMD)

```cmd
curl -X POST http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"name\":\"New Book\",\"paymentMethod\":\"CASH\",\"amount\":\"25.50\",\"associateId\":1}"
```

### Windows (PowerShell)

```powershell
$body = @{
    name = "New Book"
    paymentMethod = "CASH"
    amount = "25.50"
    associateId = 1
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method POST -Body $body -ContentType "application/json" | Select-Object -ExpandProperty Content
```

### 4. Actualizar un gasto

Primero, obtén el UUID y el ID de un gasto existente. Luego:

### Linux/Mac

```bash
curl -X PUT http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"id":1,"uuid":"<UUID_DEL_GASTO>","name":"Updated Book","paymentMethod":"CREDIT_CARD","amount":"30.00","associateId":1}'
```

### Windows (CMD)

```cmd
curl -X PUT http://localhost:8080/expenses -H "Content-Type: application/json" -d "{\"id\":1,\"uuid\":\"<UUID_DEL_GASTO>\",\"name\":\"Updated Book\",\"paymentMethod\":\"CREDIT_CARD\",\"amount\":\"30.00\",\"associateId\":1}"
```

### Windows (PowerShell)

```powershell
$body = @{
    id = 1
    uuid = "<UUID_DEL_GASTO>"
    name = "Updated Book"
    paymentMethod = "CREDIT_CARD"
    amount = "30.00"
    associateId = 1
} | ConvertTo-Json

Invoke-WebRequest -Uri http://localhost:8080/expenses -Method PUT -Body $body -ContentType "application/json"
```

### 5. Eliminar un gasto

### Linux/Mac

```bash
curl -X DELETE http://localhost:8080/expenses/<UUID_DEL_GASTO>
```

### Windows (CMD)

```cmd
curl -X DELETE http://localhost:8080/expenses/<UUID_DEL_GASTO>
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/expenses/<UUID_DEL_GASTO>" -Method DELETE
```

## Verificar la Base de Datos

### Consultar los gastos

```sql
SELECT * FROM Expense ORDER BY amount, associate_id;
```

### Consultar los asociados

```sql
SELECT * FROM Associate;
```

### Consultar gastos con información del asociado

```sql
SELECT e.id, e.name, e.amount, a.name as associate_name 
FROM Expense e 
JOIN Associate a ON e.associate_id = a.id;
```

## Conceptos Clave Aprendidos

### PanacheEntity

- Proporciona métodos estáticos como `findAll()`, `findById()`, `persist()`, `delete()`
- Incluye un campo `id` automático (Long)
- Simplifica el código de persistencia

### Relaciones JPA

- **@OneToMany**: Un asociado tiene muchos gastos
- **@ManyToOne**: Muchos gastos pertenecen a un asociado
- **@JoinColumn**: Especifica la columna de unión en la base de datos

### Transacciones

- `@Transactional` asegura que las operaciones se ejecuten en una transacción
- Si ocurre un error, se revierte toda la transacción

### Dev Services

- Inicia automáticamente PostgreSQL en un contenedor
- No requiere configuración manual de la base de datos
- Solo disponible en modo desarrollo

### Paginación y Ordenamiento

- `PanacheQuery` permite encadenar operaciones
- `Page.of()` crea una página con índice y tamaño
- `Sort.by()` permite ordenar por múltiples campos

## Resumen

Esta solución implementa:
- ✅ Entidades JPA con PanacheEntity
- ✅ Relaciones OneToMany y ManyToOne
- ✅ Operaciones CRUD completas
- ✅ Paginación y ordenamiento
- ✅ Transacciones en métodos REST
- ✅ Configuración de PostgreSQL con Dev Services

---

**Enjoy!**

**Joe**

