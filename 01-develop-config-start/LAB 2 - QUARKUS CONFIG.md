# LAB 2: QUARKUS CONFIG

**Autor:** José Díaz  
**Github Repo:** https://github.com/joedayz/quarkus-bcp-2025.git

## 1. Cargar en su IDE el proyecto 01-develop-config-start

## 2. Examina la clase `com.bcp.training.ExpenseValidatorCli`

- Esta clase define una aplicación de línea de comandos que recibe un argumento.
- La aplicación utiliza la clase `ExpenseValidator` para determinar si el argumento proporcionado está dentro de un rango definido de valores enteros y muestra un mensaje en la salida de la consola.

## 3. Ejecuta el comando `mvn quarkus:dev` para iniciar la aplicación Quarkus en modo desarrollo

Usa el parámetro `-Dquarkus.args='33'` para pasar el valor `33` como argumento de línea de comandos de la aplicación.

### Linux/Mac

```bash
mvn quarkus:dev "-Dquarkus.args='33'"
```

### Windows (CMD)

```cmd
mvn quarkus:dev "-Dquarkus.args='33'"
```

### Windows (PowerShell)

```powershell
mvn quarkus:dev "-Dquarkus.args='33'"
```

**Salida esperada:**

```
...output omitted...
Range - High: 1000
Range - Low: 250
Invalid amount: 33
...output omitted...
```

## 4. Presiona `e` para actualizar el argumento de la aplicación

Escribe `255` y luego presiona `Enter` para reiniciar la aplicación.

**NOTA:** No se ve el número que se ingresa, pero coloca `255`.

**Resultado esperado:**

```
Range - High: 1000
Range - Low: 250
Valid amount: 255
```

## 5. Reemplaza los valores codificados de forma fija por propiedades de configuración

### 5.1. Abre la clase `ExpenseValidator` e importa la anotación `@ConfigProperty`

```java
@ConfigProperty(name = "debug-enabled", defaultValue = "false")
boolean debugEnabled;
```

## 6. Realizar el cambio para las demás propiedades

Asegúrate de que termine así:

```java
@ConfigProperty(name = "range-high")
int targetRangeHigh;

@ConfigProperty(name = "range-low")
int targetRangeLow;
```

## 7. Abre el archivo `src/main/resources/application.properties`

Define las propiedades `range-high = 1024` y `range-low = 64`.

```properties
debug-enabled=true
range-high=1024
range-low=64
```

## 8. Regresa a la ventana del terminal

Presiona `Espacio` para reiniciar la aplicación. Luego verifica que la salida de la consola no muestre los mensajes de depuración del rango:

```
...output omitted...
Valid amount: 255
...output omitted...
```

**Nota:** El método `ExpenseValidator#isValidAmount()` utiliza el valor de la propiedad `debug-enabled` para imprimir mensajes de depuración. En ausencia de un valor para esa propiedad, el valor predeterminado definido en el código es `false`, y la aplicación no ejecuta el método `ExpenseValidator#debugRanges()`.

## 9. Agrupa las propiedades de configuración en una sola interfaz

### 9.1. Crea una interfaz con la configuración mínima de metadatos

- Llama a la interfaz `ExpenseConfiguration`.
- Crea la interfaz en el paquete `com.bcp.training`.
- Anota la interfaz con la anotación `io.smallrye.config.ConfigMapping`.
- Define `expense` como el prefijo de mapeo.
- Usa la anotación `io.smallrye.config.WithDefault` para definir `false` como el valor predeterminado de la propiedad de configuración `debug-enabled`.

```java
package com.bcp.training;

import io.smallrye.config.ConfigMapping;
import io.smallrye.config.WithDefault;

@ConfigMapping(prefix = "expense")
public interface ExpenseConfiguration {
    @WithDefault("false")
    boolean debugEnabled();
    
    int rangeHigh();
    
    int rangeLow();
}
```

## 10. Abre la clase `ExpenseValidator`

Reemplaza la importación de `@ConfigProperty` por la importación de `@Inject`.

## 11. Abre el archivo `application.properties`

Agrega el prefijo `expense` a todas las propiedades de configuración.

```properties
expense.range-high = 1024
expense.range-low = 64
expense.debug-enabled = true
```

## 12. Regresa a la ventana del terminal

Ejecuta el comando:

### Linux/Mac

```bash
mvn quarkus:dev "-Dquarkus.args='255'"
```

### Windows (CMD)

```cmd
mvn quarkus:dev "-Dquarkus.args='255'"
```

### Windows (PowerShell)

```powershell
mvn quarkus:dev "-Dquarkus.args='255'"
```

La salida de la consola muestra los siguientes mensajes:

[Verificar la salida esperada]

## 13. Usa la expansión de expresiones de propiedades en los valores de configuración

### 13.1. Agrega la propiedad `expense.debug-message` al archivo `application.properties`

La propiedad combina los valores de `expense.range-low` y `expense.range-high` en una cadena con fines de depuración.

```properties
expense.debug-message = Range [${expense.range-low}, ${expense.range-high}]
```

### 13.2. En la interfaz `ExpenseConfiguration`

Importa la clase `java.util.Optional`. Luego agrega un método para la propiedad `debug-message` que retorne un objeto `Optional<String>`.

```java
import java.util.Optional;

@ConfigMapping(prefix = "expense")
public interface ExpenseConfiguration {
    @WithDefault("false")
    boolean debugEnabled();
    
    int rangeHigh();
    
    int rangeLow();
    
    Optional<String> debugMessage();
}
```

## 14. Abre la clase `ExpenseValidator` y actualiza el método `debugRanges()`

Reemplaza el contenido del método con una impresión del valor de la propiedad `debug-message`.

```java
public void debugRanges() {
    config.debugMessage().ifPresent(System.out::println);
}
```

## 15. Regresa a la ventana del terminal

Presiona `Espacio` para reiniciar la aplicación y verifica los cambios.

**Salida esperada:**

```
...output omitted...
Range [64, 1024]
Valid amount: 255
...output omitted...
```

## 16. Usa un perfil para definir y sobrescribir propiedades de configuración

### 16.1. Abre el archivo `application.properties`

Establece `500` como valor de la propiedad `expense.range-low` en el perfil `dev`.

```properties
%dev.expense.range-low = 500
```

### 16.2. Regresa a la ventana del terminal

Presiona `Espacio` para reiniciar la aplicación y verifica los cambios.

**Salida esperada:**

```
Range [500, 1024]
Invalid amount: 255
```

## 17. Usa un archivo de entorno (.env) para definir y sobrescribir propiedades de configuración

### 17.1. Crea un archivo `.env` en la raíz del proyecto

Sobrescribe la propiedad `expense.range-low`. Establece `600` como el valor de la propiedad.

```env
EXPENSE_RANGE_LOW = 600
```

### 17.2. Regresa a la ventana del terminal

Presiona `Espacio` para reiniciar la aplicación y verifica los cambios.

**Salida esperada:**

```
...output omitted...
Range [600, 1024]
Invalid amount: 255
...output omitted...
```

## 18. Usa una variable de entorno para definir y sobrescribir propiedades de configuración

### 18.1. Presiona `q` para detener la aplicación Quarkus

### 18.2. Define una variable de entorno

Sobrescribe el valor de la propiedad `expense.range-low`. Establece `700` como el valor de la variable de entorno. Ejecuta la aplicación usando el siguiente comando:

### Linux o Mac

```bash
mvn clean package \
&& EXPENSE_RANGE_LOW=700 \
java -jar -Dquarkus.profile=dev \
target/quarkus-app/quarkus-run.jar 255
```

### Windows (CMD)

```cmd
mvn clean package && set EXPENSE_RANGE_LOW=700 && java -jar "-Dquarkus.profile=dev" target/quarkus-app/quarkus-run.jar 255
```

### Windows (PowerShell)

```powershell
mvn clean package; $env:EXPENSE_RANGE_LOW=700; java -jar "-Dquarkus.profile=dev" target/quarkus-app/quarkus-run.jar 255
```

**Salida esperada:**

```
Range [700, 1024]
Invalid amount: 255
```

---

**Enjoy!**

**Joe**

