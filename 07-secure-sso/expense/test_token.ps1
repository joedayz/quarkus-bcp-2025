# test_token.ps1 - Demo script showing how to use get_token.ps1
# This demonstrates the exact workflow from the guide

Write-Host "=== Token Retrieval Demo ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get the token (equivalent to: source get_token.sh user redhat)
Write-Host "Step 1: Getting bearer token..." -ForegroundColor Yellow
. .\get_token.ps1 user redhat

Write-Host ""

# Step 2: Verify the TOKEN variable (equivalent to: echo $TOKEN)
Write-Host "Step 2: Verifying TOKEN variable..." -ForegroundColor Yellow
if ($env:TOKEN) {
    Write-Host "TOKEN variable contains: $env:TOKEN" -ForegroundColor Green
} else {
    Write-Host "TOKEN variable is not set" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Demo Complete ===" -ForegroundColor Cyan
Write-Host "You can now use the TOKEN variable in your API calls:" -ForegroundColor Yellow
Write-Host "Invoke-RestMethod -Uri 'http://localhost:8080/expenses' -Headers @{'Authorization'='Bearer $env:TOKEN'}" -ForegroundColor Cyan
