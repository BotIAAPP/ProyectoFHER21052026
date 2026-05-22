---
name: maquila-acta-visto-bueno
description: Genera el Acta de Visto Bueno / Aceptación de usuarios finales (documento HTML imprimible y firmable) que cierra la prueba UAT. Úsalo cuando el usuario pida "acta de visto bueno", "acta de aceptación", "documento de aceptación de usuarios finales", "sign-off".
---

# Acta de Visto Bueno / Aceptación de usuarios finales

Genera un documento formal HTML (imprimible a PDF, con casillas de dictamen y bloques de firma).

## Estructura del documento
1. **Cabecera** con logo Aliacer (`assets/aliacer-icono.png`), título y nº de documento/versión/fecha.
2. **Datos del acta**: proyecto, sistema (QAS, mandante), proceso/transacción, documento de referencia, ronda.
3. **Objeto**: constancia de aceptación por los usuarios finales.
4. **Resultados revisados** (tabla): escenarios y su estado (VALIDADO / PENDIENTE) con evidencia (nº de pedidos).
5. **Criterios de aceptación**: checklist con casillas marcadas / sin marcar.
6. **Dictamen**: tres opciones con casilla — Aprobado / **Aprobado con observaciones** / Rechazado — y la observación/condición (p. ej. corregir Sector 10 antes de productivo).
7. **Firmas de conformidad**: bloques (usuarios finales, líder de proyecto, consultor funcional).

## Implementación
- Tema claro, profesional, con `@media print` para imprimir/exportar a PDF limpio.
- Plantilla: `Proyecto-IA/acta-visto-bueno-maquila-kmat.html`. Reemplaza datos según la ronda.
- Verifica el render con Playwright (captura) antes de entregar.

## Salida
`acta-visto-bueno-maquila-kmat.html` en `Proyecto-IA/`.
