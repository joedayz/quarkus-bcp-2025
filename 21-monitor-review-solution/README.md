# BCP Conference Monitoring Demo

Stack completo de monitoreo con Jaeger, Prometheus y Grafana para la aplicación BCP Conference.

## 🚀 Inicio Rápido

### 1. Iniciar servicios Quarkus
```bash
# Terminal 1 - Sessions service
cd sessions
./mvnw quarkus:dev

# Terminal 2 - Speakers service  
cd speakers
./mvnw quarkus:dev
```

### 2. Iniciar stack de monitoreo
```bash
./start-monitoring.sh
```

## 📊 Servicios

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Grafana** | http://localhost:3000 | admin/admin |
| **Prometheus** | http://localhost:9090 | - |
| **Jaeger** | http://localhost:16686 | - |

## 📈 Dashboard

El dashboard "BCP Conference Metrics Dashboard" incluye:
- Métrica personalizada: `callsToGetSessions`
- HTTP requests rate y response time
- JVM memory y GC metrics

## 🛑 Comandos

```bash
# Iniciar todo
./start-monitoring.sh

# Detener todo
docker-compose down

# Ver logs
docker-compose logs -f
```

## 📝 Generar Métricas

```bash
curl http://localhost:8081/sessions
curl http://localhost:8082/speaker
```
