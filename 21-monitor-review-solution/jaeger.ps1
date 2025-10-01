# PowerShell script to start Jaeger all-in-one container
# Equivalent to jaeger.sh for Windows

Write-Host "Starting the all-in-one Jaeger container" -ForegroundColor Green

# Check if Podman is available
try {
    $podmanVersion = podman --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Podman is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Podman from: https://podman.io/getting-started/installation" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "Error: Podman is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Podman from: https://podman.io/getting-started/installation" -ForegroundColor Yellow
    exit 1
}

# Start the Jaeger container
Write-Host "Starting Jaeger container with port mappings:" -ForegroundColor Cyan
Write-Host "  - 4317:4317 (OTLP gRPC)" -ForegroundColor White
Write-Host "  - 4318:4318 (OTLP HTTP)" -ForegroundColor White
Write-Host "  - 16686:16686 (Web UI)" -ForegroundColor White
Write-Host "  - 14268:14268 (HTTP Thrift)" -ForegroundColor White

podman run --rm --name jaeger `
  -p 4317:4317 `
  -p 4318:4318 `
  -p 16686:16686 `
  -p 14268:14268 `
  jaegertracing/all-in-one:1.5

# Check if the container started successfully
if ($LASTEXITCODE -eq 0) {
    Write-Host "Jaeger container stopped successfully" -ForegroundColor Green
} else {
    Write-Host "Error: Failed to start Jaeger container" -ForegroundColor Red
    exit 1
}
