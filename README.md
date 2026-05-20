# proyecto20052026

Cotizaciones de rollos de acero para el Área Metropolitana de Monterrey (AMM).

## Contenido

- `proveedores-acero-mty-*.csv` — listado de proveedores generado vía búsqueda web (skill `proveedores-acero-mty`).
- `rfq/<batch>/` — solicitudes de cotización (RFQ) en formato `.eml` listas para abrir en Outlook como drafts.
- `rfq-tracking*.csv` — seguimiento acumulativo de RFQs (status, precios recibidos, vigencia).

## Herramientas relacionadas (no incluidas en este repo)

Viven en `~/.claude/` del usuario, no se versionan aquí:

- **Skill** `proveedores-acero-mty` — busca proveedores en web y exporta CSV con razón social, RFC, dirección, teléfono, email y URL fuente. Filtros por tipo/calibre.
- **Agente** `cotizador-acero-mty` — consume el CSV de proveedores + especificaciones de un material y produce un `.eml` draft personalizado por proveedor, plus actualización de la hoja de tracking. Nunca envía correos — solo deja drafts para revisión humana.

## Reglas anti-invención

Tanto el skill como el agente están diseñados para **no inventar datos**:
- RFC ausente → `"No publicado"`, nunca un RFC fabricado.
- Precio ausente → `"Cotizar"`, nunca un precio estimado.
- Toda fila del CSV de proveedores incluye URL fuente verificable.
- El agente cotizador se detiene si su config tiene placeholders sin llenar.

## Flujo end-to-end

```
1. Skill busca proveedores  →  proveedores-acero-mty-YYYYMMDD-HHMM.csv
2. Agente lee el CSV + specs →  rfq/<batch>/*.eml + actualiza rfq-tracking.csv
3. Usuario abre cada .eml en Outlook, revisa, da clic en Enviar
4. Al recibir respuestas, actualiza columnas Precio/Vigencia en rfq-tracking.csv
```
