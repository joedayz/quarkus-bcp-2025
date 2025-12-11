# LAB 21: QUARKUS MONITORING LOGGING

**Autor:** José Díaz

**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

Abre el proyecto `18-monitor-logging-start`

## 1. Configuración Inicial

1. Abre el proyecto con tu editor favorito.
2. Ejecuta la aplicación en modo desarrollo:

**Mac/Linux:**
```bash
./mvnw quarkus:dev
```

**Windows:**
```bash
mvnw.cmd quarkus:dev
```

**Docker (si Maven no está instalado):**
```bash
docker run -it --rm -v "$(pwd)":/usr/src/maven -w /usr/src/maven maven:3.9-eclipse-temurin-17 mvn quarkus:dev
```

**Podman (alternativa a Docker):**
```bash
podman run -it --rm -v "$(pwd)":/usr/src/maven -w /usr/src/maven maven:3.9-eclipse-temurin-17 mvn quarkus:dev
```

Deberías ver una salida similar a:
```
...output omitted...
INFO [io.quarkus] (Quarkus Main Thread) expenses ... Listening on: http://localhost:8000
...output omitted...
```

## 2. Loguear Mensajes de Error

Loguea un mensaje de error cuando un request al endpoint `GET /expenses/{name}` trata de obtener un expense que no existe.

### a. Modificar ExpensesResource

Abre la clase `ExpensesResource` y modifica el método `getByName` para loguear mensajes de error cuando se lanza `ExpenseNotFoundException`:

```java
@GET
@Path( "/{name}" )
public Expense getByName( @PathParam( "name" ) String name ) {
    try {
        return expenses.getByName( name );
    } catch( ExpenseNotFoundException e ) {
        var message = e.getMessage();
        Log.error( message );
        throw new NotFoundException( message );
    }
}
```

### b. Probar el Endpoint con un Expense Inexistente

Abre una nueva terminal y haz un request para obtener el expense llamado `none`. Este expense no existe.

**Mac/Linux/Windows:**
```bash
curl -v http://localhost:8080/expenses/none
```

**Docker (si curl no está disponible):**
```bash
docker run --rm --network host curlimages/curl:latest -v http://localhost:8080/expenses/none
```

**Podman (alternativa a Docker):**
```bash
podman run --rm --network host curlimages/curl:latest -v http://localhost:8080/expenses/none
```

Deberías ver una respuesta similar a:
```
...output omitted...
< HTTP/1.1 404 Not Found
< Content-Type: application/json
< content-length: 0
<
...output omitted...
```

### c. Verificar el Log de Error

Retorna a la terminal donde la aplicación está ejecutándose y verifica que la salida muestra el siguiente error:

```
...output omitted...
ERROR [com.bcp.training.expense.ExpensesResource] {executor-thread-0} Expense not found: none
```

## 3. Loguear Mensajes de Debug y Ajustar el Log Level

### a. Agregar Log de Debug

En la clase `ExpensesResource`, modifica el método `getByName` para loguear el mensaje debug `Getting expense {name}`:

```java
@GET
@Path( "/{name}" )
public Expense getByName( @PathParam( "name" ) String name ) {
    Log.debug( "Getting expense " + name );
    try {
        return expenses.getByName( name );
    } catch( ExpenseNotFoundException e ) {
        var message = e.getMessage();
        Log.error( message );
        throw new NotFoundException( message );
    }
}
```

### b. Probar el Endpoint con un Expense Existente

Haz un request para obtener el expense llamado `joel-2`:

**Mac/Linux/Windows:**
```bash
curl -s http://localhost:8080/expenses/joel-2 | jq
```

**Si jq no está instalado:**
```bash
curl -s http://localhost:8080/expenses/joel-2
```

**Docker (con jq):**
```bash
docker run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | docker run --rm -i imega/jq .
```

**Podman (con jq):**
```bash
podman run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | podman run --rm -i imega/jq .
```

Deberías ver una respuesta similar a:
```json
{
    "uuid": "6df8b95d-afec-4171-a980-7c915a309f69",
    "name": "joel-2",
    "creationDate": "2023-01-23T10:22:32.005245452",
    "paymentMethod": "CASH",
    "amount": 10.0,
    "username": "joel@example.com"
}
```

### c. Verificar que el Mensaje de Debug No se Muestra

Retorna a la terminal donde la aplicación está ejecutándose. Verifica que el mensaje de debug no es mostrado. La consola no muestra el mensaje de debug porque el log level por defecto es `INFO`.

### d. Configurar el Log Level a DEBUG

Agrega la siguiente línea a `src/main/resources/application.properties`:

```properties
quarkus.log.level=DEBUG
```

### e. Reejecutar el Request

Reejecuta el request al mismo endpoint:

**Mac/Linux/Windows:**
```bash
curl -s http://localhost:8080/expenses/joel-2 | jq
```

**Docker:**
```bash
docker run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | docker run --rm -i imega/jq .
```

**Podman:**
```bash
podman run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | podman run --rm -i imega/jq .
```

### f. Verificar que el Mensaje de DEBUG se Muestra

Verifica que el mensaje de DEBUG es mostrado en la consola de la aplicación:

```
...output omitted...
DEBUG [io.qua.arc.run.BeanContainerImpl] (Quarkus Main Thread) No matching bean ...
DEBUG [io.qua.arc.run.BeanContainerImpl] (Quarkus Main Thread) No matching bean ...
...output omitted...
DEBUG [com.bcp.training.expense.ExpensesResource] (executor-thread-0) Getting expense joel-2
```

Observa que la aplicación podría mostrar mensajes de debug que no son relevantes para este ejercicio.

## 4. Configurar el Log Level DEBUG Solo para un Paquete Específico

### a. Cambiar el Root Log Level a INFO

En el archivo `application.properties`, cambia el root log level de `DEBUG` a `INFO`:

```properties
quarkus.log.level=INFO
```

### b. Configurar el Log Level DEBUG para el Paquete Específico

En el mismo archivo, agrega la siguiente línea para establecer el log level de la categoría `com.bcp.training.expense` a `DEBUG`:

```properties
quarkus.log.category."com.bcp.training.expense".level=DEBUG
```

### c. Reejecutar el Request

Reejecuta el request al mismo endpoint:

**Mac/Linux/Windows:**
```bash
curl -s http://localhost:8080/expenses/joel-2 | jq
```

**Docker:**
```bash
docker run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | docker run --rm -i imega/jq .
```

**Podman:**
```bash
podman run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | podman run --rm -i imega/jq .
```

### d. Verificar los Logs

Verifica que los logs de la aplicación muestran solo mensajes de debug generados en el paquete `com.bcp.training.expense`:

```
...output omitted...
INFO [io.quarkus] (Quarkus Main Thread) Profile dev activated. Live Coding activated.
INFO [io.quarkus] (Quarkus Main Thread) Installed features: [...]
INFO [io.qua.dep.dev.RuntimeUpdatesProcessor] (vert.x-worker-thread-0) Live reload total time ...
DEBUG [com.bcp.training.expense.ExpensesResource] (executor-thread-0) Getting expense joel-2
```

## 5. Personalizar el Logging en Modo de Desarrollo

Envía los logs al archivo, define un formato específico de logging, y desactiva la rotación de log cuando la aplicación reinicia.

### a. Configurar el Logging a Archivo

Agrega las siguientes líneas al archivo `application.properties`:

**Mac/Linux:**
```properties
%dev.quarkus.log.file.enabled=true
%dev.quarkus.log.file.path=$HOME/DO378/monitor-logging/dev.logs
%dev.quarkus.log.file.format=%d %-5p [%F] %m%n
%dev.quarkus.log.file.rotation.rotate-on-boot=false
```

**Windows:**
```properties
%dev.quarkus.log.file.enabled=true
%dev.quarkus.log.file.path=C:\\Users\\josed\\DO378\\monitor-logging\\dev.logs
%dev.quarkus.log.file.format=%d %-5p [%F] %m%n
%dev.quarkus.log.file.rotation.rotate-on-boot=false
```

**Nota:** Asegúrate de crear el directorio antes de ejecutar la aplicación:

**Mac/Linux:**
```bash
mkdir -p $HOME/DO378/monitor-logging
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "C:\Users\josed\DO378\monitor-logging"
```

**Windows (CMD):**
```cmd
mkdir C:\Users\josed\DO378\monitor-logging
```

### b. Reejecutar el Request

Reejecuta el request al mismo endpoint:

**Mac/Linux/Windows:**
```bash
curl -s http://localhost:8080/expenses/joel-2 | jq
```

**Docker:**
```bash
docker run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | docker run --rm -i imega/jq .
```

**Podman:**
```bash
podman run --rm --network host curlimages/curl:latest -s http://localhost:8080/expenses/joel-2 | podman run --rm -i imega/jq .
```

### c. Verificar el Archivo de Log

Verifica que el archivo de log contiene los logs en el formato específico:

**Mac/Linux:**
```bash
cat $HOME/DO378/monitor-logging/dev.logs
```

**Windows (PowerShell):**
```powershell
Get-Content C:\Users\josed\DO378\monitor-logging\dev.logs
```

**Windows (CMD):**
```cmd
type C:\Users\josed\DO378\monitor-logging\dev.logs
```

**Docker (para ver el archivo en el contenedor):**
```bash
docker exec -it <container-id> cat $HOME/DO378/monitor-logging/dev.logs
```

**Podman (para ver el archivo en el contenedor):**
```bash
podman exec -it <container-id> cat $HOME/DO378/monitor-logging/dev.logs
```

Deberías ver una salida similar a:
```
2023-01-23 09:11:39,451 DEBUG [ExpensesResource.java] Getting expense joel-2
```

### d. Detener la Aplicación

Retorna a la terminal donde la aplicación está corriendo y tipea `q` para detener la aplicación.

---

## Fin del laboratorio

**Enjoy!**  
José

