# Guía de Monitoreo - Expense Service

## Inicio Rápido

### 1. Iniciar la aplicación Quarkus
```bash
./mvnw quarkus:dev
```

### 2. Iniciar Prometheus y Grafana
```bash
docker-compose up -d
```

### 3. Verificar que todo funciona

**Verificar métricas de la aplicación:**
```bash
curl http://localhost:8080/q/metrics | grep -E "(callsTo|expenseCreation|timeSinceLast)"
```

**Verificar Prometheus:**
- Abre http://localhost:9090
- Ve a Status → Targets y verifica que el target `expense-service` esté "UP"
- En la pestaña Graph, prueba la query: `callsToPostExpenses_total`

**Verificar Grafana:**
- Abre http://localhost:3000
- Login: `admin` / `admin`
- Ve a Dashboards → Expense Service Metrics Dashboard

## Generar Tráfico de Prueba

Puedes usar el script incluido para generar tráfico:
```bash
./scripts/simulate-traffic.sh
```

O manualmente:
```bash
# GET requests
curl http://localhost:8080/expenses

# POST requests
curl -X POST http://localhost:8080/expenses \
  -H "Content-Type: application/json" \
  -d '{"description":"Test Expense","paymentMethod":"CREDIT_CARD","amount":"25.50"}'
```

## Solución de Problemas

### Prometheus no puede conectarse a la aplicación

Si ves errores de conexión en Prometheus:

1. **Verifica que la aplicación esté corriendo:**
   ```bash
   curl http://localhost:8080/q/metrics
   ```

2. **Ajusta el target en `prometheus/prometheus.yml`:**
   - En macOS/Windows con Docker Desktop: usa `host.docker.internal:8080` (ya configurado)
   - En Linux: usa `172.17.0.1:8080` o la IP de tu host
   - Si la app corre en Docker: usa el nombre del servicio de docker-compose

3. **Reinicia Prometheus:**
   ```bash
   docker-compose restart prometheus
   ```

### Grafana no muestra datos

1. Verifica que Prometheus tenga datos:
   - Abre http://localhost:9090
   - Ejecuta una query como `callsToPostExpenses_total`

2. Verifica el datasource en Grafana:
   - Ve a Configuration → Data Sources
   - Verifica que "Prometheus" esté configurado y funcione (botón "Test")

3. Verifica el dashboard:
   - Ve a Dashboards → Expense Service Metrics Dashboard
   - Revisa que las queries de Prometheus sean correctas

### Las métricas no aparecen

1. Verifica que las métricas estén habilitadas en `application.properties`
2. Verifica que la aplicación esté usando la dependencia `quarkus-micrometer-registry-prometheus`
3. Reinicia la aplicación Quarkus

## Métricas Disponibles

### Counters
- `callsToPostExpenses_total`: Total de llamadas POST a `/expenses`
- `callsToGetExpenses_total`: Total de llamadas GET a `/expenses`

### Gauge
- `timeSinceLastGetExpenses`: Tiempo en milisegundos desde la última llamada GET

### Timer
- `expenseCreationTime_seconds`: Tiempo de creación de gastos
  - `expenseCreationTime_seconds_count`: Contador total
  - `expenseCreationTime_seconds_sum`: Suma total de tiempos
  - `expenseCreationTime_seconds_bucket`: Histograma con buckets

## Detener los Servicios

```bash
# Detener sin eliminar datos
docker-compose stop

# Detener y eliminar contenedores
docker-compose down

# Detener, eliminar contenedores y volúmenes (elimina todos los datos)
docker-compose down -v
```

