# test_connection.ps1 - Diagnostic script to test Keycloak connection
Write-Host "=== Keycloak Connection Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if server is reachable
Write-Host "Test 1: Checking server connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8888" -Method Get -UseBasicParsing
    Write-Host "✅ Server is reachable (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ Server is not reachable: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Check realm configuration
Write-Host "Test 2: Checking realm configuration..." -ForegroundColor Yellow
try {
    $realmUrl = "http://localhost:8888/realms/quarkus"
    $response = Invoke-WebRequest -Uri $realmUrl -Method Get -UseBasicParsing
    Write-Host "✅ Realm 'quarkus' is accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Realm 'quarkus' is not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check client configuration
Write-Host "Test 3: Checking client configuration..." -ForegroundColor Yellow
try {
    $clientUrl = "http://localhost:8888/realms/quarkus/clients-registrations/default/backend-service"
    $response = Invoke-WebRequest -Uri $clientUrl -Method Get -UseBasicParsing
    Write-Host "✅ Client 'backend-service' is accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Client 'backend-service' is not accessible: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Check Keycloak admin console for client 'backend-service'" -ForegroundColor Yellow
Write-Host "2. Verify the client secret in the Credentials tab" -ForegroundColor Yellow
Write-Host "3. Make sure the client is configured for 'password' grant type" -ForegroundColor Yellow
Write-Host "4. Ensure the user 'user' exists and has the correct password" -ForegroundColor Yellow
