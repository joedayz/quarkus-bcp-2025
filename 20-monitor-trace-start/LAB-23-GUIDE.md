# LAB 23: QUARKUS MONITOR TRACE

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## Descripción

Este laboratorio te guiará a través de la configuración de tracing distribuido usando OpenTelemetry y Jaeger en un proyecto Quarkus que contiene 3 microservicios:

- **solver**: Evalúa una expresión dada. Devuelve el valor si la expresión es un número decimal, o delega las expresiones de suma y multiplicación a los servicios correspondientes.
- **adder**: Obtiene dos ecuaciones y devuelve la suma de sus resultados. Depende del microservicio solver para resolver ambos lados de la suma.
- **multiplier**: Obtiene dos ecuaciones y devuelve el producto de sus resultados. Depende del microservicio solver para resolver ambos lados de la multiplicación.

Los tres microservicios exponen su propia API REST. Una sola llamada del cliente para resolver una ecuación podría resultar en múltiples llamadas entre estos microservicios.

## Prerrequisitos

- Java JDK 11 o superior
- Maven 3.6 o superior
- Docker o Podman instalado
- Editor de código favorito

## Paso 1: Abrir el Proyecto

Abre el proyecto `20-monitor-trace-start` en tu editor favorito.

## Paso 2: Agregar la Extensión OpenTelemetry

Agrega la extensión `opentelemetry` a los tres servicios para habilitar el tracing.

### Linux/macOS

```bash
./add-tracing.sh
```

### Windows (PowerShell)

```powershell
.\add-tracing.ps1
```

### Comandos Manuales

Si prefieres ejecutar los comandos manualmente:

```bash
# Solver
cd solver
mvn quarkus:add-extension -Dextension="opentelemetry"
cd ..

# Adder
cd adder
mvn quarkus:add-extension -Dextension="opentelemetry"
cd ..

# Multiplier
cd multiplier
mvn quarkus:add-extension -Dextension="opentelemetry"
cd ..
```

## Paso 3: Iniciar Jaeger

Inicia la instancia local de Jaeger usando Podman o Docker.

### Opción A: Usando Podman

#### Linux/macOS

```bash
./jaeger.sh
```

#### Windows (PowerShell)

```powershell
.\jaeger.ps1
```

#### Comando Manual (Podman)

```bash
podman run --rm --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 16686:16686 \
  -p 14268:14268 \
  jaegertracing/all-in-one:1.57
```

### Opción B: Usando Docker

#### Linux/macOS/Windows

```bash
docker run --rm --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 16686:16686 \
  -p 14268:14268 \
  jaegertracing/all-in-one:1.57
```

**Nota:** Deberías ver mensajes como:
- "Starting jaeger-collector HTTP server"
- "Query server started" en el puerto 16686
- "Health Check state change" con status "ready"

Mantén esta terminal abierta mientras trabajas con el laboratorio.

## Paso 4: Configurar los Servicios para Enviar Traces a Jaeger

Configura cada servicio para enviar información de tracing a Jaeger editando los archivos `application.properties`.

### Configuración para el Servicio Adder

Edita `adder/src/main/resources/application.properties` y agrega las siguientes propiedades:

```properties
# Enable Tracing (OpenTelemetry)
quarkus.otel.service.name=adder
quarkus.otel.traces.sampler=traceidratio
quarkus.otel.traces.sampler.arg=1
quarkus.log.console.format=%d{HH:mm:ss} %-5p traceId=%X{traceId}, spanId=%X{spanId}, parentId=%X{parentId}, sampled=%X{sampled} [%c{2.}] (%t) %s%e%n
quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
quarkus.otel.exporter.otlp.traces.protocol=grpc
```

### Configuración para el Servicio Multiplier

Edita `multiplier/src/main/resources/application.properties` y agrega las mismas propiedades (ajustando el nombre del servicio):

```properties
# Enable Tracing
quarkus.otel.service.name=multiplier
quarkus.otel.traces.sampler=traceidratio
quarkus.otel.traces.sampler.arg=1
quarkus.log.console.format=%d{HH:mm:ss} %-5p traceId=%X{traceId}, spanId=%X{spanId}, parentId=%X{parentId}, sampled=%X{sampled} [%c{2.}] (%t) %s%e%n
quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
quarkus.otel.exporter.otlp.traces.protocol=grpc
```

### Configuración para el Servicio Solver

Edita `solver/src/main/resources/application.properties` y agrega las mismas propiedades (ajustando el nombre del servicio):

```properties
# Enable Tracing
quarkus.otel.service.name=solver
quarkus.otel.traces.sampler=traceidratio
quarkus.otel.traces.sampler.arg=1
quarkus.log.console.format=%d{HH:mm:ss} %-5p traceId=%X{traceId}, spanId=%X{spanId}, parentId=%X{parentId}, sampled=%X{sampled} [%c{2.}] (%t) %s%e%n
quarkus.otel.exporter.otlp.traces.endpoint=http://localhost:4317
quarkus.otel.exporter.otlp.traces.protocol=grpc
```

**Explicación de las propiedades:**

- `quarkus.otel.service.name`: Nombre del servicio que aparecerá en Jaeger
- `quarkus.otel.traces.sampler`: Tipo de sampler (traceidratio = muestreo basado en ratio)
- `quarkus.otel.traces.sampler.arg=1`: Ratio de muestreo (1 = 100% de las trazas)
- `quarkus.log.console.format`: Formato de logs que incluye información de tracing
- `quarkus.otel.exporter.otlp.traces.endpoint`: URL del Jaeger collector que recolecta la data de tracing
- `quarkus.otel.exporter.otlp.traces.protocol`: Protocolo usado para enviar traces (grpc o http/protobuf)

## Paso 5: Iniciar los 3 Microservicios

Inicia los tres microservicios usando los scripts proporcionados.

### Linux/macOS

```bash
./start.sh
```

### Windows (PowerShell)

```powershell
.\start.ps1
```

**Nota:** Los servicios se iniciarán en los siguientes puertos:
- **Solver**: http://localhost:8080 (debug: 5005)
- **Adder**: http://localhost:8081 (debug: 5006)
- **Multiplier**: http://localhost:8082 (debug: 5007)

Mantén esta terminal abierta. Presiona ENTER cuando quieras terminar todos los servicios.

### Comandos Manuales

Si prefieres iniciar los servicios manualmente en terminales separadas:

#### Linux/macOS

```bash
# Terminal 1 - Solver
cd solver
mvn quarkus:dev -Ddebug=5005

# Terminal 2 - Adder
cd adder
mvn quarkus:dev -Ddebug=5006

# Terminal 3 - Multiplier
cd multiplier
mvn quarkus:dev -Ddebug=5007
```

#### Windows (PowerShell)

```powershell
# Terminal 1 - Solver
cd solver
mvn quarkus:dev -Ddebug=5005

# Terminal 2 - Adder
cd adder
mvn quarkus:dev -Ddebug=5006

# Terminal 3 - Multiplier
cd multiplier
mvn quarkus:dev -Ddebug=5007
```

## Paso 6: Capturar Trazas y Visualizarlas en Jaeger

### 6.1. Acceder a la Consola Web de Jaeger

1. Abre tu navegador y navega a: **http://localhost:16686**
2. Aún no deberías ver ninguna traza porque no has invocado ningún endpoint en la aplicación.

### 6.2. Invocar el Endpoint del Servicio Adder

Abre una nueva terminal e invoca el endpoint:

#### Linux/macOS/Windows (con curl instalado)

```bash
curl http://localhost:8081/adder/5/3
```

**Salida esperada:** `8.0`

#### Windows (PowerShell - sin curl)

```powershell
Invoke-WebRequest -Uri "http://localhost:8081/adder/5/3" -UseBasicParsing | Select-Object -ExpandProperty Content
```

### 6.3. Visualizar la Traza del Servicio Adder

1. Refresca la consola web de Jaeger (http://localhost:16686)
2. Selecciona el servicio **adder** desde el campo **Service** en el panel **Search** a la izquierda
3. Haz clic en **Find Traces** para ver las trazas
4. Haz clic en la traza `adder:GET:com.bcp.training.AdderResource` para ver los detalles de la traza

### 6.4. Invocar el Endpoint del Servicio Multiplier

En la misma terminal, invoca el endpoint:

#### Linux/macOS/Windows (con curl instalado)

```bash
curl http://localhost:8082/multiplier/5/3
```

**Salida esperada:** `15.0`

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8082/multiplier/5/3" -UseBasicParsing | Select-Object -ExpandProperty Content
```

### 6.5. Visualizar la Traza del Servicio Multiplier

1. En Jaeger, selecciona el servicio **multiplier** desde el campo **Service**
2. Haz clic en **Find Traces**
3. Haz clic en `multiplier:GET:com.bcp.training.MultiplierService.multiply` para ver el detalle de la traza

### 6.6. Invocar el Endpoint del Servicio Solver

El servicio solver puede tomar ecuaciones compuestas con adición y multiplicación como entrada.

#### Linux/macOS/Windows (con curl instalado)

```bash
curl "http://localhost:8080/solver/5*4+3"
```

**Salida esperada:** `23.0`

#### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/solver/5*4+3" -UseBasicParsing | Select-Object -ExpandProperty Content
```

**Nota:** En PowerShell, si el símbolo `*` causa problemas, puedes usar:

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/solver/5%2A4+3" -UseBasicParsing | Select-Object -ExpandProperty Content
```

### 6.7. Visualizar la Traza del Servicio Solver

1. En Jaeger, selecciona el servicio **solver** desde el campo **Service**
2. Haz clic en **Find Traces**
3. Haz clic en `solver:GET:com.bcp.training.SolverService.solve` para ver el detalle de la traza

**Observación:** Esta traza debería mostrar múltiples spans porque el servicio solver hace llamadas a otros servicios (adder o multiplier) y estos a su vez pueden llamar al solver, creando una traza distribuida completa.

## Paso 7: Limpiar Todo

### 7.1. Detener los Microservicios

#### Si usaste los scripts:

- **Linux/macOS/Windows**: Presiona **ENTER** en la ventana terminal donde ejecutaste el script `start.sh` o `start.ps1`

#### Si iniciaste los servicios manualmente:

- Presiona **Ctrl+C** en cada terminal donde se está ejecutando un servicio

### 7.2. Detener el Contenedor de Jaeger

#### Si usaste los scripts:

- Presiona **Ctrl+C** en la terminal donde ejecutaste `jaeger.sh` o `jaeger.ps1`

#### Si iniciaste Jaeger manualmente:

- Presiona **Ctrl+C** en la terminal donde se está ejecutando el contenedor

#### Comandos alternativos para detener Jaeger:

**Con Podman:**

```bash
podman stop jaeger
```

**Con Docker:**

```bash
docker stop jaeger
```

## Resumen de Puertos

| Servicio | Puerto HTTP | Puerto Debug | Descripción |
|----------|-------------|--------------|-------------|
| Solver | 8080 | 5005 | Servicio principal de resolución de ecuaciones |
| Adder | 8081 | 5006 | Servicio de suma |
| Multiplier | 8082 | 5007 | Servicio de multiplicación |
| Jaeger UI | 16686 | - | Interfaz web de Jaeger |
| Jaeger Collector (OTLP gRPC) | 4317 | - | Recolección de traces vía gRPC |
| Jaeger Collector (OTLP HTTP) | 4318 | - | Recolección de traces vía HTTP |
| Jaeger Collector (HTTP Thrift) | 14268 | - | Recolección de traces vía Thrift HTTP |

## Troubleshooting

### Los servicios no se inician

- Verifica que los puertos 8080, 8081, 8082 no estén en uso
- Asegúrate de que Maven esté instalado y en el PATH
- Verifica que Java esté instalado correctamente

### No se ven trazas en Jaeger

- Verifica que Jaeger esté corriendo y accesible en http://localhost:16686
- Verifica que la configuración de `quarkus.otel.exporter.otlp.traces.endpoint` apunte a `http://localhost:4317`
- Asegúrate de que el contenedor de Jaeger tenga `COLLECTOR_OTLP_ENABLED=true`
- Revisa los logs de los servicios para ver si hay errores de conexión

### Error al conectar con Jaeger

- Verifica que el contenedor de Jaeger esté corriendo: `podman ps` o `docker ps`
- Verifica que los puertos estén correctamente mapeados
- En algunos sistemas, puede ser necesario usar `host.docker.internal` en lugar de `localhost` si los servicios corren en contenedores

## Conclusión

¡Felicitaciones! Has completado el laboratorio de tracing distribuido con Quarkus y Jaeger. Ahora puedes:

- Ver cómo las llamadas entre microservicios se rastrean en tiempo real
- Analizar el tiempo de ejecución de cada operación
- Identificar cuellos de botella en tu arquitectura de microservicios
- Entender el flujo completo de una petición a través de múltiples servicios

**¡Disfruta!**  
José

