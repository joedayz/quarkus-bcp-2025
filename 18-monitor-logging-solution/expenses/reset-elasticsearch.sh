#!/bin/bash

# Script para resetear Elasticsearch eliminando el volumen persistente
# Uso: ./reset-elasticsearch.sh [docker|podman]

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
echo "Reseteando Elasticsearch"
echo "=========================================="
echo ""

# Detener los servicios
echo "1. Deteniendo servicios..."
compose_cmd down
echo ""

# Eliminar el volumen de Elasticsearch
echo "2. Eliminando volumen de Elasticsearch..."
if [ "$USE_PODMAN" = true ]; then
    podman volume rm expenses_elasticsearch_data 2>/dev/null || echo "   El volumen no existe o ya fue eliminado"
else
    docker volume rm expenses_elasticsearch_data 2>/dev/null || echo "   El volumen no existe o ya fue eliminado"
fi
echo ""

# Iniciar los servicios nuevamente
echo "3. Iniciando servicios con Elasticsearch limpio..."
compose_cmd up -d elasticsearch

echo ""
echo "4. Esperando 30 segundos para que Elasticsearch inicie..."
sleep 30

# Verificar estado
echo "5. Verificando estado de Elasticsearch..."
if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "   ✓ Elasticsearch está respondiendo"
    HEALTH=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    echo "   Estado del cluster: $HEALTH"
else
    echo "   ⚠️  Elasticsearch aún no está respondiendo"
    echo "   Revisa los logs:"
    if [ "$USE_PODMAN" = true ]; then
        echo "   podman-compose logs elasticsearch"
    else
        echo "   docker compose logs elasticsearch"
    fi
fi
echo ""

echo "=========================================="
echo "Reset completado"
echo "=========================================="
echo ""
echo "Para iniciar todos los servicios:"
if [ "$USE_PODMAN" = true ]; then
    echo "  podman-compose up -d"
else
    echo "  docker compose up -d"
fi
