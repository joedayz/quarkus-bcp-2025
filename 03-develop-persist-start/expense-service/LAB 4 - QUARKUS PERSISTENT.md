# LAB 4: QUARKUS PERSISTENT

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

En este laboratorio aprenderás a:
- Configurar Hibernate ORM con Panache en Quarkus
- Crear entidades JPA usando PanacheEntity
- Establecer relaciones entre entidades (OneToMany, ManyToOne)
- Configurar PostgreSQL con Dev Services
- Implementar operaciones CRUD usando métodos de Panache
- Agregar paginación y ordenamiento
- Usar transacciones en métodos REST

## 1. Cargar en su IDE el proyecto 03-develop-persist-start

Abre el proyecto en tu IDE preferido. El proyecto contiene:
- `expense-service`: Servicio REST que gestiona gastos con persistencia

## 2. Examinar la estructura del proyecto

### 2.1. Módulo expense-service

El módulo `expense-service` contiene:
- `Expense`: Modelo de datos que representa un gasto (actualmente sin persistencia)
- `Associate`: Modelo de datos que representa un asociado (actualmente sin persistencia)
- `ExpenseResource`: Recurso REST con operaciones CRUD (incompleto)

## 3. Agregar dependencias de Hibernate ORM y PostgreSQL

### 3.1. Abre el archivo `pom.xml`

Ubicado en: `expense-service/pom.xml`

### 3.2. Agrega las dependencias necesarias

Agrega las siguientes dependencias dentro del elemento `<dependencies>`:

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

**Resultado esperado:** El archivo `pom.xml` debe incluir estas dependencias junto con las existentes.

## 4. Configurar la base de datos

### 4.1. Abre el archivo `application.properties`

Ubicado en: `expense-service/src/main/resources/application.properties`

### 4.2. Agrega la configuración de la base de datos

Reemplaza el comentario `# TODO: Add configuration` con:

```properties
quarkus.datasource.devservices.image-name=postgres:14.1
quarkus.hibernate-orm.database.generation=drop-and-create
```

**Explicación:**
- `quarkus.datasource.devservices.image-name`: Especifica la imagen de PostgreSQL para Dev Services
- `quarkus.hibernate-orm.database.generation=drop-and-create`: Crea y recrea el esquema de base de datos al iniciar

## 5. Convertir Associate en una entidad JPA

### 5.1. Abre la clase `Associate`

Ubicada en: `expense-service/src/main/java/com/bcp/training/model/Associate.java`

### 5.2. Agrega la anotación `@Entity` y extiende `PanacheEntity`

```java
@Entity
public class Associate extends PanacheEntity {
```

### 5.3. Agrega la relación OneToMany con Expense

Agrega las anotaciones necesarias al campo `expenses`:

```java
@JsonbTransient
@OneToMany(mappedBy = "associate", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
public List<Expense> expenses = new ArrayList<>();
```

**Nota:** Necesitarás importar:
- `jakarta.persistence.Entity`
- `jakarta.persistence.OneToMany`
- `jakarta.persistence.CascadeType`
- `jakarta.persistence.FetchType`
- `jakarta.json.bind.annotation.JsonbTransient`
- `io.quarkus.hibernate.orm.panache.PanacheEntity`

### 5.4. Agrega un constructor sin argumentos

Agrega el constructor requerido por JPA:

```java
public Associate() {
}
```

**Resultado esperado:**

```java
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

## 6. Convertir Expense en una entidad JPA

### 6.1. Abre la clase `Expense`

Ubicada en: `expense-service/src/main/java/com/bcp/training/model/Expense.java`

### 6.2. Agrega la anotación `@Entity` y extiende `PanacheEntity`

```java
@Entity
public class Expense extends PanacheEntity {
```

### 6.3. Agrega la relación ManyToOne con Associate

Agrega las anotaciones necesarias al campo `associate`:

```java
@JsonbTransient
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "associate_id", insertable = false, updatable = false)
public Associate associate;
```

### 6.4. Anota el campo `associateId` con `@Column`

```java
@Column(name = "associate_id")
public Long associateId;
```

### 6.5. Agrega un constructor sin argumentos

```java
public Expense() {
}
```

### 6.6. Actualiza el constructor para asociar `associateId`

En el constructor que recibe un `Associate`, agrega:

```java
this.associateId = associate.id;
```

### 6.7. Actualiza el método `of()` para buscar el Associate

Reemplaza el método `of()` con:

```java
@JsonbCreator
public static Expense of(String name, PaymentMethod paymentMethod, String amount, Long associateId) {
    return Associate.<Associate>findByIdOptional(associateId)
            .map(associate -> new Expense(name, paymentMethod, amount, associate))
            .orElseThrow(RuntimeException::new);
}
```

### 6.8. Agrega el método `update()`

Agrega el siguiente método estático:

```java
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
```

**Nota:** Necesitarás importar:
- `jakarta.persistence.Entity`
- `jakarta.persistence.ManyToOne`
- `jakarta.persistence.JoinColumn`
- `jakarta.persistence.Column`
- `jakarta.persistence.FetchType`
- `io.quarkus.hibernate.orm.panache.PanacheEntity`

**Resultado esperado:** La clase `Expense` debe extender `PanacheEntity` y tener todas las anotaciones JPA necesarias.

## 7. Implementar el ExpenseResource

### 7.1. Abre la clase `ExpenseResource`

Ubicada en: `expense-service/src/main/java/com/bcp/training/rest/ExpenseResource.java`

### 7.2. Implementa el método `list()` con paginación y ordenamiento

Reemplaza el método `list()` con:

```java
@GET
public List<Expense> list(@DefaultValue("5") @QueryParam("pageSize") int pageSize,
                          @DefaultValue("1") @QueryParam("pageNum") int pageNum) {
    PanacheQuery<Expense> expenseQuery = Expense.findAll(
            Sort.by("amount").and("associateId"));

    return expenseQuery.page(Page.of(pageNum - 1, pageSize)).list();
}
```

**Nota:** Necesitarás importar:
- `io.quarkus.hibernate.orm.panache.PanacheQuery`
- `io.quarkus.panache.common.Page`
- `io.quarkus.panache.common.Sort`

### 7.3. Haz el método `create()` transaccional y persiste la entidad

```java
@POST
@Transactional
public Expense create(final Expense expense) {
    Expense newExpense = Expense.of(expense.name, expense.paymentMethod,
            expense.amount.toString(), expense.associateId);
    newExpense.persist();

    return newExpense;
}
```

### 7.4. Implementa el método `delete()` con transacción

```java
@DELETE
@Path("{uuid}")
@Transactional
public void delete(@PathParam("uuid") final UUID uuid) {
    long numExpensesDeleted = Expense.delete("uuid", uuid);

    if (numExpensesDeleted == 0) {
        throw new WebApplicationException(Response.Status.NOT_FOUND);
    }
}
```

### 7.5. Implementa el método `update()` con transacción

```java
@PUT
@Transactional
public void update(final Expense expense) {
    try {
        Expense.update(expense);
    } catch (RuntimeException e) {
        throw new WebApplicationException(Response.Status.NOT_FOUND);
    }
}
```

## 8. Iniciar la aplicación

### 8.1. Navega al directorio expense-service

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

### 8.2. Inicia la aplicación en modo desarrollo

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

**Nota:** La primera vez que ejecutes la aplicación, Quarkus Dev Services iniciará automáticamente un contenedor PostgreSQL.

### 8.3. Verifica que la aplicación esté corriendo

Abre tu navegador y visita:
- **Swagger UI**: http://localhost:8080/q/swagger-ui
- **OpenAPI JSON**: http://localhost:8080/q/openapi
- **Dev UI**: http://localhost:8080/q/dev/

Deberías ver los endpoints disponibles en Swagger UI.

## 9. Probar los endpoints

### 9.1. Listar todos los gastos con paginación

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

**Resultado esperado:** Deberías ver un array JSON con los gastos inicializados desde `import.sql`, ordenados por `amount` y `associateId`.

### 9.2. Crear un nuevo gasto

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

**Resultado esperado:** Deberías recibir el objeto JSON del gasto creado con un `id` generado.

### 9.3. Actualizar un gasto

Primero, obtén el UUID de un gasto existente. Luego:

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

### 9.4. Eliminar un gasto

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

## 10. Verificar la base de datos

### 10.1. Acceder a la base de datos PostgreSQL

Quarkus Dev Services expone la base de datos en el puerto 5432. Puedes conectarte usando cualquier cliente PostgreSQL.

### 10.2. Consultar las tablas

Puedes usar `psql` o cualquier herramienta gráfica:

### Linux/Mac

```bash
psql -h localhost -p 5432 -U quarkus -d quarkus
```

### Windows (PowerShell)

```powershell
# Si tienes psql instalado
psql -h localhost -p 5432 -U quarkus -d quarkus
```

**Nota:** La contraseña por defecto es `quarkus`.

### 10.3. Consultar los gastos

```sql
SELECT * FROM Expense;
```

### 10.4. Consultar los asociados

```sql
SELECT * FROM Associate;
```

## Resumen

En este laboratorio has aprendido a:
- ✅ Configurar Hibernate ORM con Panache en Quarkus
- ✅ Crear entidades JPA extendiendo `PanacheEntity`
- ✅ Establecer relaciones entre entidades (OneToMany, ManyToOne)
- ✅ Configurar PostgreSQL con Dev Services
- ✅ Implementar operaciones CRUD usando métodos de Panache (`persist()`, `delete()`, `findAll()`)
- ✅ Agregar paginación y ordenamiento a las consultas
- ✅ Usar `@Transactional` en métodos REST
- ✅ Usar `import.sql` para datos iniciales

## Próximos pasos

- Explora más métodos de Panache como `find()`, `findBy()`, `count()`
- Implementa consultas personalizadas con `@NamedQuery`
- Agrega validación usando Bean Validation
- Implementa repositorios personalizados con PanacheRepository
- Explora las capacidades de Dev Services para otras bases de datos

---

**Enjoy!**

**Joe**

