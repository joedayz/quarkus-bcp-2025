#!/bin/bash

# Script para verificar el estado de Elasticsearch
# Uso: ./check-elasticsearch.sh [docker|podman]

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
echo "Verificando estado de Elasticsearch"
echo "=========================================="
echo ""

# Verificar contenedores
echo "1. Contenedores relacionados con Elasticsearch:"
if [ "$USE_PODMAN" = true ]; then
    podman ps -a | grep -i elastic || echo "   No se encontraron contenedores"
else
    docker ps -a | grep -i elastic || echo "   No se encontraron contenedores"
fi
echo ""

# Verificar logs de Elasticsearch si existe
echo "2. Intentando obtener logs de Elasticsearch..."
compose_cmd logs elasticsearch 2>/dev/null | tail -30 || echo "   No se pudieron obtener logs (el contenedor puede no existir)"
echo ""

# Verificar si el puerto está en uso
echo "3. Verificando si el puerto 9200 está en uso..."
if lsof -i :9200 > /dev/null 2>&1 || netstat -an | grep 9200 > /dev/null 2>&1; then
    echo "   ✓ El puerto 9200 está en uso"
else
    echo "   ⚠️  El puerto 9200 NO está en uso"
fi
echo ""

# Intentar iniciar Elasticsearch
echo "4. Intentando iniciar Elasticsearch..."
compose_cmd up -d elasticsearch

echo ""
echo "5. Esperando 10 segundos para que Elasticsearch inicie..."
sleep 10

# Verificar estado
echo "6. Estado de Elasticsearch:"
compose_cmd ps elasticsearch 2>/dev/null || echo "   Elasticsearch no está corriendo"
echo ""

# Verificar conectividad
echo "7. Verificando conectividad con Elasticsearch..."
if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "   ✓ Elasticsearch está respondiendo"
    HEALTH=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    echo "   Estado del cluster: $HEALTH"
else
    echo "   ⚠️  Elasticsearch NO está respondiendo"
    echo "   Revisa los logs:"
    if [ "$USE_PODMAN" = true ]; then
        echo "   podman-compose logs elasticsearch"
    else
        echo "   docker compose logs elasticsearch"
    fi
fi
echo ""
