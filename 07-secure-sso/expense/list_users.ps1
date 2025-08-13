# list_users.ps1 - Script to help with Keycloak user management
# This script provides guidance on how to access Keycloak and manage users

Write-Host "=== Keycloak User Management ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "To access your Keycloak admin console:" -ForegroundColor Yellow
Write-Host "1. Open your browser and go to: https://localhost:8888" -ForegroundColor Green
Write-Host "2. Login with your admin credentials" -ForegroundColor Green
Write-Host "3. Navigate to the 'quarkus' realm" -ForegroundColor Green
Write-Host "4. Go to 'Users' section to see existing users" -ForegroundColor Green
Write-Host ""

Write-Host "To create a new user for testing:" -ForegroundColor Yellow
Write-Host "1. In Keycloak admin console, go to Users > Add user" -ForegroundColor Green
Write-Host "2. Set Username: user" -ForegroundColor Green
Write-Host "3. Set Email: user@example.com" -ForegroundColor Green
Write-Host "4. Go to Credentials tab" -ForegroundColor Green
Write-Host "5. Set Password: redhat" -ForegroundColor Green
Write-Host "6. Turn OFF 'Temporary' password" -ForegroundColor Green
Write-Host "7. Click Save" -ForegroundColor Green
Write-Host ""

Write-Host "Alternative: Use existing user credentials" -ForegroundColor Yellow
Write-Host "If you have other users, you can modify the get_token.ps1 script:" -ForegroundColor Green
Write-Host "Example: . .\get_token.ps1 your_username your_password" -ForegroundColor Cyan
Write-Host ""

Write-Host "To test with a different user, run:" -ForegroundColor Yellow
Write-Host ". .\get_token.ps1 <your_username> <your_password>" -ForegroundColor Cyan
