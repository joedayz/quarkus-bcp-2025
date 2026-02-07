#!/bin/bash

# Script para generar logs en la aplicación Quarkus
# Uso: ./generate-logs.sh

echo "=========================================="
echo "Generando logs en la aplicación Quarkus"
echo "=========================================="
echo ""

# Verificar que la aplicación esté corriendo
if ! curl -s http://localhost:8080/q/health > /dev/null 2>&1 && ! curl -s http://localhost:8080/expenses > /dev/null 2>&1; then
    echo "⚠️  La aplicación no está respondiendo en http://localhost:8080"
    echo "   Asegúrate de que el servicio 'expenses-app' esté corriendo:"
    echo "   docker compose ps"
    echo "   o"
    echo "   podman-compose ps"
    echo ""
    exit 1
fi

echo "✓ Aplicación está respondiendo"
echo ""

# Generar varios tipos de logs
echo "1. Obteniendo todos los expenses (INFO)..."
curl -s http://localhost:8080/expenses > /dev/null
sleep 1

echo "2. Obteniendo un expense existente (DEBUG)..."
curl -s http://localhost:8080/expenses/joel-2 > /dev/null
sleep 1

echo "3. Intentando obtener un expense inexistente (ERROR)..."
curl -s http://localhost:8080/expenses/nonexistent > /dev/null
sleep 1

echo "4. Generando más requests..."
for i in {1..3}; do
    curl -s http://localhost:8080/expenses > /dev/null
    sleep 0.5
done

echo ""
echo "✓ Logs generados"
echo ""
echo "Espera 10-30 segundos para que Fluentd procese los logs..."
echo ""
echo "Luego verifica los índices:"
echo "  curl http://localhost:9200/_cat/indices?v"
echo ""
echo "Y verifica los logs en el archivo:"
echo "  tail -f logs/app.log"
echo ""
