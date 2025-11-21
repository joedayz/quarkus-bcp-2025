# PowerShell script para levantar el cluster kind con Podman
$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "expense-kind"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$CONFIG_FILE = Join-Path $ROOT_DIR "expense" ".kind" "kind-config.yaml"

# Verificar que el archivo de configuración existe
if (-not (Test-Path $CONFIG_FILE)) {
    Write-Host "Archivo de configuración no encontrado: $CONFIG_FILE" -ForegroundColor Red
    exit 1
}

# Verificar que kind esté instalado
if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host "kind no encontrado. Instala desde https://kind.sigs.k8s.io/docs/user/quick-start/" -ForegroundColor Red
    exit 1
}

# Verificar que podman esté instalado
if (-not (Get-Command podman -ErrorAction SilentlyContinue)) {
    Write-Host "podman no encontrado. Instala Podman primero." -ForegroundColor Red
    exit 1
}

# Verificar si el cluster ya existe
$existingClusters = kind get clusters 2>$null
if ($existingClusters -and ($existingClusters -split "`n" | Select-String -Pattern "^${CLUSTER_NAME}$")) {
    Write-Host "Cluster ${CLUSTER_NAME} ya existe. Omitiendo creación."
} else {
    $env:KIND_EXPERIMENTAL_PROVIDER = "podman"
    # Convertir la ruta a formato absoluto y usar comillas para evitar problemas con puntos
    $configPath = (Resolve-Path $CONFIG_FILE).Path
    Write-Host "Creando cluster con configuración: $configPath" -ForegroundColor Cyan
    & kind create cluster --name $CLUSTER_NAME --config "$configPath"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al crear el cluster" -ForegroundColor Red
        Write-Host "Ruta de configuración usada: $configPath" -ForegroundColor Yellow
        exit 1
    }
}

kubectl cluster-info

