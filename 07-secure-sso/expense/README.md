# expense

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: <https://quarkus.io/>.

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:

```shell script
./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at <http://localhost:8080/q/dev/>.

## Packaging and running the application

The application can be packaged using:

```shell script
./mvnw package
```

It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it's not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:

```shell script
./mvnw package -Dquarkus.package.jar.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using:

```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using:

```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/expense-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult <https://quarkus.io/guides/maven-tooling>.

## Authentication and Authorization Testing

This application uses OIDC (OpenID Connect) for authentication and role-based authorization. Below are examples of how to test different user roles and permissions.

### Prerequisites

1. **Red Hat SSO Server**: Make sure the SSO server is running at `http://localhost:8888`
2. **Application**: Start the Quarkus application with `./mvnw quarkus:dev`
3. **Users**: Ensure the following users exist in the `quarkus` realm:
   - `user` (password: `redhat`) - has `read` role
   - `superuser` (password: `redhat`) - has `read`, `modify`, `delete` roles

### Testing User with Read Role

#### 1. Get Token for User
```powershell
# PowerShell (Windows)
.\get_token.ps1 user redhat
```

```bash
# Bash (Linux/macOS/WSL)
source get_token.sh user redhat
```

#### 2. Verify User Roles
```powershell
# PowerShell
Invoke-RestMethod -Uri "http://localhost:8080/oidc" -Headers @{"Authorization"="Bearer $env:TOKEN"} | ConvertTo-Json
```

```bash
# Bash
curl -s http://localhost:8080/oidc -H "Authorization: Bearer $TOKEN" | jq
```

**Expected Response:**
```json
{
    "roles": [
        "read",
        "offline_access",
        "default-roles-quarkus",
        "uma_authorization"
    ]
}
```

#### 3. Read Expenses (Allowed)
```powershell
# PowerShell
Invoke-RestMethod -Uri "http://localhost:8080/expense" -Headers @{"Authorization"="Bearer $env:TOKEN"} | ConvertTo-Json
```

```bash
# Bash
curl -s http://localhost:8080/expense -H "Authorization: Bearer $TOKEN" | jq
```

#### 4. Try to Delete Expense (Forbidden - 403 Error)
```powershell
# PowerShell
$UUID = "3f1817f2-3dcf-472f-a8b2-77bfe25e79d1"
Invoke-RestMethod -Uri "http://localhost:8080/expense/$UUID" -Method DELETE -Headers @{"Authorization"="Bearer $env:TOKEN"}
```

```bash
# Bash
UUID=3f1817f2-3dcf-472f-a8b2-77bfe25e79d1
curl -X DELETE -H "Authorization: Bearer $TOKEN" http://localhost:8080/expense/$UUID
```

**Expected Result:** 403 Forbidden error

### Testing Superuser with Full Permissions

#### 1. Get Token for Superuser
```powershell
# PowerShell
.\get_token.ps1 superuser redhat
```

```bash
# Bash
source get_token.sh superuser redhat
```

#### 2. Verify Superuser Roles
```powershell
# PowerShell
Invoke-RestMethod -Uri "http://localhost:8080/oidc" -Headers @{"Authorization"="Bearer $env:TOKEN"} | ConvertTo-Json
```

```bash
# Bash
curl -s http://localhost:8080/oidc -H "Authorization: Bearer $TOKEN" | jq
```

**Expected Response:**
```json
{
    "roles": [
        "modify",
        "read",
        "offline_access",
        "default-roles-quarkus",
        "uma_authorization",
        "delete"
    ]
}
```

#### 3. Read Expenses (Allowed)
```powershell
# PowerShell
Invoke-RestMethod -Uri "http://localhost:8080/expense" -Headers @{"Authorization"="Bearer $env:TOKEN"} | ConvertTo-Json
```

```bash
# Bash
curl -s http://localhost:8080/expense -H "Authorization: Bearer $TOKEN" | jq
```

#### 4. Delete Expense (Allowed)
```powershell
# PowerShell
$UUID = "3f1817f2-3dcf-472f-a8b2-77bfe25e79d1"
Invoke-RestMethod -Uri "http://localhost:8080/expense/$UUID" -Method DELETE -Headers @{"Authorization"="Bearer $env:TOKEN"} | ConvertTo-Json
```

```bash
# Bash
UUID=3f1817f2-3dcf-472f-a8b2-77bfe25e79d1
curl -X DELETE -H "Authorization: Bearer $TOKEN" http://localhost:8080/expense/$UUID | jq
```

**Expected Result:** Success - returns updated list of expenses

### Key Learning Points

1. **Authentication**: Both users can authenticate and get valid tokens
2. **Authorization**: Different roles provide different levels of access
3. **Role-based Access Control (RBAC)**:
   - `read` role: Can only read data
   - `delete` role: Can delete data
   - `modify` role: Can modify data
4. **Security**: The application enforces role-based permissions at the API level

### Troubleshooting

- **401 Unauthorized**: Check if the SSO server is running and credentials are correct
- **403 Forbidden**: User doesn't have the required role for the operation
- **Token Expired**: Get a new token using the get_token script

## Related Guides

- REST ([guide](https://quarkus.io/guides/rest)): A Jakarta REST implementation utilizing build time processing and Vert.x. This extension is not compatible with the quarkus-resteasy extension, or any of the extensions that depend on it.

## Provided Code

### REST

Easily start your REST Web Services

[Related guide section...](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)
