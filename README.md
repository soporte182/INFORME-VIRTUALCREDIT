# Tablero público Visionamos

## Abrir el tablero
https://soporte182.github.io/INFORME-VIRTUALCREDIT/

GitHub Pages sirve la página; Supabase guarda los consumos. La integración entre GitHub y Supabase no es necesaria para este funcionamiento.

## Activar Supabase (una sola vez)
1. Abre el proyecto `VISIONAMOS-CONSUMOS` y entra en **SQL Editor > New query**.
2. Copia todo el archivo `supabase/01_configurar_visionamos.sql` y pulsa **Run**. Crea la tabla, los permisos y carga marzo a agosto. No reemplaza meses existentes.
3. Ve a **Authentication > URL Configuration**. En **Site URL**, escribe `https://soporte182.github.io/INFORME-VIRTUALCREDIT/`. Agrega esa misma URL a **Redirect URLs** y guarda.
4. En el tablero pulsa **Ingresar para editar**, ingresa `soporte@infycredit.com` y abre el enlace recibido en ese correo. No compartas el enlace de acceso.

La cuenta debe confirmar su correo. Los visitantes y otras cuentas solo pueden consultar. Las políticas de la base restringen la escritura, no solo los botones. Si Supabase rechaza el envío de correo por restricciones de su servicio de correo predeterminado, configura un SMTP propio en Supabase; no es necesario cambiar el código del tablero.

## Actualizar cada mes
Inicia sesión, pulsa **Actualizar mes**, ingresa o pega entidad / deudor / codeudor y guarda. Se almacena en Supabase sin modificar archivos de GitHub. **Descargar datos** crea un respaldo JSON de todos los meses cargados. Los meses pendientes no son ceros.

Si aparece un aviso de conexión, el tablero conserva su última información disponible (los informes originales al abrir). En ese estado no permite guardar ni presenta la conexión como completada.

## Código y publicación
`panel-consumos/` contiene el código fuente; `docs/` contiene los archivos estáticos publicados. Pages debe usar la rama **main** y carpeta **/docs**. Para actualizar el código, desde `panel-consumos` ejecuta:

```sh
npm ci
npm run build:pages
```

El resultado se escribe en `docs/`. Sube ambos cambios al repositorio. Para desarrollo local: `npm run dev:pages`.

La clave incluida en `lib/supabase.ts` es pública (publishable). Ninguna clave secreta debe incluirse en el repositorio. El proyecto original de Sites conserva su publicación independiente y no se sincroniza con esta nueva base.
