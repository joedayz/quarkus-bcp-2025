# LAB 15 - QUARKUS SECURE SSO

## Introducción

Este laboratorio te guiará a través de la implementación de Single Sign-On (SSO) seguro en Quarkus utilizando OpenID Connect (OIDC) y Keycloak como proveedor de identidad.

## Objetivos

Al finalizar este laboratorio, serás capaz de:

- Configurar Keycloak como proveedor de identidad OIDC
- Integrar autenticación OIDC en una aplicación Quarkus
- Implementar autorización basada en roles
- Probar la autenticación y autorización en endpoints REST

## Prerrequisitos

- Java 21 o superior
- Maven 3.8+
- Docker o Podman instalado
- Conocimientos básicos de Quarkus y REST APIs

## Arquitectura

La aplicación utiliza:
- **Keycloak**: Servidor de identidad y acceso (OIDC Provider)
- **Quarkus OIDC**: Extensión para integración con OIDC
- **Roles**: `read`, `modify`, `delete` para control de acceso granular

## Paso 1: Configurar Keycloak

### Opción A: Usando Docker

**Windows:**
```powershell
docker-compose up -d
```

**Linux/Mac:**
```bash
docker-compose up -d
```

### Opción B: Usando Podman

**Windows (WSL2/Linux):**
```bash
podman-compose up -d
```

**Linux/Mac:**
```bash
podman-compose up -d
```

O si prefieres usar Podman directamente:

**Linux/Mac:**
```bash
podman run -d \
  --name keycloak \
  -p 8888:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -v $(pwd)/realm.json:/opt/keycloak/data/import/realm.json:Z \
  quay.io/keycloak/keycloak:24.0 \
  start-dev --import-realm
```

**Windows (PowerShell):**
```powershell
podman run -d `
  --name keycloak `
  -p 8888:8080 `
  -e KEYCLOAK_ADMIN=admin `
  -e KEYCLOAK_ADMIN_PASSWORD=admin `
  -v ${PWD}/realm.json:/opt/keycloak/data/import/realm.json:Z `
  quay.io/keycloak/keycloak:24.0 `
  start-dev --import-realm
```

### Verificar que Keycloak está ejecutándose

**Windows:**
```powershell
docker ps
# O con Podman:
podman ps
```

**Linux/Mac:**
```bash
docker ps
# O con Podman:
podman ps
```

Deberías ver un contenedor llamado `keycloak` ejecutándose en el puerto 8888.

Accede a la consola de administración de Keycloak en: http://localhost:8888

- Usuario: `admin`
- Contraseña: `admin`

## Paso 2: Configurar la Aplicación Quarkus

### 2.1 Agregar Dependencias OIDC

Asegúrate de que tu `pom.xml` incluya las siguientes dependencias:

```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-oidc</artifactId>
</dependency>
```

### 2.2 Configurar application.properties

Edita `src/main/resources/application.properties` y configura las siguientes propiedades:

```properties
# RHSSO settings
quarkus.oidc.auth-server-url=http://localhost:8888/realms/quarkus
quarkus.oidc.client-id=backend-service
quarkus.oidc.credentials.secret=secret
quarkus.oidc.tls.verification=none

# Auth settings
quarkus.security.jaxrs.deny-unannotated-endpoints=true
```

### 2.3 Verificar la Configuración del Realm

El archivo `realm.json` ya está configurado con:

- **Realm**: `quarkus`
- **Usuarios**:
  - `user` / `redhat` (rol: `read`)
  - `superuser` / `redhat` (roles: `read`, `modify`, `delete`)
- **Cliente**: `backend-service` con secret `secret`

## Paso 3: Obtener un Token de Acceso

### Obtener Token en Windows

```powershell
.\get_token.ps1 user redhat

.\get_token.ps1 superuser redhat

echo $env:TOKEN
```

### Obtener Token en Mac o Linux

```bash
export TOKEN=$(./get_token.sh superuser redhat)

echo $TOKEN
```

## Paso 4: Probar los Endpoints

### 4.1 Probar el Endpoint OIDC

Este endpoint muestra los roles del usuario autenticado:

**Linux/Mac:**
```bash
curl -s http://localhost:8080/oidc -H "Authorization: Bearer $TOKEN" | jq
```

**Windows:**
```powershell
Invoke-RestMethod -Uri http://localhost:8080/oidc -Headers @{ Authorization = "Bearer $env:TOKEN" }
```

### 4.2 Listar Gastos (GET)

Requiere el rol `read`:

**Linux/Mac:**
```bash
curl -s http://localhost:8080/expense -H "Authorization: Bearer $TOKEN" | jq
```

**Windows:**
```powershell
Invoke-RestMethod -Uri http://localhost:8080/expense -Headers @{ Authorization = "Bearer $env:TOKEN" }
```

### 4.3 Crear un Gasto (POST)

Requiere el rol `modify`:

**Linux/Mac:**
```bash
curl -X POST http://localhost:8080/expense \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
"name": "Concurrency modern in Java",
"paymentMethod": "CREDIT_CARD",
"amount": 65.00
}'
```

**Windows:**
```powershell
$token = (./get_token.ps1 user redhat)

$headers = @{
"Content-Type" = "application/json"
"Authorization" = "Bearer $token"
}

$body = @{
name = "Almuerzo"
paymentMethod = "CREDIT_CARD"
amount = 45.75
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/expense" `
    -Method Post `
-Headers $headers `
-Body $body
```

### 4.4 Eliminar un Gasto (DELETE)

Requiere el rol `delete`:

**Linux/Mac:**
```bash
UUID=3f1817f2-3dcf-472f-a8b2-77bfe25e79d1
curl -vX DELETE -H "Authorization: Bearer $TOKEN" http://localhost:8080/expense/$UUID
```

**Windows:**
```powershell
$UUID = "3f1817f2-3dcf-472f-a8b2-77bfe25e79d1"
Invoke-RestMethod -Uri "http://localhost:8080/expense/$uuid" -Method Delete -Headers @{ Authorization = "Bearer $env:TOKEN" }
```

## Paso 5: Probar Autorización por Roles

### 5.1 Probar con Usuario 'user' (solo lectura)

**Linux/Mac:**
```bash
# Obtener token para 'user'
export TOKEN=$(./get_token.sh user redhat)

# Intentar listar (debe funcionar)
curl -s http://localhost:8080/expense -H "Authorization: Bearer $TOKEN" | jq

# Intentar crear (debe fallar con 403 Forbidden)
curl -X POST http://localhost:8080/expense \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{"name": "Test", "paymentMethod": "CREDIT_CARD", "amount": 10.00}'
```

**Windows:**
```powershell
# Obtener token para 'user'
.\get_token.ps1 user redhat

# Intentar listar (debe funcionar)
Invoke-RestMethod -Uri http://localhost:8080/expense -Headers @{ Authorization = "Bearer $env:TOKEN" }

# Intentar crear (debe fallar con 403 Forbidden)
$token = (./get_token.ps1 user redhat)
$headers = @{
"Content-Type" = "application/json"
"Authorization" = "Bearer $token"
}
$body = @{
name = "Test"
paymentMethod = "CREDIT_CARD"
amount = 10.00
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/expense" `
    -Method Post `
-Headers $headers `
-Body $body
```

### 5.2 Probar con Usuario 'superuser' (todos los permisos)

**Linux/Mac:**
```bash
# Obtener token para 'superuser'
export TOKEN=$(./get_token.sh superuser redhat)

# Todas las operaciones deben funcionar
curl -s http://localhost:8080/expense -H "Authorization: Bearer $TOKEN" | jq

curl -X POST http://localhost:8080/expense \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{"name": "Test", "paymentMethod": "CREDIT_CARD", "amount": 10.00}'
```

**Windows:**
```powershell
# Obtener token para 'superuser'
.\get_token.ps1 superuser redhat

# Todas las operaciones deben funcionar
Invoke-RestMethod -Uri http://localhost:8080/expense -Headers @{ Authorization = "Bearer $env:TOKEN" }
```

## Paso 6: Ejecutar la Aplicación

### Modo Desarrollo

**Windows:**
```powershell
.\mvnw.cmd quarkus:dev
```

**Linux/Mac:**
```bash
./mvnw quarkus:dev
```

### Modo Producción

**Windows:**
```powershell
.\mvnw.cmd clean package
.\mvnw.cmd quarkus:dev -Dquarkus.profile=prod
```

**Linux/Mac:**
```bash
./mvnw clean package
./mvnw quarkus:dev -Dquarkus.profile=prod
```

## Estructura de Roles

La aplicación define los siguientes roles en el realm de Keycloak:

- **read**: Permite leer/listar gastos
- **modify**: Permite crear y actualizar gastos
- **delete**: Permite eliminar gastos

### Mapeo de Usuarios a Roles

| Usuario | Contraseña | Roles |
|---------|------------|-------|
| `user` | `redhat` | `read` |
| `superuser` | `redhat` | `read`, `modify`, `delete` |

## Endpoints Disponibles

| Método | Endpoint | Rol Requerido | Descripción |
|--------|----------|---------------|-------------|
| GET | `/oidc` | Ninguno (`@PermitAll`) | Obtiene información del usuario autenticado |
| GET | `/expense` | `read` | Lista todos los gastos |
| POST | `/expense` | `modify` | Crea un nuevo gasto |
| PUT | `/expense` | `modify` | Actualiza un gasto existente |
| DELETE | `/expense/{uuid}` | `delete` | Elimina un gasto |

## Solución de Problemas

### Keycloak no inicia

**Verificar logs con Docker:**
```bash
docker logs keycloak
```

**Verificar logs con Podman:**
```bash
podman logs keycloak
```

### Error de conexión a Keycloak

1. Verifica que Keycloak esté ejecutándose:
   ```bash
   # Docker
   docker ps | grep keycloak
   
   # Podman
   podman ps | grep keycloak
   ```

2. Verifica que el puerto 8888 esté disponible:
   ```bash
   # Linux/Mac
   curl http://localhost:8888/realms/quarkus/.well-known/openid-configuration
   
   # Windows
   Invoke-RestMethod -Uri http://localhost:8888/realms/quarkus/.well-known/openid-configuration
   ```

### Error 401 Unauthorized

- Verifica que el token sea válido y no haya expirado
- Obtén un nuevo token usando los scripts proporcionados
- Verifica que las credenciales del cliente (`backend-service` / `secret`) sean correctas

### Error 403 Forbidden

- Verifica que el usuario tenga el rol necesario para la operación
- Usa el usuario `superuser` para tener todos los permisos

### Token no se exporta correctamente

**Linux/Mac:**
```bash
export TOKEN=$(./get_token.sh superuser redhat)
echo $TOKEN
```

**Windows:**
```powershell
.\get_token.ps1 superuser redhat
echo $env:TOKEN
```

## Comandos Útiles

### Detener Keycloak

**Docker:**
```bash
docker-compose down
```

**Podman:**
```bash
podman-compose down
# O directamente:
podman stop keycloak
podman rm keycloak
```

### Reiniciar Keycloak

**Docker:**
```bash
docker-compose restart
```

**Podman:**
```bash
podman restart keycloak
```

### Ver logs de Keycloak en tiempo real

**Docker:**
```bash
docker logs -f keycloak
```

**Podman:**
```bash
podman logs -f keycloak
```

## Ejemplos Rápidos

### Comandos Básicos Funcionales

#### Obtener Token y Probar Endpoints (Linux/Mac)

```bash
# Obtener token
export TOKEN=$(./get_token.sh superuser redhat)
echo $TOKEN

# Probar endpoint OIDC
curl -s http://localhost:8080/oidc -H "Authorization: Bearer $TOKEN" | jq

# Listar gastos
curl -s http://localhost:8080/expense -H "Authorization: Bearer $TOKEN" | jq

# Eliminar un gasto
UUID=3f1817f2-3dcf-472f-a8b2-77bfe25e79d1
curl -vX DELETE -H "Authorization: Bearer $TOKEN" http://localhost:8080/expense/$UUID
```

#### Obtener Token y Probar Endpoints (Windows)

```powershell
# Obtener token
.\get_token.ps1 superuser redhat
echo $env:TOKEN

# Probar endpoint OIDC
Invoke-RestMethod -Uri http://localhost:8080/oidc -Headers @{ Authorization = "Bearer $env:TOKEN" }

# Listar gastos
Invoke-RestMethod -Uri http://localhost:8080/expense -Headers @{ Authorization = "Bearer $env:TOKEN" }

# Eliminar un gasto
$UUID = "3f1817f2-3dcf-472f-a8b2-77bfe25e79d1"
Invoke-RestMethod -Uri "http://localhost:8080/expense/$uuid" -Method Delete -Headers @{ Authorization = "Bearer $env:TOKEN" }
```

#### Crear Gastos (Linux/Mac)

```bash
curl -X POST http://localhost:8080/expense \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d '{
"name": "Concurrency modern in Java",
"paymentMethod": "CREDIT_CARD",
"amount": 65.00
}'
```

#### Crear Gastos (Windows)

```powershell
$token = (./get_token.ps1 user redhat)

$headers = @{
"Content-Type" = "application/json"
"Authorization" = "Bearer $token"
}

$body = @{
name = "Almuerzo"
paymentMethod = "CREDIT_CARD"
amount = 45.75
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/expense" `
    -Method Post `
-Headers $headers `
-Body $body
```

## Resumen

En este laboratorio has aprendido a:

1. ✅ Configurar Keycloak como proveedor de identidad OIDC
2. ✅ Integrar autenticación OIDC en Quarkus
3. ✅ Implementar autorización basada en roles
4. ✅ Probar endpoints protegidos con diferentes usuarios y roles
5. ✅ Usar scripts multiplataforma para obtener tokens de acceso

## Próximos Pasos

- Explora la configuración avanzada de Keycloak
- Implementa refresh tokens para renovación automática
- Configura CORS para aplicaciones frontend
- Implementa logout y revocación de tokens

## Referencias

- [Quarkus Security Guide](https://quarkus.io/guides/security)
- [Quarkus OIDC Guide](https://quarkus.io/guides/security-openid-connect)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
