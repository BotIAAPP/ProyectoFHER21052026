---
name: maquila-reejecutar-pruebas
description: Re-ejecuta las pruebas en SAP con datos variantes (p. ej. otro Sector o tras una corrección del consultor) reutilizando el flujo de creación de pedido, y registra el resultado en el log de errores. Úsalo cuando el usuario pida "re-ejecutar pruebas", "volver a probar", "probar Sector 10", "reintentar el caso".
---

# Re-ejecución de pruebas en SAP

Vuelve a correr el caso con una variante de datos y deja constancia del resultado.

## Procedimiento
1. **Reutiliza** el flujo del skill `maquila-crear-pedido` (scripts en `../maquila-crear-pedido/scripts/`).
2. **Prepara la variante** de datos: copia el JSON base y cambia lo que toque (p. ej. `sector` a `10`). Hay un ejemplo en `../maquila-crear-pedido/scripts/tc01-data-sector10.json`.
3. **Asegura el navegador/sesión** (ver `maquila-crear-pedido`): Chromium en :9222 + sesión SAP activa.
4. **Ejecuta:** `node ../maquila-crear-pedido/scripts/create-from-script.js <ruta-json-variante>`.
5. **Interpreta el resultado:**
   - Éxito → nuevo `Pedido de Maquila NNNN se ha grabado.`
   - Fallo conocido (Sector 10) → `No fue posible determinar esquema de cálculo`; el pedido no se valora ni graba. **Aborta** el pedido a medias con OK code `/n`.
6. **Registra** el resultado:
   - Si se creó documento → agrégalo a `log-documentos-creados.csv`.
   - Si falló → agrega una fila a `log-errores.csv` (con fecha de re-ejecución y estado "persiste / pendiente consultor").
   - Actualiza el reporte `resultados-pruebas-maquila-kmat.html` si aplica.
   - Mantén el BOM UTF-8 al reescribir los CSV (ver skill `maquila-resultados-pruebas`).

## Nota
El ciclo es iterativo: el escenario que depende del consultor (Sector 10) dará PASS solo después de que se apliquen las correcciones de datos maestros / esquema de cálculo (ver `maquila-instrucciones-consultor`).
