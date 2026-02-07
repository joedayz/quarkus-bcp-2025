#!/bin/bash

# Script para iniciar el stack ELK (Elasticsearch, Kibana, Fluentd) con Docker o Podman
# Uso: ./start-elk.sh [docker|podman]

set -e

# Detectar si usar docker o podman
if [ "$1" == "podman" ]; then
    CMD="podman"
    USE_PODMAN=true
elif [ "$1" == "docker" ]; then
    CMD="docker"
    USE_PODMAN=false
else
    # Intentar detectar automáticamente
    if command -v podman &> /dev/null && command -v podman-compose &> /dev/null; then
        CMD="podman"
        USE_PODMAN=true
        echo "Usando Podman..."
    elif command -v docker &> /dev/null; then
        CMD="docker"
        USE_PODMAN=false
        echo "Usando Docker..."
    else
        echo "Error: No se encontró Docker ni Podman instalado"
        exit 1
    fi
fi

# Función para ejecutar compose
compose_cmd() {
    if [ "$USE_PODMAN" = true ]; then
        (cd "$SCRIPT_DIR" && podman-compose "$@")
    else
        (cd "$SCRIPT_DIR" && docker compose "$@")
    fi
}

echo "=========================================="
echo "Iniciando stack ELK con $CMD"
echo "=========================================="

# Asegurarse de que estamos en el directorio correcto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Construir la aplicación primero
echo ""
echo "1. Construyendo la aplicación Quarkus..."
if ! mvn clean package -DskipTests; then
    echo "Error: Falló la construcción de la aplicación"
    exit 1
fi

# Verificar que los archivos necesarios existen
if [ ! -d "target/quarkus-app/lib" ]; then
    echo "Error: El directorio target/quarkus-app/lib no existe después del build"
    echo "Asegúrate de que el build se completó correctamente"
    exit 1
fi

echo "✓ Build completado correctamente"

# Crear directorio de logs si no existe y dar permisos correctos
mkdir -p logs
chmod 777 logs

# Iniciar los servicios
echo ""
echo "2. Iniciando Elasticsearch, Kibana y Fluentd..."
compose_cmd up -d elasticsearch kibana fluentd

# Esperar a que Elasticsearch esté listo
echo ""
echo "3. Esperando a que Elasticsearch esté listo..."
sleep 10

# Construir y levantar la aplicación
echo ""
echo "4. Construyendo y levantando la aplicación Quarkus..."
echo "   Directorio actual: $(pwd)"
echo "   Verificando target/quarkus-app/lib existe: $([ -d "target/quarkus-app/lib" ] && echo "Sí" || echo "No")"
compose_cmd build expenses-app
compose_cmd up -d expenses-app

echo ""
echo "=========================================="
echo "Stack ELK iniciado correctamente!"
echo "=========================================="
echo ""
echo "Servicios disponibles:"
echo "  - Aplicación Quarkus: http://localhost:8080"
echo "  - Kibana: http://localhost:5601"
echo "  - Elasticsearch: http://localhost:9200"
echo ""
echo "Para ver los logs:"
if [ "$USE_PODMAN" = true ]; then
    echo "  podman-compose logs -f"
else
    echo "  docker compose logs -f"
fi
echo ""
echo "Para detener todo:"
if [ "$USE_PODMAN" = true ]; then
    echo "  podman-compose down"
else
    echo "  docker compose down"
fi
echo ""

