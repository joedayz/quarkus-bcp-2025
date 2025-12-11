# LAB 13: QUARKUS REACTIVE REVIEW

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Objetivo

Este laboratorio te guiará paso a paso para crear una aplicación Quarkus reactiva que:
- Guarda datos en una base de datos PostgreSQL
- Publica y consume eventos usando Apache Kafka
- Implementa un procesador de eventos que filtra y reenvía mensajes según la afiliación del speaker

---

## Paso 1: Abrir el Proyecto

1. Navega al directorio del proyecto:

   **Windows (PowerShell):**
   ```powershell
   cd 10-reactive-review-start\reactive-speaker
   ```

   **Windows (CMD):**
   ```cmd
   cd 10-reactive-review-start\reactive-speaker
   ```

   **Linux/Mac:**
   ```bash
   cd 10-reactive-review-start/reactive-speaker
   ```

2. Verifica que estás en el directorio correcto:

   **Windows (PowerShell):**
   ```powershell
   Get-ChildItem pom.xml
   ```

   **Windows (CMD):**
   ```cmd
   dir pom.xml
   ```

   **Linux/Mac:**
   ```bash
   ls pom.xml
   ```

---

## Paso 2: Agregar Dependencias Requeridas

Agrega las extensiones necesarias para crear un endpoint reactivo que guarda datos en PostgreSQL y envía eventos a Apache Kafka.

### 2.1. Agregar Extensiones con Maven

**Windows (PowerShell):**
```powershell
.\mvnw.cmd quarkus:add-extensions -Dextensions="rest,quarkus-messaging-kafka,hibernate-reactive-panache,reactive-pg-client"
```

**Windows (CMD):**
```cmd
mvnw.cmd quarkus:add-extensions -Dextensions="rest,quarkus-messaging-kafka,hibernate-reactive-panache,reactive-pg-client"
```

**Linux/Mac:**
```bash
./mvnw quarkus:add-extensions -Dextensions="rest,quarkus-messaging-kafka,hibernate-reactive-panache,reactive-pg-client"
```

**Nota:** Si tienes Maven instalado globalmente, puedes usar `mvn` en lugar de `./mvnw` o `.\mvnw.cmd`.

### 2.2. Verificar Dependencias Agregadas

Abre el archivo `pom.xml` y verifica que se hayan agregado las siguientes dependencias:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-messaging-kafka</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-reactive-panache</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-reactive-pg-client</artifactId>
</dependency>
```

---

## Paso 3: Configurar los Canales de Mensajería

Configuraremos 4 canales en el archivo `application.properties`:
- 1 canal de entrada (incoming)
- 3 canales de salida (outgoing)

### 3.1. Abrir application.properties

Abre el archivo: `src/main/resources/application.properties`

### 3.2. Configurar el Canal de Entrada (Incoming Channel)

Agrega la siguiente configuración para el canal `new-speakers-in`:

```properties
# Incoming Channels
mp.messaging.incoming.new-speakers-in.connector=smallrye-kafka
mp.messaging.incoming.new-speakers-in.topic=speaker-was-created
mp.messaging.incoming.new-speakers-in.auto.offset.reset=earliest
mp.messaging.incoming.new-speakers-in.value.deserializer=com.bcp.training.serde.SpeakerWasCreatedDeserializer
```

**Explicación:**
- `connector`: Usa SmallRye Kafka como conector
- `topic`: Nombre del tópico de Kafka desde el cual consumir eventos
- `auto.offset.reset`: Establece `earliest` para leer desde el inicio del tópico
- `value.deserializer`: Clase personalizada para deserializar los mensajes entrantes

### 3.3. Configurar el Canal de Salida new-speakers-out

Agrega la siguiente configuración para publicar eventos `SpeakerWasCreated`:

```properties
# Outgoing Channels
mp.messaging.outgoing.new-speakers-out.connector=smallrye-kafka
mp.messaging.outgoing.new-speakers-out.topic=speaker-was-created
mp.messaging.outgoing.new-speakers-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer
```

### 3.4. Configurar el Canal de Salida employees-out

Agrega la siguiente configuración para publicar eventos `EmployeeSignedUp`:

```properties
mp.messaging.outgoing.employees-out.connector=smallrye-kafka
mp.messaging.outgoing.employees-out.topic=employees-signed-up
mp.messaging.outgoing.employees-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer
```

### 3.5. Configurar el Canal de Salida upstream-members-out

Agrega la siguiente configuración para publicar eventos `UpstreamMemberSignedUp`:

```properties
mp.messaging.outgoing.upstream-members-out.connector=smallrye-kafka
mp.messaging.outgoing.upstream-members-out.topic=upstream-members-signed-up
mp.messaging.outgoing.upstream-members-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer
```

### 3.6. Archivo application.properties Completo

Tu archivo `application.properties` debería verse así:

```properties
# Dev Services
quarkus.datasource.devservices.image-name=registry.ocp4.example.com:8443/redhattraining/do378-postgres:14.1
quarkus.kafka.devservices.image-name=registry.ocp4.example.com:8443/redhattraining/do378-redpanda:v22.3.4

# Incoming Channels
mp.messaging.incoming.new-speakers-in.connector=smallrye-kafka
mp.messaging.incoming.new-speakers-in.topic=speaker-was-created
mp.messaging.incoming.new-speakers-in.auto.offset.reset=earliest
mp.messaging.incoming.new-speakers-in.value.deserializer=com.bcp.training.serde.SpeakerWasCreatedDeserializer

# Outgoing Channels
mp.messaging.outgoing.new-speakers-out.connector=smallrye-kafka
mp.messaging.outgoing.new-speakers-out.topic=speaker-was-created
mp.messaging.outgoing.new-speakers-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer

mp.messaging.outgoing.employees-out.connector=smallrye-kafka
mp.messaging.outgoing.employees-out.topic=employees-signed-up
mp.messaging.outgoing.employees-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer

mp.messaging.outgoing.upstream-members-out.connector=smallrye-kafka
mp.messaging.outgoing.upstream-members-out.topic=upstream-members-signed-up
mp.messaging.outgoing.upstream-members-out.value.serializer=io.quarkus.kafka.client.serialization.ObjectMapperSerializer
```

**Nota sobre Dev Services:** Si estás usando un registro de imágenes diferente o Docker Hub, puedes modificar las líneas de Dev Services. Por ejemplo:

**Para Docker Hub:**
```properties
quarkus.datasource.devservices.image-name=postgres:14.1
quarkus.kafka.devservices.image-name=redpandadata/redpanda:v22.3.4
```

**Para Podman (si no tienes acceso al registro):**
```properties
# Comentar o eliminar las líneas de image-name para usar las imágenes por defecto
# quarkus.datasource.devservices.image-name=...
# quarkus.kafka.devservices.image-name=...
```

---

## Paso 4: Crear el Deserializer Personalizado

Necesitamos crear una clase deserializer para convertir los mensajes de Kafka en instancias de `SpeakerWasCreated`.

### 4.1. Crear el Paquete serde

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Path "src\main\java\com\bcp\training\serde" -Force
```

**Windows (CMD):**
```cmd
mkdir src\main\java\com\bcp\training\serde
```

**Linux/Mac:**
```bash
mkdir -p src/main/java/com/bcp/training/serde
```

### 4.2. Crear la Clase SpeakerWasCreatedDeserializer

Crea el archivo `src/main/java/com/bcp/training/serde/SpeakerWasCreatedDeserializer.java` con el siguiente contenido:

```java
package com.bcp.training.serde;

import com.bcp.training.event.SpeakerWasCreated;
import io.quarkus.kafka.client.serialization.ObjectMapperDeserializer;

public class SpeakerWasCreatedDeserializer
        extends ObjectMapperDeserializer<SpeakerWasCreated> {
    
    public SpeakerWasCreatedDeserializer() {
        super(SpeakerWasCreated.class);
    }
}
```

---

## Paso 5: Crear el Endpoint Reactivo POST

Modificaremos la clase `SpeakerResource` para agregar un endpoint POST que:
- Recibe un objeto `Speaker`
- Lo guarda en la base de datos usando una transacción
- Envía un evento `SpeakerWasCreated` al canal `new-speakers-out`
- Retorna una respuesta HTTP 201 con el URI del elemento insertado

### 5.1. Abrir SpeakerResource.java

Abre el archivo: `src/main/java/com/bcp/training/resource/SpeakerResource.java`

### 5.2. Agregar el Emitter

Agrega un campo `Emitter` para enviar eventos al canal `new-speakers-out`:

```java
@Channel("new-speakers-out")
Emitter<SpeakerWasCreated> emitter;
```

### 5.3. Crear el Método POST

Agrega el siguiente método POST a la clase:

```java
@POST
public Uni<Response> create(Speaker newSpeaker) {
    return Panache.withTransaction(() -> 
        newSpeaker.<Speaker>persist()
            .map(speaker -> {
                SpeakerWasCreated event = new SpeakerWasCreated(
                    speaker.id,
                    speaker.fullName,
                    speaker.affiliation,
                    speaker.email
                );
                emitter.send(event);
                return Response.created(URI.create("/speakers/" + speaker.id))
                    .build();
            })
    );
}
```

### 5.4. Clase SpeakerResource Completa

Tu archivo `SpeakerResource.java` debería verse así:

```java
package com.bcp.training.resource;

import com.bcp.training.event.SpeakerWasCreated;
import com.bcp.training.model.Speaker;
import io.quarkus.hibernate.reactive.panache.Panache;
import io.smallrye.mutiny.Uni;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

import java.net.URI;
import java.util.List;

@Path("/speakers")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SpeakerResource {
    
    @Channel("new-speakers-out")
    Emitter<SpeakerWasCreated> emitter;

    @GET
    @Path("/{id}")
    public Uni<Speaker> get(Long id) {
        return Speaker.findById(id);
    }

    @GET
    public Uni<List<Speaker>> listAll() {
        return Speaker.listAll();
    }

    @POST
    public Uni<Response> create(Speaker newSpeaker) {
        return Panache.withTransaction(() -> 
            newSpeaker.<Speaker>persist()
                .map(speaker -> {
                    SpeakerWasCreated event = new SpeakerWasCreated(
                        speaker.id,
                        speaker.fullName,
                        speaker.affiliation,
                        speaker.email
                    );
                    emitter.send(event);
                    return Response.created(URI.create("/speakers/" + speaker.id))
                        .build();
                })
        );
    }
}
```

---

## Paso 6: Crear el Procesador de Eventos

Modificaremos la clase `NewSpeakersProcessor` para consumir eventos `SpeakerWasCreated` y filtrarlos según la afiliación.

### 6.1. Abrir NewSpeakersProcessor.java

Abre el archivo: `src/main/java/com/bcp/training/reactive/NewSpeakersProcessor.java`

### 6.2. Agregar los Emitters

Agrega dos campos `Emitter` para enviar eventos a los canales de salida:

```java
@Channel("employees-out")
Emitter<EmployeeSignedUp> employeeEmitter;

@Channel("upstream-members-out")
Emitter<UpstreamMemberSignedUp> upstreamEmitter;
```

### 6.3. Agregar las Importaciones Necesarias

Agrega las siguientes importaciones al inicio del archivo:

```java
import com.bcp.training.event.EmployeeSignedUp;
import com.bcp.training.event.SpeakerWasCreated;
import com.bcp.training.event.UpstreamMemberSignedUp;
import com.bcp.training.model.Affiliation;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.jboss.logging.Logger;

import java.util.concurrent.CompletionStage;
```

### 6.4. Crear el Método de Procesamiento

Agrega el siguiente método que procesa los mensajes entrantes:

```java
@Incoming("new-speakers-in")
public CompletionStage<Void> sendEventNotifications(Message<SpeakerWasCreated> message) {
    SpeakerWasCreated event = message.getPayload();
    logProcessEvent(event.id);
    
    if (event.affiliation == Affiliation.RED_HAT) {
        logEmitEvent("EmployeeSignedUp", event.affiliation);
        employeeEmitter.send(
            new EmployeeSignedUp(event.id, event.fullName, event.email)
        );
    } else if (event.affiliation == Affiliation.GNOME_FOUNDATION) {
        logEmitEvent("UpstreamMemberSignedUp", event.affiliation);
        upstreamEmitter.send(
            new UpstreamMemberSignedUp(event.id, event.fullName, event.email)
        );
    }
    
    return message.ack();
}
```

### 6.5. Clase NewSpeakersProcessor Completa

Tu archivo `NewSpeakersProcessor.java` debería verse así:

```java
package com.bcp.training.reactive;

import com.bcp.training.event.EmployeeSignedUp;
import com.bcp.training.event.SpeakerWasCreated;
import com.bcp.training.event.UpstreamMemberSignedUp;
import com.bcp.training.model.Affiliation;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.jboss.logging.Logger;

import java.util.concurrent.CompletionStage;

@ApplicationScoped
public class NewSpeakersProcessor {
    private static final Logger LOGGER = Logger.getLogger(NewSpeakersProcessor.class);

    @Channel("employees-out")
    Emitter<EmployeeSignedUp> employeeEmitter;

    @Channel("upstream-members-out")
    Emitter<UpstreamMemberSignedUp> upstreamEmitter;

    private void logEmitEvent(String eventName, Affiliation affiliation) {
        LOGGER.infov(
                "Sending event {0} for affiliation {1}",
                eventName,
                affiliation
        );
    }

    private void logProcessEvent(Long eventID) {
        LOGGER.infov(
                "Processing SpeakerWasCreated event: ID {0}",
                eventID
        );
    }

    @Incoming("new-speakers-in")
    public CompletionStage<Void> sendEventNotifications(Message<SpeakerWasCreated> message) {
        SpeakerWasCreated event = message.getPayload();
        logProcessEvent(event.id);
        
        if (event.affiliation == Affiliation.RED_HAT) {
            logEmitEvent("EmployeeSignedUp", event.affiliation);
            employeeEmitter.send(
                new EmployeeSignedUp(event.id, event.fullName, event.email)
            );
        } else if (event.affiliation == Affiliation.GNOME_FOUNDATION) {
            logEmitEvent("UpstreamMemberSignedUp", event.affiliation);
            upstreamEmitter.send(
                new UpstreamMemberSignedUp(event.id, event.fullName, event.email)
            );
        }
        
        return message.ack();
    }
}
```

---

## Paso 7: Ejecutar y Probar la Aplicación

### 7.1. Compilar el Proyecto

**Windows (PowerShell):**
```powershell
.\mvnw.cmd clean compile
```

**Windows (CMD):**
```cmd
mvnw.cmd clean compile
```

**Linux/Mac:**
```bash
./mvnw clean compile
```

### 7.2. Ejecutar la Aplicación en Modo Desarrollo

**Windows (PowerShell):**
```powershell
.\mvnw.cmd quarkus:dev
```

**Windows (CMD):**
```cmd
mvnw.cmd quarkus:dev
```

**Linux/Mac:**
```bash
./mvnw quarkus:dev
```

**Nota:** Quarkus Dev Services iniciará automáticamente:
- Una instancia de PostgreSQL
- Una instancia de Apache Kafka (usando Redpanda)

### 7.3. Acceder al Swagger UI (Opcional)

Una vez que la aplicación esté ejecutándose, puedes acceder al Swagger UI en:

```
http://localhost:8080/q/swagger-ui
```

Desde aquí puedes probar manualmente el endpoint POST `/speakers` creando un nuevo speaker.

**Ejemplo de JSON para crear un speaker:**

```json
{
  "fullName": "John Doe",
  "affiliation": "RED_HAT",
  "email": "john.doe@example.com"
}
```

O para probar con GNOME_FOUNDATION:

```json
{
  "fullName": "Jane Smith",
  "affiliation": "GNOME_FOUNDATION",
  "email": "jane.smith@example.com"
}
```

### 7.4. Verificar los Logs

En la consola donde ejecutaste `quarkus:dev`, deberías ver logs como:

```
Processing SpeakerWasCreated event: ID 1
Sending event EmployeeSignedUp for affiliation RED_HAT
```

o

```
Processing SpeakerWasCreated event: ID 2
Sending event UpstreamMemberSignedUp for affiliation GNOME_FOUNDATION
```

---

## Paso 8: Ejecutar las Pruebas

### 8.1. Ejecutar Todos los Tests

**Windows (PowerShell):**
```powershell
.\mvnw.cmd clean test
```

**Windows (CMD):**
```cmd
mvnw.cmd clean test
```

**Linux/Mac:**
```bash
./mvnw clean test
```

### 8.2. Verificar los Resultados

Deberías ver un resultado similar a:

```
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

Si hay errores, revisa los mensajes de error y verifica:
1. Que todas las dependencias estén agregadas correctamente
2. Que la configuración en `application.properties` sea correcta
3. Que el código compile sin errores

### 8.3. Ejecutar Tests de Integración (Opcional)

Para ejecutar también los tests de integración nativos:

**Windows (PowerShell):**
```powershell
.\mvnw.cmd clean verify -Pnative
```

**Windows (CMD):**
```cmd
mvnw.cmd clean verify -Pnative
```

**Linux/Mac:**
```bash
./mvnw clean verify -Pnative
```

**Nota:** Esto requiere que tengas GraalVM instalado y configurado.

---

## Solución de Problemas

### Problema: No se pueden descargar las imágenes de Docker/Podman

**Solución:** Modifica `application.properties` para usar imágenes públicas:

```properties
# Usar imágenes públicas de Docker Hub
quarkus.datasource.devservices.image-name=postgres:14.1
quarkus.kafka.devservices.image-name=redpandadata/redpanda:v22.3.4
```

O comenta las líneas para usar las imágenes por defecto:

```properties
# quarkus.datasource.devservices.image-name=...
# quarkus.kafka.devservices.image-name=...
```

### Problema: Error de compilación relacionado con el deserializer

**Solución:** Verifica que:
1. La clase `SpeakerWasCreatedDeserializer` esté en el paquete correcto: `com.bcp.training.serde`
2. El nombre de la clase en `application.properties` coincida exactamente
3. La clase extienda `ObjectMapperDeserializer<SpeakerWasCreated>`

### Problema: Los eventos no se están procesando

**Solución:** Verifica que:
1. El canal de entrada esté configurado correctamente en `application.properties`
2. El método `sendEventNotifications` tenga la anotación `@Incoming("new-speakers-in")`
3. Los emitters estén inyectados correctamente con `@Channel`

### Problema: Error de conexión a la base de datos

**Solución:** 
1. Verifica que Docker/Podman esté ejecutándose
2. Verifica que los puertos 5432 (PostgreSQL) y 9092 (Kafka) no estén en uso
3. Revisa los logs de Quarkus para ver si Dev Services inició correctamente

---

## Comandos Docker/Podman Alternativos

Si necesitas iniciar manualmente los servicios (aunque Dev Services lo hace automáticamente):

### PostgreSQL

**Docker:**
```bash
docker run --name postgres-quarkus \
  -e POSTGRES_PASSWORD=quarkus \
  -e POSTGRES_USER=quarkus \
  -e POSTGRES_DB=quarkus \
  -p 5432:5432 \
  -d postgres:14.1
```

**Podman:**
```bash
podman run --name postgres-quarkus \
  -e POSTGRES_PASSWORD=quarkus \
  -e POSTGRES_USER=quarkus \
  -e POSTGRES_DB=quarkus \
  -p 5432:5432 \
  -d postgres:14.1
```

### Kafka (Redpanda)

**Docker:**
```bash
docker run --name redpanda-quarkus \
  -p 8081:8081 \
  -p 8082:8082 \
  -p 9092:9092 \
  -p 9644:9644 \
  -d redpandadata/redpanda:v22.3.4 \
  redpanda start \
  --kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092 \
  --advertise-kafka-addr internal://localhost:9092,external://localhost:19092 \
  --pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082 \
  --advertise-pandaproxy-addr internal://localhost:8082,external://localhost:18082 \
  --schema-registry-addr internal://0.0.0.0:8081,external://0.0.0.0:18081 \
  --rpc-addr 0.0.0.0:33145 \
  --advertise-rpc-addr localhost:33145 \
  --smp 1 \
  --memory 1G \
  --mode dev-container \
  --default-log-level=info
```

**Podman:**
```bash
podman run --name redpanda-quarkus \
  -p 8081:8081 \
  -p 8082:8082 \
  -p 9092:9092 \
  -p 9644:9644 \
  -d redpandadata/redpanda:v22.3.4 \
  redpanda start \
  --kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092 \
  --advertise-kafka-addr internal://localhost:9092,external://localhost:19092 \
  --pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082 \
  --advertise-pandaproxy-addr internal://localhost:8082,external://localhost:18082 \
  --schema-registry-addr internal://0.0.0.0:8081,external://0.0.0.0:18081 \
  --rpc-addr 0.0.0.0:33145 \
  --advertise-rpc-addr localhost:33145 \
  --smp 1 \
  --memory 1G \
  --mode dev-container \
  --default-log-level=info
```

**Nota:** En la mayoría de los casos, Quarkus Dev Services manejará estos servicios automáticamente, por lo que no necesitarás ejecutar estos comandos manualmente.

---

## Resumen de Archivos Modificados/Creados

1. **pom.xml** - Agregadas dependencias de Kafka y Hibernate Reactive
2. **application.properties** - Configuración de 4 canales de mensajería
3. **SpeakerWasCreatedDeserializer.java** - Nuevo deserializer personalizado
4. **SpeakerResource.java** - Agregado endpoint POST y emitter
5. **NewSpeakersProcessor.java** - Agregado procesamiento de eventos con filtrado

---

## Conclusión

¡Felicitaciones! Has completado el laboratorio de Quarkus Reactive Review. Tu aplicación ahora:

✅ Guarda speakers en PostgreSQL usando transacciones reactivas  
✅ Publica eventos `SpeakerWasCreated` cuando se crea un nuevo speaker  
✅ Consume eventos y los filtra según la afiliación  
✅ Publica eventos específicos (`EmployeeSignedUp` o `UpstreamMemberSignedUp`) según la afiliación  
✅ Retorna respuestas HTTP apropiadas con URIs de recursos creados  

---

**¡Disfruta del aprendizaje!**  
José Díaz

