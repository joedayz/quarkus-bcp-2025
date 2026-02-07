# Stack ELK para Logging en Quarkus

Este proyecto incluye una configuración completa para coleccionar, almacenar y visualizar logs usando:
- **Fluentd**: Para coleccionar y procesar logs
- **Elasticsearch**: Para almacenar los logs
- **Kibana**: Para visualizar y analizar los logs

## Inicio Rápido

### 1. Construir la aplicación

```bash
mvn clean package -DskipTests
```

### 2. Iniciar el stack completo

**Con Docker:**
```bash
./start-elk.sh docker
# o
docker compose up -d
```

**Con Podman:**
```bash
./start-elk.sh podman
# o
podman-compose up -d
```

### 3. Generar algunos logs

```bash
# Obtener un expense existente
curl http://localhost:8080/expenses/joel-2

# Intentar obtener uno inexistente (genera error)
curl http://localhost:8080/expenses/nonexistent

# Obtener todos los expenses
curl http://localhost:8080/expenses
```

### 4. Visualizar logs en Kibana

1. Abre http://localhost:5601 en tu navegador
2. Ve a **Kibana** → **Data Views** (en el menú lateral izquierdo)
3. Haz clic en **Create data view**
4. En el campo **Name**, ingresa: `quarkus-*`
5. En el campo **Index pattern**, ingresa: `quarkus-*`
6. Selecciona `@timestamp` como time field (si está disponible)
7. Haz clic en **Create data view**
8. Ve a **Discover** para ver los logs

**Nota:** Si no ves índices aún, espera unos minutos y verifica que hay índices en Elasticsearch con: `curl http://localhost:9200/_cat/indices?v`

## Estructura del Proyecto

```
expenses/
├── docker-compose.yml          # Orquestación de servicios
├── Dockerfile                   # Imagen de la aplicación
├── fluentd/
│   └── conf/
│       └── fluent.conf         # Configuración de Fluentd
├── logs/                        # Directorio de logs (montado como volumen)
└── start-elk.sh                # Script de inicio rápido
```

## Servicios

| Servicio | Puerto | URL |
|----------|--------|-----|
| Quarkus App | 8080 | http://localhost:8080 |
| Elasticsearch | 9200 | http://localhost:9200 |
| Kibana | 5601 | http://localhost:5601 |
| Fluentd | 24224 | TCP/UDP |

## Comandos Útiles

### Ver logs de los contenedores

```bash
# Docker
docker compose logs -f expenses-app
docker compose logs -f fluentd
docker compose logs -f elasticsearch
docker compose logs -f kibana

# Podman
podman-compose logs -f expenses-app
podman-compose logs -f fluentd
podman-compose logs -f elasticsearch
podman-compose logs -f kibana
```

### Verificar estado de los servicios

```bash
# Docker
docker compose ps

# Podman
podman-compose ps
```

### Consultar Elasticsearch directamente

```bash
# Listar índices
curl http://localhost:9200/_cat/indices?v

# Buscar logs
curl "http://localhost:9200/quarkus-*/_search?pretty" | jq

# Contar logs
curl "http://localhost:9200/quarkus-*/_count?pretty"
```

### Detener el stack

```bash
# Docker
docker compose down

# Podman
podman-compose down

# Con eliminación de volúmenes (borra datos de Elasticsearch)
docker compose down -v
podman-compose down -v
```

## Configuración

### Formato de Logs

Los logs se generan en el siguiente formato:
```
2024-01-23 10:22:32,005 DEBUG [com.bcp.training.expense.ExpensesResource] (executor-thread-0) Getting expense joel-2
```

Fluentd parsea este formato y extrae los siguientes campos:
- `timestamp`: Fecha y hora del log
- `level`: Nivel del log (DEBUG, INFO, ERROR, etc.)
- `logger`: Clase que generó el log
- `thread`: Thread que ejecutó el código
- `message`: Mensaje del log

### Enriquecimiento de Logs

Fluentd agrega automáticamente:
- `hostname`: Nombre del host
- `service_name`: "expenses-app"
- `environment`: "development"

## Troubleshooting

### Elasticsearch no inicia

- Verifica que el puerto 9200 no esté en uso
- Revisa los logs: `docker compose logs elasticsearch`
- Asegúrate de tener al menos 512MB de RAM disponible

### Kibana no se conecta a Elasticsearch

- Espera unos segundos después de que Elasticsearch esté listo
- Verifica que ambos contenedores estén en la misma red

### No se ven logs en Kibana

- Espera unos minutos para que Fluentd procese los logs (Fluentd procesa cada 5 segundos)
- Verifica que el data view está configurado: `quarkus-*` (en **Kibana** → **Data Views**)
- Verifica que hay índices en Elasticsearch: `curl http://localhost:9200/_cat/indices?v`
- Revisa los logs de Fluentd: `docker compose logs fluentd`
- Verifica que hay logs en Elasticsearch: `curl http://localhost:9200/quarkus-*/_count`
- Asegúrate de que la aplicación está generando logs (haz algunas peticiones HTTP)

### Fluentd no procesa logs

- Verifica que el archivo de log existe: `docker compose exec expenses-app ls -la /var/log/quarkus/`
- Revisa los logs de Fluentd para errores de parsing
- Verifica que el volumen está montado correctamente

## Personalización

### Cambiar el formato de logs

Edita `src/main/resources/application.properties` y modifica:
```properties
quarkus.log.file.format=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c{2.}] (%t) %s%e%n
```

Si cambias el formato, también necesitarás actualizar la expresión regular en `fluentd/conf/fluent.conf`.

### Agregar más campos a los logs

Modifica el filtro `<filter>` en `fluentd/conf/fluent.conf` para agregar más metadatos.

## Referencias

- [Quarkus Logging Guide](https://quarkus.io/guides/logging)
- [Fluentd Documentation](https://docs.fluentd.org/)
- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)

