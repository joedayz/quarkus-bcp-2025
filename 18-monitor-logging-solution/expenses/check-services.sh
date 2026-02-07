#!/bin/bash

# Script para verificar el estado de los servicios
# Uso: ./check-services.sh [docker|podman]

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
echo "Verificando estado de servicios"
echo "=========================================="
echo ""

# Verificar servicios
echo "1. Estado de los servicios:"
compose_cmd ps
echo ""

# Verificar si la aplicación está respondiendo
echo "2. Verificando si la aplicación responde..."
if curl -s http://localhost:8080/expenses > /dev/null 2>&1; then
    echo "✓ La aplicación está respondiendo en http://localhost:8080"
else
    echo "⚠️  La aplicación NO está respondiendo"
    echo "   Verifica que el servicio 'expenses-app' esté corriendo"
fi
echo ""

# Verificar archivo de logs en el contenedor
echo "3. Verificando archivo de logs en el contenedor..."
if compose_cmd exec -T expenses-app ls -la /var/log/quarkus/ 2>/dev/null | grep app.log; then
    echo "✓ El archivo app.log existe en el contenedor"
    echo "   Contenido (últimas 5 líneas):"
    compose_cmd exec -T expenses-app tail -n 5 /var/log/quarkus/app.log 2>/dev/null || echo "   (archivo vacío o no accesible)"
else
    echo "⚠️  El archivo app.log NO existe en el contenedor"
    echo "   Verificando directorio:"
    compose_cmd exec -T expenses-app ls -la /var/log/quarkus/ 2>/dev/null || echo "   Directorio no existe o no es accesible"
fi
echo ""

# Verificar archivo de logs en el host
echo "4. Verificando archivo de logs en el host..."
if [ -f "logs/app.log" ]; then
    echo "✓ El archivo logs/app.log existe en el host"
    echo "   Tamaño: $(wc -l < logs/app.log) líneas"
    echo "   Últimas 3 líneas:"
    tail -n 3 logs/app.log | sed 's/^/   /'
else
    echo "⚠️  El archivo logs/app.log NO existe en el host"
    echo "   El volumen puede no estar montado correctamente"
fi
echo ""

# Verificar logs de la aplicación
echo "5. Logs recientes del contenedor (últimas 10 líneas):"
compose_cmd logs --tail=10 expenses-app 2>/dev/null | tail -n 10 || echo "   No se pudieron obtener logs"
echo ""

# Verificar configuración de logging
echo "6. Verificando variables de entorno de logging..."
compose_cmd exec -T expenses-app env 2>/dev/null | grep QUARKUS_LOG || echo "   No se encontraron variables QUARKUS_LOG"
echo ""

echo "=========================================="
echo "Recomendaciones:"
echo "=========================================="
echo ""
if ! curl -s http://localhost:8080/expenses > /dev/null 2>&1; then
    echo "1. Inicia la aplicación:"
    echo "   compose_cmd up -d expenses-app"
    echo ""
fi

if [ ! -f "logs/app.log" ]; then
    echo "2. El archivo de logs no existe. Posibles causas:"
    echo "   - La aplicación no ha generado logs aún"
    echo "   - El volumen no está montado correctamente"
    echo "   - Verifica que el directorio 'logs' existe y tiene permisos correctos"
    echo ""
    echo "   Intenta generar logs:"
    echo "   ./generate-logs.sh"
    echo ""
fi

echo "3. Si el problema persiste, revisa los logs del contenedor:"
echo "   compose_cmd logs expenses-app"
echo ""
