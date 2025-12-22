#!/bin/bash

# Script para generar las claves JWT necesarias para el proyecto Parks
# Este script genera un par de claves RSA (privada y pública) para firmar y verificar tokens JWT

echo "Generando claves JWT para el proyecto Parks..."

# Directorio donde se guardarán las claves
KEYS_DIR="src/main/resources"

# Verificar que el directorio existe
if [ ! -d "$KEYS_DIR" ]; then
    echo "Error: El directorio $KEYS_DIR no existe"
    exit 1
fi

# Generar clave privada RSA de 2048 bits
echo "Generando clave privada..."
openssl genpkey -algorithm RSA -out "$KEYS_DIR/privateKey.pem" -pkeyopt rsa_keygen_bits:2048

if [ $? -ne 0 ]; then
    echo "Error al generar la clave privada"
    exit 1
fi

# Extraer la clave pública de la clave privada
echo "Generando clave pública..."
openssl rsa -pubout -in "$KEYS_DIR/privateKey.pem" -out "$KEYS_DIR/publicKey.pem"

if [ $? -ne 0 ]; then
    echo "Error al generar la clave pública"
    exit 1
fi

echo "✓ Claves generadas exitosamente:"
echo "  - $KEYS_DIR/privateKey.pem"
echo "  - $KEYS_DIR/publicKey.pem"
echo ""
echo "Nota: Estas claves son solo para desarrollo local. NO uses estas claves en producción."

