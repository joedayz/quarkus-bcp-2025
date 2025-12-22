# LAB 12 - QUARKUS REACTIVE MESSAGING

## Descripción General

Este laboratorio te guiará a través de la creación de una aplicación compuesta de dos servicios que simulan la intranet de un banco. En esta aplicación puedes crear cuentas de banco con un balance inicial, y analizar la creación de cuentas bancarias para detectar actividad sospechosa.

En este ejercicio, usarás **reactive messaging** para conectar los servicios **joedayz-bank** y **fraud-detector**.

**NOTA:** El servicio usa una versión contenerizada de Kafka, por esa razón, algunos mensajes de warning acerca de que el leader no está disponible, pueden aparecer en los logs. Estos warnings no afectan el ejercicio.

## Repositorio

```
https://github.com/joedayz/quarkus-bcp-2025.git
```

## Prerequisitos

- Java 17 o superior
- Maven 3.8+
- Docker y Docker Compose **O** Podman y Podman Compose (para Kafka)
- Un editor de código (VS Code, IntelliJ IDEA, etc.)

## Estructura del Proyecto

El proyecto contiene dos servicios principales:

- **joedayz-bank**: Servicio que permite crear cuentas bancarias y procesa eventos para asignar tipos de cuenta
- **fraud-detector**: Servicio que analiza las cuentas creadas y detecta actividad sospechosa

---

## Configuración Inicial: Infraestructura (Kafka y PostgreSQL)

### Iniciar los Contenedores

Antes de comenzar con los servicios, necesitas iniciar Kafka y PostgreSQL usando Docker Compose o Podman Compose.

#### Opción 1: Usando Docker Compose

**Windows (PowerShell/CMD):**
```powershell
cd joedayz-bank
docker-compose up -d
```

**Linux/Mac:**
```bash
cd joedayz-bank
docker-compose up -d
```

#### Opción 2: Usando Podman Compose

**Windows (PowerShell/CMD):**
```powershell
cd joedayz-bank
podman-compose up -d
```

**Linux/Mac:**
```bash
cd joedayz-bank
podman-compose up -d
```

### Verificar que los Contenedores Están Corriendo

#### Docker:
```bash
# Windows (PowerShell/CMD), Linux, Mac
docker ps
```

#### Podman:
```bash
# Windows (PowerShell/CMD), Linux, Mac
podman ps
```

Deberías ver contenedores corriendo para:
- `joedayz-postgres` (PostgreSQL en puerto 5432)
- `joedayz-zookeeper` (Zookeeper en puerto 2181)
- `joedayz-kafka` (Kafka en puerto 9092)
- `joedayz-kafka-ui` (Kafka UI opcional en puerto 9080)

### Detener los Contenedores (al finalizar el laboratorio)

#### Docker:
```bash
# Windows (PowerShell/CMD), Linux, Mac
cd joedayz-bank
docker-compose down
```

#### Podman:
```bash
# Windows (PowerShell/CMD), Linux, Mac
cd joedayz-bank
podman-compose down
```

---

## Parte 1: Configuración del Servicio joedayz-bank

### 1. Abrir el Proyecto

#### 1.1. Navegar al Directorio del Proyecto

**Windows (PowerShell):**
```powershell
cd joedayz-bank
```

**Windows (CMD):**
```cmd
cd joedayz-bank
```

**Linux/Mac:**
```bash
cd joedayz-bank
```

#### 1.2. Examinar los Archivos

Abre el proyecto con tu editor y examina los archivos:

- La clase **com.bcp.training.model.BankAccount** es una entidad Panache que modela una cuenta bancaria.
- La clase **com.bcp.training.resource.BankAccountsResource** expone dos REST endpoints. Uno para obtener todas las cuentas de la base de datos, y otra que crea nuevas cuentas bancarias.

### 2. Agregar Dependencia y Configurar Kafka

#### 2.1. Agregar la Extensión de Kafka

**Windows (PowerShell/CMD), Linux, Mac:**
```bash
mvn quarkus:add-extension -Dextensions=quarkus-messaging-kafka
```

#### 2.2. Configurar Kafka Bootstrap Servers

Abre el archivo `src/main/resources/application.properties` y configura `localhost:9092` como el valor para la propiedad `kafka.bootstrap.servers`:

```properties
# Kafka Settings
kafka.bootstrap.servers = localhost:9092
```

#### 2.3. Configurar un Incoming Channel

Configura un incoming channel con las siguientes propiedades:

- Establece el nombre del incoming channel a **new-bank-accounts-in**.
- Usa el kafka topic **bank-account-was-created** para recibir eventos
- Establece la propiedad **offset.reset** del incoming channel a **earliest**.
- Deserializa los mensajes entrantes con la clase **com.bcp.training.serde.BankAccountWasCreatedDeserializer**.

Agrega la siguiente configuración en `application.properties`:

```properties
# Incoming Channels
mp.messaging.incoming.new-bank-accounts-in.connector = smallrye-kafka
mp.messaging.incoming.new-bank-accounts-in.topic = bank-account-was-created
mp.messaging.incoming.new-bank-accounts-in.auto.offset.reset = earliest
mp.messaging.incoming.new-bank-accounts-in.value.deserializer = com.bcp.training.serde.BankAccountWasCreatedDeserializer
```

#### 2.4. Configurar un Outgoing Channel

Configura un outgoing channel con las siguientes propiedades:

- Establece el nombre del outgoing channel a **new-bank-accounts-out**.
- Usa el tópico **bank-account-was-created** para enviar eventos
- Establece la clase de quarkus `ObjectMapperSerializer` como el serializer para los mensajes outgoing.

Agrega la siguiente configuración en `application.properties`:

```properties
# Outgoing Channels
mp.messaging.outgoing.new-bank-accounts-out.connector = smallrye-kafka
mp.messaging.outgoing.new-bank-accounts-out.topic = bank-account-was-created
mp.messaging.outgoing.new-bank-accounts-out.value.serializer = io.quarkus.kafka.client.serialization.ObjectMapperSerializer
```

### 3. Crear la Clase de Evento y Deserializer

#### 3.1. Crear la Clase BankAccountWasCreated

Crea una clase que representa el evento de crear una cuenta bancaria:

- Llama a la clase `BankAccountWasCreated`
- Crea la entidad en el paquete `com.bcp.training.event`
- El evento debe tener un `Long id` y `Long balance` como atributos

**Código:**

```java
package com.bcp.training.event;

public class BankAccountWasCreated {
    public Long id;
    public Long balance;

    public BankAccountWasCreated() {}

    public BankAccountWasCreated(Long id, Long balance) {
        this.id = id;
        this.balance = balance;
    }
}
```

#### 3.2. Crear el Deserializer

Crear un deserializer que transforma mensajes tipo evento desde Apache Kafka a instancias `BankAccountWasCreated`:

- Llama a la clase `BankAccountWasCreatedDeserializer`
- Crea la entidad en el paquete `com.bcp.training.serde`

**Código:**

```java
package com.bcp.training.serde;

import com.bcp.training.event.BankAccountWasCreated;
import io.quarkus.kafka.client.serialization.ObjectMapperDeserializer;

public class BankAccountWasCreatedDeserializer
        extends ObjectMapperDeserializer<BankAccountWasCreated> {
    public BankAccountWasCreatedDeserializer() {
        super(BankAccountWasCreated.class);
    }
}
```

### 4. Actualizar el Endpoint POST /accounts

#### 4.1. Agregar el Emitter

Abre la clase `BankAccountsResource` y luego agrega una variable `Emitter` para enviar un evento `BankAccountWasCreated` al channel `new-bank-accounts-out`:

```java
@Channel("new-bank-accounts-out")
Emitter<BankAccountWasCreated> emitter;
```

#### 4.2. Actualizar el Método sendBankAccountEvent()

Actualiza el método `sendBankAccountEvent()` para usar el emitter, y enviar eventos `BankAccountWasCreated` al Apache Kafka:

```java
public void sendBankAccountEvent(Long id, Long balance) {
    emitter.send(new BankAccountWasCreated(id, balance));
}
```

#### 4.3. Actualizar el Método create()

Actualizar el método `create()` para enviar eventos `BankAccountWasCreated` después de insertar nuevos registros a la base de datos:

```java
@POST
public Uni<Response> create(@Valid BankAccount bankAccount) {
    // Validar que el balance no sea null
    if (bankAccount.balance == null) {
        return Uni.createFrom().item(
            Response.status(Response.Status.BAD_REQUEST)
                .entity("{\"error\": \"El balance no puede ser null\"}")
                .build()
        );
    }
    
    // Validar que el balance sea positivo
    if (bankAccount.balance <= 0) {
        return Uni.createFrom().item(
            Response.status(Response.Status.BAD_REQUEST)
                .entity("{\"error\": \"El balance debe ser un número positivo\"}")
                .build()
        );
    }
    
    return Panache
        .<BankAccount>withTransaction(bankAccount::persist)
        .onItem()
        .transform(inserted -> {
            sendBankAccountEvent(inserted.id, inserted.balance);
            return Response.created(
                URI.create("/accounts/" + inserted.id)
            ).build();
        });
}
```

### 5. Crear el Consumidor de Eventos

Crea un consumidor de eventos `BankAccountWasCreated` para establecer el tipo de bank account.

**Lógica:**
- Si el balance es menor a 100000, entonces el tipo de cuenta debe ser **regular**.
- Caso contrario, el tipo debe ser **premium**.

**Tip:** Puedes usar el método `logEvent()` para debuggear los eventos procesados.

#### 5.1. Abrir la Clase AccountTypeProcessor

Abre la clase `com.bcp.training.reactive.AccountTypeProcessor`.

#### 5.2. Actualizar el Método calculateAccountType()

Actualiza el método `calculateAccountType()` para retornar `premium` cuando el balance es mayor o igual a 100000, y `regular` en caso contrario:

```java
public String calculateAccountType(Long balance) {
    return balance >= 100000 ? "premium" : "regular";
}
```

#### 5.3. Agregar el Método processNewBankAccountEvents()

Agrega un método llamado `processNewBankAccountEvents` que procesa eventos `BankAccountWasCreated` y retorna valores `Uni<Void>`:

- Establece el incoming channel a **new-bank-accounts-in**.
- Anota el método con la anotación `@ActivateRequestContext`.
- Encuentra registros en la base de datos usando el event ID.
- Usa un session transaction para cerrar la conexión a la base de datos después de actualizar los registros.

**Código:**

```java
@Incoming("new-bank-accounts-in")
@ActivateRequestContext
public Uni<Void> processNewBankAccountEvents(BankAccountWasCreated event) {
    String assignedAccountType = calculateAccountType(event.balance);
    logEvent(event, assignedAccountType);
    
    return session.withTransaction(
        s -> BankAccount.<BankAccount>findById(event.id)
            .onItem()
            .ifNotNull()
            .invoke(entity -> entity.type = assignedAccountType)
            .replaceWithVoid()
    );
}
```

#### 5.4. Iniciar la Aplicación

**Windows (PowerShell/CMD), Linux, Mac:**
```bash
mvn quarkus:dev
```

Deberías ver un mensaje similar a:

```
Listening on: http://localhost:8080
```

---

## Parte 2: Configuración del Servicio fraud-detector

### 6. Abrir el Proyecto fraud-detector

#### 6.1. Navegar al Directorio

Abre una nueva terminal y navega al directorio del proyecto:

**Windows (PowerShell):**
```powershell
cd ..\fraud-detector
```

**Windows (CMD):**
```cmd
cd ..\fraud-detector
```

**Linux/Mac:**
```bash
cd ../fraud-detector
```

#### 6.2. Examinar los Archivos

Abre el proyecto con tu editor y examina los archivos:

- `com.bcp.training.event.BankAccountWasCreated`: Representa eventos de creación de cuentas bancarias.
- `com.bcp.training.event.HighRiskAccountWasDetected`: Representa un evento de alto riesgo.
- `com.bcp.training.event.LowRiskAccountWasDetected`: Representa un evento de bajo riesgo.
- `com.bcp.training.serde.BankAccountWasCreatedDeserializer`: Un deserializer para eventos `BankAccountWasCreated`.
- `application.properties`: Define la configuración para incoming channels (llamado `new-bank-accounts-in`) y outgoing channels (llamados `low-risk-alerts-out` y `high-risk-alerts-out`).

### 7. Crear el Sistema de Detección de Fraude

Crea un sistema de detección de fraude que procesa eventos `BankAccountWasCreated`:

- Procesa eventos entrantes `BankAccountWasCreated`.
- Calcula un fraud score para eventos entrantes `BankAccountWasCreated`.
- Usa el fraud score para enviar eventos `HighRiskAccountWasDetected` o `LowRiskAccountWasDetected` a Kafka.

#### 7.1. Agregar Emitter para LowRiskAccountWasDetected

Abre la clase `com.bcp.training.reactive.FraudProcessor` y agrega una variable `Emitter` para enviar eventos `LowRiskAccountWasDetected` al channel `low-risk-alerts-out`:

```java
@ApplicationScoped
public class FraudProcessor {
    private static final Logger LOGGER =
        Logger.getLogger(FraudProcessor.class);

    @Channel("low-risk-alerts-out")
    Emitter<LowRiskAccountWasDetected> lowRiskEmitter;
}
```

#### 7.2. Agregar Emitter para HighRiskAccountWasDetected

Agrega una variable `Emitter` para enviar eventos `HighRiskAccountWasDetected` al channel `high-risk-alerts-out`:

```java
@Channel("high-risk-alerts-out")
Emitter<HighRiskAccountWasDetected> highRiskEmitter;
```

#### 7.3. Implementar el Método sendEventNotifications()

Actualiza el método `sendEventNotifications` que procesa eventos `BankAccountWasCreated` y retorna `CompletionStage<Void>`:

- Establece el incoming channel a **new-bank-accounts-in**.
- Si el fraud score del evento entrante es mayor a 50, debe enviar un evento `HighRiskAccountWasDetected` al channel `high-risk-alerts-out`.
- Si el fraud score del evento entrante es mayor a 20 y menor o igual a 50, debe enviar un evento `LowRiskAccountWasDetected` al channel `low-risk-alerts-out`.
- Caso contrario, el evento debe ser ignorado.
- Puedes usar `logBankAccountWasCreatedEvent()`, `logFraudScore()`, y `logEmitEvent()` para debuggear la lógica.

**Código:**

```java
@Incoming("new-bank-accounts-in")
public CompletionStage<Void> sendEventNotifications(Message<BankAccountWasCreated> message) {
    BankAccountWasCreated event = message.getPayload();
    logBankAccountWasCreatedEvent(event);
    
    Integer fraudScore = calculateFraudScore(event.balance);
    logFraudScore(event.id, fraudScore);
    
    if (fraudScore > 50) {
        logEmitEvent("HighRiskAccountWasDetected", event.id);
        highRiskEmitter.send(new HighRiskAccountWasDetected(event.id));
    } else if (fraudScore > 20) {
        logEmitEvent("LowRiskAccountWasDetected", event.id);
        lowRiskEmitter.send(new LowRiskAccountWasDetected(event.id));
    }
    
    return message.ack();
}
```

#### 7.4. Iniciar la Aplicación

**Windows (PowerShell/CMD), Linux, Mac:**
```bash
mvn quarkus:dev
```

Deberías ver un mensaje similar a:

```
Listening on: http://localhost:8081
```

---

## Parte 3: Pruebas End-to-End

### 8. Verificar la Lógica de la Aplicación

Finalmente hagamos un test end-to-end para verificar la lógica de la aplicación.

#### 8.1. Abrir el Navegador

Abre el navegador y ve al URL `http://localhost:8080`

#### 8.2. Crear Primera Cuenta

En el área **Create Bank Account**, ingresa `5000` en el campo **Initial Balance**, y clic en **Create**. Observa que el front end muestra la cuenta creada en la sección de abajo, pero, sin tipo de cuenta.

#### 8.3. Crear Segunda Cuenta

En el área **Create Bank Account**, ingresa `200000` en el campo **Initial Balance** y clic en **Create**. Observa que el front end muestra la cuenta creada en la sección de abajo sin tipo de cuenta.

#### 8.4. Verificar Tipos de Cuenta

Refresca la página y verifica que el processor actualizó el tipo de cuenta por detrás, y ahora el front end muestra los tipos de cuenta. La cuenta con balance de 5000 tiene el tipo **regular** asignado, y el otro tipo de cuenta tiene el tipo **premium** asignado.

#### 8.5. Verificar Logs del fraud-detector

Retorna a la terminal de línea de comandos que ejecuta el servicio `fraud-detector` y verifica que el processor ejecutó la lógica para detectar cuentas sospechosas.

Deberías ver logs similares a:

```
[...FraudProcessor] (...) Received BankAccountWasCreated - ID: 1 Balance: 5,000
[...FraudProcessor] (...) Fraud score was calculated - ID: 1 Score: 25
[...FraudProcessor] (...) Sending a LowRiskAccountWasDetected event for bank account #1
...
[...FraudProcessor] (...) Received BankAccountWasCreated - ID: 2 Balance: 200,000
[...FraudProcessor] (...) Fraud score was calculated - ID: 2 Score: 75
[...FraudProcessor] (...) Sending a HighRiskAccountWasDetected event for bank account #2
```

#### 8.6. Detener fraud-detector

Presiona la letra `q` para salir y cierra la terminal.

#### 8.7. Detener joedayz-bank

Retorna a la terminal que ejecuta el servicio `joedayz-bank` y luego presiona `q` para detener la aplicación.

---

## Resumen

¡Felicitaciones! Has terminado el laboratorio.

En este laboratorio has aprendido a:

- Configurar SmallRye Reactive Messaging con Apache Kafka en Quarkus
- Crear eventos y deserializers personalizados
- Implementar emitters para enviar eventos a Kafka
- Crear consumidores de eventos reactivos
- Implementar lógica de procesamiento de eventos asíncrona
- Construir una arquitectura orientada a eventos (EDA) con Quarkus

---

## Estructura de Eventos

### Eventos en el Sistema

1. **BankAccountWasCreated**: Se emite cuando se crea una nueva cuenta bancaria
   - `id`: Long - Identificador de la cuenta
   - `balance`: Long - Balance inicial de la cuenta

2. **HighRiskAccountWasDetected**: Se emite cuando se detecta una cuenta de alto riesgo
   - `id`: Long - Identificador de la cuenta

3. **LowRiskAccountWasDetected**: Se emite cuando se detecta una cuenta de bajo riesgo
   - `id`: Long - Identificador de la cuenta

### Canales de Kafka

- **bank-account-was-created**: Tópico para eventos de creación de cuentas
- **low-risk-account-was-detected**: Tópico para alertas de bajo riesgo
- **high-risk-account-was-detected**: Tópico para alertas de alto riesgo

---

## Troubleshooting

### Kafka no está disponible

Asegúrate de que Kafka esté corriendo. Puedes usar Docker Compose o Podman Compose:

#### Docker Compose:
```bash
# Windows (PowerShell/CMD), Linux, Mac
cd joedayz-bank
docker-compose up -d
```

#### Podman Compose:
```bash
# Windows (PowerShell/CMD), Linux, Mac
cd joedayz-bank
podman-compose up -d
```

### Verificar el Estado de los Contenedores

#### Docker:
```bash
# Windows (PowerShell/CMD), Linux, Mac
docker ps
docker logs joedayz-kafka
```

#### Podman:
```bash
# Windows (PowerShell/CMD), Linux, Mac
podman ps
podman logs joedayz-kafka
```

### Puerto ya en uso

Si el puerto 8080 o 8081 está en uso, puedes cambiar el puerto en `application.properties`:

```properties
quarkus.http.port=8082
```

### Eventos no se procesan

Verifica que:
- Kafka esté corriendo y accesible en `localhost:9092`
- Los canales estén correctamente configurados en `application.properties`
- Los deserializers estén correctamente implementados

### Limpiar Contenedores y Volúmenes

Si necesitas empezar desde cero:

#### Docker:
```bash
# Windows (PowerShell/CMD), Linux, Mac
cd joedayz-bank
docker-compose down -v
docker-compose up -d
```

#### Podman:
```bash
# Windows (PowerShell/CMD), Linux, Mac
cd joedayz-bank
podman-compose down -v
podman-compose up -d
```

---

**Autor:** Jose Diaz  
**Academia:** JOEDAYZ academy
