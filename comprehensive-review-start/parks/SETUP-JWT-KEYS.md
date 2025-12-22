# Configuración de Claves JWT

Este proyecto requiere claves RSA para firmar y verificar tokens JWT. Tienes dos opciones:

## Opción 1: Generar las claves automáticamente (Recomendado)

Ejecuta el script correspondiente a tu sistema operativo:

### Windows

**Opción A: Desde CMD o PowerShell**
```cmd
cd parks
generate-jwt-keys.bat
```

**Opción B: Desde Git Bash (si tienes Git instalado)**
```bash
cd parks
./generate-jwt-keys.sh
```

**Requisito:** Necesitas tener OpenSSL instalado en Windows:
- **Opción 1:** Descarga desde [Win32OpenSSL](https://slproweb.com/products/Win32OpenSSL.html)
- **Opción 2:** Usa Chocolatey: `choco install openssl`
- **Opción 3:** Si tienes Git instalado, Git Bash incluye OpenSSL

### Linux/Mac

```bash
cd parks
./generate-jwt-keys.sh
```

**Requisito:** OpenSSL generalmente viene preinstalado. Si no, instálalo con tu gestor de paquetes.

Este script generará automáticamente:
- `src/main/resources/privateKey.pem` - Clave privada para firmar tokens
- `src/main/resources/publicKey.pem` - Clave pública para verificar tokens

## Opción 2: Generar las claves manualmente

Si prefieres generar las claves manualmente o el script no funciona:

**Linux/Mac:**
```bash
cd src/main/resources
openssl genpkey -algorithm RSA -out privateKey.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in privateKey.pem -out publicKey.pem
```

**Windows (CMD/PowerShell):**
```cmd
cd src\main\resources
openssl genpkey -algorithm RSA -out privateKey.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in privateKey.pem -out publicKey.pem
```

**Windows (Git Bash):**
```bash
cd src/main/resources
openssl genpkey -algorithm RSA -out privateKey.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in privateKey.pem -out publicKey.pem
```

## Opción 3: Usar claves compartidas (Solo para desarrollo/educación)

Si el instructor ha compartido las claves en el repositorio, simplemente asegúrate de que los archivos estén en `src/main/resources/`:
- `privateKey.pem`
- `publicKey.pem`

**⚠️ IMPORTANTE:** 
- Estas claves son SOLO para desarrollo local y propósitos educativos
- NUNCA uses estas claves en producción
- En producción, genera claves únicas y mantenlas seguras

## Verificación

Después de generar o copiar las claves, verifica que existan:

**Linux/Mac:**
```bash
ls -la src/main/resources/*.pem
```

**Windows:**
```cmd
dir src\main\resources\*.pem
```

Deberías ver ambos archivos: `privateKey.pem` y `publicKey.pem`.

