# LAB 10: QUARKUS REACTIVE ARCHITECTURE

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedavz/quarkus-bcp-2025.git

## Descripción

Este laboratorio demuestra cómo implementar una arquitectura reactiva en Quarkus para mejorar el rendimiento de aplicaciones que realizan operaciones de I/O lentas. El proyecto consta de dos servicios:

- **products**: Servicio REST que expone una API para consultar productos y su historial de precios
- **prices**: Servicio externo que proporciona datos históricos de precios (simula un proceso costoso que tarda ~2 segundos)

## Problema

El servicio **products** está configurado para usar solo:
- 1 hilo de trabajo (worker thread)
- 1 hilo de event-loop

El endpoint `GET /product/{id}/priceHistory` depende del servicio **prices** para obtener datos históricos. Como el servicio **prices** tarda aproximadamente 2 segundos en responder, cada solicitud bloquea el hilo de trabajo durante ese tiempo, causando que las solicitudes se pongan en cola y el rendimiento se degrade significativamente.

## Estructura del Proyecto

```
07-reactive-architecture-start/
├── products/          # Servicio Quarkus (Java)
│   ├── src/main/java/com/bcp/training/
│   │   ├── ProductsResource.java      # Recurso REST
│   │   ├── PricesService.java         # Cliente REST
│   │   ├── ProductPriceHistory.java   # Modelo de datos
│   │   └── Price.java                 # Modelo de datos
│   ├── benchmark.sh                   # Script de benchmark (Linux/Mac)
│   ├── benchmark.ps1                  # Script de benchmark (Windows)
│   └── pom.xml
└── prices/            # Servicio externo (Python)
    ├── app.py
    └── README.md
```

## Prerequisitos

- Java 21+
- Maven 3.8+
- Docker o Podman
- curl (o PowerShell en Windows)

## Configuración Inicial

### 1. Ejecutar el servicio prices

Ejecuta el servicio **prices** según el container runtime que tengas configurado:

**Podman:**
```bash
podman run -d --name prices -p 5500:5000 --restart=always docker.io/joedayz/do378-reactive-architecture-prices:latest
```

**Docker:**
```bash
docker run -d --name prices -p 5500:5000 --restart=always docker.io/joedayz/do378-reactive-architecture-prices:latest
```

### 2. Configuración del servicio products

El archivo `application.properties` está configurado con:

```properties
quarkus.http.access-log.enabled=true
quarkus.rest-client."com.bcp.training.PricesService".url=http://localhost:5000/

quarkus.thread-pool.max-threads=1
quarkus.vertx.worker-pool-size=1
quarkus.vertx.event-loops-pool-size=1
```

**Nota:** Esta configuración limita los hilos para fines de demostración del problema de bloqueo.

## Ejecución del Laboratorio

### Paso 1: Verificar el problema de bloqueo

#### 1.1. Navegar al directorio del proyecto

```bash
cd products
```

#### 1.2. Iniciar el servicio products en modo desarrollo

```bash
mvn quarkus:dev
```

Deberías ver:
```
INFO [io.quarkus] Listening on: http://localhost:8080
```

#### 1.3. Probar el endpoint (bloqueante)

**Linux/MacOS/Git Bash:**
```bash
time curl http://localhost:8080/products/1/priceHistory
```

**Windows PowerShell:**
```powershell
Measure-Command { curl http://localhost:8080/products/1/priceHistory }
```

Verifica que el request toma alrededor de 2 segundos en finalizar.

#### 1.4. Ejecutar el benchmark

El script `benchmark.sh` envía 10 requests en un segundo, pero toma más de 20 segundos en recibir todas las respuestas.

**Linux/MacOS/Git Bash:**
```bash
time ./benchmark.sh
```

**Windows PowerShell:**
```powershell
./benchmark.ps1
```

**Resultado esperado:** ~20 segundos (2 segundos por request × 10 requests)

#### 1.5. Inspeccionar los logs

Verifica que el `executor-thread-0` worker thread atendió los requests uno por uno, tomándole dos segundos por cada request:

```
INFO [io.qua.htt.access-log] (executor-thread-0) ... 26/Jan/2023:14:08:28
INFO [io.qua.htt.access-log] (executor-thread-0) ... 26/Jan/2023:14:08:30
INFO [io.qua.htt.access-log] (executor-thread-0) ... 26/Jan/2023:14:08:32
```

### Paso 2: Agregar dependencias REST y REST Client

Las dependencias ya están incluidas en el `pom.xml`, pero si necesitas reconfigurarlas:

```bash
# Remover extensiones
mvn quarkus:remove-extensions -Dextensions="rest,rest-jackson,rest-client,rest-client-jackson"

# Agregar extensiones
mvn quarkus:add-extensions -Dextensions="rest,rest-jackson,rest-client,rest-client-jackson"
```

### Paso 3: Implementar operaciones no bloqueantes

#### 3.1. Modificar PricesService para retornar Uni

Actualiza `PricesService.java` para que el método retorne `Uni<ProductPriceHistory>`:

```java
@GET
@Path("/history/{productId}")
Uni<ProductPriceHistory> getProductPriceHistory(
    @PathParam("productId") final Long productId
);
```

#### 3.2. Modificar ProductsResource para usar Uni

Actualiza `ProductsResource.java`:

```java
@GET
@NonBlocking
@Path("/{productId}/priceHistory")
public Uni<ProductPriceHistory> getProductPriceHistory(
    @PathParam("productId") final Long productId
) {
    return pricesService.getProductPriceHistory(productId);
}
```

**Nota:** La anotación `@NonBlocking` fuerza que el endpoint sea no bloqueante. Sin embargo, cuando un método retorna un `Uni`, Quarkus automáticamente lo trata como no bloqueante.

#### 3.3. Reiniciar la aplicación

Detén la aplicación (presiona `q`) y reinicia:

```bash
mvn quarkus:dev
```

#### 3.4. Probar el endpoint asíncrono

**Linux/MacOS/Git Bash:**
```bash
curl http://localhost:8080/products/1/priceHistory | jq
```

**Windows PowerShell:**
```powershell
Invoke-RestMethod http://localhost:8080/products/1/priceHistory | ConvertTo-Json -Depth 10
```

Deberías recibir una respuesta válida sin errores.

#### 3.5. Inspeccionar los logs

Verifica que el `vert.x-eventloop-thread-0` atiende el request:

```
INFO [io.qua.htt.access-log] (vert.x-eventloop-thread-0) ...
```

#### 3.6. Ejecutar el benchmark nuevamente

**Linux/MacOS/Git Bash:**
```bash
time ./benchmark.sh
```

**Windows PowerShell:**
```powershell
./benchmark.ps1
```

**Resultado esperado:** ~3 segundos (6 veces más rápido que la versión bloqueante)

El tiempo de respuesta no-bloqueante procesa los 10 requests seis veces más rápido que usando la estrategia bloqueante.

#### 3.7. Verificar que todos los requests usan el event loop

Inspecciona los logs y verifica que `vert.x-eventloop-thread-0` atiende todos los requests.

### Paso 4: Eliminar @NonBlocking (opcional)

Cuando un método retorna un `Uni`, Quarkus automáticamente lo trata como no bloqueante. Puedes eliminar la anotación `@NonBlocking`:

```java
@GET
@Path("/{productId}/priceHistory")
public Uni<ProductPriceHistory> getProductPriceHistory(
    @PathParam("productId") final Long productId
) {
    return pricesService.getProductPriceHistory(productId);
}
```

El endpoint seguirá funcionando correctamente.

### Paso 5: Manejar operaciones bloqueantes con @Blocking

#### 5.1. Probar el endpoint bloqueante

El endpoint `/products/blocking` simula una operación que bloquea el event loop por 30 segundos:

**Linux/MacOS/Git Bash:**
```bash
curl http://localhost:8080/products/blocking; echo
```

**Windows PowerShell:**
```powershell
curl http://localhost:8080/products/blocking
```

**Advertencia:** Verás un `io.vertx.core.VertxException: Thread blocked` en los logs de la aplicación.

#### 5.2. Ejecutar benchmark mientras el endpoint bloqueante está activo

Mientras esperas que el endpoint bloqueante responda, abre una nueva terminal y ejecuta el benchmark:

```bash
time ./benchmark.sh
```

**Resultado:** El benchmark será muy lento (~23 segundos) porque el event loop thread está bloqueado.

#### 5.3. Agregar @Blocking al endpoint bloqueante

Modifica `ProductsResource.java`:

```java
@GET
@Blocking
@Path("/blocking")
public Uni<String> blocking() {
    try {
        Thread.sleep(30000);
    } catch(InterruptedException e) {
        e.printStackTrace();
    }
    return Uni.createFrom().item("I am a blocking operation");
}
```

La anotación `@Blocking` indica a Quarkus que esta operación debe ejecutarse en un worker thread en lugar del event loop.

#### 5.4. Reiniciar y probar

1. Reinicia la aplicación
2. Envía un request al endpoint `/products/blocking`
3. Mientras esperas, ejecuta el benchmark en otra terminal

**Resultado esperado:** El benchmark debería completarse en ~3 segundos, demostrando que el event loop no está bloqueado.

#### 5.5. Inspeccionar los logs

Verifica que:
- Los requests a `/products/1/priceHistory` son atendidos por `vert.x-eventloop-thread-0`
- El request a `/products/blocking` es atendido por `executor-thread-0` (worker thread)

```
INFO [io.qua.htt.access-log] (vert.x-eventloop-thread-0) ... "GET /products/1/priceHistory HTTP/1.1" 200 6741
INFO [io.qua.htt.access-log] (vert.x-eventloop-thread-0) ... "GET /products/1/priceHistory HTTP/1.1" 200 6741
INFO [io.qua.htt.access-log] (executor-thread-0) ... "GET /products/blocking HTTP/1.1" 200 25
```

## Conceptos Clave

### Operaciones Bloqueantes vs No Bloqueantes

- **Bloqueante:** Una operación que espera por I/O (red, base de datos, archivos) bloquea el hilo hasta que completa
- **No Bloqueante:** Una operación que no bloquea el hilo, permitiendo que otros requests sean procesados mientras espera

### Anotaciones

- **`@NonBlocking`:** Fuerza que un endpoint se ejecute en el event loop (no bloqueante)
- **`@Blocking`:** Fuerza que un endpoint se ejecute en un worker thread (para operaciones bloqueantes)
- **Retornar `Uni`:** Automáticamente hace que un endpoint sea no bloqueante

### Threads en Quarkus

- **Event Loop Threads:** Manejan operaciones no bloqueantes (I/O asíncrono)
- **Worker Threads:** Manejan operaciones bloqueantes (CPU intensivas o I/O bloqueante)

## Resultados Esperados

| Escenario | Tiempo (10 requests) | Thread Utilizado |
|-----------|---------------------|------------------|
| Bloqueante (inicial) | ~20 segundos | executor-thread-0 |
| No Bloqueante (Uni) | ~3 segundos | vert.x-eventloop-thread-0 |
| Bloqueante con @Blocking | No bloquea event loop | executor-thread-0 |

## Finalización

Para detener la aplicación products, presiona `q` en la terminal donde está ejecutándose.

Para detener el contenedor prices:

**Podman:**
```bash
podman stop prices
podman rm prices
```

**Docker:**
```bash
docker stop prices
docker rm prices
```

## Referencias

- [Quarkus Reactive Architecture](https://quarkus.io/guides/reactive-architecture)
- [Mutiny - Reactive Programming Library](https://smallrye.io/smallrye-mutiny/)
- [REST Client Reactive](https://quarkus.io/guides/rest-client-reactive)

---

**Felicitaciones. Has terminado el laboratorio.**

José Díaz

