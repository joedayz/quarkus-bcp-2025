# Notas para Instructores: Compartir Claves JWT

Este documento explica las opciones para compartir las claves JWT con los estudiantes.

## ⚠️ Consideraciones de Seguridad

**IMPORTANTE:** Las claves privadas (`privateKey.pem`) NUNCA deben compartirse en repositorios públicos de producción. Sin embargo, para propósitos educativos y desarrollo local, es aceptable compartirlas si:

1. El repositorio es **privado** o solo accesible a estudiantes del curso
2. Las claves son **solo para desarrollo local**
3. Los estudiantes entienden que estas claves NO deben usarse en producción

## Opciones Recomendadas

### ✅ Opción 1: Script de Generación Automática (MEJOR PRÁCTICA)

**Ventajas:**
- Cada estudiante genera sus propias claves únicas
- No hay riesgo de compartir claves accidentalmente
- Enseña buenas prácticas de seguridad
- No necesitas mantener claves en el repositorio

**Implementación:**
- Los scripts `generate-jwt-keys.sh` y `generate-jwt-keys.bat` ya están creados
- Los estudiantes solo ejecutan el script y listo
- Documentación en `SETUP-JWT-KEYS.md`

**Recomendación:** ✅ **Usa esta opción**

### Opción 2: Compartir Claves en el Repositorio (Solo si es necesario)

Si prefieres que todos usen las mismas claves (por ejemplo, para pruebas compartidas):

**Pasos:**

1. **Asegúrate de que el repositorio sea privado** o tenga acceso restringido

2. **Agrega las claves al repositorio:**
   ```bash
   git add parks/src/main/resources/privateKey.pem
   git add parks/src/main/resources/publicKey.pem
   git commit -m "Add JWT keys for development"
   git push
   ```

3. **Verifica que NO estén en .gitignore:**
   - Los archivos `.pem` NO deben estar ignorados si quieres compartirlos
   - Si están en `.gitignore`, quítalos de ahí

4. **Agrega una nota de advertencia** en el README o en un archivo separado

**Cuándo usar:**
- Si necesitas que todos los estudiantes usen las mismas claves
- Si el repositorio es privado
- Si es solo para desarrollo/educación

### Opción 3: Compartir Solo la Clave Pública

Si quieres un enfoque híbrido:

1. Comparte solo `publicKey.pem` en el repositorio
2. Cada estudiante genera su propia `privateKey.pem`
3. Esto permite verificar tokens pero cada uno firma con su propia clave

**Nota:** Esto puede causar problemas si los tokens necesitan ser compartidos entre servicios.

## Recomendación Final

**Para un curso educativo:**

1. ✅ **Usa la Opción 1 (Scripts de generación)** - Es la mejor práctica
2. ✅ **Incluye los scripts en el repositorio** - Ya están creados
3. ✅ **Documenta el proceso** - Ya está en `SETUP-JWT-KEYS.md`
4. ✅ **Enseña seguridad** - Explica por qué cada uno debe tener sus propias claves

**Si realmente necesitas compartir claves:**

1. ⚠️ Solo si el repositorio es **privado**
2. ⚠️ Agrega una advertencia clara de que son solo para desarrollo
3. ⚠️ Considera usar un repositorio separado o un sistema de gestión de secretos

## Archivos Creados

- `parks/generate-jwt-keys.sh` - Script para Linux/Mac
- `parks/generate-jwt-keys.bat` - Script para Windows  
- `parks/SETUP-JWT-KEYS.md` - Documentación para estudiantes
- `INSTRUCTOR-NOTES-JWT-KEYS.md` - Este archivo

## Verificación

Para verificar que todo funciona:

1. Los estudiantes ejecutan el script de generación
2. Verifican que los archivos `.pem` existan en `src/main/resources/`
3. Ejecutan la aplicación y prueban el login
4. Verifican que pueden cambiar el estado de los parques como admin

