# test_grant_types.ps1 - Test different grant types and configurations
Write-Host "=== Testing Different Grant Types ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Password grant (what we're trying to use)
Write-Host "Test 1: Password Grant Type" -ForegroundColor Yellow
Write-Host "This is what we need for the get_token script" -ForegroundColor Gray
Write-Host ""

# Test 2: Client credentials grant (for testing client configuration)
Write-Host "Test 2: Client Credentials Grant Type" -ForegroundColor Yellow
Write-Host "This tests if the client is properly configured" -ForegroundColor Gray

$OIDC_SERVER_URL = "http://localhost:8888"
$REALM = "quarkus"
$CLIENT_ID = "backend-service"
$CLIENT_SECRET = "dk9dYtW7usj1Nma1lo6jXmcN7we6qmeH"
$TOKEN_URL = "$OIDC_SERVER_URL/realms/$REALM/protocol/openid-connect/token"

# Test client credentials grant
$clientBody = @{
    grant_type = "client_credentials"
    client_id = $CLIENT_ID
    client_secret = $CLIENT_SECRET
}

try {
    Write-Host "Testing client credentials grant..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Uri $TOKEN_URL -Method Post -Body $clientBody -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Client credentials grant works!" -ForegroundColor Green
        Write-Host "This means the client is properly configured." -ForegroundColor Green
        Write-Host ""
        Write-Host "The issue is likely that 'password' grant type is not enabled." -ForegroundColor Yellow
        Write-Host "In Keycloak admin console:" -ForegroundColor Yellow
        Write-Host "1. Go to Clients > backend-service" -ForegroundColor Cyan
        Write-Host "2. Go to Advanced tab" -ForegroundColor Cyan
        Write-Host "3. Enable 'password' in Grant Types" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Client credentials grant failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This means there's a problem with the client configuration." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "If client credentials works but password doesn't:" -ForegroundColor Yellow
Write-Host "- Enable 'password' grant type in Keycloak" -ForegroundColor Cyan
Write-Host ""
Write-Host "If client credentials doesn't work:" -ForegroundColor Yellow
Write-Host "- Check client secret and access type" -ForegroundColor Cyan
