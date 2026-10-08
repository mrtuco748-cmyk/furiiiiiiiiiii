# Plan de trabajo en 3 equipos — F.U.R.I. (2026-09-01)

> Basado en `documentacion/diagnostico-2026-09-01.md`. Divide el trabajo en 3 equipos con
> **propiedad exclusiva de archivos**: ninguna IA toca un archivo de otro equipo, para trabajar
> en paralelo sin colisiones de merge.
>
> **Regla de oro para los 3 equipos**: NO editar archivos ajenos. Si un equipo necesita un cambio
> en un archivo de otro, lo anota en "pendientes de coordinación" y lo resuelve el dueño.
>
> **Verificación por equipo**: `flutter analyze` + `flutter test` (suite actual) al terminar.
> **Documentación**: cada equipo actualiza `docs/contexto/historial.md` con sus cambios.

---

## ✅ PRERREQUISITO — RESUELTO (2026-09-01)

**Destino del Pizarrón v2: ELIMINADO.** El usuario decidió que "el pizarrón ahora es la sección de
notas". Se limpió todo (ver `historial.md` 2026-09-01): botón del Home → `/notes`, tablas SQLite y
Supabase removidas, `react_deck_card` corregido sobre `deck_cards.reactions`, `board_media_service`
y migraciones de board borradas. **C1 y C2 quedan resueltos** y los equipos ya no dependen de esta
decisión. C3 (borrar `letters_screen_backup.dart`) sigue en el Equipo 2.

---

## 🟦 EQUIPO 1 — Cloud / Infraestructura / Backend

**Lema**: consistencia de la base de datos + seguridad + bot. **No toca `lib/`.**

| Prioridad | Tarea | Archivos |
|-----------|-------|----------|
| CRÍTICO | **C1: unificar `react_deck_card`** para que opere sobre `deck_cards.reactions` (espejar `supabase_schema.sql:789-812`), eliminar la versión que apunta a `board_elements_v2`, y alinear `toggle_reaction` (whitelist, `updated_at`, `USING` en vez de `%L`) | `supabase/migration_reaction_rpc.sql`, `supabase_schema.sql` |
| ALTO | **Incluir `chat_typing` en el schema maestro** (hoy solo vive en la migración) | `supabase_schema.sql`, `supabase/migration_chat_typing.sql` |
| ALTO | **Consolidar las 4 migraciones de calendario** en una sola fuente de verdad | `supabase/migration_calendar_full.sql`, `migration_schedules_sync.sql`, `migration_schedule_class_sync.sql`, `migration_class_schedules.sql` |
| ALTO | **Quitar secretos del repo**: service account de Firebase + anon key/URL → `Deno.env`/Vault. NO dejar keys en el código | `supabase/functions/send-push/index.ts`, `supabase_schema.sql`, `supabase/migration_push_categories.sql` |
| ALTO | **Bot**: arreglar firma de `encolar()` (2 params) o limpiar los ~20 call sites de 6 args; completar `descripcionLogro()` para los 5 logros nuevos | `bot-furi/bot.js` |
| MEDIO | CI del bot: `npm ci` en vez de `npm install`, `timeout-minutes`, remover listeners de ACK | `.github/workflows/bot-whatsapp.yml`, `bot-furi/bot.js` |
| MEDIO | Scripts de build: propagar exit code correcto en `build-all.ps1`, `upload-apk` debe fallar (exit 1) si no sube | `scripts/*.ps1` |

**Entrega**: 1 archivo SQL unificado de migraciones + schema master consistente + bot sin código
muerto + 0 secretos en el repo. Verificación: lectura del SQL + `node --check bot.js`.

---

## 🟨 EQUIPO 2 — Código muerto / Arquitectura de pantallas

**Lema**: limpiar el muerto y partir los monolitos. **No toca** providers de datos ni la DB.

| Prioridad | Tarea | Archivos |
|-----------|-------|----------|
| CRÍTICO | **C3: borrar `letters_screen_backup.dart`** (verificar 0 imports antes) | `lib/screens/letters_screen_backup.dart` |
| ~~CRÍTICO~~ | ~~C2: bloque "Pizarra" del Home~~ ✅ RESUELTO 2026-09-01 (ahora abre `/notes`) | ~~`home_screen.dart`, `router.dart`~~ |
| ALTO | **Eliminar 4 providers muertos** (`SyncProvider`, `StudyProvider`, `MenuProvider`, `ThemeProvider`) y sus registros | `lib/providers/sync_provider.dart`, `study_provider.dart`, `menu_provider.dart`, `theme_provider.dart`, `lib/main.dart` |
| ALTO | **Borrar `board_media_service.dart`** (código muerto) | `lib/services/board_media_service.dart` |
| ALTO | **Limpiar dependencias sin uso** (`table_calendar`, `url_launcher`, packs de iconos, `flutter_svg`; mover `flutter_launcher_icons` a dev_deps) | `pubspec.yaml` |
| ALTO | **Partir el monolito de `ejercicios_screen.dart`** (~2200 líneas) en pestañas/widgets (mismo patrón del chat: lógica + widgets separados) | `lib/screens/ejercicios/` |
| ALTO | **Partir el monolito de `trivia_screen.dart`** (~1100 líneas) | `lib/screens/trivia/` |
| ALTO | **Corregir `goNamed`** (Settings): agregar `name:` a las rutas del router o cambiar el call | `lib/screens/settings_screen.dart`, `lib/router.dart` |
| MEDIO | Home: dedupe de los 12 shortcuts (2 arrays), arreglar `_confettiAt(0,0)`, alias `final raw` redundante | `lib/screens/home_screen.dart` |

**Entrega**: código muerto eliminado, 2 monolitos partidos, router/navegación consistente.
Verificación: `flutter analyze` + `flutter test` + revisar que no queden imports rotos.

---

## 🟩 EQUIPO 3 — Consistencia de datos en la app + Estilo visual

**Lema**: corregir los bugs de consistencia de datos y cumplir `skill_visual`. **No toca** SQL, bot ni router.

| Prioridad | Tarea | Archivos |
|-----------|-------|----------|
| ALTO | **Comentarios de workouts**: pasar de update de documento `social` completo a una RPC/merge atómico (mismo patrón que reacciones) | `lib/providers/workout_provider.dart` (+ proponer SQL al Equipo 1 si hace falta) |
| ALTO | **`class_schedule_provider.updateSchedule`**: resetear `synced=1` tras push exitoso | `lib/providers/class_schedule_provider.dart`, `lib/database/database_helper.dart` |
| MEDIO | **`.limit()` que trunca silenciosamente** (`deck` 200, `favorites` 200, `gallery` 50) — paginar o quitar; `couple_achievements` con queries pesadas sin dedupe | `lib/providers/deck_provider.dart`, `favorites_provider.dart`, `gallery_provider.dart`, `couple_achievements_provider.dart` |
| MEDIO | **`notes_provider`**: ~~decidir si las notas deben compartirse con la pareja~~ ✅ RESUELTO (sync Supabase implementado, `migration_notes_sync.sql` propuesto) | `lib/providers/notes_provider.dart`, `lib/screens/notes/notes_screen.dart` |
| MEDIO | **`metas_screen`**: fix `Expanded`→unbounded height (`:253`), SnackBar rojo de éxito (`:329`), controllers sin dispose | `lib/screens/metas_screen.dart` |
| MEDIO | **`catch (_) {}` silenciosos** en pantallas → log con contexto o feedback | `letters_screen`, `metas_screen`, `retos_screen`, `nosotros_screen` |
| MEDIO | **Cumplimiento `skill_visual`** (sombras negras + semitransparencias) en TODAS las pantallas no asignadas a otro equipo | pantallas de `screens/` |
| BAJO | `notes_screen` GlobalKey `_fabKey` inútil, colores repetidos; `login_screen` orden de identidad; `rewards_screen` `cost` hardcodeado; `nosotros_screen` comentario colgado al final | varios |

**Entrega**: datos consistentes (comentarios sin race) + `skill_visual` cumplido en las pantallas asignadas.
Verificación: `flutter analyze` + `flutter test`.

---

## 📌 PENDIENTES DE COORDINACIÓN (cruzan equipos)

| Pendiente | Equipos involucrados | Resolución |
|-----------|----------------------|------------|
| ~~Destino del Pizarrón v2~~ ✅ RESUELTO 2026-09-01 | 1, 2 | Eliminado → el botón del Home abre Notas; whitelist de `toggle_reaction` y `react_deck_card` corregidas |
| ~~Tablas SQLite huérfanas de la pizarra en `database_helper.dart`~~ ✅ RESUELTO 2026-09-01 | 2 (decisión), 3 (dueño del archivo) | Removidas (`board_elements_v2`, `board_activity`, `board_tags`) de `onCreate` y migraciones |
| ~~Nueva RPC para comentarios de workouts~~ ✅ SQL listo (Equipo 3) | 1 (SQL), 3 (código) | Equipo 3 escribió `supabase/migration_workout_comments_rpc.sql` (add/delete_workout_comment) y rewireó `workout_provider.dart`. **✅ Y además las integró al schema maestro (sección 29c) y las ejecutó en prod** vía Management API. También `supabase/migration_notes_sync.sql` (sync de notas) integrado al schema maestro (sección 14, con `title` + RLS + realtime) y **ejecutado en prod**. |

---

## 🧪 Verificación global al cerrar los 3 equipos

```bash
flutter analyze
flutter test
node --check bot-furi/bot.js
```

- [ ] `flutter analyze` sin errores nuevos (baseline actual ~20 issues informativos)
- [ ] Suite de tests completa en verde
- [ ] `historial.md` actualizado por cada equipo
- [ ] `errores-conocidos.md` actualizado si se resolvieron bugs
- [ ] Documentación sincronizada con el código real (prerrequisito del pizarrón resuelto)
