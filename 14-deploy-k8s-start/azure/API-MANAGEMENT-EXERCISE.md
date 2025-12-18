# Ejercicio: Azure API Management (APIM)

## ¿Qué es Azure API Management?

**Azure API Management (APIM)** es un servicio gestionado de Azure que actúa como API Gateway para tus microservicios. Proporciona un punto de entrada único, seguro y escalable para tus APIs.

### Arquitectura sin APIM:
```
Cliente 1 ──┐
Cliente 2 ──┼──> expense-service:8080 (IP directa)
Cliente 3 ──┘

Cliente 1 ──┐
Cliente 2 ──┼──> expense-client:8080 (IP directa)
Cliente 3 ──┘
```

**Problemas:**
- Los clientes necesitan conocer múltiples endpoints
- No hay control centralizado de acceso
- Difícil implementar autenticación, rate limiting, logging
- Exponer múltiples servicios directamente

### Arquitectura con Azure APIM:
```
Cliente 1 ──┐
Cliente 2 ──┼──> Azure APIM ──┬──> expense-service (interno en AKS)
Cliente 3 ──┘                 └──> expense-client (interno en AKS)
```

**Beneficios:**
- ✅ Punto de entrada único y seguro
- ✅ Control centralizado (autenticación, autorización, rate limiting)
- ✅ Enrutamiento inteligente
- ✅ Logging y monitoreo centralizado
- ✅ Transformación de requests/responses
- ✅ Versionado de APIs
- ✅ Developer Portal
- ✅ Analytics y métricas avanzadas
- ✅ Integración con Azure AD

## Componentes de Azure APIM

1. **API Gateway**: Punto de entrada para todas las requests
2. **Developer Portal**: Portal para desarrolladores que consumen las APIs
3. **Management API**: API para gestionar APIM programáticamente
4. **Analytics**: Métricas y logs de uso

## Ejercicio Paso a Paso

### Paso 1: Crear Azure API Management

```bash
# Cargar configuración si existe
source azure-config.env  # Linux/macOS
# o
. azure-config.ps1       # Windows PowerShell

# Crear Azure APIM (nivel Developer para desarrollo/testing)
az apim create \
  --resource-group $RESOURCE_GROUP \
  --name expense-apim \
  --publisher-email admin@example.com \
  --publisher-name "BCP Training" \
  --sku-name Developer \
  --location $LOCATION
```

**Nota sobre SKUs:**
- **Developer**: Para desarrollo/testing (~$50/mes)
- **Basic**: Para producción pequeña (~$200/mes)
- **Standard**: Para producción media (~$300/mes)
- **Premium**: Para producción grande (~$500+/mes)

**Tiempo estimado:** 30-45 minutos para crear el servicio APIM.

### Paso 2: Obtener la URL del APIM

```bash
# Obtener la URL del gateway
az apim show \
  --resource-group $RESOURCE_GROUP \
  --name expense-apim \
  --query "gatewayUrl" -o tsv

# Ejemplo de URL: https://expense-apim.azure-api.net
```

### Paso 3: Configurar Backend que apunta a AKS

Azure APIM necesita saber dónde están tus servicios. Hay dos opciones:

#### Opción A: Backend apuntando al LoadBalancer de AKS

Si tus servicios tienen LoadBalancer:

```bash
# Obtener IP del servicio expense-client
CLIENT_IP=$(kubectl get svc expense-client -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Crear backend en APIM
az apim backend create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --backend-id expense-client-backend \
  --url "http://${CLIENT_IP}:8080" \
  --protocol http
```

#### Opción B: Backend apuntando a través de Private Endpoint (Recomendado para producción)

Para producción, es mejor usar Private Endpoint o conectarse directamente a los pods a través de un servicio interno.

### Paso 4: Crear APIs en APIM

#### Crear API para expense-service

```bash
az apim api create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --api-id expense-service-api \
  --path "expenses" \
  --display-name "Expense Service API" \
  --service-url "http://<SERVICE_IP>:8080"
```

#### Crear API para expense-client

```bash
az apim api create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --api-id expense-client-api \
  --path "client" \
  --display-name "Expense Client API" \
  --service-url "http://<CLIENT_IP>:8080"
```

### Paso 5: Agregar Operaciones (Endpoints)

#### Agregar operaciones a expense-service API

```bash
# GET /expenses
az apim api operation create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --api-id expense-service-api \
  --operation-id get-expenses \
  --method GET \
  --url-template "/expenses"

# POST /expenses
az apim api operation create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --api-id expense-service-api \
  --operation-id create-expense \
  --method POST \
  --url-template "/expenses"
```

#### Agregar operaciones a expense-client API

```bash
# GET /expenses
az apim api operation create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --api-id expense-client-api \
  --operation-id get-expenses \
  --method GET \
  --url-template "/expenses"

# POST /expenses
az apim api operation create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --api-id expense-client-api \
  --operation-id create-expense \
  --method POST \
  --url-template "/expenses"
```

### Paso 6: Publicar las APIs

```bash
# Crear un producto (agrupa APIs)
az apim product create \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --product-id expenses-product \
  --product-name "Expenses Product" \
  --description "APIs para gestión de gastos"

# Agregar APIs al producto
az apim product api add \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --product-id expenses-product \
  --api-id expense-service-api

az apim product api add \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --product-id expenses-product \
  --api-id expense-client-api
```

### Paso 7: Probar las APIs a través de APIM

```bash
# Obtener la URL del gateway
GATEWAY_URL=$(az apim show --resource-group $RESOURCE_GROUP --name expense-apim --query "gatewayUrl" -o tsv)

# Probar expense-service a través de APIM
curl "${GATEWAY_URL}/expenses/expenses"

# Probar expense-client a través de APIM
curl "${GATEWAY_URL}/client/expenses"
```

## Configuraciones Avanzadas

### Autenticación con Subscription Key

Por defecto, APIM requiere una subscription key:

```bash
# Obtener subscription key
az apim subscription list \
  --resource-group $RESOURCE_GROUP \
  --service-name expense-apim \
  --query "[0].primaryKey" -o tsv

# Usar en las requests
curl -H "Ocp-Apim-Subscription-Key: <SUBSCRIPTION_KEY>" \
  "${GATEWAY_URL}/expenses/expenses"
```

### Rate Limiting

Configurar rate limiting en políticas:

```xml
<rate-limit calls="100" renewal-period="60" />
```

### CORS

Habilitar CORS en las políticas de APIM.

### Transformación de Requests/Responses

Usar políticas para transformar datos antes de enviarlos al backend.

## Arquitectura Recomendada

### Para Desarrollo/Testing:

```
Cliente → APIM (Developer SKU) → LoadBalancer → AKS Services
```

### Para Producción:

```
Cliente → APIM (Standard/Premium) → Private Endpoint → AKS Services (ClusterIP)
```

## Costos

⚠️ **Importante**: Azure APIM tiene costos asociados:

- **Developer**: ~$50/mes (solo para desarrollo)
- **Basic**: ~$200/mes
- **Standard**: ~$300/mes
- **Premium**: ~$500+/mes

**Recomendación:** Usa Developer SKU para desarrollo/testing y elimínalo cuando no lo uses.

## Troubleshooting

### El APIM no puede conectarse al backend

**Causa:** El backend no es accesible desde APIM.

**Solución:**
- Verificar que el servicio tiene LoadBalancer o está expuesto públicamente
- Verificar conectividad de red
- Considerar usar Private Endpoint para producción

### Error 401 Unauthorized

**Causa:** Falta subscription key o es inválida.

**Solución:**
```bash
# Obtener subscription key correcta
az apim subscription list --resource-group $RESOURCE_GROUP --service-name expense-apim
```

### Las APIs no aparecen en el Developer Portal

**Causa:** El producto no está publicado o las APIs no están asociadas.

**Solución:**
- Verificar que el producto está publicado
- Verificar que las APIs están agregadas al producto

## Limpieza

Para eliminar Azure APIM (y evitar costos):

```bash
az apim delete \
  --resource-group $RESOURCE_GROUP \
  --name expense-apim \
  --yes
```

O eliminar todo el Resource Group:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## Recursos Adicionales

- [Documentación oficial de Azure APIM](https://docs.microsoft.com/azure/api-management/)
- [Azure APIM Policies](https://docs.microsoft.com/azure/api-management/api-management-policies)
- [Azure APIM REST API](https://docs.microsoft.com/rest/api/apimanagement/)

## Resumen

✅ **Azure APIM** proporciona un API Gateway gestionado y completo
✅ **Punto de entrada único** para todos los microservicios
✅ **Funcionalidades avanzadas**: autenticación, rate limiting, analytics
✅ **Developer Portal** para documentar y probar APIs
✅ **Integración** con otros servicios de Azure
✅ **Ideal para producción** empresarial

Los scripts automatizados facilitan la configuración inicial, pero APIM ofrece muchas más opciones de configuración a través del portal de Azure.
