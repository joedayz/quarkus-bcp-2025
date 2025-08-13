# Token Retrieval Scripts

This directory contains scripts to retrieve bearer tokens from the OIDC (OpenID Connect) server for authentication with the expense application.

## Prerequisites

1. **Red Hat SSO Server**: Make sure the SSO server is running at `http://localhost:8888`
2. **User Account**: You need a valid user account in the `quarkus` realm
3. **Network Access**: The scripts need to be able to reach the SSO server

## Available Scripts

### 1. Bash Script (Linux/macOS/WSL)

**File**: `get_token.sh`

**Usage**:
```bash
source get_token.sh <username> <password>
```

**Example**:
```bash
source get_token.sh user redhat
```

### 2. PowerShell Script (Windows)

**File**: `get_token.ps1`

**Usage**:
```powershell
. .\get_token.ps1 <username> <password>
```

**Example**:
```powershell
. .\get_token.ps1 user redhat
```

## How It Works

Both scripts:

1. **Connect to OIDC Server**: Send a request to the token endpoint at `http://localhost:8888/realms/quarkus/protocol/openid-connect/token`
2. **Authenticate**: Use the password grant flow with the provided credentials
3. **Extract Token**: Parse the response to extract the access token
4. **Export Variable**: Set the `TOKEN` environment variable with the bearer token

## Configuration

The scripts use the following configuration (matching `application.properties`):

- **OIDC Server URL**: `http://localhost:8888`
- **Realm**: `quarkus`
- **Client ID**: `backend-service`
- **Client Secret**: `dk9dYtW7usj1Nma1lo6jXmcN7we6qmeH`

## Using the Token

After running the script successfully, you can use the `TOKEN` environment variable in subsequent requests:

### Bash/Linux
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/expenses
```

### PowerShell/Windows
```powershell
Invoke-RestMethod -Uri "http://localhost:8080/expenses" -Headers @{"Authorization"="Bearer $env:TOKEN"}
```

## Troubleshooting

### Common Issues

1. **Connection Failed**: Make sure the SSO server is running at `http://localhost:8888`
2. **Invalid Credentials**: Verify the username and password are correct
3. **Certificate Issues**: The scripts use `--insecure` (bash) or `-SkipCertificateCheck` (PowerShell) to bypass SSL verification

### Error Messages

- **"Failed to connect to OIDC server"**: Check if the SSO server is running
- **"Failed to retrieve token"**: Check credentials and server configuration
- **"No access token found"**: The server response didn't contain a valid token

## Security Notes

- The scripts store the token in environment variables
- Tokens have expiration times and need to be refreshed
- Never commit tokens to version control
- Use HTTPS in production environments

## Example Workflow

### Bash (Linux/macOS/WSL)
```bash
# 1. Get the token
source get_token.sh user redhat
Token successfully retrieved.

# 2. Verify the TOKEN variable
echo $TOKEN
eyJh....gDlXrGA

# 3. Use the token to access protected endpoints
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/expenses
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/oidc
```

### PowerShell (Windows)
```powershell
# 1. Get the token
. .\get_token.ps1 user redhat
Token successfully retrieved.

# 2. Verify the TOKEN variable
echo $env:TOKEN
eyJh....gDlXrGA

# 3. Use the token to access protected endpoints
Invoke-RestMethod -Uri "http://localhost:8080/expenses" -Headers @{"Authorization"="Bearer $env:TOKEN"}
Invoke-RestMethod -Uri "http://localhost:8080/oidc" -Headers @{"Authorization"="Bearer $env:TOKEN"}
```
