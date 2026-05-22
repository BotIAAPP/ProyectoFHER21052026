---
name: maquila-crear-pedido
description: Crea un pedido de maquila (transacción VA01) en SAP S/4HANA WebGUI leyendo los datos desde un JSON / Script de Pruebas (data-driven), manejando Chromium con Playwright vía CDP. Úsalo cuando el usuario pida "crear un pedido de maquila", "ejecutar VA01", "capturar pedido KMAT", "crear pedido en SAP" o ejecutar el caso TC-01.
---

# Crear pedido de maquila (VA01) en SAP — data-driven

Crea un pedido de venta de maquila con material configurable (KMAT) en SAP WebGUI, leyendo los datos de un archivo JSON (que a su vez refleja el Script de Pruebas UAT).

## Datos de entrada (JSON)
Ver `scripts/tc01-data.json`. Campos:
`clase` (ZMAQ), `org` (LM00), `canal` (50), `sector` (00), `solicitante` (GILM000002), `referencia`, `fecha` (DD.MM.AAAA), `material` (43000005), `cantidad`, `parte` (nº de parte cliente, p. ej. `95432 CODO 3 1/2" A 90º`).

## Procedimiento
1. **Navegador/sesión.** Si no hay Chromium escuchando CDP en `localhost:9222`, lánzalo en background: `node scripts/launcher.js` y espera la línea `READY`. Usa un perfil persistente (`scripts/userdata`), así que la sesión SAP puede seguir activa entre corridas.
2. **Verifica la sesión:** `node scripts/snap.js`. Si el título es `SAP Easy Access` (o una transacción) ya está logueado. Si es `Entrada al sistema`, pide al usuario que inicie sesión **manualmente** en la ventana visible (NO automatizar credenciales).
3. **Prepara los datos:** edita/crea el JSON con los valores deseados.
4. **Ejecuta:** `node scripts/create-from-script.js <ruta-al-json>` (por defecto `scripts/tc01-data.json`).
5. **Lee el resultado:** el script imprime `Pedido de Maquila NNNN se ha grabado.` y deja la captura en `pw/shot.png`. Reporta el número de pedido.

## Detalles técnicos clave (gotchas)
- El campo OK code `#ToolbarOkCode` viene **colapsado**; el script lo fuerza visible antes de teclear.
- En SAP WebGUI, cuando un campo tiene valor, su `title` cambia a `"VALOR - Etiqueta"`. Selecciona por **sufijo**: `input[title$="Etiqueta"]`.
- **Sector 00** en la pantalla inicial fija el área `LM00/50/00` (válida) y **evita el popup** "Áreas de ventas para cliente". Con **Sector 10** SAP falla con `"No fue posible determinar esquema de cálculo"` (pendiente de datos maestros — ver skill `maquila-instrucciones-consultor`).
- Celdas de la tabla de posiciones (`...[fila,col]_c`) son `span` readonly: escribe con **click + `keyboard.type`**, NO con `fill()`.
- El material KMAT abre la pantalla de configuración; basta capturar **NUMERO DE PARTE CLIENTE** y SAP deriva ancho, calibre, acabado, ángulo, longitud y peso.
- Aviso "material no susceptible de configuración (motivo 2)" → clic **Continuar** (informativo).
- Control de disponibilidad sin stock (maquila MTO) → clic **Continuar** para grabar igual.
- Si hay varias pestañas, selecciona la de SAP por URL que contenga `qashanada`.
- Para **abortar** un pedido a medias sin grabar: OK code `/n`.

## Scripts incluidos
- `scripts/launcher.js` — lanza Chromium headed persistente con CDP en :9222.
- `scripts/create-from-script.js` — flujo VA01 completo data-driven (`node create-from-script.js <json>`).
- `scripts/snap.js` — captura/verifica el estado de la pestaña SAP.
- `scripts/tc01-data.json` — datos de ejemplo (Sector 00). `scripts/tc01-data-sector10.json` — variante Sector 10.

## Salida
Número de pedido creado (p. ej. `4010030436`) o el mensaje de error de SAP si falla.
