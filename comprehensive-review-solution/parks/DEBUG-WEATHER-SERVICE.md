# Debug: Weather Service Connection Issues

## Problema

Aparece el warning:
```
Weather service is not reachable. Assuming no weather warnings are active for park X (Park Name).
```

A pesar de que el servicio weather está corriendo y responde correctamente con `curl`.

## Diagnóstico

### 1. Verificar que el servicio weather está corriendo

```bash
curl http://localhost:8090/warnings
```

Debería devolver un JSON con las alertas meteorológicas.

### 2. Verificar la configuración del cliente REST

En `application.properties`:
```properties
quarkus.rest-client.weather-api.url=http://localhost:8090
```

### 3. Verificar los logs del servicio parks

Con el logging adicional agregado, deberías ver:
- `Checking weather for park X (Park Name) in city: CityName`
- `Received N weather warnings for CityName`
- O un error específico si hay problemas

### 4. Posibles causas

#### A. Timeout muy corto
El `@Timeout` por defecto es 1 segundo. Se aumentó a 5 segundos, pero si el servicio tarda más, activará el fallback.

**Solución:** Aumentar el timeout o verificar por qué el servicio tarda tanto.

#### B. Problema con Fault Tolerance y Uni reactivo
`@Timeout` de MicroProfile Fault Tolerance puede tener problemas con operaciones reactivas (`Uni`). El timeout podría estar cortando la operación antes de que se complete.

**Solución:** Considerar usar timeout directamente en el `Uni` en lugar de `@Timeout`.

#### C. Problema de serialización/deserialización
Si hay un error al deserializar la respuesta JSON, podría activar el fallback.

**Solución:** Verificar que los modelos `WeatherWarning`, `WeatherWarningType`, y `WeatherWarningLevel` coincidan exactamente con la respuesta del servicio weather.

#### D. Problema con el cliente REST reactivo
El cliente REST reactivo podría necesitar configuración adicional.

**Solución:** Verificar que `quarkus-rest-client` esté correctamente configurado y que el endpoint del servicio weather devuelva `application/json`.

## Pasos para diagnosticar

1. **Reiniciar el servicio parks** con el logging adicional
2. **Llamar al endpoint** `/parks/{id}/weathercheck`
3. **Revisar los logs** para ver:
   - Si se llama al método `checkWeatherForPark`
   - Si se reciben las advertencias
   - Qué error específico ocurre (si hay alguno)

## Logs esperados (si funciona correctamente)

```
INFO [com.redhat.smartcity.ParkGuard] Checking weather for park 1 (Vondelpark) in city: Amsterdam
INFO [com.redhat.smartcity.ParkGuard] Received 2 weather warnings for Amsterdam
```

## Logs esperados (si hay error)

```
ERROR [com.redhat.smartcity.ParkGuard] Error calling weather service for park 1 (Vondelpark): [mensaje de error específico]
```

O si se activa el fallback:
```
WARN [com.redhat.smartcity.ParkGuard] Weather service is not reachable. Assuming no weather warnings are active for park 1 (Vondelpark).
```

