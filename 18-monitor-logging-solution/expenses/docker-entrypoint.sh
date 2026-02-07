#!/bin/bash

# Script de entrada para asegurar que el directorio de logs existe y tiene permisos correctos
set -e

# Crear el directorio de logs si no existe (el volumen debería montarlo, pero por si acaso)
mkdir -p /var/log/quarkus || true

# Ejecutar el comando original
exec "$@"
