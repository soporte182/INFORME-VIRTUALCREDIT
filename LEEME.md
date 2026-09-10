# Proyecto Visionamos - Control de bolsa

Página: https://visionamos-bolsa-consumos.soporte506107.chatgpt.site
Vigencia: marzo 2026 a febrero 2027. Bolsa: 15.000 análisis.

## Contenido
- panel-consumos/: código completo, componentes, estilos, configuración, dependencias fijadas y migraciones.
- PDF originales en la raíz: informes de marzo a agosto de 2026.
- consumos-respaldo-online.json: copia de los datos del sitio al exportar.
- panel-consumos/lib/initial-data.json: base de los informes originales.

Incluye la bolsa de 15.000 destacada, participación ordenada de mayor a menor, evolución por entidad y actualización mensual.

## Ejecutar en otro equipo
Requiere Node.js 22.13 o superior y npm. Se necesita conexión para instalar dependencias.
1. Descomprime el ZIP.
2. Abre una terminal dentro de panel-consumos.
3. Ejecuta: npm ci
4. Crea la base local: npx wrangler d1 execute site-creator-d1 --local --config=wrangler.local.json --persist-to=.wrangler/state --file=drizzle/0000_lively_lorna_dane.sql
   Este paso se realiza una sola vez por base local nueva.
5. Ejecuta: npm run dev
6. Abre la dirección que indique la terminal (normalmente http://localhost:3000).

La base local es independiente de la base del sitio publicado. Los seis meses originales aparecen automáticamente. Para usar el respaldo exportado como base de una instalación nueva, con el servidor detenido, copia consumos-respaldo-online.json sobre panel-consumos/lib/initial-data.json ANTES de iniciar; cualquier registro ya guardado en la base local tiene prioridad sobre esa base inicial.

## Actualizar los consumos
En la página, selecciona Actualizar mes. Escribe la fuente y las entidades con cantidades de deudor y codeudor, o pega tres columnas desde Excel sin encabezados. Guarda el mes. Editar un mes reemplaza su detalle completo; no lo duplica. Descargar datos permite obtener nuevos respaldos JSON.

## Preparar una versión de producción
Ejecuta npm run build. El resultado se genera en dist/. Este proyecto usa React/Vinext y Cloudflare Workers/D1; no es un HTML autónomo que se abra con doble clic ni se publica copiándolo a cualquier hosting estático.
La configuración .openai/hosting.json identifica el sitio existente. Para publicarlo en ese sitio usa Sites con la cuenta propietaria. Para otro proveedor debes configurar Workers, D1 y acceso privado equivalentes. No contiene credenciales de publicación.

## Verificar o volver a extraer los PDF
El script scripts/extract_reports.py requiere Python y pypdf (python -m pip install pypdf). Ejecútalo desde panel-consumos: python scripts/extract_reports.py. Los seis PDF deben conservarse en la carpeta superior. El script reconstruye la base original de seis meses y verifica 6.335 consumos; no procesa automáticamente nuevos meses.

## Alcance del respaldo
No se incluyen node_modules (se reconstruye con npm ci), archivos temporales, credenciales, historial Git ni la base interna administrada por el proveedor. Su contenido de consumos se entrega en JSON. El ZIP contiene el código fuente; los compilados se regeneran con npm run build.
