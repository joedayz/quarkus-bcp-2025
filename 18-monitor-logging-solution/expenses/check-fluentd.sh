#!/bin/bash

# Script para verificar el estado de Fluentd
# Uso: ./check-fluentd.sh [docker|podman]

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
echo "Verificando Fluentd"
echo "=========================================="
echo ""

# 1. Verificar que Fluentd está corriendo
echo "1. Verificando que Fluentd está corriendo..."
if compose_cmd ps | grep -q "fluentd.*Up"; then
    echo "✓ Fluentd está corriendo"
else
    echo "⚠️  Fluentd NO está corriendo"
    echo "   Iniciando Fluentd..."
    compose_cmd up -d fluentd
    sleep 5
fi
echo ""

# 2. Verificar logs de Fluentd
echo "2. Logs recientes de Fluentd (últimas 30 líneas):"
compose_cmd logs --tail=30 fluentd 2>/dev/null | tail -n 30
echo ""

# 3. Verificar que Fluentd puede ver el archivo de logs
echo "3. Verificando acceso al archivo de logs..."
if [ -f "logs/app.log" ]; then
    echo "✓ El archivo logs/app.log existe"
    LINE_COUNT=$(wc -l < logs/app.log 2>/dev/null || echo "0")
    echo "   Líneas en el archivo: $LINE_COUNT"
    if [ "$LINE_COUNT" -gt 0 ]; then
        echo "   Últimas 3 líneas del archivo:"
        tail -n 3 logs/app.log | sed 's/^/   /'
    fi
else
    echo "⚠️  El archivo logs/app.log NO existe"
fi
echo ""

# 4. Verificar que Fluentd puede acceder al archivo dentro del contenedor
echo "4. Verificando acceso desde el contenedor Fluentd..."
if compose_cmd exec -T fluentd test -f /var/log/quarkus/app.log 2>/dev/null; then
    echo "✓ Fluentd puede ver el archivo /var/log/quarkus/app.log"
    CONTAINER_LINES=$(compose_cmd exec -T fluentd wc -l < /var/log/quarkus/app.log 2>/dev/null || echo "0")
    echo "   Líneas visibles para Fluentd: $CONTAINER_LINES"
else
    echo "⚠️  Fluentd NO puede ver el archivo /var/log/quarkus/app.log"
    echo "   Verificando directorio..."
    compose_cmd exec -T fluentd ls -la /var/log/quarkus/ 2>/dev/null || echo "   Directorio no accesible"
fi
echo ""

# 5. Verificar conectividad con Elasticsearch
echo "5. Verificando conectividad con Elasticsearch desde Fluentd..."
if compose_cmd exec -T fluentd curl -s http://elasticsearch:9200/_cluster/health > /dev/null 2>&1; then
    echo "✓ Fluentd puede conectarse a Elasticsearch"
    HEALTH=$(compose_cmd exec -T fluentd curl -s http://elasticsearch:9200/_cluster/health 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    echo "   Estado del cluster: $HEALTH"
else
    echo "⚠️  Fluentd NO puede conectarse a Elasticsearch"
    echo "   Verificando si Elasticsearch está corriendo..."
    if curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
        echo "   ✓ Elasticsearch está respondiendo en localhost"
        echo "   ⚠️  Problema de conectividad desde Fluentd (puede ser red Docker)"
    else
        echo "   ⚠️  Elasticsearch NO está respondiendo"
    fi
fi
echo ""

# 6. Verificar posición del archivo de Fluentd
echo "6. Verificando posición del archivo de Fluentd..."
if compose_cmd exec -T fluentd test -f /var/log/quarkus/app.log.pos 2>/dev/null; then
    echo "✓ Archivo de posición existe"
    POS=$(compose_cmd exec -T fluentd cat /var/log/quarkus/app.log.pos 2>/dev/null || echo "vacío")
    echo "   Posición: $POS"
else
    echo "⚠️  Archivo de posición NO existe (Fluentd puede no haber leído el archivo aún)"
fi
echo ""

# 7. Verificar índices en Elasticsearch
echo "7. Verificando índices en Elasticsearch..."
INDICES=$(curl -s http://localhost:9200/_cat/indices?v 2>/dev/null | grep quarkus || echo "No hay índices quarkus")
if [ "$INDICES" == "No hay índices quarkus" ]; then
    echo "⚠️  No hay índices con patrón 'quarkus-*' en Elasticsearch"
    echo "   Esto indica que Fluentd no está enviando logs"
else
    echo "✓ Índices encontrados:"
    echo "$INDICES"
fi
echo ""

echo "=========================================="
echo "Recomendaciones:"
echo "=========================================="
echo ""

if [ "$INDICES" == "No hay índices quarkus" ]; then
    echo "1. Si Fluentd está corriendo pero no hay índices:"
    echo "   - Espera 10-30 segundos (Fluentd procesa cada 5 segundos)"
    echo "   - Genera más logs: ./generate-logs.sh"
    echo "   - Revisa los logs de Fluentd para errores"
    echo ""
    echo "2. Si hay errores en los logs de Fluentd:"
    echo "   - Verifica la configuración en fluentd/conf/fluent.conf"
    echo "   - Verifica que Elasticsearch esté accesible desde Fluentd"
    echo "   - Reinicia Fluentd: compose_cmd restart fluentd"
fi

echo ""
