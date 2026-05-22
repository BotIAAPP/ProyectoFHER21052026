---
name: maquila-notificacion-usuarios
description: Genera un borrador de correo (.eml) de notificación a usuarios clave con el resumen de resultados UAT para su análisis y de cara al visto bueno. Úsalo cuando el usuario pida "notificar a usuarios clave", "correo de resultados a usuarios", "avisar a usuarios clave".
---

# Notificación a usuarios clave (.eml)

Genera un correo HTML como **borrador** para revisar y enviar desde Outlook.

## Formato del .eml
Igual que el skill `maquila-instrucciones-consultor`: `To:` vacío, `Subject:` ASCII sin acentos, `X-Unsent: 1`, `Content-Type: text/html; charset=UTF-8`, cuerpo HTML con acentos y estilos inline. **No usar Outlook COM.**

## Contenido recomendado
1. Saludo a usuarios clave + contexto de la ronda UAT.
2. **Escenario validado** (p. ej. Sector 00) con bullets del alcance probado.
3. **Tabla de evidencia**: pedidos creados (nº, área, material, cantidad, valor, estado GRABADO).
4. **Pendiente** no bloqueante (p. ej. Sector 10 en gestión con el consultor).
5. **Solicitud**: revisar el reporte, enviar comentarios, agendar sesión de análisis de cara al visto bueno.
6. Adjuntos sugeridos (reporte de resultados + CSVs). Firma.

## Plantilla y previsualización
- Plantilla: `Proyecto-IA/notificacion-usuarios-clave-maquila-kmat.eml`.
- Modo mensaje (cabecera + cuerpo): `pw/render-msg.js`.

## Salida
`notificacion-usuarios-clave-maquila-kmat.eml` en `Proyecto-IA/`.
