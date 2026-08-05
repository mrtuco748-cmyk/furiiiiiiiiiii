# F.U.R.I. - Flutter App para Parejas

## REGLA #1: SIEMPRE leer documentación ANTES, actualizar DESPUÉS

Esta es la regla más importante del proyecto. DEBES seguirla en cada tarea sin excepción.

### ANTES de escribir una sola línea de código
1. Identifica qué área del proyecto vas a modificar
2. Lee los archivos relevantes en `docs/contexto/`:
   - `arquitectura.md` — para entender la estructura
   - `convenciones.md` — para seguir el estilo de código
   - `decisiones.md` — para no violar decisiones técnicas ya tomadas
   - `errores-conocidos.md` — para no reintroducir bugs ya resueltos
   - `historial.md` — para entender cambios recientes
3. Lee `skill_visual .md` SIEMPRE que toques cualquier archivo con UI
4. Lee `FURI-Nosotros-Skill.md` si trabajas en la pantalla Nosotros

### DESPUÉS de completar el código
1. Actualiza `docs/contexto/historial.md` — agrega una entrada con:
   - Fecha, tipo (BUGFIX/FEATURE/REFACTOR), título descriptivo
   - Resumen de cambios realizados
   - Lecciones aprendidas
   - Archivos impactados
2. Si el cambio afecta arquitectura, actualiza `arquitectura.md`
3. Si resolviste un bug, actualiza `errores-conocidos.md`
4. Si cambiaste UI, actualiza `skill_visual .md`
5. Si trabajaste en Nosotros, actualiza `FURI-Nosotros-Skill.md`
6. Si introdujiste nuevas entidades/tablas, actualiza `glosario.md`

## Documentación del proyecto

Toda la documentación del proyecto vive en:

- `docs/contexto/` — Arquitectura, convenciones, decisiones, errores conocidos, flujo de trabajo
- `documentacion/` — Documentación general, guías de estilo, planes
- `skill_visual .md` — Guía de estilo visual (brutalista modificado)
- `FURI-Nosotros-Skill.md` — Especificación de la pantalla Nosotros

### Archivos que siempre debes leer

- `docs/contexto/arquitectura.md` — Estructura del proyecto
- `docs/contexto/convenciones.md` — Convenciones de código
- `docs/contexto/decisiones.md` — Decisiones técnicas tomadas
- `docs/contexto/errores-conocidos.md` — Bugs y problemas conocidos
- `docs/contexto/forma-de-trabajo-con-el-usuario.md` — Cómo interactuar con el usuario
- `docs/contexto/flujo-de-trabajo.md` — Flujo de trabajo del proyecto
- `docs/contexto/glosario.md` — Términos y definiciones del proyecto
- `docs/contexto/historial.md` — Historial de cambios
- `docs/contexto/bot-whatsapp.md` — Documentación del bot de WhatsApp
- `skill_visual .md` — Reglas visuales: fondo=borde mismo color, sólido, redondo, sin negro puro

## Stack del proyecto

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
- **Plataformas**: Android, Windows
- **Usuarios**: Facu y Rocio (personalización por usuario)

## Comandos importantes

```bash
flutter pub get        # Instalar dependencias
flutter run            # Ejecutar en dispositivo conectado
flutter analyze        # Análisis estático
flutter test           # Ejecutar tests
```

## Reglas adicionales

- NUNCA hagas commit sin que el usuario lo pida explícitamente
- Antes de tocar UI, lee `skill_visual .md` — las reglas de estilo son obligatorias
- Si hay ambigüedad, pregunta antes de actuar
- Mantén la documentación sincronizada con el código

---

## RECORDATORIO OBLIGATORIO — NO IGNORAR

**Antes de responder o escribir código**, lee TODO `docs/contexto/`. No solo algunos archivos: TODOS. Esto incluye `arquitectura.md`, `convenciones.md`, `decisiones.md`, `errores-conocidos.md`, `historial.md`, `glosario.md`, `flujo-de-trabajo.md`, `forma-de-trabajo-con-el-usuario.md`, `bot-whatsapp.md`.

**Al terminar cualquier cambio de código**, actualiza como mínimo `docs/contexto/historial.md`. Si el cambio toca otra área de documentación, actualiza también ese archivo.

Esta regla no tiene excepciones. Si la ignoras, estás haciendo el trabajo mal.
