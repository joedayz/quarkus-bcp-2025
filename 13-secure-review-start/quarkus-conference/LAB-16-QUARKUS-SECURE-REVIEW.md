# LAB 16: QUARKUS SECURE REVIEW

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

Abre el proyecto `13-secure-review-start`.

## Instrucciones

Este ejercicio usa la aplicación speaker como backend. El backend se integra con un servidor Keycloak para autenticación y autorización. Adicionalmente, el backend se integra con una aplicación front-end SPA.

### 1. Abre la aplicación expenses

#### 1.1. Navega al directorio 13-secure-review

#### 1.2. Abre el proyecto con tu editor favorito.

### 2. Integra la aplicación speaker con el servidor SSO

Usa la siguiente configuración:
- **SSO Server URL:** http://localhost:8888
- **Keycloak realm:** quarkus
- **Client Id:** backend-service
- **Client secret:** secret

#### 2.1. Agrega la extensión quarkus-oidc al proyecto:

```bash
mvn quarkus:add-extension -Dextensions=oidc
```

#### 2.2. Configura la integración con OIDC

Agrega las siguientes propiedades en `src/main/resources/application.properties`:

```properties
# RHSSO settings
quarkus.oidc.auth-server-url=http://localhost:8888/realms/quarkus
quarkus.oidc.client-id=backend-service
quarkus.oidc.credentials.secret=secret
quarkus.oidc.tls.verification=none
```

#### 2.3. Verifica que el test ConfigTest pasa

Soluciona cualquier problema que encuentres:

```bash
mvn clean test -Dtest=ConfigTest
```

### 3. Configura CORS para la aplicación speaker

La aplicación debería permitir solo requests del origen localhost en el puerto 9000 en dev u 8080 en prod. Denegar requests de otros orígenes.

#### 3.1. Agrega las siguientes propiedades en `src/main/resources/application.properties`

```properties
# CORS settings
quarkus.http.cors=true
quarkus.http.cors.origins=http://localhost:9000,http://localhost:8080
quarkus.http.cors.methods=GET,POST,PUT,DELETE,OPTIONS
quarkus.http.cors.headers=accept,authorization,content-type,x-requested-with
quarkus.http.cors.exposed-headers=Content-Disposition
quarkus.http.cors.access-control-max-age=24H
```

#### 3.2. Verifica que el CorsTest pasa:

```bash
mvn clean test -Dtest=CorsTest
```

### 4. Configurar la autorización de los siguientes endpoints

- **GET /speakers:** necesita el rol de `read`.
- **GET /speakers/{uuid}:** necesita el rol de `read`.
- **POST /speakers:** necesita el rol de `modify`.
- **PUT /speakers/{uuid}:** necesita el rol de `modify`.

#### 4.1. Abre `com.bcp.training.SpeakerResource`

Usa la anotación `@RolesAllowed` para asegurar los endpoints.

#### 4.2. Verifica que el test SpeakerResourceTest pasa:

```bash
mvn clean test -Dtest=SpeakerResourceTest
```

### 5. Opcionalmente, usa el front-end speaker-dashboard para probar la aplicación speaker

#### 5.1. Inicia el servicio speaker:

```bash
mvn quarkus:dev
```

#### 5.2. Valida que Keycloak está corriendo

En un navegador web, por ejemplo Firefox, abre http://localhost:8888 para validar que el Keycloak está corriendo sin problemas. 

Si no está corriendo, en el directorio `speaker` levanta el servicio con:

**Docker:**
```bash
docker compose up -d
```

**Podman:**
```bash
podman compose up -d
```

**Nota importante:** Se ha configurado la aplicación `frontend-service` en el `realm.json`.

#### 5.3. Abre el frontend

Abre http://localhost:9000. Usa el usuario `user` y password `redhat`. Debes ver un dashboard con 4 speakers.

#### 5.4. Prueba crear un speaker (debe fallar)

Click en **Add a speaker**. Ingresa tus nombres y apellidos en first name y last name respectivamente. Luego, haz click en **Confirm**. Se te mostrará un error, porque no estás autorizado a crear speakers. Cierra todas las ventanas para desloguearte.

#### 5.5. Prueba con usuario autorizado

En una nueva ventana, abre http://localhost:9000. Usa el usuario `superuser` y password `redhat`.

#### 5.6. Prueba crear un speaker (debe funcionar)

Click en **Add a speaker**. Ingresa tus nombres y apellidos nuevamente en first name y last name respectivamente. Luego click en **Confirm**. La llamada funcionará satisfactoriamente, porque el usuario superuser sí puede crear speakers. Cierra la ventana del navegador.

#### 5.7. Detén la aplicación

Retorna a la terminal y ejecuta el servicio speaker y presiona la letra `q` para detener la aplicación.

---

## Solución

Este ejercicio usa la aplicación speaker como backend. El backend se integra con un servidor Keycloak para autenticación y autorización. Adicionalmente, el backend se integra con una aplicación front-end SPA.

### 1. Abre la aplicación expenses

#### 1.1. Navega al directorio 13-secure-review

#### 1.2. Abre el proyecto con tu editor favorito.

### 2. Integra la aplicación speaker con el servidor SSO

Usa la siguiente configuración:
- **SSO Server URL:** http://localhost:8888
- **Keycloak realm:** quarkus
- **Client Id:** backend-service
- **Client secret:** secret

#### 2.1. Agrega la extensión quarkus-oidc al proyecto:

```bash
mvn quarkus:add-extension -Dextensions=oidc
```

#### 2.2. Configura la integración con OIDC

Agrega las siguientes propiedades en `src/main/resources/application.properties`:

```properties
# RHSSO settings
quarkus.oidc.auth-server-url=http://localhost:8888/realms/quarkus
quarkus.oidc.client-id=backend-service
quarkus.oidc.credentials.secret=secret
quarkus.oidc.tls.verification=none
```

#### 2.3. Verifica que el test ConfigTest pasa

Soluciona cualquier problema que encuentres:

```bash
mvn clean test -Dtest=ConfigTest
```

### 3. Configura CORS para la aplicación speaker

La aplicación debería permitir solo requests del origen localhost en el puerto 9000 y 8080. Denegar requests de otros orígenes.

#### 3.1. Agrega las siguientes propiedades en `src/main/resources/application.properties`

```properties
# CORS settings
quarkus.http.cors=true
quarkus.http.cors.origins=http://localhost:9000,http://localhost:8080
quarkus.http.cors.methods=GET,POST,PUT,DELETE,OPTIONS
quarkus.http.cors.headers=accept,authorization,content-type,x-requested-with
quarkus.http.cors.exposed-headers=Content-Disposition
quarkus.http.cors.access-control-max-age=24H
```

#### 3.2. Verifica que el CorsTest pasa:

```bash
mvn clean test -Dtest=CorsTest
```

### 4. Configurar la autorización de los siguientes endpoints

- **GET /speakers:** necesita el rol de `read`.
- **GET /speakers/{uuid}:** necesita el rol de `read`.
- **POST /speakers:** necesita el rol de `modify`.
- **PUT /speakers/{uuid}:** necesita el rol de `modify`.

#### 4.1. Abre `com.bcp.training.SpeakerResource`

Usa la anotación `@RolesAllowed` para asegurar los endpoints.

#### 4.2. Verifica que el test SpeakerResourceTest pasa:

```bash
mvn clean test -Dtest=SpeakerResourceTest
```

### 5. Opcionalmente, usa el front-end speaker-dashboard para probar la aplicación speaker

#### 5.1. Inicia el speaker service:

```bash
mvn quarkus:dev
```

#### 5.2. Valida que Keycloak está ejecutándose

En un navegador web, por ejemplo Firefox, abre http://localhost:8888 y valida que el Keycloak está ejecutándose. Esto es necesario para que la aplicación front-end haga redirect a los usuarios a la página de login de Keycloak.

#### 5.3. Inicia la aplicación frontend

**Windows:**
```cmd
npm install
npm run dev
```

**Linux/Mac:**
```bash
npm install
npm run dev
```

Esto levantará la aplicación en el puerto 9000 y abre http://localhost:9000. Usa el usuario `user` y password `redhat`. Verás el dashboard con 4 speakers.

#### 5.4. Prueba crear un speaker (debe fallar)

Click en **Add un speaker**. Ingresa tus nombres y apellidos en first name y last name, luego click en **Confirm**. Se te mostrará un error, porque el usuario `user` no está autorizado a crear speakers. Cierra todos los navegadores para desloguearte.

#### 5.5. Prueba con usuario autorizado

En una nueva ventana abre http://localhost:9000. Usa el usuario `superuser` y password `redhat`.

#### 5.6. Prueba crear un speaker (debe funcionar)

Click en **Add a speaker**. Ingresa tus nombres y apellidos en firstname y lastname respectivamente. Luego haz click en **Confirm**. La llamada funcionará exitosamente, porque el usuario superuser sí tiene permiso para crear speakers. Cierra la ventana del navegador.

#### 5.7. Detén la aplicación

Retorna a la terminal y ejecuta el servicio speaker y luego presiona la letra `q` para terminar la aplicación.

---

Si lograste llegar aquí. **¡Felicitaciones!** Has terminado tu security review.

**José**
