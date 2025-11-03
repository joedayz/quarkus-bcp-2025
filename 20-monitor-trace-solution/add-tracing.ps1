#!/usr/bin/env pwsh

Write-Host "Adding tracing extension to the 'solver' project " -ForegroundColor Green
Set-Location "./solver"
mvn quarkus:add-extension -Dextension="opentelemetry"
Set-Location ".."

Write-Host "Adding tracing extension to the 'adder' project " -ForegroundColor Green
Set-Location "./adder"
mvn quarkus:add-extension -Dextension="opentelemetry"
Set-Location ".."

Write-Host "Adding tracing extension to the 'multiplier' project " -ForegroundColor Green
Set-Location "./multiplier"
mvn quarkus:add-extension -Dextension="opentelemetry"
Set-Location ".."

Write-Host ""