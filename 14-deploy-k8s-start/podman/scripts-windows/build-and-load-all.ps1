# PowerShell script para construir y cargar imágenes con Podman
$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "expense-kind"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)

function Build-AndLoad {
    param(
        [string]$dir,
        [string]$name,
        [string]$dockerfile
    )

    Write-Host "`n=== Building ${name} in ${dir} ===" -ForegroundColor Cyan
    Push-Location (Join-Path $ROOT_DIR $dir)
    
    mvn -q package
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir con Maven" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    $shortTag = "${name}:latest"
    $localTag = "localhost/${name}:latest"
    
    podman build -f $dockerfile -t $shortTag .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al construir la imagen" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    podman tag $shortTag $localTag
    
    Write-Host "Loading ${localTag} into kind..."
    $env:KIND_EXPERIMENTAL_PROVIDER = "podman"
    
    $loaded = $false
    kind load docker-image $localTag --name $CLUSTER_NAME 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Loaded ${localTag} via docker-image" -ForegroundColor Green
        $loaded = $true
    } else {
        Write-Host "Falling back to image-archive for ${localTag}"
        $targetDir = Join-Path $ROOT_DIR $dir "target"
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        $archivePath = Join-Path $targetDir "${name}-image.tar"
        podman save -o $archivePath $localTag
        if ($LASTEXITCODE -eq 0) {
            kind load image-archive $archivePath --name $CLUSTER_NAME
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Loaded ${localTag} via image-archive" -ForegroundColor Green
                $loaded = $true
            }
        }
    }
    
    if (-not $loaded) {
        Write-Host "Error al cargar la imagen ${localTag}" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

Build-AndLoad "expense-service" "expense-service" "src/main/docker/Dockerfile.jvm"
Build-AndLoad "expense-client" "expense-client" "src/main/docker/Dockerfile.jvm"

Write-Host "`nTodas las imágenes cargadas." -ForegroundColor Green

