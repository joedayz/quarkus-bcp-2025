#!/bin/bash

# Script para depurar problemas de logging
# Uso: ./debug-logging.sh [docker|podman]

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
echo "Depuración de Logging"
echo "=========================================="
echo ""

# 1. Verificar que el servicio está corriendo
echo "1. Verificando que expenses-app está corriendo..."
if compose_cmd ps | grep -q "expenses-app.*Up"; then
    echo "✓ El servicio expenses-app está corriendo"
else
    echo "⚠️  El servicio expenses-app NO está corriendo"
    echo "   Iniciando el servicio..."
    compose_cmd up -d expenses-app
    sleep 5
fi
echo ""

# 2. Verificar que la aplicación responde
echo "2. Verificando que la aplicación responde..."
if curl -s http://localhost:8080/expenses > /dev/null 2>&1; then
    echo "✓ La aplicación responde correctamente"
else
    echo "⚠️  La aplicación NO responde"
    echo "   Revisando logs del contenedor..."
    compose_cmd logs --tail=20 expenses-app
    exit 1
fi
echo ""

# 3. Verificar el directorio de logs en el contenedor
echo "3. Verificando directorio de logs en el contenedor..."
compose_cmd exec -T expenses-app ls -la /var/log/quarkus/ 2>/dev/null || {
    echo "⚠️  No se puede acceder al directorio /var/log/quarkus en el contenedor"
    echo "   Intentando crear el directorio..."
    compose_cmd exec expenses-app mkdir -p /var/log/quarkus
    compose_cmd exec expenses-app chmod 777 /var/log/quarkus
}
echo ""

# 4. Verificar variables de entorno
echo "4. Verificando variables de entorno de logging..."
compose_cmd exec -T expenses-app env 2>/dev/null | grep QUARKUS_LOG || echo "⚠️  No se encontraron variables QUARKUS_LOG"
echo ""

# 5. Verificar archivo de logs en el contenedor
echo "5. Verificando archivo de logs en el contenedor..."
if compose_cmd exec -T expenses-app test -f /var/log/quarkus/app.log 2>/dev/null; then
    echo "✓ El archivo app.log existe en el contenedor"
    echo "   Tamaño: $(compose_cmd exec -T expenses-app wc -l < /var/log/quarkus/app.log 2>/dev/null || echo "0") líneas"
    echo "   Últimas 5 líneas:"
    compose_cmd exec -T expenses-app tail -n 5 /var/log/quarkus/app.log 2>/dev/null | sed 's/^/   /'
else
    echo "⚠️  El archivo app.log NO existe en el contenedor"
    echo "   Esto puede ser normal si aún no se han generado logs"
fi
echo ""

# 6. Verificar archivo de logs en el host
echo "6. Verificando archivo de logs en el host..."
if [ -f "logs/app.log" ]; then
    echo "✓ El archivo logs/app.log existe en el host"
    echo "   Tamaño: $(wc -l < logs/app.log) líneas"
else
    echo "⚠️  El archivo logs/app.log NO existe en el host"
    echo "   Verificando directorio logs..."
    ls -la logs/ || echo "   El directorio logs no existe"
fi
echo ""

# 7. Generar logs de prueba
echo "7. Generando logs de prueba..."
echo "   Haciendo peticiones a la aplicación..."
curl -s http://localhost:8080/expenses > /dev/null
sleep 1
curl -s http://localhost:8080/expenses/joel-2 > /dev/null
sleep 1
curl -s http://localhost:8080/expenses/nonexistent > /dev/null
sleep 2

echo "   Peticiones completadas"
echo ""

# 8. Verificar nuevamente el archivo de logs
echo "8. Verificando nuevamente el archivo de logs..."
if compose_cmd exec -T expenses-app test -f /var/log/quarkus/app.log 2>/dev/null; then
    echo "✓ El archivo app.log ahora existe en el contenedor"
    echo "   Contenido (últimas 10 líneas):"
    compose_cmd exec -T expenses-app tail -n 10 /var/log/quarkus/app.log 2>/dev/null | sed 's/^/   /'
    
    if [ -f "logs/app.log" ]; then
        echo ""
        echo "✓ El archivo logs/app.log también existe en el host"
        echo "   Contenido (últimas 10 líneas):"
        tail -n 10 logs/app.log | sed 's/^/   /'
    else
        echo ""
        echo "⚠️  El archivo aún NO existe en el host"
        echo "   Esto puede indicar un problema con el volumen montado"
        echo "   Verificando el volumen..."
        compose_cmd ps expenses-app | grep volumes || echo "   No se encontró información del volumen"
    fi
else
    echo "⚠️  El archivo app.log aún NO existe después de generar logs"
    echo ""
    echo "   Posibles causas:"
    echo "   1. La aplicación no está escribiendo logs al archivo"
    echo "   2. Problema con la configuración de logging"
    echo "   3. Problema con permisos"
    echo ""
    echo "   Revisando logs de la aplicación para más información..."
    compose_cmd logs --tail=30 expenses-app | grep -i "log\|error\|exception" || echo "   No se encontraron mensajes relevantes"
fi
echo ""

echo "=========================================="
echo "Diagnóstico completado"
echo "=========================================="
echo ""
