---
name: maquila-resultados-pruebas
description: Genera el documento de resultados de pruebas UAT (reporte HTML) y los logs en CSV (log de documentos creados y log de errores) a partir de la ejecución de pruebas en SAP. Úsalo cuando el usuario pida "generar documento de resultados", "reporte UAT", "log de documentos creados", "log de errores".
---

# Documento de resultados de pruebas UAT + logs

Genera (a) un reporte HTML de resultados imprimible y (b) dos CSV de bitácora abribles en Excel.

## Entradas
- **Documentos creados:** por cada pedido → nº documento, caso, transacción, área de ventas, material, cantidad, valor neto, estado, fecha.
- **Errores/incidencias:** por cada uno → caso/paso, transacción, mensaje SAP exacto, severidad (ERROR / ADVERTENCIA / INFORMATIVO), causa y resolución.

## Procedimiento
1. **Reporte HTML.** Usa como plantilla `Proyecto-IA/resultados-pruebas-maquila-kmat.html`. Estructura: cabecera con logo Aliacer (`assets/aliacer-icono.png`), datos de la prueba, resumen ejecutivo (cards), **Log de documentos creados** (tabla), **Log de errores** (tabla con pills de severidad), observaciones/dictamen y firmas. Reemplaza los datos por los de la corrida. Tema claro, imprimible (CSS `@media print`).
2. **CSV.** Genera `log-documentos-creados.csv` y `log-errores.csv`.
   - CSV válido: entrecomilla los campos con comas; duplica las comillas internas (`""`).
   - **UTF-8 con BOM** para que Excel muestre bien los acentos. El Write tool NO pone BOM → después reescribe con PowerShell:
     `$t=[IO.File]::ReadAllText($f,[Text.Encoding]::UTF8); [IO.File]::WriteAllText($f,$t,(New-Object Text.UTF8Encoding($true)))`
   - En PowerShell inline, para acentos/`º`/`·` usa códigos `[char]` (p. ej. `[char]0x00F3` = ó, `0x00BA` = º, `0x00B7` = ·) y evita arrays `@(...)` con `+` y comas (colapsan a 1 elemento; parentiza cada elemento).
3. **Verifica** el render del HTML abriendo el archivo con Playwright y tomando captura (opcional pero recomendado).

## Salida
`resultados-pruebas-maquila-kmat.html`, `log-documentos-creados.csv`, `log-errores.csv` en `Proyecto-IA/`.
