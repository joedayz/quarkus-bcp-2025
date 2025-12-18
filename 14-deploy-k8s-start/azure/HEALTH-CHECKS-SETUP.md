# Configuración de Health Checks en Quarkus

## ¿Por qué necesitamos Health Checks?

Los **health checks** son endpoints HTTP que Kubernetes usa para verificar el estado de tus aplicaciones mediante los **probes** (liveness y readiness).

## Dependencia Requerida

Quarkus NO incluye health checks por defecto. Necesitas agregar la extensión `quarkus-smallrye-health`.

## Paso 1: Agregar la Dependencia

### expense-service/pom.xml

Agrega esta dependencia en la sección `<dependencies>`:

```xml
<dependency>
  <groupId>io.quarkus</groupId>
  <artifactId>quarkus-smallrye-health</artifactId>
</dependency>
```

### expense-client/pom.xml

Agrega la misma dependencia:

```xml
<dependency>
  <groupId>io.quarkus</groupId>
  <artifactId>quarkus-smallrye-health</artifactId>
</dependency>
```

## Paso 2: Verificar que se agregó correctamente

```bash
# Verificar en expense-service
grep -A 2 "quarkus-smallrye-health" expense-service/pom.xml

# Verificar en expense-client
grep -A 2 "quarkus-smallrye-health" expense-client/pom.xml
```

Deberías ver la dependencia en ambos archivos.

## Paso 3: Reconstruir las aplicaciones

```bash
cd azure

# Reconstruir y subir las imágenes con la nueva dependencia
./scripts/build-and-push-all.sh
```

Esto:
1. Compila las aplicaciones con la nueva dependencia
2. Construye las imágenes Docker
3. Las sube a Azure Container Registry

## Paso 4: Verificar que los endpoints funcionan localmente (opcional)

Antes de desplegar, puedes probar localmente:

```bash
# En expense-service
cd expense-service
mvn quarkus:dev

# En otra terminal, probar los endpoints:
curl http://localhost:8080/q/health
curl http://localhost:8080/q/health/live
curl http://localhost:8080/q/health/ready
```

Deberías ver respuestas JSON como:
```json
{
  "status": "UP",
  "checks": []
}
```

## Paso 5: Redesplegar en AKS

```bash
cd azure

# Redesplegar con las nuevas imágenes
./scripts/deploy-all.sh
```

## Paso 6: Verificar que los endpoints funcionan en Kubernetes

```bash
# Obtener nombre de un pod
SERVICE_POD=$(kubectl get pods -l app=expense-service -o jsonpath='{.items[0].metadata.name}')

# Probar los endpoints desde dentro del pod
kubectl exec $SERVICE_POD -- wget -q -O- http://localhost:8080/q/health
kubectl exec $SERVICE_POD -- wget -q -O- http://localhost:8080/q/health/live
kubectl exec $SERVICE_POD -- wget -q -O- http://localhost:8080/q/health/ready
```

## Endpoints Disponibles

Una vez agregada la dependencia, Quarkus expone automáticamente:

| Endpoint | Propósito | Usado por |
|----------|-----------|-----------|
| `/q/health` | Health check general | Monitoreo general |
| `/q/health/live` | Liveness check | Liveness Probe |
| `/q/health/ready` | Readiness check | Readiness Probe |

### Respuestas Esperadas

**Estado UP (saludable):**
```json
{
  "status": "UP",
  "checks": []
}
```

**Estado DOWN (no saludable):**
```json
{
  "status": "DOWN",
  "checks": [
    {
      "name": "...",
      "status": "DOWN"
    }
  ]
}
```

## Configuración Avanzada (Opcional)

### Personalizar los endpoints

En `application.properties`:

```properties
# Cambiar el path base (por defecto es /q/health)
quarkus.smallrye-health.root-path=/health

# Deshabilitar endpoints específicos
quarkus.smallrye-health.liveness-enabled=true
quarkus.smallrye-health.readiness-enabled=true
```

### Agregar checks personalizados

Puedes crear checks personalizados implementando interfaces:

```java
@ApplicationScoped
public class CustomHealthCheck implements HealthCheck {
    @Override
    public HealthCheckResponse call() {
        return HealthCheckResponse.up("custom-check");
    }
}
```

## Troubleshooting

### Los endpoints devuelven 404

**Causa:** La dependencia no está agregada o la aplicación no se reconstruyó.

**Solución:**
1. Verificar que la dependencia está en `pom.xml`
2. Reconstruir la aplicación: `mvn clean package`
3. Reconstruir la imagen Docker
4. Redesplegar en Kubernetes

### Los probes fallan en Kubernetes

**Causa:** Los endpoints no están disponibles o la aplicación no está lista.

**Diagnóstico:**
```bash
# Ver logs del pod
kubectl logs <pod-name>

# Probar el endpoint manualmente
kubectl exec <pod-name> -- wget -q -O- http://localhost:8080/q/health/ready

# Ver eventos del pod
kubectl describe pod <pod-name>
```

**Solución:**
- Verificar que la aplicación está corriendo
- Verificar que el puerto es correcto (8080)
- Ajustar `initialDelaySeconds` en los probes si la app tarda en iniciar

## Verificación Final

Después de seguir todos los pasos:

```bash
# 1. Verificar que los pods tienen probes configurados
kubectl describe pod <pod-name> | grep -A 5 "Liveness\|Readiness"

# 2. Verificar que los endpoints responden
./scripts/test-probes.sh

# 3. Verificar que los pods están en estado Ready
kubectl get pods
```

## Resumen

✅ Agregar `quarkus-smallrye-health` a ambos `pom.xml`
✅ Reconstruir las imágenes: `./scripts/build-and-push-all.sh`
✅ Redesplegar: `./scripts/deploy-all.sh`
✅ Verificar: `./scripts/test-probes.sh`

Una vez completado, los probes de Kubernetes podrán usar los endpoints `/q/health/live` y `/q/health/ready`.
