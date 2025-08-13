# debug_token.ps1 - Debug script to get detailed token request/response info
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

# OIDC server configuration
$OIDC_SERVER_URL = "http://localhost:8888"
$REALM = "quarkus"
$CLIENT_ID = "backend-service"
$CLIENT_SECRET = "dk9dYtW7usj1Nma1lo6jXmcN7we6qmeH"

Write-Host "=== Debug Token Request ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "Server: $OIDC_SERVER_URL" -ForegroundColor Green
Write-Host "Realm: $REALM" -ForegroundColor Green
Write-Host "Client: $CLIENT_ID" -ForegroundColor Green
Write-Host "Username: $Username" -ForegroundColor Green
Write-Host ""

# Get the token endpoint URL
$TOKEN_URL = "$OIDC_SERVER_URL/realms/$REALM/protocol/openid-connect/token"
Write-Host "Token URL: $TOKEN_URL" -ForegroundColor Yellow
Write-Host ""

# Prepare the request body
$body = @{
    grant_type = "password"
    client_id = $CLIENT_ID
    client_secret = $CLIENT_SECRET
    username = $Username
    password = $Password
}

Write-Host "Request Body:" -ForegroundColor Yellow
$body | Format-Table -AutoSize
Write-Host ""

try {
    Write-Host "Sending request..." -ForegroundColor Yellow
    
    # Use Invoke-WebRequest to get more details
    $response = Invoke-WebRequest -Uri $TOKEN_URL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
    
    Write-Host "✅ Request successful!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response Headers:" -ForegroundColor Yellow
    $response.Headers | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "Response Body:" -ForegroundColor Yellow
    $responseBody = $response.Content | ConvertFrom-Json
    $responseBody | ConvertTo-Json -Depth 10
    
    if ($responseBody.access_token) {
        Write-Host ""
        Write-Host "✅ Token found!" -ForegroundColor Green
        $env:TOKEN = $responseBody.access_token
        Write-Host "Token preview: $($responseBody.access_token.Substring(0, [Math]::Min(50, $responseBody.access_token.Length)))..." -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "❌ Request failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        
        # Try to get response body
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            $reader.Close()
            
            Write-Host "Response Body:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor Red
        } catch {
            Write-Host "Could not read response body" -ForegroundColor Red
        }
    }
}
