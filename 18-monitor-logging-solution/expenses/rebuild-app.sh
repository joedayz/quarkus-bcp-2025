#!/bin/bash

# Script para reconstruir la aplicación y la imagen Docker
# Uso: ./rebuild-app.sh [docker|podman]

set -e

# Detectar si usar docker o podman
if [ "$1" == "podman" ]; then
    CMD="podman"
    USE_PODMAN=true
elif [ "$1" == "docker" ]; then
    CMD="docker"
    USE_PODMAN=false
else
    if command -v podman &> /dev/null && command -v podman-compose &> /dev/null; then
        CMD="podman"
        USE_PODMAN=true
    elif command -v docker &> /dev/null; then
        CMD="docker"
        USE_PODMAN=false
    else
        echo "Error: No se encontró Docker ni Podman instalado"
        exit 1
    fi
fi

compose_cmd() {
    if [ "$USE_PODMAN" = true ]; then
        (cd "$SCRIPT_DIR" && podman-compose "$@")
    else
        (cd "$SCRIPT_DIR" && docker compose "$@")
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Reconstruyendo aplicación Quarkus"
echo "=========================================="
echo ""

# 1. Construir la aplicación (esto incluye el application.properties actualizado)
echo "1. Construyendo la aplicación Quarkus..."
if ! mvn clean package -DskipTests; then
    echo "Error: Falló la construcción de la aplicación"
    exit 1
fi

echo "✓ Build completado correctamente"
echo ""

# 2. Reconstruir la imagen Docker
echo "2. Reconstruyendo la imagen Docker..."
compose_cmd build --no-cache expenses-app

echo "✓ Imagen reconstruida"
echo ""

# 3. Reiniciar el contenedor
echo "3. Reiniciando el contenedor..."
compose_cmd up -d expenses-app

echo ""
echo "=========================================="
echo "Aplicación reconstruida y reiniciada"
echo "=========================================="
echo ""
echo "Espera unos segundos para que la aplicación inicie..."
echo ""
echo "Luego verifica que está funcionando:"
echo "  curl http://localhost:8080/expenses"
echo ""
echo "Y verifica que se están generando logs:"
echo "  tail -f logs/app.log"
echo ""
