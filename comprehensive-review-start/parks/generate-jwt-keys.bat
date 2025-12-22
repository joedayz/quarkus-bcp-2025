@echo off
REM Script para generar las claves JWT necesarias para el proyecto Parks (Windows)
REM Este script genera un par de claves RSA (privada y pública) para firmar y verificar tokens JWT
REM Requiere OpenSSL instalado en el sistema

echo ========================================
echo Generador de Claves JWT - Windows
echo ========================================
echo.

REM Verificar que OpenSSL está instalado
where openssl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] OpenSSL no esta instalado o no esta en el PATH.
    echo.
    echo Por favor instala OpenSSL:
    echo   1. Descarga desde: https://slproweb.com/products/Win32OpenSSL.html
    echo   2. O usa Chocolatey: choco install openssl
    echo   3. O usa Git Bash (incluye OpenSSL)
    echo.
    echo Si usas Git Bash, ejecuta este script desde Git Bash en lugar de CMD.
    echo.
    pause
    exit /b 1
)

echo [OK] OpenSSL encontrado
echo.

REM Directorio donde se guardarán las claves
set KEYS_DIR=src\main\resources

REM Verificar que el directorio existe
if not exist "%KEYS_DIR%" (
    echo [ERROR] El directorio %KEYS_DIR% no existe
    echo Por favor ejecuta este script desde el directorio raiz del proyecto parks
    echo.
    pause
    exit /b 1
)

REM Generar clave privada RSA de 2048 bits
echo [1/2] Generando clave privada...
openssl genpkey -algorithm RSA -out "%KEYS_DIR%\privateKey.pem" -pkeyopt rsa_keygen_bits:2048

if errorlevel 1 (
    echo [ERROR] Error al generar la clave privada
    echo Verifica que OpenSSL este correctamente instalado
    echo.
    pause
    exit /b 1
)

REM Extraer la clave pública de la clave privada
echo [2/2] Generando clave publica...
openssl rsa -pubout -in "%KEYS_DIR%\privateKey.pem" -out "%KEYS_DIR%\publicKey.pem"

if errorlevel 1 (
    echo [ERROR] Error al generar la clave publica
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo [EXITO] Claves generadas exitosamente
echo ========================================
echo.
echo Archivos creados:
echo   - %KEYS_DIR%\privateKey.pem
echo   - %KEYS_DIR%\publicKey.pem
echo.
echo Nota: Estas claves son solo para desarrollo local.
echo       NO uses estas claves en produccion.
echo.
pause

