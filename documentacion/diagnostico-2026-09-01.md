# Diagnóstico Completo de F.U.R.I. — 2026-09-01

> Auditoría estática de TODO el código (apartados A→D), en orden: cimientos, capa de datos,
> pantallas y sistemas transversales. Hallazgos verificados con `archivo:linea`.
> No se modificó nada en esta fase.

---

## 0. El hallazgo mayor: documentación ↔ código desincronizados

> ✅ **RESUELTO 2026-09-01**: el usuario decidió eliminar el pizarrón ("el pizarrón ahora es la
> sección de notas"). C1 y C2 quedaron corregidos; las tablas SQLite/Supabase, `board_media_service`
> y las migraciones de board se removieron. Ver `historial.md` 2026-09-01. Los CRÍTICOS que
> dependían de esto ya no bloquean a los equipos.

El proyecto documenta como vivo un sistema que **no existe en el código**: el **Pizarrón v2**
completo (`lib/screens/pizarra_v2/`, `lib/providers/board_provider_v2.dart`) no está por ningún
lado. Quedan solo restos:

- Tablas SQLite huérfanas en `database_helper.dart:65-293` (`board_elements_v2`, `board_activity`, `board_tags`) — **ya removidas**
- `services/board_media_service.dart` — **código muerto** — **ya borrado**
- RPC `react_deck_card` + whitelist `toggle_reaction` que referencian `board_elements_v2` — **ya corregidas a `deck_cards.reactions`**
- `arquitectura.md`, `historial.md`, `auditoria-pizarron-v2.md`, `prompt-debugging-pizarron-v2.md`
  describen todo eso como si existiera

**Decisión pendiente**: resucitar el pizarrón o limpiar doc + tablas + RPC. Es prerrequisito para
varios hallazgos de abajo.

---

## 🔴 CRÍTICOS

| # | Hallazgo | Dónde |
|---|---------|-------|
| C1 | **`react_deck_card` opera sobre la tabla equivocada.** La migración la define sobre `board_elements_v2.data`; el schema maestro sobre `deck_cards.reactions`. Como ambas se ejecutaron con `CREATE OR REPLACE`, la desplegada depende del orden → riesgo real de reacciones del mazo escribiendo en la pizarra | `supabase/migration_reaction_rpc.sql:100-156` vs `supabase_schema.sql:789-812` |
| C2 | **Bloque "Pizarra" del Home navega a ruta inexistente.** `_openPizarra` hace `context.push(RouterRoutes.letters)` (`/letters`), que **no tiene GoRoute** (solo existe `/cartas`) | `lib/screens/home_screen.dart:365-367`, `lib/router.dart:52` |
| C3 | **`letters_screen_backup.dart` es código muerto completo** (24 KB, 0 imports) — duplica lógica y `catch (_) {}` | `lib/screens/letters_screen_backup.dart` |

---

## 🟠 ALTOS

### Datos / consistencia
- ~~**Comentarios de workouts con last-write-wins**~~ ✅ RESUELTO 2026-09-01 (Equipo 3): los comentarios
  ya NO se envían con el documento `social` completo; pasan por RPC `add_workout_comment` /
  `delete_workout_comment` con merge atómico. `lib/providers/workout_provider.dart`
- **`chat_typing` usada en Dart pero ausente del schema maestro** (solo en migración).
  `supabase_schema.sql` / `lib/providers/chat_provider.dart`
- **`class_schedule_provider.updateSchedule` no resetea `synced=1`** tras push exitoso → re-escritura
  redundante en cada `load()`. `lib/providers/class_schedule_provider.dart:150-164`
- **4 migraciones de calendario superpuestas** (source-of-truth fragmentado):
  `migration_calendar_full`, `migration_schedules_sync`, `migration_schedule_class_sync`, `migration_class_schedules`

### Seguridad
- **Clave privada completa del service account de Firebase hardcodeada** en `send-push/index.ts:8-35`
- **Anon key + URL del proyecto hardcodeadas** en 2 scripts SQL (`supabase_schema.sql:179-187`,
  `migration_push_categories.sql:34-42`)

### Código
- **Bot**: `encolar()` declara 2 parámetros pero ~20 call sites le pasan 6 (muertos/engañosos).
  `bot-furi/bot.js:538` vs `576-581`; y `descripcionLogro()` mapea solo 8 de los **13 logros** →
  notificaciones vacías. `bot.js:519-531, 1096`
- **IA inactiva**: `.suggest()` nunca se llama desde pantallas, y `studyTip/financeTip/...` devuelven
  strings fijas sin tocar el modelo Gemini. `lib/services/ai_service.dart`
- **Settings**: `context.goNamed(RouterRoutes.settings)` lanza porque **ninguna ruta registra `name:`**.
  `lib/screens/settings_screen.dart:52`
- **4 providers registrados pero muertos** (sin consumidores): `SyncProvider`, `StudyProvider`,
  `MenuProvider`, `ThemeProvider`. `lib/main.dart:190,191,203,204`
- **Monolitos**: `ejercicios_screen.dart` (~2200 líneas), `trivia_screen.dart` (~1100) — violan el
  patrón de separación ya aplicado al chat

---

## 🟡 MEDIOS (resumen)

- **`skill_visual` violado masivamente**: ~90 `BoxShadow` negros (prohibido) + ~100 semitransparencias
  (`Colors.white24`, `withValues(alpha:0.x)`, `black26`) en casi todas las pantallas
- **`catch (_) {}` silenciosos**: `letters_screen:85,127,230`, `metas_screen:74`, `retos_screen:70`,
  `nosotros` (varios)
- **`metas_screen:253`**: `Expanded` en `Column(min)` dentro de `SingleChildScrollView` →
  `unbounded height` latente; y `:329` usa SnackBar ROJO para un ÉXITO
- **`schedule_form`/`finanzas`**: TextFields en una sola línea gigante con `fillColor: white24` (ilegibles)
- **`.limit()` trunca silenciosamente**: `deck_provider` (200), `favorites_provider` (200),
  `gallery_provider` (50), `couple_achievements` (~15 queries pesadas sin dedupe)
- ~~**`notes_provider` solo-local**~~ ✅ RESUELTO 2026-09-01 (Equipo 3): las notas ahora se comparten con la pareja (sync Supabase offline-first). `lib/providers/notes_provider.dart`
- **Dependencias declaradas sin uso**: `table_calendar`, `url_launcher`, `font_awesome_flutter`,
  `material_design_icons_flutter`, `phosphor_flutter`, `flutter_svg`
- **Bot**: `npm install` en CI (debería ser `npm ci`), sin `timeout-minutes`, listeners de ACK nunca removidos

---

## 🟢 BAJOS / Notas

- `home_screen`: lista de 12 shortcuts duplicada (2 arrays) + `_confettiAt(0,0)` en `_onModeTap` (`:68`)
- `nosotros_screen:1046`: comentario colgado FUERA de la clase al final del archivo
- `notes_screen:17`: `GlobalKey _fabKey` inútil; borrado sin confirmación
- `login_screen`: pisa `AppState.identity` antes de confirmar contra Supabase (`:53`)
- `rewards_screen:158`: `const cost = 10` hardcodeado
- Varios `TextEditingController` sin `dispose` (metas/retos); `Future.delayed` sin cancelar (retos)
- Android: `EnableImpeller=false` permanente, firma debug en release, `usesCleartextTraffic=true`,
  `org.gradle.daemon=false`; release firmado con clave **debug** (`build.gradle.kts:34`)

---

## ✅ Lo que está bien (reforzar)

- Router GoRouter: **0 `Navigator.push` a pantallas completas** (solo `pop` legítimos en diálogos/sheets)
- Chat bien separado UI/lógica (`chat_style.dart` + `chat/widgets/`)
- 4 estados (LOADING/EMPTY/ERROR/DATA) bien en: chat, notes, galería, notificaciones, ejercicios,
  finanzas, favoritos, trivia, deck_overlay
- Merge offline-first (`cloudId` + `synced`) en schedule/class_schedule es sólido
- RPC de reacciones con optimista + reconciliación correcta
- Ventana dinámica + LID + ACK del bot bien resueltos

---

## 🎯 Prioridad de acción sugerida

1. Resolver la divergencia C1 (`react_deck_card`) — riesgo de datos cruzados ya.
2. Decidir el destino del pizarrón v2 (C2, C3, `board_media_service`, tablas huérfanas, doc stale).
3. Quitar secretos del repo (Firebase + anon key) a Deno.env/Vault.
4. Eliminar código muerto: `letters_screen_backup`, 4 providers muertos, deps sin usar.
5. Arreglar comentarios de workouts (last-write-wins) con la RPC.
6. Corregir `goNamed` (Settings) y los 2 monolitos.
7. Sesión de cumplimiento `skill_visual` (sombras + transparencias).
8. Sincronizar la documentación con el código real.
