# Laboratorio: Revisión de Pruebas

**Autor:** José Díaz  
**GitHub Repo:** `https://github.com/joedayz/quarkus-bcp-2025.git`  
**Proyecto a Abrir:** `06-test-review-start`

## Instrucciones

Está probando una aplicación basada en microservicios que implementa un sistema de gestión de conferencias. La aplicación consta de tres microservicios:

1. **Microservicio `schedule`:**
   - **Función:** Gestiona los horarios de las conferencias.
   - **Base de datos:** Almacena datos en una base de datos H2 en memoria.
   - **Razón del fallo inicial de las pruebas:** Las pruebas fallan inicialmente porque el endpoint HTTP de prueba no está configurado y el H2 Dev Service no está funcionando.

2. **Microservicio `speaker`:**
   - **Función:** Gestiona los oradores de las conferencias.
   - **Base de datos:** Almacena datos en una base de datos H2 en memoria.
   - **Inicialización:** Cuando el servicio se inicia, Quarkus pobla la base de datos con datos de prueba.
   - **Razón del fallo inicial de las pruebas:** Las pruebas fallan inicialmente debido a una dependencia faltante y un escenario de prueba que requiere que la base de datos devuelva una lista vacía de oradores.

3. **Microservicio `session`:**
   - **Función:** Gestiona las sesiones de las conferencias.
   - **Base de datos:** Almacena datos en una base de datos PostgreSQL.
   - **Dependencias:** Este servicio depende del servicio `speaker` para obtener información de los oradores.
   - **Razón del fallo inicial de las pruebas:** Las pruebas fallan inicialmente porque Quarkus no puede encontrar la imagen del contenedor PostgreSQL y el servicio `speaker` no es accesible.

**Objetivo Final:** Debe hacer que las pruebas pasen en cada uno de los tres servicios.

---

## Paso 1: Abrir el proyecto schedule y corregir la clase ScheduleResourceTest

### Instrucciones:
- Convierta las pruebas de esta clase en pruebas Quarkus.
- Haga que las pruebas utilicen la URL base de la clase ScheduleResource.

### 1.1. Navegue al directorio del servicio schedule.

```bash
cd schedule
```

### 1.2. Abra el proyecto con el editor de su preferencia, como VSCode o Intellij IDEA.

### 1.3. Verifique que cuatro pruebas estén fallando.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[ERROR] Errors:
[ERROR] ScheduleResourceTest.testAdd:41 >> Connect Connection refused
[ERROR] ScheduleResourceTest.testAllSchedules:50 >> IllegalState This ...
[ERROR] ScheduleResourceTest.testRetrieve:28 >> Connect Connection refused
[ERROR] ScheduleResourceTest.testRetrieveByVenue:61 >> IllegalState This ...
[INFO] [ERROR] Tests run: 4, Failures: 0, Errors: 4, Skipped: 0
[INFO] [INFO]
[INFO] BUILD FAILURE
```

### 1.4. Abra el archivo `src/test/java/com/bcp/training/conference/ScheduleResourceTest.java` y agregue las anotaciones `@QuarkusTest` y `@TestHTTPEndpoint`.

- La anotación `@TestHTTPEndpoint` debe usar el endpoint de la clase ScheduleResource.

**Código a agregar:**

```java
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.http.TestHTTPEndpoint;

@QuarkusTest
@TestHTTPEndpoint(ScheduleResource.class)
public class ScheduleResourceTest {
    // ...
}
```

### 1.5. Verifique que las pruebas aún fallen, pero ahora debido a un error diferente.

Ejecute las pruebas nuevamente:

```bash
mvn test
```

**Salida esperada:**
```
ERROR [org.hib.eng.jdb.spi.SqlExceptionHelper] (main) Connection is broken: "java.net.UnknownHostException: schedules-db.conference.svc.cluster.local: schedules-db.conference.svc.cluster.local"
[ERROR] Errors:
[ERROR] ScheduleResourceTest.testAllSchedules:51 >> Persistence org.hibernate.exception...
[ERROR] ScheduleResourceTest.testRetrieveByVenue:62 >> Persistence org.hibernate.except...
[INFO] [ERROR] Tests run: 4, Failures: 2, Errors: 2, Skipped: 0
```

---

## Paso 2: Las pruebas del servicio schedule siguen fallando debido a un error de conexión a la base de datos

### Instrucción:
Quarkus no activa Dev Services para H2 porque la configuración de la aplicación contiene propiedades de conexión H2 inexistentes. Modifique el archivo de configuración para que la propiedad de conexión H2 no se aplique al perfil de prueba.

### 2.1. Abra el archivo `src/main/resources/application.properties`.

- La base de datos H2 está configurada con una URL de conexión específica, lo que hace que H2 Dev Services se desactive.
- Use el prefijo `%prod.` para indicar que la URL de conexión H2 es solo para producción.

**Configuración a modificar:**

```properties
%prod.quarkus.datasource.jdbc.url=jdbc:h2:tcp://schedules-db.conference.svc.cluster.local/~/schedules
```

### 2.2. Verifique que todas las pruebas pasen.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
[INFO] [INFO]
[INFO] BUILD SUCCESS
```

---

## Paso 3: Cambie al servicio speaker e inyecte la dependencia faltante DeterministicIdGenerator en la clase SpeakerResourceTest

### Instrucción:
Para inyectar esta dependencia, la clase `DeterministicIdGenerator` también debe actualizarse para ser un bean singleton mock.

### 3.1. Navegue al directorio del servicio speaker.

```bash
cd ../speaker
```

### 3.2. Abra el proyecto con el editor de su preferencia.

### 3.3. Verifique que las pruebas fallen debido a un error de compilación.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[ERROR] COMPILATION ERROR:
[INFO]
[ERROR] /.../SpeakerResourceTest.java: [25,9] cannot find symbol
symbol: variable idGenerator
location: class com.redhat.training.speaker.SpeakerResourceTest
[INFO] 1 error
[INFO]
[INFO] BUILD FAILURE
```

### 3.4. Abra el archivo `src/test/java/com/bcp/training/speaker/SpeakerResourceTest.java` e inyecte el bean DeterministicIdGenerator en el campo idGenerator.

**Código a agregar:**

```java
import jakarta.inject.Inject;

@QuarkusTest
public class SpeakerResourceTest {
    @Inject
    DeterministicIdGenerator idGenerator;
    
    // ...
}
```

### 3.5. Abra el archivo `src/test/java/com/bcp/training/speaker/DeterministicIdGenerator.java` e identifique la clase como un mock singleton bean.

**Código a agregar:**

```java
import io.quarkus.test.junit.mockito.Mock;
import jakarta.inject.Singleton;

@Mock
@Singleton
public class DeterministicIdGenerator implements IdGenerator {
    // ...
}
```

### 3.6. Verifique que las pruebas pasen parcialmente. Una prueba pasa, pero el método de prueba testListEmptySpeakers aún falla porque la base de datos no está vacía.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[ERROR] Failures:
[ERROR] SpeakerResourceTest.testListEmptySpeakers:49 1 expectation failed.
JSON path size() doesn't match. Expected: is 0 Actual: 5
[INFO] [ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0
[INFO] [INFO]
[INFO] BUILD FAILURE
```

---

## Paso 4: Actualice la prueba SpeakerResourceTest#testListEmptySpeakers del servicio speaker para preparar un escenario en el que Speaker#listAll devuelva una lista vacía

### Instrucción:
Como la base de datos se llena inicialmente con datos, debe mockear la entidad Panache Speaker y el método Speaker#listAll para que retorne una lista vacía.

### 4.1. Mockee la entidad Panache para simular un escenario en el que la base de datos de speakers esté vacía.

**Código a agregar en el método `testListEmptySpeakers()`:**

```java
import io.quarkus.test.panache.PanacheMock;
import org.mockito.Mockito;
import java.util.Collections;

@Test
public void testListEmptySpeakers() {
    PanacheMock.mock(Speaker.class);
    Mockito.when(Speaker.listAll())
        .thenReturn(Collections.emptyList());
    
    given()
        .when()
        .get("/speaker")
        .then()
        .statusCode(200)
        .body("size()", is(0));
}
```

### 4.2. Verifique que las dos pruebas pasen.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] [INFO]
[INFO] BUILD SUCCESS
```

---

## Paso 5: Abra el microservicio session y corrija la configuración de Dev Services

### Instrucción:
Use la imagen de PostgreSQL para Dev Services: `postgres:14.1`

### 5.1. Navegue al directorio del servicio session.

```bash
cd ../session
```

### 5.2. Abra el proyecto con el editor de su preferencia.

### 5.3. Verifique que las pruebas fallen debido a un error de imagen de contenedor.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
Caused by: org.testcontainers.containers.ContainerLaunchException: Container startup failed
Caused by: org.testcontainers.containers.ContainerFetchException: Can't get Docker image:
[ERROR] Errors:
[ERROR] SessionResourceTest.testGetSessionWithSpeaker >> Runtime java.lang.RuntimeExcep...
[INFO] [ERROR] Tests run: 2, Failures: 0, Errors: 2, Skipped: 1
[INFO]
[INFO] BUILD FAILURE
```

### 5.4. Abra el archivo `src/main/resources/application.properties` y corrija la propiedad `quarkus.datasource.devservices.image-name`.

**Configuración a modificar:**

```properties
quarkus.datasource.devservices.image-name=postgres:14.1
```

### 5.5. Ejecute las pruebas. Verifique que el método testGetSessionWithSpeaker falle.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[ERROR] Failures:
[ERROR] SessionResourceTest.testGetSessionWithSpeaker:53 1 expectation failed.
JSON path speaker.firstName doesn't match. Expected: Pablo Actual: null
[INFO] [ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0
[INFO] [INFO]
[INFO] BUILD FAILURE
```

---

## Paso 6: La prueba testGetSessionWithSpeaker del servicio session cubre código que envía una solicitud HTTP al servicio de speakers

### Instrucciones:
- La prueba falla porque el otro servicio **no es accesible**.
- En particular, el código que realiza la solicitud HTTP es el método `SpeakerService#getById`.
- Corrija la prueba **mockeando este método**.
- El método mockeado debe **retornar un speaker** que cumpla con las expectativas de la prueba.

### 6.1. Abra el archivo `src/test/java/com/bcp/training/conference/session/SessionResourceTest.java`.

En el método `testGetSessionWithSpeaker()`, mockee el servicio de speakers para que devuelva un speaker:

**Código a agregar:**

```java
import org.mockito.Mockito;
import com.bcp.training.conference.speaker.Speaker;

@Test
public void testGetSessionWithSpeaker() {
    int speakerId = 12;
    Mockito.when(speakerService.getById(Mockito.anyInt()))
        .thenReturn(new Speaker(speakerId, "Pablo", "Solar"));
    
    given()
        .contentType("application/json")
        .and()
        .body(sessionWithSpeakerId(speakerId))
        .post("/sessions");

    when()
        .get("/sessions/1")
        .then()
        .statusCode(200)
        .contentType("application/json")
        .body("speaker.firstName", equalTo("Pablo"));
}
```

### 6.2. Ejecute las pruebas y verifique que pasen.

Ejecute las pruebas:

```bash
mvn test
```

**Salida esperada:**
```
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] [INFO]
[INFO] BUILD SUCCESS
```

---

## Conclusión

Esto termina el laboratorio.

¡Enjoy!

**José**

