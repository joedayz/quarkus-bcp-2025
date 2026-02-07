#!/bin/bash

# Script de diagnóstico para el stack ELK
# Uso: ./diagnose-elk.sh [docker|podman]

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
        podman-compose "$@"
    else
        docker compose "$@"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Diagnóstico del Stack ELK"
echo "=========================================="
echo ""

# 1. Verificar que los servicios estén corriendo
echo "1. Verificando servicios..."
compose_cmd ps
echo ""

# 2. Verificar índices en Elasticsearch
echo "2. Verificando índices en Elasticsearch..."
INDICES=$(curl -s http://localhost:9200/_cat/indices?v 2>/dev/null | grep quarkus || echo "No hay índices quarkus")
if [ "$INDICES" == "No hay índices quarkus" ]; then
    echo "⚠️  No se encontraron índices con patrón 'quarkus-*'"
    echo "   Esto es normal si aún no se han generado logs"
else
    echo "✓ Índices encontrados:"
    echo "$INDICES"
fi
echo ""

# 3. Verificar si hay logs en el archivo
echo "3. Verificando archivo de logs..."
if [ -f "logs/app.log" ]; then
    LOG_COUNT=$(wc -l < logs/app.log 2>/dev/null || echo "0")
    echo "✓ Archivo de logs existe con $LOG_COUNT líneas"
    if [ "$LOG_COUNT" -gt 0 ]; then
        echo "   Últimas 3 líneas:"
        tail -n 3 logs/app.log | sed 's/^/   /'
    else
        echo "   ⚠️  El archivo está vacío"
    fi
else
    echo "⚠️  El archivo logs/app.log no existe"
    echo "   Esto puede ser normal si la aplicación aún no ha generado logs"
fi
echo ""

# 4. Verificar logs de Fluentd
echo "4. Verificando logs de Fluentd (últimas 10 líneas)..."
compose_cmd logs --tail=10 fluentd 2>/dev/null | tail -n 10 || echo "   No se pudieron obtener logs de Fluentd"
echo ""

# 5. Verificar logs de la aplicación
echo "5. Verificando logs de la aplicación (últimas 5 líneas)..."
compose_cmd logs --tail=5 expenses-app 2>/dev/null | tail -n 5 || echo "   No se pudieron obtener logs de la aplicación"
echo ""

# 6. Verificar conectividad de Elasticsearch
echo "6. Verificando conectividad con Elasticsearch..."
if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    echo "✓ Elasticsearch está respondiendo"
    HEALTH=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo "   Estado del cluster: $HEALTH"
else
    echo "⚠️  No se puede conectar a Elasticsearch en http://localhost:9200"
fi
echo ""

# 7. Recomendaciones
echo "=========================================="
echo "Recomendaciones:"
echo "=========================================="
echo ""

if [ "$INDICES" == "No hay índices quarkus" ]; then
    echo "Para generar logs y crear índices:"
    echo "1. Asegúrate de que la aplicación esté corriendo:"
    echo "   curl http://localhost:8080/expenses"
    echo ""
    echo "2. Genera algunos logs haciendo peticiones:"
    echo "   curl http://localhost:8080/expenses/joel-2"
    echo "   curl http://localhost:8080/expenses/nonexistent"
    echo ""
    echo "3. Espera 10-30 segundos para que Fluentd procese los logs"
    echo ""
    echo "4. Verifica los índices nuevamente:"
    echo "   curl http://localhost:9200/_cat/indices?v"
    echo ""
    echo "5. Luego crea el Data View en Kibana con el patrón: quarkus-*"
else
    echo "✓ Los índices existen. Puedes crear el Data View en Kibana:"
    echo "  - Ve a Kibana → Data Views"
    echo "  - Crea un data view con el patrón: quarkus-*"
fi
echo ""
