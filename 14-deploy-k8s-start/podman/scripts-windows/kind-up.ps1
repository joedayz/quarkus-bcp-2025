# PowerShell script para levantar el cluster kind con Podman
$ErrorActionPreference = "Stop"

$CLUSTER_NAME = "expense-kind"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$CONFIG_DIR = Join-Path $ROOT_DIR "expense" ".kind" "kind-config.yaml"

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
    kind create cluster --name $CLUSTER_NAME --config $CONFIG_DIR
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al crear el cluster" -ForegroundColor Red
        exit 1
    }
}

kubectl cluster-info

