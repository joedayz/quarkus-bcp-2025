#!/bin/bash

# Script para reconstruir Fluentd y verificar su funcionamiento
# Uso: ./rebuild-fluentd.sh [docker|podman]

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
echo "Reconstruyendo Fluentd"
echo "=========================================="
echo ""

# Detener Fluentd si está corriendo
echo "1. Deteniendo Fluentd..."
compose_cmd stop fluentd 2>/dev/null || echo "   Fluentd no estaba corriendo"
echo ""

# Reconstruir la imagen de Fluentd
echo "2. Reconstruyendo la imagen de Fluentd..."
compose_cmd build --no-cache fluentd
echo ""

# Iniciar Fluentd
echo "3. Iniciando Fluentd..."
compose_cmd up -d fluentd
echo ""

# Esperar unos segundos para que Fluentd inicie
echo "4. Esperando 10 segundos para que Fluentd inicie..."
sleep 10
echo ""

# Verificar logs de Fluentd
echo "5. Verificando logs de Fluentd (últimas 30 líneas)..."
compose_cmd logs fluentd | tail -30
echo ""

# Verificar que Fluentd esté corriendo
echo "6. Verificando estado de Fluentd..."
if compose_cmd ps fluentd | grep -q "Up"; then
    echo "   ✓ Fluentd está corriendo"
else
    echo "   ⚠️  Fluentd NO está corriendo"
    echo "   Revisa los logs con:"
    if [ "$USE_PODMAN" = true ]; then
        echo "   podman-compose logs fluentd"
    else
        echo "   docker compose logs fluentd"
    fi
fi
echo ""

echo "=========================================="
echo "Reconstrucción completada"
echo "=========================================="
echo ""
echo "Para ver los logs en tiempo real:"
if [ "$USE_PODMAN" = true ]; then
    echo "  podman-compose logs -f fluentd"
else
    echo "  docker compose logs -f fluentd"
fi
echo ""
