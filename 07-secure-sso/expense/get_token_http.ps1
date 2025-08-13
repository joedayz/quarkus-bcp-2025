# get_token_http.ps1 - Test version using HTTP instead of HTTPS
# Usage: . .\get_token_http.ps1 <username> <password>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

# OIDC server configuration (testing with HTTP)
$OIDC_SERVER_URL = "http://localhost:8888"
$REALM = "quarkus"
$CLIENT_ID = "backend-service"
$CLIENT_SECRET = "secret"

Write-Host "Authenticating with OIDC server..." -ForegroundColor Green
Write-Host "Server: $OIDC_SERVER_URL" -ForegroundColor Yellow
Write-Host "Realm: $REALM" -ForegroundColor Yellow
Write-Host "Client: $CLIENT_ID" -ForegroundColor Yellow
Write-Host "Username: $Username" -ForegroundColor Yellow

# Get the token endpoint URL
$TOKEN_URL = "$OIDC_SERVER_URL/realms/$REALM/protocol/openid-connect/token"

# Prepare the request body
$body = @{
    grant_type = "password"
    client_id = $CLIENT_ID
    client_secret = $CLIENT_SECRET
    username = $Username
    password = $Password
}

try {
    # Request the token using password grant flow
    $response = Invoke-RestMethod -Uri $TOKEN_URL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    
    # Extract the access token
    $TOKEN = $response.access_token
    
    if ($TOKEN) {
        # Set the token as an environment variable
        $env:TOKEN = $TOKEN
        
        Write-Host "Token successfully retrieved." -ForegroundColor Green
    } else {
        Write-Host "Error: No access token found in response" -ForegroundColor Red
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: Failed to retrieve token" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the SSO server is running at $OIDC_SERVER_URL" -ForegroundColor Yellow
    exit 1
}
