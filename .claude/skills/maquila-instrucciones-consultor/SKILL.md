---
name: maquila-instrucciones-consultor
description: Genera un borrador de correo (.eml) con instrucciones al consultor funcional para corregir los errores detectados en las pruebas SAP. Úsalo cuando el usuario pida "instrucciones al consultor funcional", "correo al consultor", "pasar errores al consultor".
---

# Instrucciones al consultor funcional (.eml)

Genera un correo HTML como **borrador** para que el usuario lo revise y envíe desde Outlook.

## Formato del .eml (importante)
- Cabeceras: `To:` (vacío, lo llena el usuario), `Cc:`, `Subject:` **en ASCII sin acentos** (evita mojibake en el asunto), `X-Unsent: 1`, `MIME-Version: 1.0`, `Content-Type: text/html; charset=UTF-8`, `Content-Transfer-Encoding: 8bit`, línea en blanco, luego el cuerpo `<html>...`.
- El **cuerpo** sí lleva acentos (charset UTF-8). Estilos inline (Calibri), email-safe.
- **NO usar Outlook COM** (`New-Object -ComObject Outlook.Application`) — el entorno del usuario lo bloquea. El `.eml` con `X-Unsent: 1` abre como borrador con doble clic.

## Contenido recomendado
1. Saludo + contexto (proceso, ambiente QAS, caso probado).
2. **Incidencia principal** con el mensaje SAP exacto (blockquote).
3. Pregunta de alcance (¿el escenario problemático está en alcance?).
4. **Tabla de acciones** solicitadas con su transacción. Para el caso típico del Sector 10 (LM00/50/10): extender cliente (`BP/XD02`), determinación de esquema de cálculo (`OVKK`), asignación de área / procedimiento de precios del tipo de pedido (`OVXG`/`VOV8`), extensión del material a la división (`MM02`).
5. Incidencias informativas (solo confirmar).
6. **Caso de referencia que sí funciona** (p. ej. LM00/50/00 → pedido valorado).
7. Próximos pasos + adjuntos sugeridos (reporte de resultados, log de errores).
8. Firma.

## Plantilla y previsualización
- Plantilla: `Proyecto-IA/instrucciones-consultor-funcional-maquila-kmat.eml`.
- Para mostrarlo en "modo mensaje" (cabecera Para/Asunto/De + cuerpo): usar `pw/render-msg.js` (renderiza el .eml y captura).

## Salida
`instrucciones-consultor-funcional-maquila-kmat.eml` en `Proyecto-IA/`.
