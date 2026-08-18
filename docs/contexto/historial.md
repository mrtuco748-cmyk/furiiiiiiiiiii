# Historial de Cambios y Aprendizajes

## [2026-08-17] - FEATURE - Calendario completo: eventos por día, gestión de tipos y recordatorios programados (port desde Gastronomia-App)
**Resumen**: Se portaron a F.U.R.I las funciones de calendario/clases/eventos de Gastronomia-App que faltaban: pantalla de eventos por día con navegación por fecha, gestión de tipos de clase y de evento (crear/editar/borrar con color e icono), campo Profesor en el formulario de evento, y recordatorios locales programados (eventos: 1h antes + al empezar; clases: semanal recurrente 1h antes). Se conectaron los accesos desde el calendario (botones Clases + Día) y se rescató `ClassBoardScreen`, que era código muerto (nadie navegaba a él).
**Cambios realizados**:
- `pubspec.yaml`: + `flutter_timezone: ^4.1.0` (nombre IANA de la zona del dispositivo para `zonedSchedule`).
- `lib/services/notification_service.dart`: nuevos `scheduleNotification()` (`zonedSchedule` con `AndroidScheduleMode.inexactAllowWhileIdle` + `_ensureTz()` con flutter_timezone y fallback por offset) y `cancel(id)`. Todo en try/catch: en desktop `zonedSchedule` no está implementado → no-op seguro.
- `lib/services/event_notification_service.dart` (nuevo): `specsForEvent()` lógica pura (1h antes + al empezar; ids `100000+id` y `100000+id+1`), `rescheduleAll()` (cancela los vigentes y reprograma), `cancelForEvent()`.
- `lib/services/class_notification_service.dart` (nuevo): `nextOccurrence()` (próxima ocurrencia semanal, convención Dart `weekday` 1=Lun..7=Dom), `specsForClass()` (1h antes con `matchDateTimeComponents: dayOfWeekAndTime`, id `200000+id`), `rescheduleAll()`.
- `lib/providers/schedule_provider.dart` y `class_schedule_provider.dart`: `_rescheduleNotifs()` después de load/add/update/delete y de los eventos realtime. Decisión del usuario: recordatorios para TODOS los eventos y clases (calendario compartido — ambos dispositivos avisan todo).
- `lib/screens/calendar/daily_events_screen.dart` (nuevo): lista de eventos fechados + clases recurrentes del día; navegación con chevrons + date picker; card de evento con icono/color del tipo, tap=editar, long-press=borrar con confirmación; card de clase → abre `ClassBoardScreen`; estados LOADING/EMPTY/ERROR/DATA; estilo brutalista (ConcretePainter, TapTile, cian #00D4FF).
- `lib/screens/calendar/calendar_home_screen.dart`: botones "Día" y "Clases" en la barra de mes (abren `DailyEventsScreen` y `ClassBoardScreen`); limpieza de warnings preexistentes del archivo.
- `lib/screens/calendar/class_board_screen.dart`: botón gestión de tipos de clase (crear con color picker de 16 colores, editar nombre/color, borrar); diálogo de clase ampliado con hora fin y profesor; al editar se preservan `cloudId`/`userId`/`color` (antes se perdían al reconstruir el objeto); botón settings dentro del diálogo.
- `lib/screens/calendar/schedule_form_screen.dart`: campo Profesor/Instructor; gestión de tipos de evento (crear con color + picker de 30 iconos, borrar); fecha y horas ahora muestran su valor (antes solo iconos); `_backBtn` conectado al Stack (el form no tenía forma de cancelar en desktop).
- `lib/providers/class_type_provider.dart` + `lib/database/database_helper.dart`: defaults "Gastronomía 1"/"Pastelería 1" → "Clase" (cian) + "Práctico" (verde lima). Solo aplica a instalaciones nuevas; las existentes se editan con la nueva UI de gestión.
- `lib/main.dart`: `initializeDateFormatting('es')` para `DateFormat` con locale es.
- Tests TDD: `test/services/event_notification_service_test.dart` (5) + `test/services/class_notification_service_test.dart` (8). Total 13 nuevos; suite completa 152 verdes. Build Windows release verificado (exe completo con `flutter_timezone_plugin.dll`).
**Lecciones**:
- flutter_local_notifications **18.0.1** usa API posicional: `zonedSchedule(id, title, body, scheduledDate, details, {...})` y `cancel(id)`; la API con named parameters es de v19+. "Too few positional arguments" al compilar delata la versión vieja.
- timezone 0.10.1: `Location(name, transitionAt, transitionZone, zones)` pide `List<int>` de transiciones e índices, y `TimeZone(offset, {isDst, abbreviation})`. Fallback por offset: `Location('device-local', [minTime], [0], [TimeZone(offset.inSeconds, isDst: false, abbreviation: 'loc')])` (mismo patrón que `_UTC` del paquete).
- `tz.local` por defecto es UTC: sin setear la zona del dispositivo (flutter_timezone) los recordatorios quedan desfasados por el offset. El fallback por offset cubre Argentina (sin DST desde 2010).
- Los ids de notificación de eventos y clases deben vivir en namespaces separados (SQLite autoincrement por tabla → ids repetidos): eventos 100000+, clases 200000+.
- El exe en uso bloquea el linker (LNK1104) — cerrar la app antes de `flutter build windows --release`.
- TRK0005 (cl.exe no encontrado) vuelve a aparecer cuando un plugin nuevo fuerza rebuild CMake: activar `vcvarsall.bat amd64` antes del build.
- Un helper de test con `id ?? 3` no puede testear el caso "id null": el default enmascara el null. Recibir `int?` y dejar que el caso de prueba construya el objeto explícito.
**Impacto**: `pubspec.yaml`, `notification_service.dart`, 2 servicios nuevos, 2 providers, 4 screens de calendario, `class_type_provider.dart`, `database_helper.dart`, `main.dart`, 2 archivos de test, docs.
**Relacionado con**: D-3 (SQLite), D-2 (Supabase), D-4 (skill_visual), errores-conocidos (TRK0005/LNK1104), glosario (tipos de evento/clase).

## [2026-08-17] - FEATURE - Sección Ejercicios: botón pesa, plan semanal, retos y stats
**Resumen**: El botón del Home con icono de planta (Icons.spa, que solo lanzaba confeti) ahora es una pesa (Icons.fitness_center) en verde lima #39FF14 que abre la nueva pantalla "Ejercicios". Sección compartida con 4 pestañas: Hoy (plan semanal por día con rutinas y marcas F/R), Ejercicios (registros con historial de pesos, reacciones y comentarios), Retos (aprobación y completado conjuntos) y Stats (rachas individuales, sesiones por semana, grupos musculares). Sincronizada con Supabase + realtime; el bot de WhatsApp avisa ejercicios nuevos, sesiones completadas, retos y racha rota.
**Cambios realizados**:
- `lib/models/workout_social.dart` (nuevo): `WorkoutSocial` + `WorkoutComment` — reacciones (max 5 keys, 1 por usuario, se mueve entre keys como el chat) y comentarios (delete en cascada de replies) embebidos en `social` JSONB. `mergeReactions` (unión de user_ids por key) y `mergeComments` (unión por id) para el realtime — evita el race de reacciones concurrentes (lección del pizarrón BUG 2).
- `lib/models/workout_log.dart` (nuevo): registro de ejercicio (nombre obligatorio; series/reps/peso/descanso/grupo/notas opcionales), `loggedOn`, `summary` ("4x10 @ 60kg"), social embebido, copyWith con clears.
- `lib/models/workout_routine.dart` (nuevo): rutina con `dayOfWeek` (1-7) y `items` JSONB (`RoutineItem`).
- `lib/models/workout_completion.dart` (nuevo): marca "entrené este día" por persona.
- `lib/models/workout_challenge.dart` (nuevo): reto con `approvedBy`/`completedBy` (ambos deben aprobar/completar — 2 personas), toggle sin duplicados.
- `lib/models/workout_stats.dart` (nuevo): lógica pura — `streakFor` (días consecutivos hasta hoy/ayer), `weightHistoryFor`, `lastWeightFor`, `sessionsThisWeek/LastWeek`, `distinctExerciseNames`, `muscleGroupCounts`.
- `lib/providers/workout_provider.dart` (nuevo): CRUD de las 4 tablas + realtime con merge social, `toggleCompletion` (marca/desmarca por user), `toggleChallengeApproval/Completion`, getters de dominio (streaks, stats). Registrado en `lib/main.dart` (15º provider).
- `lib/screens/ejercicios/ejercicios_screen.dart` (nuevo, ~1900 líneas): 4 pestañas con chips verde lima (#39FF14 sobre #0E3A0E), header + tabs + FAB contextual (rutina/ejercicio/reto). Hoy: semana completa (LUN-DOM) con rutina del día, items tap=registrar pre-rellenado, badges F/R de completado, racha en cabecera. Ejercicios: cards con autor, summary, reacciones; tap=detalle (evolución de peso + comentarios), long-press=reacciones. Retos: estado de aprobación/completado por persona, sheet de acciones. Stats: rachas, sesiones, grupos. Estados loading/empty/error/data; skill_visual (fondo=borde, redondo, sin negro puro, botones con iconos).
- `lib/screens/home_screen.dart`: `bottomBtn(const Color(0xFF39FF14), Icons.fitness_center, const Color(0xFF062B06), 5, _openEjercicios)` — reemplaza el botón spa/confeti; `_openEjercicios` sin confeti.
- `supabase/migration_workouts.sql` (nuevo): tablas `workout_logs`, `workout_routines`, `workout_completions` (UNIQUE user+date+routine), `workout_challenges` + índices + RLS full access + GRANTs + publicación realtime. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: tablas #25-28 + índices + RLS + policies.
- `bot-furi/bot.js`: categorías #16 workout_logs (nuevo ejercicio), #17 workout_completions (sesión completada), #18 workout_challenges (creado/aprobado/completado), #19 racha rota (streak >= 3 y no entrenó hoy ni ayer; tracking `streak-{uuid}-{fecha}`). Helper `diasConsecutivos`.
- Tests TDD: `workout_log_test` (10), `workout_routine_test` (5), `workout_challenge_test` (7), `workout_social_test` (7), `workout_stats_test` (9). Total 38 nuevos; suite completa 152 verdes.
**Lecciones**:
- El comportamiento de reacciones del proyecto (chat) es 1 reacción ACTIVA por usuario: al reaccionar con otra key, la reacción se MUEVE. Los tests que asumían "5 keys del mismo usuario" fallaron y se ajustaron al comportamiento real.
- `WorkoutSocial` era una clase sin constructor `const` pero los tests la usaban como `const WorkoutSocial(...)` → error "Couldn't find constructor" que en realidad era import faltante en el test (la clase vive en workout_social.dart, no se re-exporta desde workout_challenge.dart).
- Lambdas pasadas a `Future<void> Function(String)` fallan si no reciben el parámetro; y `StateSetter` (de StatefulBuilder) no es asignable a `void Function()` — envolver con `() => setSheetState(() {})`.
- `'$series\x$reps'` en Dart es trampa: `\x` inicia un escape hex. Usar `'$series' 'x' '$reps'` (literales adyacentes) o `${series}x${reps}`.
- En la app los infos `use_build_context_synchronously` se silencian con `if (!mounted) return;` después del await del dialog, patrón ya usado en favoritos.
**Impacto**: 6 modelos nuevos, 1 provider nuevo, 1 pantalla nueva, `main.dart`, `home_screen.dart`, `supabase/migration_workouts.sql` (nuevo), `supabase_schema.sql`, `bot-furi/bot.js`, 5 archivos de test, docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot), errores-conocidos (race reacciones JSONB), skill-pantallas, glosario, bot-whatsapp.

## [2026-08-17] - FEATURE - Mazo: tarjetas swipe tipo Tinder (ideas, chistes, poemas, recetas, retos, random, sueño, me pasó)
**Resumen**: Nueva sección "Mazo" con tarjetas creadas por Facu y Rocio que se deslizan en 4 direcciones: ➡️ me encanta, ⬅️ no me gusta, ⬇️ me gusta, ⬆️ meh. Al entrar a la app, si hay tarjetas sin deslizar, aparece el overlay encima del Home (con X para cerrar). Hay MATCH cuando ambos dieron me encanta a la misma tarjeta → pantalla especial "FURI!!" con confetti. Las tarjetas ya deslizadas se pueden re-deslizar desde el historial. El bot de WhatsApp avisa tarjeta nueva (a la pareja) y match (a ambos).
**Cambios realizados**:
- `supabase/migration_deck_cards.sql` (nuevo): tabla `deck_cards` (id, category, content, created_by, reactions JSONB `{"user_id": "encanta"|"me_gusta"|"meh"|"no_me_gusta"}`, created_at, updated_at) + índices + RLS full access + publicación realtime. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: agregada tabla `deck_cards` (#24) con índice, RLS y policy.
- `lib/models/deck_card.dart` (nuevo): `DeckReaction` (4 valores), `DeckCategory` (8 categorías), `DeckCard` con `toMap`/`fromMap` (reacciones JSONB tolerantes), `withReaction` (inmutable), `mergedReactions`/`mergedFromCloud` (merge anti-race: las reacciones locales pisan a las cloud del mismo user), `isMatch` (>=2 reacciones y todas encanta).
- `lib/providers/deck_provider.dart` (nuevo): `load()` (Supabase + realtime `deck_cards_changes`), `pendingFor`/`historyFor` (filtran por reacción del usuario activo), `matches`/`matchCount`, `add()`, `react()` (update optimista + JSONB), `delete()`, `applyCloudCards()` (lógica pura: merge cloud+local y detección de transición a match → `pendingMatch`), `consumeMatch()`. Registrado en `lib/main.dart` (14º provider).
- `lib/screens/mazo/deck_style.dart` (nuevo): estilo por categoría (emoji, label, color brutalista) y por reacción (label, color, icono, dirección).
- `lib/screens/mazo/deck_overlay.dart` (nuevo): overlay encima del Home con stack de 3 tarjetas (escala descendente), drag en 4 direcciones con sello de reacción, rotación progresiva, snap-back y salida animada (160ms) → `pv.react()`. Header con contador de pendientes, botón historial, botón + crear y X cerrar. 4 botones de acción (X roja, pulgar amarillo, meh gris, corazón verde) para desktop/sin drag. Estados LOADING/EMPTY/ERROR/DATA. Modo re-swipe con banner "deslizá de nuevo".
- `lib/screens/mazo/create_deck_card_modal.dart` (nuevo): dialog con chips de las 8 categorías (fondo=borde, check en la seleccionada), TextField multilinea (max 1000), botón guardar con icono check que se habilita al escribir (listener del controller).
- `lib/screens/mazo/deck_history_sheet.dart` (nuevo): bottom sheet con las tarjetas ya deslizadas: mi reacción + reacciones de la pareja + botón re-deslizar (vuelve al overlay en modo re-swipe de esa tarjeta).
- `lib/screens/mazo/deck_match_overlay.dart` (nuevo): pantalla "FURI!!" gigante en color de la categoría + tarjeta + confetti (flutter_confetti) + botón seguir. No dice "match" (pedido del usuario).
- `lib/screens/home_screen.dart`: `_initDeck()` en initState (post frame: load + abrir overlay si hay pendientes); `_openMazo()` en el bloque con iconos ▶/🖼️/▶ del Home (antes decorativo); Stack del Home ahora monta `DeckOverlay` (si `_showDeck`) y `DeckMatchOverlay` vía `Consumer<DeckProvider>` cuando hay `pendingMatch` (encima de todo, incluso sin deck abierto).
- `bot-furi/bot.js`: categoría #14 `deck_cards` (tarjeta nueva en última hora → avisa a la pareja del creador, con categoría y preview de 90 chars) y categoría #15 `deck match` (reactions con >=2 valores todos 'encanta' y updated_at en última hora → avisa a AMBOS con "🃏 *FURI!!*"). Tracking keys `deck-{id}` y `deckmatch-{id}`.
- Tests TDD: `test/models/deck_card_test.dart` (12 tests) + `test/providers/deck_provider_test.dart` (13 tests). Total 25 nuevos, todos verdes.
**Lecciones**:
- El JSONB de reacciones se envía entero en cada update: dos reacciones simultáneas (Facu y Rocio) se pisan. El fix usado (como en el pizarrón): merge en el callback realtime con las reacciones locales ganando para el mismo user (`mergedFromCloud`), porque mi UPDATE en vuelo aún no está en el server y un `load()` completo lo borraría de la vista.
- La detección de match debe ser por TRANSICIÓN (local no-match → merged match), no por estado: si no, cada reload/realtime de una carta ya matcheada volvería a disparar la pantalla "FURI!!".
- `pendingFor(null)` devuelve todas las cartas (sin identidad cargada no se puede filtrar) — útil para tests.
- Un `showDialog`/bottom sheet que se habilita según el texto necesita `_ctrl.addListener(() => setState(() {}))`; evaluar `_ctrl.text` una sola vez en el build deja el botón congelado.
**Impacto**: `supabase/migration_deck_cards.sql` (nuevo), `supabase_schema.sql`, `lib/models/deck_card.dart` (nuevo), `lib/providers/deck_provider.dart` (nuevo), `lib/screens/mazo/` (5 archivos nuevos), `lib/main.dart`, `lib/screens/home_screen.dart`, `bot-furi/bot.js`, tests (2 archivos nuevos), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot), errores-conocidos (race de reacciones JSONB), skill-pantallas, glosario, bot-whatsapp.

## [2026-08-14] - FEATURE+BUGFIX - Calendario compartido: ambos usuarios ven las fechas del otro
**Resumen**: El calendario no compartía eventos entre Facu y Rocio. Cada dispositivo solo veía lo guardado en su SQLite local. Fix: sync bidireccional completo de `schedules` (eventos fechados) y `class_schedules` (clases recurrentes) con Supabase, merge por cloudId, realtime, y migración SQL que arregla la causa raíz del fallo silencioso de los INSERT.
**Cambios realizados**:
- `lib/models/schedule.dart`: nuevo campo `cloudId` (PK cloud vs id local), `toSupabaseMap()` (`user_id` snake_case, sin id local, fecha YYYY-MM-DD), `fromCloudRow()` (id del servidor → cloudId), `fromMap` tolera `user_id`/`userId` y filas legacy.
- `lib/models/class_schedule.dart`: nuevo `fromCloudRow()`.
- `lib/providers/schedule_provider.dart`: reescrito — `loadSchedules()` hace push de filas locales sin cloudId, pull de TODAS las filas cloud, merge por cloudId (updatedAt decide conflictos; filas cloud ausentes en local se borran = delete de la pareja). `addSchedule`/`updateSchedule`/`deleteSchedule` sincronizan con Supabase (update/delete usan cloudId como PK cloud, no el id local). Realtime `schedules_sync` (INSERT/UPDATE/DELETE) con `ConflictAlgorithm.ignore` + índice único por cloudId para no duplicar filas en la carrera realtime vs. insert propio.
- `lib/providers/class_schedule_provider.dart`: `loadSchedules()` ahora también hace pull+merge del cloud (las clases de la pareja aparecen). `updateSchedule` resuelve el cloudId desde la BD local (antes hacía INSERT duplicado cuando el objeto no traía cloudId). Realtime `class_schedules_sync`.
- `lib/providers/schedule_sync.dart` (nuevo): `buildScheduleSyncPlan()` — lógica pura del merge (testeable).
- `lib/database/database_helper.dart`: SQLite v8 — columna `cloudId` en `schedules` + índices únicos `idx_schedules_cloudId`/`idx_class_schedules_cloudId` (WHERE cloudId IS NOT NULL). `insert()` acepta `conflictAlgorithm`.
- `lib/screens/calendar/schedule_form_screen.dart`: al guardar setea `userId: AppState.identity` (colores F/R por celda).
- `supabase/migration_schedules_sync.sql` (nuevo): `user_id` en `schedules`, `color` → BIGINT, y agrega `schedules` + `class_schedules` a la publicación realtime. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: `schedules` actualizado (`user_id`, `color BIGINT DEFAULT 4286262670`).
- Bugfix colateral: `lib/screens/pizarra_v2/pizarra_screen_v2.dart` tenía un error de sintaxis preexistente (declaración `final world` dentro de un collection-if) que rompía la compilación de TODA la app; se hoisteó el cálculo al builder del Consumer.
- Tests: `test/models/schedule_test.dart` (5) + `test/providers/schedule_sync_test.dart` (5). Total 77 verdes.
**Lecciones**:
- El INSERT a Supabase fallaba en silencio desde siempre: `color` mandaba un ARGB de Flutter (4286262670) que excede el `INTEGER` de Postgres → error 22003 tragado por el try/catch → los eventos nunca llegaban a la nube. Mismo bug ya resuelto en `class_schedules`.
- El id local de SQLite (autoincrement) nunca coincide con el BIGSERIAL de Supabase: hay que persistir un `cloudId` aparte y usarlo como PK cloud en update/delete.
- Merge por cloudId con `updatedAt` como árbitro cubre el caso "la pareja borró algo": fila local con cloudId ausente en cloud = delete remoto.
- En la carrera "realtime INSERT propio vs insert local", un índice único sobre cloudId + `ConflictAlgorithm.ignore` evita duplicados.
**Impacto**: `schedule.dart`, `class_schedule.dart`, `schedule_provider.dart`, `class_schedule_provider.dart`, `schedule_sync.dart` (nuevo), `database_helper.dart`, `schedule_form_screen.dart`, `migration_schedules_sync.sql` (nuevo), `supabase_schema.sql`, `pizarra_screen_v2.dart`, tests.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), errores-conocidos (calendar sync), glosario (Schedule).

## [2026-08-12] - BUGFIX - Fixes de auditoría del pizarrón v2 (10 bugs: 3 críticos + 4 altos + 3 medios)
**Resumen**: Tras la auditoría completa del pizarrón v2 (19 bugs encontrados en `documentacion/auditoria-pizarron-v2.md`), se aplicaron los fixes por prioridad: BUG 1 (offline sync), BUG 2 (reacciones race), BUG 3 (conectores huérfanos), BUG 4 (drag jitter), BUG 5 (isLocked), BUG 6 (reacción sin feedback), BUG 7 (comentario huérfano), BUG 8 (búsqueda cross-board), BUG 9 (retry cloud writes), BUG 12 (comment length). 67 tests verdes, `flutter analyze` sin errores nuevos.
**Cambios realizados**:
- `lib/providers/board_provider_v2.dart`:
  - **BUG 1+9 (CRÍTICO+ALTO)**: `_saveToLocal` ahora acepta `syncedFlag` para marcar elementos como no sincronizados. Nuevo `_markUnsynced(id)` que setea `synced=0` en SQLite. `moveLocal()` y `update()` marcan `synced=0` cuando están offline o cuando el cloud write del debounce timer falla. Tras un cloud write exitoso, marcan `synced=1`. `_pushUnsyncedToCloud()` ahora diferencia entre elementos sin id cloud (INSERT) y elementos con id cloud pero modificados offline (UPDATE). Import de `board_element_data.dart` para `ConnectorData`.
  - **BUG 5 (ALTO)**: `update()` y `moveLocal()` ahora chequean `isLocked` y retornan early si el elemento está bloqueado.
  - **BUG 2 (CRÍTICO)**: El callback de realtime ahora mergeea las reacciones del cloud con las locales (union de user_ids por key) en vez de reemplazar el data completo. Nuevo helper `_reactionsOf(data)`.
  - **BUG 3 (CRÍTICO)**: `delete()` ahora busca y elimina en cascada los conectores cuyo `fromId` o `toId` apuntan al elemento borrado (memoria + SQLite + cloud).
  - **BUG 8**: Nuevo `loadSearchPool()` que carga TODOS los elementos no archivados de SQLite sin filtro de `board_id`, para búsqueda cross-board.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`:
  - **BUG 4 (ALTO)**: `onPanUpdate` ahora usa `live.x`/`live.y` del elemento vivo en vez del snapshot del build. Previene jitter en drags rápidos.
  - **BUG 8**: `BoardSearchPanel` ahora recibe `provider` (BoardProviderV2) en vez de `elements` (List). `_goToElement` ahora cambia al tablero del elemento si está en otro board (`pv.setBoard(el.boardId)`).
- `lib/screens/pizarra_v2/widgets/board_search_panel.dart`:
  - **BUG 8**: Convertido de StatelessWidget a StatefulWidget. Carga el pool cross-board en `initState` con `provider.loadSearchPool()` (async). Hint cambiado a "Buscar en todos los tableros...". Estado de loading con spinner verde.
- `lib/screens/pizarra_v2/widgets/board_element_options.dart`:
  - **BUG 6 (ALTO)**: `react()` ahora detecta si `withToggledReaction` devuelve la misma referencia (`identical()`) — indica límite de 5 reacciones alcanzado. Muestra SnackBar "Máximo 5 reacciones por elemento" + haptic feedback. También relee el elemento vivo (`pv.findById`) para usar data fresca.
  - **BUG 7 (ALTO)**: `withCommentRemoved()` ahora hace cascade-delete: borra el comentario Y todas sus respuestas (donde `replyToId == commentId`). Previere respuestas huérfanas sin contexto.
  - **BUG 12 (MEDIO)**: TextField de comentarios ahora tiene `maxLength: 1000`.
**Lecciones**:
- `withToggledReaction` devuelve la misma referencia `data` cuando alcanza el límite de 5 reacciones — `identical(newData, live.data)` detecta este caso sin cambiar el return type.
- Un elemento modificado offline ya tiene un id cloud pero `synced=1` del sync inicial. Hay que marcarlo `synced=0` explícitamente al guardar local offline, y que `_pushUnsyncedToCloud` haga UPDATE (no INSERT) para los que ya tienen id.
- El merge de reacciones en realtime es necesario porque el `data` JSONB se envía entero en cada update — dos updates concurrentes pisan el campo completo. El merge union los user_ids por key preserva ambas reacciones.
- Los conectores referencian elementos por `fromId`/`toId` en `data` JSONB — borrar un elemento sin limpiar sus conectores deja conectores fantasma en la BD.
- El drag jitter ocurría porque `onPanUpdate` usaba `el.x` (snapshot del build) + delta del frame actual. Si entre pan events no llegaba un rebuild, todos los events acumulaban delta sobre la posición vieja. Usar `_liveElement(pv, el).x` resuelve el problema.
- `isLocked` se persistía pero nunca se validaba — agregar el check en `update()` y `moveLocal()` es suficiente (el delete se mantiene con confirmación UI).
**Impacto**: `board_provider_v2.dart`, `pizarra_screen_v2.dart`, `board_search_panel.dart`, `board_element_options.dart`. 67 tests verdes, `flutter analyze` 0 errores nuevos.
**Relacionado con**: `documentacion/auditoria-pizarron-v2.md`, D-2 (Supabase), D-3 (SQLite), errores-conocidos

## [2026-08-12] - DECISION - Etapa 5 del pizarrón cancelada (undo/redo global, doble tap, atajos, exportar)
**Resumen**: El usuario canceló la Etapa 5 (undo/redo global Ctrl+Z/Y, doble tap en espacio vacío para crear nota, atajos desktop, exportar PNG/PDF). No había código implementado de esa etapa — solo referencias en la spec.
**Cambios realizados**:
- `skill-pantallas.md`: eliminados de la spec del pizarrón "Doble tap vacío: Crear nota nueva", "Undo/Redo: Ctrl+Z/Ctrl+Y + botón en mobile", "Atajos desktop", "Exportar: PNG + PDF". Agregados a la sección "NO incluido".
**Nota**: El botón undo del editor de dibujo (`board_drawing_editor.dart`) se mantiene — es deshacer el último stroke del dibujo (feature del editor desde la Etapa 2b), no el undo/redo global del tablero que era parte de la Etapa 5.
**Impacto**: `skill-pantallas.md`
**Relacionado con**: plan de etapas del pizarrón

## [2026-08-12] - FEATURE - Pizarrón v2: Etapa 4 (sub-tableros + separadores + migración board_v2)
**Resumen**: Se agregaron sub-tableros (tableros anidados que se abren con tap y tienen botón Volver), separadores manuales horizontales/verticales, y la migración SQL que crea `board_elements_v2` + `boards` en Supabase (el sync cloud de la pizarra v2 nunca funcionó porque la tabla no existía en prod).
**Cambios realizados**:
- `supabase/migration_board_v2.sql` (nuevo): crea `board_elements_v2` (espejo del schema SQLite local: type, title, content, x/y, width/height, rotation, color, text_color, font_family, font_size, text_align, is_bold/italic/underline, emoji_header, tags JSONB, priority, assigned_to, user_id, status, is_collapsed/locked/archived/new, board_id, z, data JSONB, timestamps), `boards` (id BIGSERIAL, name, parent_id, created_at) con raíz id=1 "Pizarra", RLS full access, GRANTs, e `ALTER PUBLICATION supabase_realtime ADD TABLE board_elements_v2` para el realtime. Idempotente. **PENDIENTE ejecutar en SQL Editor de Supabase** — sin esto el sync cloud sigue fallando en silencio.
- `lib/providers/board_provider_v2.dart`: `_boards` + getters `boards`/`boardName`/`parentBoardId`; `loadBoards()` (cargado en `load()`); `createBoard(name, parentId)` (insert + reload); `goBackBoard()` (setBoard al padre).
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: 2 herramientas nuevas — Sub-tablero (folder, morado) y Separador (remove, violeta).
- `lib/screens/pizarra_v2/widgets/board_header.dart`: en modo canvas el título muestra `provider.boardName` (breadcrumb del tablero actual) en vez de "Pizarra".
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: `_createSubBoard()` (dialog de nombre → `createBoard` → agrega elemento `subBoard` con `SubBoardData{boardId}`), `_openSubBoard()` (tap → `setBoard` + centra el canvas), `_createSeparator()`, `_toggleSeparator()` (tap cambia orientación horizontal/vertical), botón "Volver" arriba-izquierda cuando `parentBoardId != null`, renders `_subBoardBody` (folder + nombre + chevron) y `_separatorBody` (línea de color). Quitado el `BoardZoomSlider` (pedido del usuario).
**Lecciones**:
- El sync cloud de la pizarra v2 nunca había funcionado: `board_elements_v2` solo existía en SQLite local. Cualquier feature "realtime" del pizarrón depende de ejecutar la migración en prod.
- Los sub-tableros reutilizan el `board_id` que ya estaba en el modelo y en el provider (`setBoard` + `load()` filtran por tablero); solo faltaba la tabla `boards` y el flujo de creación.
- El separador guarda su orientación en `data['orientation']` y el tap lo rota intercambiando width/height.
**Impacto**: `migration_board_v2.sql` (nuevo), `board_provider_v2.dart`, `board_tools_menu.dart`, `board_header.dart`, `pizarra_screen_v2.dart`
**Relacionado con**: skill-pantallas.md (spec pizarrón — sub-tableros, breadcrumb, separadores), D-2 (Supabase), Etapa 4 del plan

## [2026-08-12] - FEATURE - Pizarrón v2: Etapa 3 (reacciones + comentarios + badges F/R + badge NUEVO)
**Resumen**: Cada elemento del pizarrón ahora tiene reacciones por long-press (mismo formato que el chat), comentarios con respuestas, badge de autor (F=azul, R=morado) y badge NUEVO que desaparece al ver el elemento.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_element_options.dart` (nuevo): `BoardSocialData` con lógica pura de reacciones (`{key: [userIds]}`, max 5 keys, 1 por usuario por key — espejo de `Message.toggleReaction`) y comentarios (`{id, userId, text, createdAt, replyToId}`) embebidos en `el.data` (se sincronizan vía `update()` + realtime). `showElementOptionsSheet()`: bottom sheet con barra de reacciones (6 emojis default + custom vía dialog + chips de keys custom existentes), y 4 acciones: Comentarios (con contador), Duplicar (copia con offset +30 y id nuevo), Archivar, Eliminar (con confirmación). `showCommentsSheet()`: lista de comentarios con badge de autor, tiempo relativo, responder (hilo con preview "→"), borrar solo si es mío, input con keyboard insets.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: `_buildElementCard` ahora envuelve el elemento en `Stack(clipBehavior: Clip.none)` con: reacciones inline debajo del card (chips con key + contador), badge NUEVO verde arriba-izquierda, badge de autor (inicial F/R con color azul/morado) arriba-derecha. Long-press abre `showElementOptionsSheet` (reemplaza el viejo diálogo de borrado). Tap marca el elemento como visto (`markAsSeen`) si `isNew`.
- `lib/providers/board_provider_v2.dart`: nuevo `findById(int?)` para resolver el elemento vivo desde sheets/dialogs.
- `lib/models/board_element_v2.dart`: `copyWith` ahora acepta `createdAt` (necesario para duplicar con timestamp nuevo y no colisionar los lookups por `createdAt`).
- Eliminado código muerto: `board_element_panel.dart`, `board_canvas.dart`, `board_note_renderer.dart`, `board_element_renderer.dart` (no se importaban desde el reset del 11/8; los renderers vivos ya se llaman directo desde la pantalla).
**Lecciones**:
- Las reacciones/comentarios embebidos en `el.data` no necesitan tablas nuevas: `update()` + Realtime hacen el sync entre dispositivos. El formato de reacciones espeja el del chat para consistencia.
- Los sheets que mutan datos del provider deben leer el elemento VIVO (`pv.findById`) en cada acción, no el snapshot con el que se abrieron, y hacer `setSheetState`/`ListenableBuilder` para refrescar el contador.
- `copyWith(clearId: true)` mantiene el `createdAt` original; al duplicar hay que pasar `createdAt: DateTime.now()` explícito o el nuevo elemento colisiona en los lookups por timestamp.
**Impacto**: `board_element_options.dart` (nuevo), `pizarra_screen_v2.dart`, `board_provider_v2.dart`, `board_element_v2.dart`, 4 archivos muertos eliminados
**Relacionado con**: skill-pantallas.md (reglas 6/7/8 — comentable/reaccionable/interactuable, badge NUEVO), D-2 (Supabase realtime), Etapa 3 del plan

## [2026-08-12] - FEATURE - Pizarrón v2: Etapa 2 (header + vistas + búsqueda + zoom + actividad + tags)
**Resumen**: Se integraron al canvas los widgets de organización que quedaron muertos tras el reset del 11/8: header con cambio de vista, vistas Lista/Timeline/Archivados, buscador, panel de actividad, gestor de tags y slider de zoom.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: nuevo estado `_viewMode` (canvas/list/timeline/archived) + `_searchOpen`/`_searchText`/`_activityOpen`/`_tagManagerOpen`. El `InteractiveViewer` ahora solo se monta en modo canvas; las vistas lista/timeline/archivados reemplazan el canvas con `Positioned.fill`. `BoardHeader` siempre visible arriba (nombre de vista clickeable cicla canvas→lista→timeline→archivados→canvas, botones tags/actividad/búsqueda, indicador online). `BoardZoomSlider` abajo a la derecha (solo canvas). `BoardSearchPanel` busca por título/contenido/tags y navega al elemento. `BoardActivityPanel` carga con `pv.loadActivity()`. `BoardTagManager` crea tags. Nuevos `_goToElement(el)` (cambia a canvas y centra la transformación en el elemento), `_toggleActivity()`, `_restoreElement(el)` (toggleArchive).
- Limpieza de imports muertos en widgets activados: `board_list_view.dart`, `board_timeline_view.dart`, `board_archived_view.dart` (app_state sin uso), `board_drawing_editor.dart`, `board_audio_editor.dart` (app_state/services/dart:io sin uso), `board_checklist_renderer.dart` (services innecesario).
**Lecciones**:
- Los widgets viejos (`BoardHeader`, `BoardListView`, etc.) son todos `Positioned` — deben ser hijos directos del `Stack` de la pantalla; las vistas completas (lista/timeline) se envuelven en `Positioned.fill` con padding top para no quedar debajo del header.
- `_goToElement` centra por traducción pura (sin escala): `translation = screenCenter - elementCenter`. Simple y suficiente para navegar a un resultado de búsqueda.
- Al cambiar de vista hay que cancelar el modo conector y cerrar el buscador, si no quedan banners colgados sobre la vista nueva.
**Impacto**: `pizarra_screen_v2.dart`, `board_list_view.dart`, `board_timeline_view.dart`, `board_archived_view.dart`, `board_drawing_editor.dart`, `board_audio_editor.dart`, `board_checklist_renderer.dart`
**Relacionado con**: skill-pantallas.md (spec pizarrón — Organización: búsqueda, vistas, breadcrumb), Etapa 2 del plan

## [2026-08-12] - FEATURE - Pizarrón v2: menú radial + tipos nuevos (checklist, dibujo, video, audio, conectores)
**Resumen**: Se completó la Etapa 1 del pizarrón: menú radial con 6 herramientas, creación y renderizado de todos los tipos de elemento en el canvas, y modo conector para unir elementos con flechas. Los elementos nuevos se crean en el centro del viewport actual.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: reescrito. Reemplazado el FAB verde por `BoardToolsMenu` (menú radial con Nota, Checklist, Dibujo, Video, Audio, Conector). El canvas ahora renderiza todos los tipos: notas (estilo completo), checklists (`BoardChecklistRenderer` con edición inline), dibujos (`BoardDrawingRenderer`), videos (`BoardVideoRenderer`, tap abre URL en navegador con `url_launcher`), audios (`BoardAudioRenderer` con waveform + play). Conectores pintados en capa `CustomPaint` de 10000x10000 con `MultiConnectorPainter` (bezier + flecha). Wrapper común de gestos (`HitTestBehavior.opaque`): tap → acción por tipo, long-press → confirmación de borrado, pan → mover. Modo conector: banner cian arriba ("ORIGEN"/"DESTINO") + highlight del elemento; cancelar con botón. Banner de error rojo con reintentar. `_screenCenterToWorld()` para spawnear en el centro del viewport (inversa de la matriz del InteractiveViewer).
- `lib/providers/board_provider_v2.dart`: `update()` ahora soporta elementos sin id cloud (busca por `identical` → `id` → `createdAt`, actualiza local, debounce cloud solo si hay id). `_saveToLocal()` para elementos sin id actualiza la fila local por `created_at` en vez de insertar (evita duplicados en SQLite durante ediciones offline).
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: corregidas violaciones de skill_visual (fondo semitransparente `withValues(alpha: 0.2)` → sólido, fondo=borde mismo color, icono oscuro).
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart`: nuevo param `targetId` para editar un dibujo específico (tap en el canvas), no solo el último creado.
- `lib/screens/pizarra_v2/editors/board_audio_editor.dart`: nuevo param `targetId`; busca el audio por id con fallback al último.
- `lib/screens/pizarra_v2/editors/board_video_search.dart`: nuevos params `spawnX`/`spawnY` (el video se crea en el centro del viewport).
- `lib/screens/pizarra_v2/note/note_card_modal.dart`: nuevos params `initialX`/`initialY` (notas nuevas spawnean en el centro del viewport, antes x:200 y:200 fijo).
- `lib/screens/pizarra_v2/renderers/board_checklist_renderer.dart`: `didUpdateWidget` que refresca los datos internos cuando el elemento cambia desde afuera (realtime de la pareja).
**Lecciones**:
- Los editores de dibujo/audio guardan al "último elemento del tipo": para editar uno específico desde el canvas hay que pasar `targetId` (con fallback al último, que cubre el flujo de creación).
- Un elemento creado optimista (sin id cloud) no puede usarse en `update()` con `eq('id')`; hay que resolverlo por `identical`/`createdAt` y persistir local por `created_at` para no duplicar filas en SQLite.
- Los conectores no deben ser hijos `Positioned`: se pintan en una capa `CustomPaint` del tamaño del mundo, que calcula los centros desde los elementos referenciados (se actualizan solos al moverlos).
- El renderer de checklist es un StatefulWidget con copia interna de `data`: sin `didUpdateWidget` los cambios de la pareja por realtime no se reflejaban.
**Impacto**: `pizarra_screen_v2.dart`, `board_provider_v2.dart`, `board_tools_menu.dart`, `board_drawing_editor.dart`, `board_audio_editor.dart`, `board_video_search.dart`, `note_card_modal.dart`, `board_checklist_renderer.dart`
**Relacionado con**: skill-pantallas.md (spec pizarrón), D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual), Etapa 1 del plan

## [2026-08-12] - BUGFIX - ClassSetupWizard ahora solo aparece al entrar al calendario
**Resumen**: El wizard de "Cuantas clases tienes a la semana?" se mostraba al abrir la app (HomeScreen). Ahora solo aparece al entrar a la pantalla del calendario (CalendarHomeScreen).
**Cambios realizados**:
- `lib/screens/home_screen.dart`: eliminado `_checkClassSetup()` y su llamado en `initState`. Limpiados imports huérfanos (`provider`, `DatabaseHelper`, `ClassScheduleProvider`, `class_setup_wizard`, `pizarra_screen`).
- `lib/screens/calendar/calendar_home_screen.dart`: agregado `_checkClassSetup()` que revisa si hay clases configuradas en SQLite local; si no hay, abre el `ClassSetupWizard`. Se llama en `initState` antes de `_loadData()`. Agregados imports necesarios (`DatabaseHelper`, `class_setup_wizard`).
**Lecciones**:
- La verificación de setup inicial no debe bloquear la experiencia de toda la app; es mejor ubicarla en el contexto donde se necesita (calendario).
**Impacto**: `home_screen.dart`, `calendar_home_screen.dart`

## [2026-08-12] - FEATURE+BUGFIX - Notas funcionales en canvas + polish completo del editor
**Resumen**: Las notas ahora se renderizan en el canvas del pizarrón con su estilo real (forma, color, gradiente, borde). Se pueden arrastrar, editar (tap) y eliminar (long press). Además se pulieron bugs críticos de los editores y se agregaron opciones faltantes.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: integrado `BoardProviderV2` + `Consumer` para cargar y renderizar notas en el canvas. Cada nota se muestra con su color, shape (ClipPath), gradiente y borde real. Soporte drag-to-move (desactiva canvas pan durante el drag), tap para editar, long-press para eliminar con confirmación. `_MiniShapeClipper` para formas igual que en el modal. Canvas reducido a 10000x10000 con `boundaryMargin: 5000` (antes `double.infinity` causaba bugs).
- `lib/screens/pizarra_v2/note/note_card_modal.dart`: soporte para `noteId` — carga datos existentes al editar, guarda con `provider.update()` si es edición o `provider.add()` si es nueva. Color default cambiado a violeta (`#5C2D91`) para visibilidad. Gradiente por defecto con colores violeta/azul/cian. Patrones solo se muestran si `patternEnabled: true` (toggle en Capa 2). `_PatternPainter` con 12 patrones (agregados Diagonales, Círculos, Triángulos, Panal). `_CardBorderPainter` con renderizado real: punteado dibuja círculos, dashed pinta segmentos, doble usa 2 líneas, ondulado usa sinusoide, relieve doble stroke.
- `lib/screens/pizarra_v2/note/note_background_editor.dart`: `TextEditingController` con `dispose()` (fix memory leak). `didUpdateWidget` completo para todos los campos. Slider de saturación agregado. Labels de sliders ampliados a 72px. Capa 1 (Color) eliminada — solo Capa 1 Degradado + Capa 2 Patrón con toggle on/off. Color picker de gradiente usa `GradientColorPicker` (StatefulWidget propio, evita bug de `StatefulBuilder`).
- `lib/screens/pizarra_v2/note/note_border_editor.dart`: agregado slider de espaciado (1-20px). `didUpdateWidget` completo incluyendo spacing.
- `lib/screens/pizarra_v2/note/note_font_editor.dart`: Google Fonts cargadas con `GoogleFonts.getFont()`. Nombres de fuente corregidos (Open Sans, Dancing Script, etc.). Color dot negro reemplazado por `#444444`.
- `lib/screens/pizarra_v2/note/note_audio_recorder.dart`: cleanup de archivos temporales en `dispose()`. `_recorder.stop()` automático al cerrar. Manejo de `null` en `stop()`.
- `lib/screens/pizarra_v2/note/note_toolbar.dart`: haptic feedback en los 5 botones. Barreras semitransparentes (`barrierColor: Colors.black26`) en todos los bottom sheets. Editor de fondo limitado a 55% de altura.
- `lib/screens/pizarra_v2/note/note_shape_editor.dart`: borde=fondo en estado no seleccionado (regla brutalista).
- `lib/screens/pizarra_v2/note/note_color_editor.dart`: glow en color seleccionado.
- `lib/screens/pizarra_v2/note/note_gradient_color_picker.dart` (nuevo): dialog de picker de color para gradientes, StatefulWidget propio.
- `lib/screens/pizarra_v2/note/note_common_color_wheel.dart` (nuevo): `SimpleColorWheel` compartido entre font editor y border editor (elimina 2 copias duplicadas del color wheel).
- `lib/services/notification_service.dart`: `LateInitializationError` fix — `_showLocalNotification` envuelta en try-catch + guard `_initialized`.
**Lecciones**:
- `StatefulBuilder` resetea variables locales en cada rebuild del builder — para diálogos de color, usar un `StatefulWidget` propio que mantenga el estado.
- Los `CustomPainter` necesitan `HitTestBehavior.opaque` si el child no es hittable.
- `BoxDecoration.border` es final — no se puede mutar; crear una nueva decoración para cada estado de borde.
- El `InteractiveViewer` gana la guerra de gestos contra `GestureDetector` anidados — desactivar `panEnabled` durante drags de notas.
- Los archivos de audio temporal deben limpiarse en `dispose()` o quedan huérfanos en el filesystem.
**Impacto**: `pizarra_screen_v2.dart`, `note_card_modal.dart`, `note_background_editor.dart`, `note_border_editor.dart`, `note_font_editor.dart`, `note_toolbar.dart`, `note_shape_editor.dart`, `note_color_editor.dart`, `note_audio_recorder.dart`, `note_gradient_color_picker.dart` (nuevo), `note_common_color_wheel.dart` (nuevo), `notification_service.dart`
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual), errores-conocidos

## [2026-08-11] - FEATURE - Pizarrón v2: editores de fondo por capas, fuente y borde (Etapa 2)
**Resumen**: Se completó la toolbar derecha del modal de nota con los 3 botones restantes: Fondo (violeta), Fuente (fucsia) y Borde (naranja). Cada uno abre un bottom sheet con editor completo.
**Cambios realizados**:
- `lib/screens/pizarra_v2/note/note_background_editor.dart` (nuevo): sistema de 3 capas con tabs — Capa 1 Color (muestra el color base), Capa 2 Tipo (Liso/Lineal/Radial + selector de 3 colores del gradiente), Capa 3 Patrón (8 patrones: puntos, líneas H/V, cuadrícula, zigzag, diamantes, ondas, rayas + patrón personalizado con texto/emoji). Sliders para grosor, ángulo, tamaño, opacidad y espaciado del patrón.
- `lib/screens/pizarra_v2/note/note_font_editor.dart` (nuevo): 12 Google Fonts (Roboto, Open Sans, Lato, Montserrat, Oswald, Raleway, Poppins, Dancing Script, Pacifico, Permanent Marker, Caveat, Indie Flower), 5 colores base + "+" para custom, slider de tamaño 8-48px con botones +/-.
- `lib/screens/pizarra_v2/note/note_border_editor.dart` (nuevo): toggle on/off, color, 6 tipos de borde (Sólido, Punteado, Dashed, Doble, Ondulado, Relieve), slider de grosor 1-10px.
- `lib/screens/pizarra_v2/note/note_toolbar.dart`: reescrito con todos los botones funcionales, fondos violeta/fucsia/naranja, cada uno abre su bottom sheet con los editores completos.
- `lib/screens/pizarra_v2/note/note_card_modal.dart`: agregado estado `_bgState`, `_fontState`, `_borderState` con handles, y helper `_toSerializable` para persistir Colors en el Map de datos.
**Lecciones**:
- Los Maps con valores mixtos (Color + primitives) necesitan serialización explícita antes de pasarlos a `data` del BoardElementV2 (que espera `Map<String,dynamic>` sin Colors).
- `.clamp()` en `num` devuelve `num` no `double`; usar `.toDouble()` al pasarlo a un parámetro `double`.
- Los bottom sheets con sliders necesitan `isScrollControlled: true` + `viewInsets` para que el teclado no tape el contenido.
**Impacto**: 3 archivos nuevos en `lib/screens/pizarra_v2/note/`, 2 modificados. `flutter analyze` 0 issues. Exe compilado OK.
**Relacionado con**: skill_visual.md, D-4, Etapa 1 del modal de nota

## [2026-08-11] - FEATURE - Pizarrón v2: modal de nota con toolbar de edición (Etapa 1)
**Resumen**: Se creó el modal de nota desde cero. Al apretar el botón verde flotante aparece un modal centrado con: título, cuerpo de texto, grabadora de audio funcional, selector de imagen de galería con picker de posición (arriba/medio/abajo), y toolbar derecha con 5 botones (Forma, Color, Fondo - placeholder, Fuente - placeholder, Borde - placeholder). Forma tiene 6 opciones (rectángulo, cuadrado, círculo, óvalo, diamante, hexágono). Color tiene 5 colores brutalistas base + rueda de color custom con slider de tono y cuadrado saturación/brillo + últimos 5 colores custom. Nota se persiste en Supabase + SQLite vía BoardProviderV2.
**Cambios realizados**:
- `lib/screens/pizarra_v2/note/note_card_modal.dart` (nuevo): modal principal con TextField para título y cuerpo, picker de imagen (`image_picker`) con selector de posición (top/middle/bottom) vía bottom sheet, integración con NoteAudioRecorder y NoteToolbar, botón de guardar que llama a `BoardProviderV2.add()`.
- `lib/screens/pizarra_v2/note/note_toolbar.dart` (nuevo): barra vertical con 5 botones (Forma cian, Color naranja, Fondo/A/B gris placeholder). Modo shape y color abren bottom sheets.
- `lib/screens/pizarra_v2/note/note_shape_editor.dart` (nuevo): grid de 6 formas con iconos (rectángulo, cuadrado, círculo, óvalo, diamante, hexágono), selección con highlight verde.
- `lib/screens/pizarra_v2/note/note_color_editor.dart` (nuevo): 5 colores brutalistas (#FF6B00, #FF00FF, #00D4FF, #39FF14, #9D00FF) + botón "+" que abre color wheel. Sección de colores recientes (últimos 5 custom).
- `lib/screens/pizarra_v2/note/note_color_wheel.dart` (nuevo): barra de tono (hue) horizontal + cuadrado saturación/brillo con gradientes, ambos con GestureDetector para pan. Preview con hex code en tiempo real.
- `lib/screens/pizarra_v2/note/note_audio_recorder.dart` (nuevo): grabador de audio funcional con `record` package (mic/stop), contador de tiempo, confirmacion visual (check verde) y botón de borrar.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: agregado estado `_showNote`, el botón verde ahora abre el modal en vez de hacer nada, y el NoteCardModal se superpone en el Stack cuando está activo.
**Lecciones**:
- `Color.value` está deprecated en Flutter 3.27+; usar `toARGB32()` para el int argb y `.r`/`.g`/`.b` (0-1 doubles) para canales individuales.
- `image_picker: ^1.2.3` devuelve `XFile` (no `File`); se usa `.path` directamente con `Image.file()`.
- El NoteCardModal usa `context.read<BoardProviderV2>()` vía Provider (registrado en main.dart), sin necesidad de declarar imports en el screen padre.
- La toolbar derecha se posiciona como parte del mismo `Row` que la card en el modal, no como `Positioned` separado.
**Impacto**: 6 archivos nuevos en `lib/screens/pizarra_v2/note/`, 1 modificado (`pizarra_screen_v2.dart`). `flutter analyze` 0 issues.
**Relacionado con**: skill_visual.md (fondo=borde, sin sombras, redondo, sin negro puro), D-2 (Supabase), D-3 (SQLite)

## [2026-08-11] - REFACTOR - Pizarrón v2: rediseño desde cero, solo lienzo con grid
**Resumen**: Se borró toda la funcionalidad del pizarrón v2 (elementos, herramientas, header, paneles, editores, vistas alternativas) y se dejó únicamente el lienzo infinito con grid de puntitos y pan/zoom. Es el punto de partida para un rediseño completo desde cero.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: reescrito de 387 a 100 líneas. Solo contiene `Scaffold` con fondo `#0A0A0A`, grid de puntitos `#333333` cada 30px (`_GridPainter` inline), e `InteractiveViewer` con pan/zoom (0.1x-5x). Se conserva el enum `BoardViewMode` para que los widgets viejos no rompan el análisis.
- Eliminadas todas las dependencias del provider, modelos, editores, renderers y widgets del pizarrón.
- La navegación desde `home_screen.dart` sigue funcionando (`const PizarraScreenV2()`).
**Lecciones**:
- El grid de puntitos se pinta en espacio de pantalla (Stack externo al InteractiveViewer) transformado por la matriz del `TransformationController`, así no necesita `boundaryMargin` limitado.
- Los widgets viejos (header, timeline, etc.) quedan como código muerto en disco pero no se importan; el `flutter analyze` los sigue chequeando, por eso se conservó `BoardViewMode`.
**Impacto**: `lib/screens/pizarra_v2/pizarra_screen_v2.dart`
**Relacionado con**: skill-pantallas.md (especificación del pizarrón obsoleta para esta iteración), D-4 (skill_visual)

## [2026-08-11] - BUGFIX - Bot WhatsApp: migración a LID de WhatsApp (resolución + cache + conexión descartable)
**Resumen**: El bot dejó de entregar mensajes el ~2026-08-10. WhatsApp migró el enrutamiento de contactos a IDs de dispositivo vinculado (`@lid`): enviar al JID con número normal resuelve sin error pero el servidor NO entrega (pérdida silenciosa). Fix: resolver LIDs con `onWhatsApp()` en conexión descartable, cachear en `lids.json`, y enviar al JID LID. Verificado end-to-end con ACK `status=4` (leído).
**Cambios realizados**:
- `bot-furi/bot.js`: nueva sección de resolución de LIDs — `lidCache` + `cargarLidsCache()` + `guardarLidCache(phone, lid)` + `lidJid(sock, phone)` + `resolverLidsSolo()`. `main()` ahora resuelve LIDs en conexión descartable si faltan en cache. `enviarMensaje()` usa SOLO cache (nunca llama `onWhatsApp` en la conexión principal). `esperarAck()` agrega flush periódico (`sock.ev.flush()`) cada 2s para liberar ACKs retenidos por `AwaitingInitialSync`.
- `bot-furi/lids.json` (nuevo, gitignored): cache de LIDs persistido.
- `bot-furi/.gitignore`: agregados `lids.json` y `*.txt`.
- Quitado `console.log([DEBUG-ACK])` temporal de `esperarAck`.
- Verificación: mood-120 de prueba → enviado a `83189842346022@lid` (Facu) → ACK status=4 → marcado en `bot_notificaciones` → limpieza del test row.
- `docs/contexto/bot-whatsapp.md`: sección de LID reescrita con fix real (no "re-vincular QR").
- `docs/contexto/errores-conocidos.md`: entrada LID marcada RESUELTO 2026-08-11 con fix real.
**Lecciones**:
- `onWhatsApp()` devuelve `lid` YA con sufijo `@lid`; si se concatena otro `@lid` queda `xxx@lid@lid`.
- `onWhatsApp()` puede romper el stream con `xml-not-well-formed` (2 de 3 corridas); la conexión descartable lo aísla.
- El event buffer de Baileys (`AwaitingInitialSync`) retiene `messages.update`; el flush periódico los libera.
- Re-vincular WhatsApp (borrar `auth/` + QR nuevo) NO servía: el bloqueo era del JID destino (LID), no de las claves de cifrado. La sesión ya tenía las claves LID de los contactos.
- Los LIDs de contactos NO están en la sesión del bot: se obtienen con una query a WhatsApp (`onWhatsApp`) y se cachean.
**Impacto**: `bot-furi/bot.js`, `bot-furi/.gitignore`, `bot-furi/lids.json` (nuevo), `docs/contexto/bot-whatsapp.md`, `docs/contexto/errores-conocidos.md`, `docs/contexto/historial.md`
**Relacionado con**: D-10 (bot WhatsApp), errores-conocidos (mensajes en cola LID), bot-whatsapp.md

## [2026-08-10] - BUGFIX+BUILD - Keystore eliminado + APK release firmado con firma debug (se instala sobre versiones previas)
**Resumen**: La app no funcionaba en el Realme C11 de Rocio (sin acceso USB). El usuario pidió eliminar la keystore (que "no hace falta") y que el APK se instale sí o sí en todos los dispositivos. Se eliminó la firma custom (CN=Furi) y se volvió a la **firma debug estándar de Flutter** — la misma que usaban los APK que sí instalaban antes del 6/8 — que se instala sobre cualquier instalación debug previa sin desinstalar.
**Cambios realizados**:
- `android/app/build.gradle.kts`: eliminado el bloque `signingConfigs { create("release") }` con key.properties y el `signingConfig = signingConfigs.getByName("release")`. Ahora `release { signingConfig = signingConfigs.getByName("debug") }`.
- Borrados `android/key.properties` y `android/app/upload-keystore.jks`.
- **Hallazgo crítico**: tras quitar el signingConfig del release, el primer build generó un APK **COMPLETAMENTE SIN FIRMAR** (`apksigner verify` → `DOES NOT VERIFY: Missing META-INF/MANIFEST.MF`; sin bloque de firma v2 en el ZIP; META-INF sin MANIFEST.MF/CERT.RSA). AGP **NO** asigna automáticamente la firma debug en este proyecto cuando el buildType release queda sin signingConfig. Fix: `signingConfig = signingConfigs.getByName("debug")` explícito → `Verifies (v2 scheme: true)` con `CN=Android Debug`.
- Build universal `app-release.apk` (64.6 MB, todas las ABIs: arm64-v8a + armeabi-v7a + x86_64, minSdk 24, targetSdk 36) verificado con apksigner 37.0.0.
- Release GitHub `v1.0.2-debug-firma` creado (el link `releases/latest` apunta al nuevo). Subida por API REST (`uploads.github.com`) porque `gh release upload` colgaba; la velocidad de subida varía de ~3 KB/s a ~370 KB/s.
**Lecciones**:
- **Sin signingConfig explícito en release, AGP puede NO firmar el APK** (no siempre hace el fallback al debug config): el APK compila "√ Built" pero Android lo rechaza al instalar. SIEMPRE verificar `apksigner verify` después de tocar la firma — y antes de mandar un APK a otro celular.
- La firma debug de Flutter (`~/.android/debug.keystore`) es la misma en todos los builds del mismo dev machine y es la más compatible para instalación manual: cualquier dispositivo que alguna vez aceptó un APK debug acepta el nuevo sin desinstalar.
- La firma CN=Furi (keystore del 6/8) queda **huérfana**: los APK v1.0.1 instalados en el Realme C11 requieren desinstalación previa para aceptar la v1.0.2. Documentado en la guía de instalación.
- El keystore propio era innecesario para instalación manual en 2 celulares; aportaba solo fricción (incompatibilidad de firma con los APK debug previos).
**Impacto**: `android/app/build.gradle.kts`, `android/key.properties` (borrado), `android/app/upload-keystore.jks` (borrado), `build/app/outputs/flutter-apk/app-release.apk`, GitHub release `v1.0.2-debug-firma`, `docs/contexto/historial.md`, `docs/contexto/flujo-de-trabajo.md`, `documentacion/GUIA_INSTALACION_APK.md`, `docs/contexto/errores-conocidos.md`
**Relacionado con**: errores-conocidos (firma release/APK no instalado), flujo-de-trabajo (build APK, firma), entrada keystore 2026-08-06

## [2026-08-08] - BUGFIX - Bot WhatsApp: API key invalidada hacía parecer "sesión cerrada" (todo el día sin notificar)
**Resumen**: El bot decía "No hay sesion guardada en Supabase" en cada corrida de CI y mostraba QR sin poder conectarse. La sesión de WhatsApp estaba **intacta** en `bot_sessions` (104 claves, `creds.json` presente, `updated_at` 10:24 UTC); el problema era que la `SUPABASE_KEY` en `bot-furi/.env` y el secret `SUPABASE_KEY` de GitHub (creado el 2026-08-05) eran la service role key vieja invalidada por Supabase → toda query respondía `Unregistered API key`/`Invalid API key` → `loadSessionFromSupabase()` encontraba error y trataba la sesión como inexistente → pedía QR y moría por timeout ("Sesión cerrada" aparente).
**Cambios realizados**:
- Verificación: query con la key vieja → `Unregistered API key`; con la key publicable de la app → lee/escribe todas las tablas del bot (16 tablas verificadas una por una, incluidas `bot_sessions` y `bot_notificaciones`).
- `bot-furi/.env`: `SUPABASE_KEY` cambiada de service role key vieja a la **service role key nueva** (provista por el usuario).
- GitHub secret `SUPABASE_KEY`: actualizado en gh (secret list + `gh secret set`).
- Verificación local + CI (key nueva): `node bot.js` → "Sesion cargada desde Supabase" → "Conectado a WhatsApp" → "Sin novedades para notificar". **Sin reescanear QR** (la sesión no se perdió).
- Verificación CI: `gh workflow run` → log: "Sesion cargada desde Supabase", "Conectado a WhatsApp", "Bot finalizado" — restaurado.
**Lecciones**:
- Un "Sesion cerrada / No hay sesion guardada" del bot NO siempre significa sesión de WhatsApp vencida: la primera autopsia es probar una query a `bot_sessions` con la key del `.env`. Si da `Invalid API key`/`Unregistered API key`, es la key, no el QR.
- La service role key vieja del proyecto fue invalidada por Supabase; las key nuevas que funcionan son las publishable. El bot puede operar con la publishable porque las tablas `bot_sessions`/`bot_notificaciones` tienen policies `FOR ALL USING (true)`.
- `cargarUsuarios()`/verificaciones usan la misma key: si la lectura falla, todo "no funciona" parecía desconexión.
**Impacto**: `bot-furi/.env`, GitHub secret `SUPABASE_KEY`, `docs/contexto/bot-whatsapp.md`, `docs/contexto/historial.md`
**Relacionado con**: D-10 (bot), errores-conocidos (sesión LID — no re-relacionar, este ES distinto: key rota)

## [2026-08-08] - BUGFIX - Clases del wizard nunca se subían a Supabase (color ARGB fuera de rango en columna INTEGER)
**Resumen**: Las clases/materias configuradas en el wizard se guardaban solo en SQLite local y la tabla cloud `class_schedules` quedaba en `count = 0`. Causa raíz: la columna `color` en la BD cloud se creó como `INTEGER` (máx 2147483647) pero el modelo manda `0xFF7B2D8E` = **4286262670**, fuera de rango → Supabase respondía `22003: value "4286262670" is out of range for type integer` y `_pushToSupabase()` (try/catch) lo tragaba silenciosamente → `cloudId` nunca se asignaba → el wizard volvía a aparecer en cada apertura.
**Cambios realizados**:
- `supabase/migration_class_schedules.sql`: `color BIGINT DEFAULT 4286262670` en el CREATE + `ALTER TABLE class_schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;` idempotente para tablas ya creadas.
- `supabase_schema.sql`: `color BIGINT DEFAULT 4286262670` en el CREATE TABLE master.
- Verificado en vivo contra la API REST (anon key): SELECT devuelve 200 con `count 0` (tabla existía, vacía); INSERT directo reproduce el error 22003 exacto; `profiles` responde OK (proyecto y anon key válidos).
**Lecciones**:
- Un color ARGB de Flutter (`0xFFRRGGBB`) como int siempre excede el rango del `INTEGER` de Postgres (máx 2147483647). Cualquier columna cloud que persista colores ARGB debe ser `BIGINT`.
- El try/catch de `_pushToSupabase` convierte el fallo de migración de tipo en un "sync roto en silencio": la clase queda local, el cloudId nunca se setea y el wizard aparece de nuevo. Vale la pena revisar los logs `developer.log` ante "se guarda local pero no en la nube".
- El sync automático de clases existentes ya existe (`_syncUnsyncedToSupabase` dentro de `loadSchedules`): basta abrir la app una vez tras ejecutar la migración para que las clases locales suban solas.
**Impacto**: `supabase/migration_class_schedules.sql`, `supabase_schema.sql`, `docs/contexto/errores-conocidos.md`, `docs/contexto/historial.md`. **Pendiente de acción manual**: ejecutar `migration_class_schedules.sql` en el SQL Editor de Supabase para que la columna pase a BIGINT.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), errores-conocidos (ClassSetupWizard color fuera de rango)

## [2026-08-08] - BUILD+BUGFIX - APK no se instalaba en el Realme C11 de Rocio → Release en GitHub + fix compilación pizarra v2
**Resumen**: La app dejó de instalarse en el Realme C11 (Rocio, en otra provincia, sin acceso ADB). Los APK viejos sí instalaban, los nuevos daban "aplicación no instalada". Investigación: (1) los APK nuevos cambiaron de firma (debug → keystore CN=Furi el 6/8), por lo que una versión vieja instalada en el celular hace que Android rechace el update con `INSTALL_FAILED_UPDATE_INCOMPATIBLE`; (2) WhatsApp/Drive renombran el archivo a `.apk.1` → "aplicación no instalada". Solución: subir el APK universal actual a GitHub Releases (descarga por Chrome mantiene el nombre `.apk`), indicarle a Rocio desinstalar la versión vieja primero.
**Cambios realizados**:
- Fix de compilación: `lib/screens/pizarra_v2/widgets/board_canvas.dart:153` pasaba 2 argumentos a `_liveElement()` (que acepta 1) → `release` no compilaba (`Target kernel_snapshot_program failed`).
- Rebuild `flutter build apk --release` → `app-release.apk` (64.6 MB, minSdk 24, targetSdk 36, ABIs arm64-v8a+armeabi-v7a+x86_64, firma CN=Furi).
- Publicado release en GitHub: `v1.0.1-apk-instalable` con el APK adjunto → https://github.com/mrtuco748-cmyk/furiiiiiiiiiii/releases/tag/v1.0.1-apk-instalable
  (El primer intento creó un Draft; se completó con `gh release upload --clobber` + `gh release edit --draft=false`).
- `documentacion/GUIA_INSTALACION_APK.md`: método A con link de GitHub + Chrome (no renombra). Tabla de errores ampliada con "bloqueada por seguridad → desactivar escaneo de Play Protect".
**Lecciones**:
- Un APK release que compila en dev (debug) puede fallar en release por errores de lint que solo aparecen en la compilación de AOT/`kernel_snapshot` (board_canvas.dart:153 `_liveElement(el, d)`). Correr al menos una vez `flutter build apk --release` tras cada milestone.
- Los APK con firma nueva NO se pueden instalar sobre una versión vieja con otra firma: hay que desinstalar primero ("aplicación no instalada"). Se documentó el paso 0 en la guía.
- WhatsApp/Drive renombran/cortan APKs grandes: el método confiable es descarga con Chrome desde GitHub Releases (link `releases/latest`).
- Si el update sin ADB: GitHub Actions ya está configurado; el Release se puede re-subir con un solo comando `gh release create` (o `gh release upload --clobber` + `--draft=false`).
**Impacto**: `app-release.apk` (nuevo), `github.com/mrtuco748-cmyk/furiiiiiiiiiii` releases, `documentacion/GUIA_INSTALACION_APK.md`, `lib/screens/pizarra_v2/widgets/board_canvas.dart`, `docs/contexto/historial.md`.
**Relacionado con**: errores-conocidos (firma release/APK), flujo-de-trabajo (build APK), D-4, pizarra v2

## [2026-08-08] - BUGFIX - Limpieza de 228 notas espurias de la pizarra v2 (DB local del exe)
**Resumen**: Las notas espurias creadas por el bug del doble tap (ver entrada anterior) quedaron persistidas en la BD SQLite local del exe: 228 elementos `note` con título "Nueva nota", contenido vacío y `created_at` idéntico (2026-08-08T06:44:17.281814). Se borraron de la BD local. Además se descubrió que la tabla `board_elements_v2` NO existe en Supabase (error "No se pudo encontrar la tabla en schema cache" con supabase-js), así que el sync de la pizarra v2 falla en silencio y los datos viven solo en SQLite local.
**Cambios realizados**:
- Backup de la BD: `build\windows\x64\runner\Release\.dart_tool\sqflite_common_ffi\databases\furi_calendar.db.backup_20260808` (106 KB).
- Script temporal `tool/board_cleanup.dart` (usando `package:sqlite3` del proyecto; SQLITE3 CLI no disponible, `better-sqlite3` no compila con gyp) que lista y borra las notas vacías con `DELETE ... WHERE type='note' AND (content IS NULL OR content='') AND title='Nueva nota'`. Eliminado tras usarlo (no se deja código muerto).
- Resultado: 230 → 2 elementos. Quedan el dibujo (id 26, "Nuevo dibujo") y el video (id 149, "YouTube Video") que el usuario creó a propósito.
**Lecciones**:
- En Windows no hay CLI de sqlite3 disponible y `better-sqlite3` falla a compilar (node-gyp). Lo más simple para operar la BD local es un script Dart con `package:sqlite3` (ya transitivo del proyecto) y `dart run`.
- La API de Supabase (service key) bloqueada para REST directo: "Forbidden use of secret API key in browser outside". Solo usar supabase-js con `ws` como transport en Node 20.
- La pizarra v2 NO está sincronizada con la nube (tabla ausente en Supabase) → borrar datos locales de la pizarra es suficiente; no hay soporte cloud para la v2 todavía.
**Impacto**: `build\windows\x64\runner\Release\.dart_tool\sqflite_common_ffi\databases\furi_calendar.db` (+ backup), `docs/contexto/historial.md`
**Relacionado con**: entrada doble tap espurias (2026-08-08), D-3 (SQLite)

## [2026-08-08] - BUGFIX - Pizarra v2: dibujos/videos no se movían + notas espurias por doble tap
**Resumen**: Tras testear con el exe, ningún tipo de tarjeta respondía (arrastrar/mover/interactuar) y se creaban notas no deseadas. Tres causas combinadas: (1) el `GestureDetector` de cada elemento usaba `HitTestBehavior.deferToChild`, que delega el hit test al child — un `CustomPaint` (dibujos) no es hit-testable, así que los gestos no llegaban al elemento; (2) `BoardVideoRenderer` tenía su propio `GestureDetector` con `onTap` que robaba el tap del elemento y abría el navegador en vez de seleccionar (nunca se seleccionaba → `panEnabled` seguía `true` → el InteractiveViewer robaba el drag); (3) el `onDoubleTap` del elemento solo existía para notas, así que el doble tap sobre dibujos/videos caía al fondo y ejecutaba `onDoubleTapEmpty` → creadas notas espurias en cada doble click.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: `behavior: HitTestBehavior.opaque` en el GestureDetector de elemento (captura gestos en toda el área, aunque el child no pinte en ese pixel); `onTap` ahora si el elemento es video y ya está seleccionado abre el video (segundo tap), sino selecciona; `onDoubleTap` para todo tipo absorbe el gesto (notas alternan edición; resto solo selecciona — evita que caiga al fondo y cree notas); nuevo helper `_liveElement(el)` que busca por id con fallback `createdAt % 1000000` (mismo id que el usado en el build) para mover/actualizar la copia viva; nuevo `_openVideo(el)` con `url_launcher` (imports `board_element_data.dart` y `url_launcher`).
- `lib/screens/pizarra_v2/renderers/board_video_renderer.dart`: eliminado el `GestureDetector` interno con `onTap` y `_openVideo`; ahora es puramente visual (thumbnail + play button + título). La apertura la maneja el canvas al tocar el video seleccionado.
**Lecciones**:
- `HitTestBehavior.deferToChild` en el GestureDetector de un elemento NO funciona si el child no participa del hit test en ese punto: un `CustomPaint` sin `hitTest` propio (o `Image.network` en errorBuilder) no captura eventos → el elemento queda "muerto" para gestos. `opaque` garantiza que el área completa del widget responda; los hijos internos (TextField) siguen recibiendo sus propios gestos porque están más profundo que en el árbol.
- Doble GestureDetector anidado (renderer + elemento) roba la selección: el renderer interno con `onTap` siempre gana y el elemento nunca se selecciona. La interacción de tipo "abrir video" debe hacerla el canvas (con elemento seleccionado) o el panel, no el renderer.
- Si el `onDoubleTap` del fondo (crear nota) es configurable y los elementos no lo absorben, el doble click sobre cualquier tipo de card sin `onDoubleTap` propio genera notas espurias: hay que absorber el gesto arriba en todos los tipos.
**Impacto**: `lib/screens/pizarra_v2/widgets/board_canvas.dart`, `lib/screens/pizarra_v2/renderers/board_video_renderer.dart`. 67 tests verdes, `flutter analyze` 0 errores.
**Relacionado con**: entrada regresión panEnabled (2026-08-08), skill_visual (sin cambios), D-2 (Supabase), D-3 (SQLite)

## [2026-08-08] - BUGFIX - Pizarra v2: notas no se movían ni editaban (regresión panEnabled) + build Windows completo
**Resumen**: Tras la ronda 2 de bugs, al testear el usuario descubrió que las notas no se podían mover ni escribir. Causa: el fix de la ronda 2 cambió `panEnabled` a `!_isEditingText` (pan siempre habilitado salvo edición), y el InteractiveViewer robaba los gestos del GestureDetector interno de cada nota → el drag no llegaba y el doble tap para editar tampoco. Se revirtió el comportamiento y se agregó soporte de move para elementos recién creados (sin id cloud). Además se completó la compilación del exe de Windows, que quedaba sin DLLs por un fallo intermedio de NuGet.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: `panEnabled` vuelve a `widget.selectedId == null && !widget.connectorMode`; eliminado el getter `_isEditingText` (innecesario). El `onPanUpdate` ahora usa `widget.provider.moveLocal(liveEl, ...)` (mueve aunque el elemento no tenga id cloud) y el renderer recibe `onRequestEdit` para entrar a edición con doble tap sobre el texto.
- `lib/providers/board_provider_v2.dart`: nuevo `moveLocal(BoardElementV2 el, double x, double y)` — actualiza la copia local (busca por `identical` → `id` → `createdAt`), `notifyListeners()`, guarda en SQLite y sincroniza a cloud con debounce de 300ms solo si hay id cloud (si no, queda solo local hasta que el id llegue del realtime).
- `lib/screens/pizarra_v2/renderers/board_note_renderer.dart`: nuevo callback `onRequestEdit` (VoidCallback?) — el doble tap sobre el texto ahora llama a `onRequestEdit` para que el canvas active el modo edición (antes re-emitía el contenido sin entrar en edición).
- `lib/screens/pizarra_v2/renderers/board_element_renderer.dart`: nuevo param `onRequestEdit` que se propaga al renderer interno.
- Build Windows: el build `flutter build windows --release` previo fallaba con "ZIP decompression failed (-5)" al descargar un paquete NuGet de `audioplayers_windows` (red schannel intermitente) y dejaba el `runner\Release\` SOLO con `furi_app.exe` (sin DLLs ni `data/`). Se copió el contenido de `build\windows\x64\install\` (todas las DLLs, `flutter_windows.dll`, `app.so`, `icudtl.dat`, `data/flutter_assets`) a `build\windows\x64\runner\Release\`.
**Lecciones**:
- El conflicto pan vs. gestos de notas es a dos bandas: con `panEnabled` siempre true el InteractiveViewer roba el drag de las notas; con pan siempre false no se puede panear con un elemento seleccionado. La solución usada: pan deshabilitado solo cuando hay selección activa (`selectedId != null`), porque el elemento seleccionado se mueve con su propio GestureDetector (no necesita el pan del fondo) y el doble tap para editar también llega.
- Un build de Flutter Windows "√ Built" puede quedar incompleto si el paso de NuGet/CIFalló silenciosamente: no basta con que exista `furi_app.exe`; hay que verificar que el folder de release tenga `flutter_windows.dll` y `data/`.
- Al borrar `build\windows` hay que activar el entorno MSVC (`D:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat amd64`) o CMake no encuentra `cl.exe` (TRK0005).
**Impacto**: `lib/screens/pizarra_v2/widgets/board_canvas.dart`, `lib/providers/board_provider_v2.dart`, `lib/screens/pizarra_v2/renderers/board_note_renderer.dart`, `lib/screens/pizarra_v2/renderers/board_element_renderer.dart`, `build\windows\x64\runner\Release\` (exe completo), `docs/contexto/historial.md`. Exe recompilado 2026-08-08 06:35, 1.4 MB.
**Relacionado con**: entrada ronda 2 (2026-08-08), skill_visual (sin cambios), D-2 (Supabase), D-3 (SQLite)

## [2026-08-08] - BUGFIX - Pizarra v2: 18 bugs de UX/funcionalidad (ronda 2)
**Resumen**: Tras la primera ronda de 24 bugs, se corrigieron 18 bugs adicionales de la pizarra v2: notas que no guardaban texto, columna is_archived faltante en instalaciones nuevas, Tag Manager que cerraba la pantalla, conectores sin UI de origen/destino, checklist sin edición de texto, comentarios que no aparecían al agregar, editor de dibujo sin carga de strokes existentes, audio sin reproducción, reacciones sin mostrar inline, código muerto eliminado, zoom slider estático, renderers faltantes para subBoard/separator, markAsSeen sin await en cloud, pan deshabilitado al seleccionar, vistas alternativas sin estados, drawing imagePath con icono genérico, video con dialog muerto, y _pushUnsyncedToCloud sin asignar id cloud.
**Cambios realizados**:
- `lib/screens/pizarra_v2/renderers/board_element_renderer.dart`: el `onContentChanged` de la nota ahora emite `{'_content': content}` (antes `quillDelta` inexistente) y `board_canvas` lo traduce a `copyWith(content:)`; se agregan renderers para `subBoard` (card con icono dashboard + título) y `separator` (línea horizontal/vertical según data).
- `lib/database/database_helper.dart`: `is_archived INTEGER NOT NULL DEFAULT 0` agregado al CREATE TABLE de `board_elements_v2` en instalaciones nuevas (el upgrade v7 ya lo tenía).
- `lib/screens/pizarra_v2/widgets/board_tag_manager.dart`: nuevo param `onClose`; el botón X llama `widget.onClose` en vez de `Navigator.pop(context)` que cerraba toda la pantalla.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: modo conector completo — `_connectorMode`/`_connectorFromId`, `_createAndEdit('connector')` entra a modo selección, `_handleConnectorSelect` crea el elemento con `ConnectorData(fromId, toId)`, banner inferior con instrucciones y botón "Cancelar", panel de opciones oculto en modo conector; pasa `transformController` al zoom slider.
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: params `connectorMode`/`connectorFromId`, `panEnabled` queda en `widget.selectedId == null && !widget.connectorMode` (se desactiva con selección — revertido en la sesión siguiente porque `_isEditingText` rompía mover/editar notas); highlight cian del origen del conector; reacciones inline (chips con emojis de `data['reactions']`).
- `lib/screens/pizarra_v2/renderers/board_checklist_renderer.dart`: diálogo de edición ahora hace `Navigator.pop` con el texto en las acciones Cancelar/Guardar (antes `setState` local nunca devolvía); llave `}` faltante agregada.
- `lib/screens/pizarra_v2/widgets/board_element_panel.dart`: `_showComments` usa `_liveComments()` (relee del provider por id) para que el comentario nuevo aparezca de inmediato.
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart`: `initState` carga strokes del último dibujo existente y guarda en ese elemento (`_targetId`), no en uno nuevo.
- `lib/screens/pizarra_v2/renderers/board_audio_renderer.dart`: reescrito como StatefulWidget con `Audioplayers` — reproduce `DeviceFileSource(localPath)` o `UrlSource(storagePath)`, waveform con progreso, formato de duración mm:ss.
- `lib/screens/pizarra_v2/widgets/board_element_card.dart`: eliminado (código muerto).
- `lib/screens/pizarra_v2/widgets/board_zoom_slider.dart`: reescrito con `TransformationController` de verdad — botón -/+, Slider vinculado al scale (0.1-5.0), escala preservando el centro.
- `lib/providers/board_provider_v2.dart`: `markAsSeen` ahora hace `await` del update cloud con try/catch; `_pushUnsyncedToCloud` inserta con `clearId: true` (no envía el id local de SQLite al cloud), guarda el id cloud en memoria y reconcilia la fila local (delete del id local + re-save con el id cloud + synced=1). Prevenía colisiones y updates que apuntaban a filas inexistentes.
- `lib/screens/pizarra_v2/widgets/board_list_view.dart` / `board_timeline_view.dart` / `board_archived_view.dart`: estados LOADING (spinner) y ERROR (mensaje + retry) además del vacío.
- `lib/screens/pizarra_v2/renderers/board_drawing_renderer.dart`: `Image.file` si `imagePath != null` (antes icono genérico).
- `lib/screens/pizarra_v2/renderers/board_video_renderer.dart`: al tocar abre el video en navegador externo con `url_launcher` (agregada a pubspec) en vez de un dialog con solo la URL.
- `pubspec.yaml`: agregada `url_launcher: ^6.3.1`.
**Lecciones**:
- `panEnabled` con `!editingText` (siempre true salvo edición) hacía que el InteractiveViewer robara los gestos de las notas: con GestureDetector interno del elemento, el pan del fondo y el drag/elemento pelean. Se revierte a desactivar el pan con selección activa (`selectedId == null`) — el elemento seleccionado se mueve con su propio GestureDetector, sin conflicto.
- Los widgets con botones que cierran (Tag Manager) no deben usar `Navigator.pop` si están embebidos en un Stack con otro Scaffold debajo: cierran toda la app.
- El id local de SQLite (`INTEGER PRIMARY KEY` autoincrement) NO es el id cloud (BIGSERIAL): al subir hay que `clearId: true`, tomar `res['id']` y reconciliar la fila local (borrar la fila con el id viejo y reinsertar con el cloud id).
- Un audio embebido en un renderer debe ser StatefulWidget con dispose del player, o el stream queda escuchando y el audio sigue reproduciendo tras cerrar la pizarra.
- url_launcher ya estaba en pubspec.lock (transitiva) — declararla en pubspec directo no cambia la versión resuelta.
**Impacto**: 13 archivos modificados + 1 eliminado, 67 tests verdes, `flutter analyze` 0 errores.
**Relacionado con**: skill-pantallas.md (pizarrón), D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual)

## [2026-08-07] - BUGFIX - Pizarra v2: 24 bugs críticos de UX/funcionalidad
**Resumen**: Tras testear la pizarra como usuario se corrigieron 24 bugs que rompían flujos reales: grid no visible, notas no editables, mover solo funciona una vez, panel de opciones con botones rotos, menú radial no funciona, dibujo/video/audio sacan del pizarrón, conectores no crean, zoom/pan se buguea, notas del otro no interactúan, vista archivados no cambia, tags no crean, colores no cambian, tipos se ven iguales, reacciones no funcionan, comentarios no agregan, sub-tableros no crean, colapsar no funciona, bloquear no funciona, fuente/tamaño/alineación no cambian, emoji header no agrega, performance lenta, no guarda offline, reiniciar no arregla.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: reescrito con GestureDetector separado del InteractiveViewer, grid siempre visible, panEnabled=false cuando hay selección, hitTestBehavior.deferToChild para permitir TextField, live element lookup para moves, clipBehavior.none en Stack.
- `lib/screens/pizarra_v2/widgets/board_element_panel.dart`: reescrito como StatefulWidget con dialogs funcionales para editar, color picker, font picker, reacciones, comentarios. Cada botón ahora tiene implementación real.
- `lib/screens/pizarra_v2/renderers/board_note_renderer.dart`: reescrito como StatefulWidget con TextEditingController + FocusNode, autoFocus en edición, save on every change, double tap para entrar en modo edición.
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: reescrito con callbacks individuales por tipo (onCreateNote, onCreateChecklist, etc.), crea elemento y abre editor correspondiente sin salir del pizarrón.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: reescrito con estados separados para cada editor (_showDrawingEditor, _showAudioEditor), createAndEdit() que crea elemento y abre editor, callbacks individuales al menu.
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart`: reescrito sin referencia a elemento específico, guarda al elemento de dibujo más reciente, onClose callback.
- `lib/screens/pizarra_v2/editors/board_audio_editor.dart`: reescrito sin referencia a elemento específico, guarda al elemento de audio más reciente, onClose callback.
- `lib/screens/pizarra_v2/editors/board_video_search.dart`: reescrito con onClose callback, no sale del pizarrón.
- `lib/screens/pizarra_v2/renderers/board_checklist_renderer.dart`: reescrito con edición de texto por item, asignación toggle, progress bar, delete items.
- `lib/providers/board_provider_v2.dart`: reescrito con saveToLocal inmediato en add/update, bool→int conversion para SQLite, JSON encode/decode para tags/data, markAsSeen con sync local+cloud, toggleArchive, offline-first load.
**Lecciones**:
- InteractiveViewer + GestureDetector anidados causan conflicto de gestos. Separar el GestureDetector del InteractiveViewer y usar panEnabled=false cuando hay selección resuelve el problema de "mover solo funciona una vez".
- hitTestBehavior.deferToChild permite que los hijos (TextField) reciban taps mientras el padre sigue recibiendo pan.
- TextField necesita FocusNode + autoFocus + addPostFrameCallback para funcionar dentro de un GestureDetector.
- Los editores (dibujo, audio, video) no deben recibir un elemento específico; deben crear uno nuevo y guardarlo al elemento más reciente de ese tipo.
- SQLite necesita bools como ints (0/1) y maps como JSON strings.
- El provider debe guardar en SQLite inmediatamente en add/update, no solo en debounce.
**Impacto**: 10 archivos reescritos, 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 1/2/3 del pizarrón, skill-pantallas.md, D-2 (Supabase), D-3 (SQLite)

## [2026-08-07] - FEATURE - Pizarrón v2: Etapa 3 (Polish - Vistas múltiples + Archivados + Tags + Búsqueda)
**Resumen**: Se agregaron vistas alternativas (lista, timeline, archivados), gestión de tags personalizados, campo isArchived, y navegación entre vistas desde el header.
**Cambios realizados**:
- `lib/models/board_element_v2.dart`: agregado campo `isArchived` con copyWith, toMap, fromMap.
- `lib/providers/board_provider_v2.dart`: `elements` filtra archivados, nuevos getters `allElements`, `archivedElements`, método `toggleArchive()`.
- `lib/database/database_helper.dart`: agregada columna `is_archived` a `board_elements_v2`.
- `lib/screens/pizarra_v2/widgets/board_list_view.dart` (nuevo): vista de lista con cards por elemento, tipo, autor, tags.
- `lib/screens/pizarra_v2/widgets/board_timeline_view.dart` (nuevo): vista timeline cronológico con línea vertical, dots por autor, tiempo relativo.
- `lib/screens/pizarra_v2/widgets/board_archived_view.dart` (nuevo): vista de archivados con botón restaurar.
- `lib/screens/pizarra_v2/widgets/board_tag_manager.dart` (nuevo): panel para crear/gestionar tags con colores, guardados en SQLite.
- `lib/screens/pizarra_v2/widgets/board_header.dart`: actualizado con selector de vista (tap en nombre cambia: Pizarra → Lista → Timeline → Archivados), botón de tags.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: enum `BoardViewMode`, integración de vistas, estado para tag manager.
**Lecciones**:
- Las vistas alternativas reusan los mismos datos del provider, solo cambian el renderer. Patrón escalable: nueva vista = nuevo widget + caso en el switch del build.
- `isArchived` filtra por defecto en `elements`, pero `allElements` incluye todo. Así las vistas de canvas/lista/timeline no muestran archivados, pero la vista de archivados sí.
- Los tags se guardan en SQLite (`board_tags`) y se cargan al iniciar el provider. Escalable: se pueden sync con cloud en el futuro.
- El header cambia de vista con un tap simple (ciclo: canvas → lista → timeline → archivados → canvas). Simple pero efectivo.
**Impacto**: 4 archivos nuevos, 5 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 2 del pizarra, skill-pantallas.md, D-2 (Supabase), D-3 (SQLite)

## [2026-08-07] - FEATURE - Pizarrón v2: Etapa 2b (Editores interactivos + Video Search + Audio Recording + Drawing Editor)
**Resumen**: Se agregaron editores interactivos para dibujo, audio y video. Drawing editor con herramientas (brush, eraser, line, rectangle, circle), colores y tamaño de pincel. Audio editor con grabación de voz y waveform en tiempo real. Video search dialog para pegar URLs de YouTube/TikTok.
**Cambios realizados**:
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart` (nuevo): editor de dibujo con canvas, herramientas (brush, eraser, line, rectangle, circle), paleta de 8 colores, slider de tamaño, undo, clear.
- `lib/screens/pizarra_v2/editors/board_audio_editor.dart` (nuevo): grabador de audio con waveform en tiempo real, botón record/stop, duración, guardado local.
- `lib/screens/pizarra_v2/editors/board_video_search.dart` (nuevo): dialog para pegar URLs de YouTube/TikTok, parseo automático de thumbnail YouTube, validación de URL.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: integrado con editores, estado para mostrar/ocultar editores.
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: callbacks para abrir editores específicos por tipo.
- `lib/models/board_element_data.dart`: agregado `copyWith` a `DrawingStroke`.
**Lecciones**:
- Drawing strokes se guardan como JSON de puntos. Si crecen mucho, futuro: renderizar a imagen y guardar en Storage.
- Audio recording usa `record` package que ya estaba en pubspec. Waveform se genera en tiempo real simulando amplitud.
- YouTube thumbnails se obtienen gratis via `img.youtube.com/vi/{id}/hqdefault.jpg`.
- Los editores se abren como bottom sheets para mantener contexto del pizarrón.
**Impacto**: 3 archivos nuevos, 3 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 2 del pizarrón, D-2 (Supabase), skill-pantallas.md

## [2026-08-07] - FEATURE - Pizarrón v2: Etapa 2 (Renderers por tipo + Checklist + Conectores + Drawing + Video + Audio)
**Resumen**: Se agregaron renderers específicos por tipo de elemento, modelos de datos type-safe, y soporte para checklist, drawing, video, audio y conectores con curvas bezier.
**Cambios realizados**:
- `lib/models/board_element_data.dart` (nuevo): modelos type-safe por tipo (ChecklistData, ConnectorData, VideoData, AudioData, DrawingData, SeparatorData, SubBoardData). Cada modelo serializa/deserializa al campo `data` de BoardElementV2.
- `lib/screens/pizarra_v2/renderers/` (nueva carpeta):
  - `board_note_renderer.dart`: renderer de notas con texto simple (formato rico completo en etapa futura).
  - `board_checklist_renderer.dart`: checklist con items, estados (pending/in_progress/done), asignación a Facu/Rocio, progress bar, reordenar.
  - `board_drawing_renderer.dart`: dibujo libre con strokes (brush, eraser, line, rectangle, circle). Renderiza con CustomPainter.
  - `board_video_renderer.dart`: video embed con thumbnail + play button. Soporta YouTube, TikTok, otros.
  - `board_audio_renderer.dart`: audio con waveform visual, botón play/pause, duración.
  - `board_connector_renderer.dart`: conectores con curvas bezier, líneas rectas, punteadas, etiquetas, flechas. Calcula posiciones en tiempo de renderizado desde elementos referenciados.
  - `board_element_renderer.dart`: widget unificado que delega al renderer específico según el tipo.
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: reescrito para usar renderers unificados, capa de conectores detrás de elementos, soporte para edición inline.
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: actualizado con botones para checklist, dibujo, video, audio, conector.
- `pubspec.yaml`: eliminada dependencia flutter_quill (API incompatible), se usa TextField simple por ahora.
**Lecciones**:
- flutter_quill tiene API inestable entre versiones. Mejor usar TextField simple + formato básico por ahora, agregar formato rico completo después.
- Los conectores no deben guardar posiciones, solo fromId/toId. Las posiciones se calculan al renderizar desde los elementos referenciados. Así se actualizan automáticamente cuando los elementos se mueven.
- Los renderers por tipo permiten escalabilidad: nuevo tipo = nuevo renderer + caso en el switch del renderer unificado.
- Drawing strokes como JSON pueden ser grandes. Futuro: renderizar a imagen y guardar en Storage, mantener solo path en `data`.
**Impacto**: 8 archivos nuevos, 3 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 1 del pizarrón, skill-pantallas.md (especificación del pizarrón), D-2 (Supabase)

## [2026-08-07] - FEATURE - Pizarrón v2: Etapa 1 (Sync + Offline + Estructura nueva)
**Resumen**: Se comenzó el rediseño completo del pizarrón basado en 100 preguntas respondidas. Etapa 1: nueva estructura de código, modelo de datos completo, provider con sync realtime + offline, canvas básico con notas, panel de edición, badge NUEVO, historial de actividad.
**Cambios realizados**:
- `lib/models/board_element_v2.dart` (nuevo): modelo completo con título, contenido, formato de texto (B/I/U, tamaño, color, fuente, alineación), color de fondo custom, emoji header, tags, prioridad, asignado, estado, colapsable, bloqueable, auto-size, badge NUEVO, autoría.
- `lib/providers/board_provider_v2.dart` (nuevo): provider con offline-first (SQLite cache), sync con Supabase, realtime, debounce para moves/resizes, actividad, tags guardados, markAsSeen.
- `lib/database/database_helper.dart`: versión 7 con tablas `board_elements_v2`, `board_activity`, `board_tags`.
- `lib/screens/pizarra_v2/` (nueva carpeta): pantalla reescrita desde cero en widgets separados:
  - `pizarra_screen_v2.dart`: pantalla principal con Stack de widgets.
  - `widgets/board_canvas.dart`: InteractiveViewer + grid de puntos grises + skeleton loading.
  - `widgets/board_header.dart`: header minimalista con nombre del tablero + search + actividad + indicador online.
  - `widgets/board_tools_menu.dart`: menú radial con botón + que expande herramientas.
  - `widgets/board_element_card.dart`: card de elemento con badge de autor (iniciales color), badge NUEVO, tags, prioridad, colapsado, bloqueado, animación scale bounce.
  - `widgets/board_element_panel.dart`: bottom sheet con opciones (editar, color, fuente, reacciones, comentarios, duplicar, bloquear, eliminar).
  - `widgets/board_search_panel.dart`: búsqueda con preview + filtros.
  - `widgets/board_activity_panel.dart`: panel lateral con historial de actividad.
  - `widgets/board_zoom_slider.dart`: indicador de zoom.
- `lib/main.dart`: registrado `BoardProviderV2`.
- `lib/screens/home_screen.dart`: navegación actualizada a `PizarraScreenV2`.
- `skill-pantallas.md`: agregada especificación completa del pizarrón (100 respuestas).
**Lecciones**:
- Los imports en subcarpetas necesitan `../../../` para llegar a `lib/`.
- `ConflictAlgorithm` viene de `sqflite`, no de `supabase_flutter`.
- Text no tiene `fontSize` como parámetro directo — va dentro de `TextStyle`.
- El modelo v2 es inmutable (`copyWith`) — cada actualización crea una nueva instancia.
- Offline-first: cargar SQLite primero, luego sync con cloud. Los elementos no sincronizados tienen `synced = 0`.
**Impacto**: 12 archivos nuevos, 3 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: skill-pantallas.md (especificación del pizarrón), D-2 (Supabase), D-3 (SQLite offline)

## [2026-08-07] - FEATURE - Skill de Pantallas y Sincronización (skill-pantallas.md) v2
**Resumen**: Se creó `skill-pantallas.md` en la raíz como regla obligatoria que documenta las reglas de sincronización entre Facu y Rocio, estructura de cada pantalla, estados visuales, navegación, colores por usuario y reglas de negocio por pantalla. **Versión 2**: se agregaron reglas de "todo comentable + todo reaccionable + todo interactuable".
**Cambios realizados**:
- `skill-pantallas.md` (nuevo, v2): Reglas generales de sync (todo en tiempo real, notificaciones solo por bot WhatsApp, colores por usuario, 4 estados por pantalla, mapa de navegación), **regla 6 "todo comentable"** (excepto chat que ya tiene reply), **regla 7 "todo reaccionable"** (long-press → emojis como WhatsApp, max 5 keys), **regla 8 "todo interactuable"** (no hay nada de solo lectura), fichas detalladas de 13 pantallas con filas de comentarios y reacciones, checklist de implementación actualizado, pantallas excluidas.
- Cada ficha incluye: tabla, sync, permisos, colores, reacciones, comentarios, estados visuales.
- Se excluyeron LoginScreen, SettingsScreen, MapaScreen, NotificationsScreen (simples o sin sync compleja).
**Lecciones**:
- El skill se creó iterativamente con 14 preguntas al usuario vía tool `question`.
- Formato elegido: reglas generales + fichas por pantalla (no tablas comparativas ni sección por pantalla pura).
- Las reglas de permisos son "por pantalla" — se documentaron las que ya existen en el código; las que no están confirmadas se pueden ajustar después.
- "Todo comentable" excluye chat porque ya tiene reply/swipe-to-reply.
- "Todo reaccionable" usa mismo formato que chat: long-press → 🥰😘😍:v xD :0 + custom, max 5 keys, 1 por usuario por key.
**Impacto**: `skill-pantallas.md` (nuevo, v2), `docs/contexto/historial.md`
**Relacionado con**: AGENTS.md (regla de leer docs antes), skill_visual.md, FURI-Nosotros-Skill.md

## [2026-08-07] - BUGFIX - Pizarrón: 12 bugs de UX/persistencia (dialogs, IDs, flechas, links, estados)
**Resumen**: Tras testear la pizarra como usuario se corrigieron bugs que rompían flujos reales: botones Crear de dialogs siempre deshabilitados, elementos sin id cloud (duplicados + no se podían conectar/borrar bien), flecha del conector al revés, editar link borraba comentarios, sub-tablero en (20,20), comentarios con snapshot stale, sin UI de error y skill_visual en carpeta/search.
**Cambios realizados**:
- `lib/models/board_element.dart`: `copyWith` ahora acepta `id`/`clearId`/`color`/`userId`. `toMap` usa `userId ?? AppState.myId` (no pisa autoría). `fromMap` acepta `data` como `Map` dinámico (no solo `Map<String,dynamic>`).
- `lib/providers/board_data_provider.dart`:
  - `add()` hace `.insert().select().single()` y fusiona el id cloud en la copia optimista (conserva x/y/data locales). Si falla, rollback del optimista.
  - Realtime: mergea optimista sin id (evita duplicados) y no pisa moves/resizes pendientes.
  - `delete()` limpia conectores huérfanos. Nuevo `deleteLocal` para elementos sin id. Getter `isEmpty`.
- `lib/screens/pizarra/pizarra_screen.dart`:
  - Dialogs con `StatefulBuilder` + `onChanged` (Crear se habilita al tipear). Helper `_promptText`.
  - Links: guarda URL normalizada en `content` + `data` sin borrar comments.
  - Sub-tablero spawnea en centro del viewport. Doble-tap board parsea `boardId` int/string. Back limpia selección.
  - Conectores: flecha en el destino (`_drawArrowhead(b, a)`), evita dupes del mismo par.
  - Move/resize/comentarios usan `_liveElement` (copia actual del provider, no el snapshot del build).
  - Borrar resuelve por id o por temp-id local. Banner + pantalla de error con retry.
  - skill_visual: carpeta board y panel búsqueda con fondo=borde.
- Tests: 12 board_element + 8 board_data_provider = 20 verdes. `flutter analyze` sin issues.
**Lecciones**:
- `onPressed: ctrl.text.isNotEmpty ? fn : null` se evalúa UNA vez al build del dialog → botón Crear queda null para siempre. Hay que `StatefulBuilder` + `onChanged`/`setState`.
- Insert sin `.select()` deja el elemento local sin id → no se puede conectar/borrar por id, y el realtime agrega un segundo. Siempre `insert().select().single()` y mergear.
- `_drawArrowhead(canvas, a, b)` con tip=a dibuja la punta en el origen; la punta va en el destino.
- `updateDataLocal(el, {url, title})` pisa el map entero y borra `comments`. Hay que `{...el.data, ...}`.
- En pan/resize el `el` del build queda stale tras el primer frame; hay que releer del provider (`_liveElement`).
**Impacto**: `lib/models/board_element.dart`, `lib/providers/board_data_provider.dart`, `lib/screens/pizarra/pizarra_screen.dart`, tests.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), historial pizarrón etapa 1/2.

## [2026-08-07] - FEATURE - Pizarrón: lienzo infinito + centrado + alta en el centro del visible + tipos limpiados
**Resumen**: El pizarrón tenía un límite de 20000px (`boundaryMargin` del InteractiveViewer) que cortaba el arrastre/zoom y se mostraba desde la esquina. Ahora el lienzo es infinito, arranca centrado en el origen, los elementos nuevos se colocan en el centro del viewport actual y se eliminaron los tipos `postit` y `arrow`.
**Cambios realizados**:
- `lib/screens/pizarra/pizarra_screen.dart`:
  - **Lienzo infinito**: grid movido a un `CustomPaint` en el Stack externo (espacio de pantalla) que repinta según la transformento actual, en vez de pintarlo dentro del InteractiveViewer limitado por el SizedBox. `boundaryMargin` de `EdgeInsets.all(_boardSize)` → `EdgeInsets.all(double.infinity)` y los `Stack` internos con `clipBehavior: Clip.none`, así los elementos pueden ubicarse y verse en cualquier parte sin recortarse.
  - **Centrado al iniciar**: `_goToCenter()` ahora centra el mundo en la pantalla usando `MediaQuery.size` (antes ponía `(-500, -400)`).
  - **Agregar al centro del viewport**: nuevo `_screenCenterToWorld()` (invierte `_transformController.value` y transforma el punto central de la pantalla a coordenadas mundo) usado en `_spawnAdd()` para ubicar el elemento centrado en el punto actual de la vista. Reemplazado `_randPos()` aleatorio.
  - **Tipos eliminados**: se quitó `postit` y `arrow` de las herramientas flotantes, del renderizado (`_buildElementBody`), del `_typeIcon`, del `onDoubleTap` para editar y de la referencia en el contenido por defecto.
**Lecciones**:
- Un lienzo "infinito" con InteractiveViewer se logra pintando el fondo en espacio de pantalla (superpuesto externo transformado por la matriz) en vez de dentro del hijo escalado; así dejas `boundaryMargin` infinito y no necesitás un SizedBox enorme ni límite.
- Para que los elementos aparezcan donde el usuario está viendo hay que traducir el centro de la pantalla al espacio mundo con la inversa de la transformación actual (`MatrixUtils.transformPoint(inverse, center)`), no usar coordenadas aleatorias.
- `_randPos()` dependía de la traslación actual + ruido; era la causa de que las notas aparecieran "en otro lado". El centrado por transform es más predecible.
**Impacto**: `lib/screens/pizarra/pizarra_screen.dart`
**Relacionado con**: D-4 (skill_visual — la grid/selección siguen usando fondo=borde), historial pizarrón etapa 1/2

## [2026-08-07] - BUGFIX - Crash de Firebase Messaging en Windows (MissingPluginException)
**Resumen**: Al abrir la app en desktop (Windows) tras el login, explotaba `MissingPluginException: No implementation found for method Messaging#getToken`. `NotificationService.initialize()` seteaba `_firebaseAvailable = true` (el singleton `FirebaseMessaging.instance` se crea sin tocar la plataforma) pero `firebase_messaging` no tiene plugin nativo en Windows → `registerTokenAfterLogin()` llamaba `getToken()` y lanzaba.
**Cambios realizados**:
- `lib/services/notification_service.dart`: nuevo getter `_supportsMessaging` (`!kIsWeb && (Platform.isAndroid || Platform.isIOS)`). En `initialize()` solo se instancia `_fcm` si la plataforma lo soporta; en desktop queda `null`. `registerTokenAfterLogin()` chequea `_supportsMessaging` y envuelve `getToken()`/`onTokenRefresh` en try/catch. Import de `foundation` para `kIsWeb`; removido import innecesario de `material`.
- Recompilados exe + APKs split-per-abi.
**Lecciones**:
- `FirebaseMessaging.instance` no lanza en plataformas sin plugin: devuelve un objeto. El crash aparece recién en el primer `MethodChannel` (`getToken`, `requestPermission`, `onMessage`). Hay que gatear por plataforma, no por éxito del singleton.
- Windows/Linux/macOS desktop no tienen `firebase_messaging` nativo; guardar con `kIsWeb` + `Platform.isAndroid/iOS`.
**Impacto**: `lib/services/notification_service.dart`
**Relacionado con**: D-7 (FCM), build exe Windows.

## [2026-08-07] - FEATURE - Pizarrón: comentarios+menciones (I), búsqueda (J) y tableros anidados (K)
**Resumen**: Etapa 2 de acercar el pizarrón a Milanote. Se agregaron comentarios por elemento con respuestas y highlight de menciones @, búsqueda integrada que zoom y selecciona el elemento, y tableros anidados (canvas por sub-tablero, breadcrumb, crear sub-tablero, elemento carpeta navegable).
**Cambios realizados**:
- **I. Comentarios**: métodos `_commentsOf`, `_openComments`, `_showCommentsSheet` (bottom sheet con lista + input, responder a un comentario con `replyTo`, highlight de `@menciones`), `_addComment`, `_deleteComment`, `_commentRow` y badge de contador en el elemento. Persisten en `data['comments']` vía `updateDataLocal`.
- **J. Búsqueda**: botón lupa en header → panel `_searchPanel`, `_searchResults` filtra por `content` y `data['title']` (excluyendo conectores), `_goToElement` transpone el transform al centro del resultado y lo selecciona.
- **K. Tableros anidados**: tabla `boards` (id, name, parent_id, created_at) con id=1 raíz "Pizarra" + RLS `full_access_boards`. Columna `board_elements.board_id BIGINT NOT NULL DEFAULT 1` + índice. `BoardElement` gana `boardId`. `BoardDataProvider` gana `_boardId`, `boardName`, `loadBoards`, `createBoard`, `setBoard`; `load()` filtra por `board_id`, el realtime ignora cambios de otros tableros, `add()` inyecta el tablero actual en el elemento. Pantalla: stack `_boardStack`, `_openBoard` (doble tap en elemento carpeta), `_goBackBoard`, `_createSubBoard` (dialog → crea board + agrega elemento tipo `board`), breadcrumb con nombre del tablero, body tipo `board` (carpeta + nombre + chevron).
- `supabase_schema.sql` y `supabase/migration_board_milanote.sql` actualizados con `boards`, `board_id`, `full_access_boards`. **PENDIENTE ejecutar migración en SQL Editor.**
- Tests: 2 nuevos en `board_element_test` (boardId default/serialización + copyWith). Total 59 verdes. `flutter analyze` sin issues en los 4 archivos tocados.
**Lecciones**:
- `firstOrNull` viene de `package:collection`; evitarlo con búsqueda manual para no sumar dependencia.
- Al agregar RLS hay que habilitarlo (`ENABLE ROW LEVEL SECURITY`) + policy `FOR ALL USING (true)` y `GRANT` sobre la secuencia (`boards_id_seq`), igual que `board_elements`.
- Un `showModalBottomSheet` con `StatefulBuilder` anidado en varios `Padding`/`SizedBox` es frágil de cerrar; reescribirlo plano (bloques indentados) reduce errores de paréntesis.
- Los tableros anidados necesitan que `add()` inyecte el `boardId` actual vía `copyWith`, no que el modelo conozca el tablero.
**Impacto**: `lib/models/board_element.dart`, `lib/providers/board_data_provider.dart`, `lib/screens/pizarra/pizarra_screen.dart`, `supabase_schema.sql`, `supabase/migration_board_milanote.sql`, `test/models/board_element_test.dart`.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual — tipo board usa fondo=borde, redondo, sin sombras), historial etapa 1 del pizarrón.

## [2026-08-07] - BUGFIX - Bot WhatsApp: enviarMensaje reintentaba y duplicaba la entrega 3x
**Resumen**: Tras re-vincular la sesión (fix LID), el bot ya entregaba pero cada mensaje llegaba 3 veces. Causa: `enviarMensaje` tenía bucle de reintentos (hasta 3) pensado para el escenario LID roto donde no se confirmaba la entrega. Una vez que la sesión quedó sana, el ACK tarda >8s en una sesión restaurada de Supabase, así que el timeout de 8s vencía antes del ACK y el bot volvía a mandar el mismo texto → duplicado 3x.
**Cambios realizados**:
- `bot-furi/bot.js`: `enviarMensaje` ya NO reintenta. Con la sesión sana, reenviar el mismo mensaje duplica la entrega: WhatsApp ya lo recibió aunque el ACK tarde. Ahora manda una vez, espera ACK con ventana generosa (20s), y cuenta como entregado si `sendMessage` resolvió aunque no llegue ACK oportuno. Devuelve `false` solo si `sendMessage` lanza.
**Lecciones**:
- La verificación con datos reales (insertar reto + correr el bot) reveló que "el mensaje no se confirma" ≠ "el mensaje no se entregó". Cuando el destinatario recibe pero el ACK se pierde, reintentar solo duplica.
- El reintento como parche de disponibilidad (para LID roto) es contraproducente una vez que la causa raíz (claves LID) se resuelve. Hay que quitar el reintento cuando la entrega ya funciona, o condicionarlo.
- El ACK en sesión restaurada de Supabase tarda más de 8s; usa una ventana de espera generosa (20s) para no mandar copias extra.
**Impacto**: `bot-furi/bot.js`
**Relacionado con**: D-10 (bot WhatsApp), fix sesión LID previo (mismo día)

## [2026-08-07] - BUGFIX - Bot WhatsApp: mensajes se quedaban "en cola" sin entregarse y se marcaban como notificados igual
**Resumen**: El bot "enviaba" mensajes que nadie recibía. Investigación end-to-end (inserción real de datos + ejecución del bot + seguimiento de ACK de entrega) reveló dos problemas:
1. **Entrega no confirmada**: `sendMessage` de Baileys resuelve apenas escribe al socket, NO cuando WhatsApp entrega. El bot cerraba la conexión ~1s después sin esperar el ACK, así que en CI (sesión efímera restaurada de Supabase) el mensaje quedaba encolado y se perdía.
2. **Marcado prematuro**: el bot marcaba el registro como "notificado" en `bot_notificaciones` ANTES de confirmar la entrega, por lo que nunca reintentaba — de ahí "el bot dice que las envió pero no llegaron".
3. **Causa raíz de la no-entrega**: la sesión guardada en Supabase está desincronizada con los nuevos IDs de dispositivo vinculado (LID) de WhatsApp. La sesión tiene `me.lid` (`36130036682897:2@lid`) y claves de cifrado (`session-*.json`) solo para los números normales, pero WhatsApp ahora enruta los contactos a `@lid` (ej. `83189842346022@lid`) para los que NO hay `session record` → `SessionError: No session record` → no se cifra → no se entrega → sin ACK. Las emociones sí llegaban porque matcheaban claves viejas; el resto (notas, metas, cartas, etc.) no.
**Cambios realizados**:
- `bot-furi/bot.js`: `enviarMensaje` ahora espera la confirmación del servidor (`esperarAck` escuchando `messages.update` con status >= SERVER_ACK, timeout 8s) con hasta 2 reintentos, y devuelve `true` solo si se confirma.
- `bot-furi/bot.js`: `marcarNotificado` ahora acumula en memoria (`marksPendientes`) en vez de escribir en la BD. Se persiste solo tras envío confirmado vía `flushMarksPendientes(num)`. Si el envío falla, el registro NO se marca y se reintenta en la próxima corrida (no se pierde).
**Lecciones**:
- `sendMessage` NO garantiza entrega: resuelve al escribir en el socket. Para CI efímero hay que esperar el ACK (`messages.update` status 1/2/3) y reintentar.
- Nunca marcar un registro como "notificado" antes de confirmar la entrega: causa pérdida silenciosa e irreversible.
- WhatsApp migró de enrutar por número (`@s.whatsapp.net`) a IDs de dispositivo vinculado (`@lid`). Si la sesión guardada no tiene claves de cifrado para los `@lid` de los contactos, los mensajes se encolan pero jamás se cifran/entregan. **Fix permanente**: re-vincular el número del bot escaneando QR de nuevo (borrar `auth/` + re-escanear) para regenerar claves LID válidas, y luego subir la sesión nueva a Supabase.
**Impacto**: `bot-furi/bot.js`
**Pendiente**: re-vincular WhatsApp del bot (escaneo QR) para regenerar claves LID; sin eso, el código mejora el comportamiento pero WhatsApp seguirá sin poder cifrar a los contactos migrados a LID.
**Relacionado con**: D-10 (bot WhatsApp), bot-whatsapp.md

## [2026-08-07] - FEATURE - Pizarrón Milanote-style: selección+resize, imágenes, links y conectores
**Resumen**: Primera etapa de acercar el pizarrón a Milanote. Se extendió el modelo de elementos para soportar capas (z), metadatos flexibles (data JSONB) y 3 tipos nuevos: imagen, link y conector. Se agregó selección con borde, 8 handles de resize, traer al frente, subida de imágenes a Supabase Storage, cards de link con favicon y líneas/flechas que siguen a los elementos.
**Cambios realizados**:
- `lib/models/board_element.dart` (nuevo): modelo extraído del provider. Campos nuevos `z` (int, capas) y `data` (Map JSONB). Tipos `image`, `link`, `connector`. `copyWith` ampliado (width/height/data/z), getter `center`. Test en `test/models/board_element_test.dart`.
- `lib/providers/board_data_provider.dart`: importa el modelo. Nuevos `resizeLocal`/`resize`, `bringToFront` (z=max+1 persistido), `updateDataLocal`/`_updateData`. `move`/`resize` con throttle unificado en `_flushPending` (moves + resizes). Realtime reescrito: maneja delete vía `oldRecord['id']` y evita el null-check de `newRecord`. Getter `zOrdered`. Test en `test/providers/board_data_provider_test.dart`.
- `lib/services/board_media_service.dart` (nuevo): bucket privado `board-media`, `uploadImage` (XFile→File), `downloadImage` con cache en memoria, `deleteImage`.
- `supabase/migration_board_milanote.sql` (nuevo): `ALTER board_elements ADD z INTEGER`, `ADD data JSONB`, crea bucket `board-media` privado + policies. **PENDIENTE ejecutar en SQL Editor**. `supabase_schema.sql` actualizado.
- `lib/screens/pizarra/pizarra_screen.dart`: reescrito. Selección con borde, 8 handles de resize (esquinas + bordes, mínimo 40px), traer al frente, render de imagen (bytes con cache), card de link con favicon (google s2) y host, conectores dibujados en capa `CustomPaint` que se autoposicionan entre los centros de los elementos y siguen al moverlos (flecha, opcional punteada). Modo conector: elegir origen → icono timeline → elegir destino.
**Lecciones**:
- Un modelo `const` no puede inicializar `createdAt` con `DateTime.now()` en el initializer; hay que sacar el `const` del constructor o recibir el valor.
- La pantalla quedó dos veces "casi lista" con código muerto y métodos sin definir (`_deleteDot`, extensiones `moveElement` que no existían en el provider). Lección: verificar cada símbolo referenciado contra el provider/API real antes de asumir que compila, y no encolar archivos con clases placeholder.
- Supabase Storage `.upload` espera `File` (dart:io), no `XFile` de image_picker; hay que convertir con `File(file.path)`.
- El callback de realtime: en eventos DELETE `newRecord` puede venir vacío/no-null; usar `oldRecord['id']` para resolver el id borrado.
**Impacto**: 4 archivos nuevos/modificados en `lib/`, `supabase_schema.sql`, `supabase/migration_board_milanote.sql`, 2 archivos de test.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), errores-conocidos (sin nuevos)
**Pendiente**: ejecutar `migration_board_milanote.sql` en prod; en la etapa 2 (B/D/G/H) quedan notas con formato rico, tareas/checkbox, tableros anidados, cursor de la pareja y menciones.

## [2026-08-06] - BUILD - Firma de release propia (keystore) para APK instalable en otro celular
**Resumen**: El APK release usaba la firma `debug` (el default de Flutter), lo que impedía reinstalar sobre versiones previas y era marcada como no fiable por Realme. Se configuró un keystore de release propio y la firma automática del build release.
**Cambios realizados**:
- Generado `android/app/upload-keystore.jks` (SHA256withRSA 2048, validez 10000 días, alias `upload`) vía `keytool` de JDK en `D:\jdk17\jdk17`.
- Creado `android/key.properties` con storePassword/keyPassword/keyAlias/storeFile.
- `android/build.gradle.kts`: carga `key.properties`, agrega `signingConfigs { create("release") }` y lo usa como `signingConfig` del `buildTypes.release` (en vez de `debug`).
- `.gitignore`: excluye `android/key.properties` y `android/app/*.jks`/`*.keystore`.
- `documentacion/GUIA_INSTALACION_APK.md`: guía de instalación para el Realme C11 (permiso apps desconocidas, desinstalar versión vieja). `docs/contexto/flujo-de-trabajo.md`: sección de firma de release.
- Compilado `app-release.apk` (63.5 MB) y verificado con `apksigner` que el certificado es `CN=Furi, ..., C=AR` (no el debug).
**Lecciones**:
- Flutter firma el release con `debug` por defecto; para entregar un APK re-instalable hay que definir un `signingConfig` de release con keystore propio. Sin `key.properties`, el release compila pero con firma vacía → Android no lo instala.
- Realme/Android piden permisos de "instalar apps desconocidas" por-app y no permiten reemplazar otra firma sin desinstalar. Son dos causas distintas a comunicarle a quien instala.
- El `jarsigner -verify` no reporta el CN en entradas de ZIP de v2 signing; usar `apksigner arbitrio --print-certs` del build-tools para confirmar.
**Impacto**: `android/app/upload-keystore.jks` (nuevo, no commiteado), `android/key.properties` (nuevo, no commiteado), `android/app/build.gradle.kts`, `.gitignore`, `documentacion/GUIA_INSTALACION_APK.md`, `docs/contexto/flujo-de-trabajo.md`
**Relacionado con**: flujo-de-trabajo (build APK), errores-conocidos (pantalla negra), instalación en otro celular

## [2026-08-06] - FEATURE+BUGFIX - Bot segmentado por usuario, sync de clases viejo, errores y schema
**Resumen**: Sesión de cierre de pendientes: el bot de WhatsApp ahora enruta cada notificación solo a la persona que NO la generó (cada uno ve solo lo que agrega la otra), sincronización automática de las clases existentes de SQLite que jamás se subieron a Supabase, logging para catches silenciosos, y schema SQL maestro completo.
**Cambios realizados**:
1. **Bot segmentado por destinatario** (`bot-furi/bot.js`):
   - Nuevo `cargarUsuarios()` que mapea `profiles.id` → identidad (facu/rocio).
   - Nuevo `destinosPara(usuarios, creatorId)`: si el creador del registro es Facu vai a ROCIO_NUMERO y viceversa; si no se identifica el creador, va a ambos (default).
   - `yaNotificado()` ahora filtra por `phone` además de `(tabla, registro_id)` para permitir tracking por destinatario.
   - `verificarYNotificar()` acumula en `mensajesPorNum` (map phone → textos) en vez de un array único, y envía a cada destinatario solo su difusión.
   - Aniversarios seguien compartidos (van a ambos, son fechas de pareja).
   - Mapeo por columna de creador por tabla: schedules→`user_id`, class_schedules→`user_id`, moods→`user_id`, letters→`from_user`, challenges→`couple_id`, goals→`couple_id`, tasks→`created_by`, transactions/gallery/notes/timeline→`user_id`, custom_questions→`from_user`.
2. **Sync automático de clases viejas**:
   - SQLite sube a versión 6 (`cloudId INTEGER` en `class_schedules`).
   - `ClassSchedule` gana `cloudId`.
   - `ClassScheduleProvider._syncUnsyncedToSupabase()` corre dentro de `loadSchedules()`: sube a Supabase toda clase con `cloudId == null` y guarda el id cloud devuelto.
   - `_pushToSupabase()` ahora usa `cloudId` como PK cloud para update/delete (antes usaba el id local de SQLite, que NO coincide con el BIGSERIAL de Supabase → update/delete apuntaban a fila equivocada).
   - `addSchedule()` persiste `cloudId`; `deleteSchedule()` borra por id cloud.
3. **Errores silenciosos con logging** (`lib/`):
   - `catch (_) {}` reemplazados por `developer.log` con contexto en: `chat_provider.dart` (marks), `chat_media_service.dart` (delete cloud), `chat_screen.dart` (sendText/sendMedia), `home_screen.dart` (checkClassSetup), `calendar_home_screen.dart`, `metas_screen.dart`, `retos_screen.dart`.
   - Excepción: `sound_service.dart` y pizarra (parse de color) se dejan silenciosos (fallo intencional/no-Supabase).
4. **Schema master completo** (`supabase_schema.sql`):
   - Aclaraba `class_schedules` (tabla nueva) + índice `day_of_week`.
   - `gallery_comments` (tabla) + índice.
   - Columnas nuevas consolidadas en el CREATE: `gallery.description`, `gallery.reactions`, `goals.completed_by`, `letters.seen_by`, `challenges.seen_by`.
   - RLS + policies para `gallery_comments` y `class_schedules`.
   - Pendiente: ejecutar las migraciones en prod (class_schedules, gallery_comments, seen_by, etc.) para DBs ya existentes.
**Lecciones**:
- El problema del sync de clases era doble: (a) las clases viejas se quedaron solo en SQLite porque el sync se agregó después; (b) el update/delete en código usaba `eq('id', idLocalDeSQLite)` pero Supabase asigna su propio BIGSERIAL → update/delete apuntaban a filas que no existen (o a otras). La solución correcta es guardar explícitamente el `cloudId` devuelto por el insert y usarlo como PK cloud.
- Para enrutar notificaciones por usuario, el bot necesitó conocer el mapeo `user_id` (UUID) → identidad, que vive en `profiles`. No basta comparar strings de identidad (algunas tablas guardan `profile.id`, otras guardan `text`).
- La tabla `bot_notificaciones` no estaba diseñada para enviar distinto a cada destinatario: había que agregar el filtro por `phone` en el `yaNotificado`, de lo contrario la primera verificación marcaria el key y bloquearía el envío al segundo destino.
**Impacto**: `bot-furi/bot.js`, `lib/models/class_schedule.dart`, `lib/providers/class_schedule_provider.dart`, `lib/database/database_helper.dart`, `lib/providers/chat_provider.dart`, `lib/services/chat_media_service.dart`, `lib/screens/chat_screen.dart`, `lib/screens/home_screen.dart`, `lib/screens/calendar/calendar_home_screen.dart`, `lib/screens/metas_screen.dart`, `lib/screens/retos_screen.dart`, `supabase_schema.sql`, `test/models/class_schedule_test.dart`, docs
**Relacionado con**: D-10 (bot), D-3 (SQLite), errores-conocidos (schema faltante, bot)

## [2026-08-06] - BUGFIX - Notificaciones del chat duplicadas con la app abierta
**Resumen**: Cada mensaje nuevo generaba 2 notificaciones locales cuando la app estaba abierta. Habia dos mecanismos simultaneos para el mismo evento: el push FCM (trigger `notify_new_message` -> Edge Function `send-push` -> `onMessage` -> `_showLocalNotification`) y el Realtime local (`startListening` escucha INSERT en `messages` -> `_showLocalNotification`). Ambos mostraban una notificacion para el mismo mensaje.
**Cambios realizados**:
- `lib/services/notification_service.dart` (`_listenFCMForeground`): ahora ignora los mensajes de FCM con `data['type'] == 'message'`, porque ese caso ya lo cubre el Realtime cuando la app esta abierta. El push FCM sigue funcionando para app cerrada (background handler), y el Realtime cubre app abierta. Resultado: 1 notificacion por mensaje.
- Tests 45 verdes, analyze sin errores nuevos en el archivo.
**Lecciones**:
- En este stack hay doble via de notificacion para el chat: FCM (por trigger de BD, pensado para app cerrada) y Realtime local (para app abierta). Cuando la app esta en foreground ambos se disparan y duplican. La solucion es que FCM foreground no muestre el tipo `message` y delegue al Realtime.
- El `onMessage` de FCM se dispara tambien con la app abierta; no hay que mostrar localmente lo que ya muestra el canal Realtime.
**Impacto**: `lib/services/notification_service.dart`
**Relacionado con**: D-7 (FCM), errores-conocidos (sin nuevo)

## [2026-08-06] - FEATURE - Bot WhatsApp: clases recurrentes en Supabase + aviso antes de empezar
**Resumen**: Las clases configuradas vivian solo en SQLite local (`class_schedules` del dispositivo), por lo que el bot de WhatsApp (que solo consulta Supabase) no podia avisar cuando empiezan. Se agrego la tabla `class_schedules` en Supabase, doble escritura en el provider, y una categoria #14 de clases en el bot que avisa el titulo y horario de las clases de hoy en las proximas 2h.
**Cambios realizados**:
- `supabase/migration_class_schedules.sql` (nuevo): crea la tabla `class_schedules` (id BIGSERIAL PK, `day_of_week` int, `class_type_id` bigint, `start_time`/`end_time` text, `title`, `professor`, `user_id` text, `color` int default 4286262670 = 0xFF7B2D8E, `created_at`/`updated_at` timestamptz) + indice por `day_of_week`. Idempotente (IF NOT EXISTS). Pendiente ejecutar en SQL Editor.
- `lib/models/class_schedule.dart`: nuevo `toSupabaseMap()` que mapea a snake_case (`day_of_week`, `start_time`, `end_time`, `user_id`, `color`).
- `lib/providers/class_schedule_provider.dart`: `addSchedule`, `updateSchedule` y `deleteSchedule` ahora sincronizan con Supabase (ademas de SQLite). Insert reserva el id autoincremental de SQLite (no se usa como PK cloud); `_pushToSupabase(map, id)` hace update vs insert segun corresponda.
- `bot-furi/bot.js`: nueva categoria #14 `CLASS_SCHEDULES`. Consulta `class_schedules`, filtra las de hoy (`day_of_week === hoy`), y avisa las que empiecen en las proximas 2h con `📚 *Clase: titulo*` + horario (inicio o inicio-fin) + "En X minutos". Tracking key `class-{id}-{date}-{start_time}`.
- `docs/contexto/bot-whatsapp.md`: tabla ahora lista 14 categorias (arreglado: antes decia 14 pero el titulo era "12"). `docs/contexto/glosario.md`: `class_schedules` ahora SQLite + Supabase.
**Lecciones**:
- No hay RPC `pg_sql` disponible en el proyecto; para DDL hay que ejecutar la migracion en el SQL Editor de Supabase (manual, como las demas).
- La conversel de dia es trampa: Dart `DateTime.weekday` es 1=lunes..7=domingo, pero JS `Date.getDay()` es 0=domingo..6=sabado. Hay que convertir `jsDia === 0 ? 7 : jsDia` antes de comparar con `day_of_week`.
- El bot avisa clases a TODOS los destinatarios (no separa por `user_id`); el `user_id` de la clase se usa para saber de quien es, pero el aviso se manda a FACU y ROCIO por igual (la app es de pareja compartida).
**Impacto**: `supabase/migration_class_schedules.sql`, `lib/models/class_schedule.dart`, `lib/providers/class_schedule_provider.dart`, `bot-furi/bot.js`, docs.
**Relacionado con**: D-3 (SQLite), D-10 (bot), bot-whatsapp.md

## [2026-08-06] - FEATURE - Bot WhatsApp: categoria #13 de preguntas del boton ❓
**Resumen**: El bot no avisaba cuando alguien creaba/respondia una pregunta en la seccion "Nosotros" (boton ❓). La causa: esa pantalla guarda las preguntas en la tabla `custom_questions` (no en `daily_questions`/`question_answers`, que estaban vacias), y el bot no tenia categoria para esa tabla. El usuario creo carta, reto, pregunta y favorito, corrio el bot manualmente en GitHub Actions y no le llego nada por WhatsApp.
**Cambios realizados**:
- `bot-furi/bot.js`: nueva categoria #13 `CUSTOM_QUESTIONS`. Consulta `custom_questions` de la ultima hora, une `from_user:profiles!from_user(name)`, y avisa con `❓ *<nombre>* te hizo una pregunta nueva` (si `answer` es null) o `❓ *<nombre>* respondio una pregunta` (si tiene `answer`/`answered_at`). Tracking key `question-{id}`, tabla `custom_questions` en `bot_notificaciones`.
- `docs/contexto/bot-whatsapp.md`: tabla de categorias ahora lista 13 (custom_questions) y flujo "Itera las 13 categorias".
- Verificado end-to-end de forma real: el envio de WhatsApp funciona (test directo a FACU y ROCIO), el bot detecto y registro 3 preguntas en `bot_notificaciones` (incluidas `question-17` y `question-18` que el usuario habia creado y nunca se habian avisado), y envio el WhatsApp. Se inserto y luego elimino una pregunta de prueba (id 19) y su notificacion para no polucionar datos.
**Lecciones**:
- El bot funciona (detecta y envia). El problema era de cobertura de tablas: una funcionalidad de la app (preguntas de Nosotros) escribia en `custom_questions`, que no estaba en lista del bot. Ante "el bot no avisa", lo primero es mapear en que tabla escribe cada pantalla y comparar contra las categorias del bot.
- El envio a WhatsApp se confirmo de forma aislada (script `_test_send.mjs` con `sock.sendMessage` OK a ambos numeros), separando "deteccion" de "envio". El bot envia DESDE el numero del bot (`MI_NUMERO`), no desde el usuario.
- Nota: el cliente `@supabase/supabase-js` de Node 20 necesita `realtime: { transport: WebSocket }` o falla con "Node.js 20 detected without native WebSocket support"; para scripts de diagnostico sin realtime se puede usar REST fetch directo.
**Impacto**: `bot-furi/bot.js`, `docs/contexto/bot-whatsapp.md`, `docs/contexto/historial.md`
**Relacionado con**: D-10 (bot WhatsApp), bot-whatsapp.md

## [2026-08-06] - FEATURE - Ticks de chat en 3 estados (enviado/entregado/leído)
**Resumen**: El chat ahora distingue 1 palomita (enviado), 2 palomitas (entregado) y 2 palomitas azules (leído), tipo WhatsApp. Antes solo había enviado (✓) y leído (✓✓).
**Cambios realizados**:
- `lib/models/message.dart`: nuevo enum `MessageTick { sent, delivered, read }` y getter `tickState` que prioriza `readAt` > `deliveredAt` > `sent`. El modelo ya tenía `deliveredAt`/`readAt`.
- `lib/providers/chat_provider.dart`: nuevo `markIncomingDelivered()` que escribe `delivered_at` en los mensajes recibidos por realtime sin marcarlos como leídos. El callback de realtime insert ahora llama a `markIncomingDelivered()` en vez de `markIncomingRead()`. `markIncomingRead()` se mantiene para cuando se abre el chat (escribe `read` + `read_at`).
- `lib/screens/chat_screen.dart`: el tick renderiza según `message.tickState` — sent → `Icons.done`, delivered → `Icons.done_all`, read → `Icons.done_all` en azul `#4FC3FF`.
- `test/models/message_test.dart`: 3 tests nuevos para `tickState`. Total 45 tests verdes, analyze sin errores.
**Lecciones**:
- "Entregado" en una arquitectura servidor-local sin push de entrega confiado se define como "el dispositivo de la pareja recibió el mensaje por realtime sin abrirlo". "Leído" = abrir el chat. No hay confirmación de servidor de "entregado" como en WhatsApp; es una aproximación.
- El `copyWith` del modelo ya soportaba `deliveredAt`/`readAt`, solo faltaba propagarlos y renderizarlos.
- Separar el mark de realtime (entregado) del de apertura (leído) evita que el mensaje salte directo a azul antes de que la pareja abra el chat.
**Impacto**: `lib/models/message.dart`, `lib/providers/chat_provider.dart`, `lib/screens/chat_screen.dart`, `test/models/message_test.dart`
**Relacionado con**: feature chat media/reacciones previo, errores-conocidos (ticks de chat)

## [2026-08-06] - BUGFIX - Pizarrón abría en la esquina, ahora aparece centrada
**Resumen**: Al abrir la pizarra, el lienzo quedaba en la esquina superior izquierda (posición identidad). Ahora se centra automáticamente al primer frame.
**Cambios realizados**:
- `lib/screens/pizarra/pizarra_screen.dart`: `initState` agrega `WidgetsBinding.instance.addPostFrameCallback((_) => _goToCenter())` para centrar la transformación tras el primer frame, reusando `_goToCenter()` existente (`translate(-500, -400)`).
**Lecciones**:
- `TransformationController` arranca en identidad; para mostrar un lienzo infinito centrado hay que setear la transformación después del primer frame con `addPostFrameCallback`.
**Impacto**: `lib/screens/pizarra/pizarra_screen.dart`
**Relacionado con**: D-4 (skill_visual — sin cambio de estilo)

## [2026-08-06] - BUGFIX - Chat: barra de escribir saltaba arriba con el teclado
**Resumen**: Al tocar el campo de escribir aparecía el teclado y la barra de input se iba super arriba. Causa: doble-conteo de insets. `Scaffold` tenía `resizeToAvoidBottomInset: true` (default), así que el body ya se encogía con el teclado; además `_inputArea` y `_replyBanner` sumaban `MediaQuery.of(context).viewInsets.bottom`, volviendo a reservar el alto del teclado → el input flotaba ~`keyboard` px por arriba.
**Cambios realizados**:
- `lib/screens/chat_screen.dart`: `Scaffold` ahora con `resizeToAvoidBottomInset: false` (el layout se posiciona manualmente).
- `_msgArea` dejó de usar `height: areaH = h * 0.76` fija y ahora usa `bottom: keyboard + 8 + h * 0.09 + 4`, así la lista se acorta contra el input cuando el teclado aparece (la última línea queda visible sobre la barra).
- `_inputArea`/`_replyBanner` ya usaban `viewInsets` — ahora sin doble-conteo son correctos.
- Tests 42 verdes, `flutter analyze` sin issues.
**Lecciones**:
- Con `resizeToAvoidBottomInset: true` (default) el Scaffold ya completa el teclado; sumar `viewInsets.bottom` en los `Positioned` del Stack produce doble reserva. Hay que elegir un solo mecanismo: o dejar que el Scaffold encoga el body y NO usar `viewInsets`, o poner `resizeToAvoidBottomInset: false` y posicionar con `viewInsets` explícito.
- Un `Positioned` en un `Stack` con `bottom: keyboard + X` es la forma de subir el input con el teclado cuando el body no se encoge.
**Impacto**: `lib/screens/chat_screen.dart`
**Relacionado con**: D-4 (skill_visual — sin cambio de estilo, solo layout), errores-conocidos (sin nuevo)

## [2026-08-06] - BUGFIX - Migración favorites: columna subtitle inexistente
**Resumen**: La migración `migration_favorites_dual_rating.sql` fallaba con `ERROR 42703: column "subtitle" does not exist`. En la BD la columna legacy era `title` (no `subtitle`). PostgreSQL compila el `UPDATE ... SET critica = subtitle` al vuelo y falla aunque después haya un `DROP COLUMN IF EXISTS`, porque el parseo del statement __ completo antes de ejecutarse.
**Cambios realizados**:
- `supabase/migration_favorites_dual_rating.sql`: reescrita con bloque `DO $$ ... $$` PL/pgSQL que consulta `information_schema.columns` para saber si `subtitle`/`rating` existen antes de referenciarlas, usando `EXECUTE` dinámico solo cuando la columna está presente.
- Sigue siendo idempotente: `ADD COLUMN IF NOT EXISTS` + chequeos condicionales.
**Lecciones**:
- PostgreSQL valida la existencia de columnas al compilar el statement completo, NO línea por línea. Un `UPDATE` que referencia una columna inexistente falla con 42703 en runtime aunque venga un `DROP COLUMN` después.
- Para migraciones que tocan columnas legacy opcionales, hay que chequear `information_schema.columns` dentro de un bloque `DO` y usar `EXECUTE` con SQL dinámico.
**Impacto**: `supabase/migration_favorites_dual_rating.sql`
**Relacionado con**: D-2 (Supabase), errores-conocidos (migración favorites)

## [2026-08-06] - BUGFIX - Bot WhatsApp fallaba en GitHub Actions (validación de sesión rota)
**Resumen**: El bot en GitHub Actions dejó de funcionar: timeout de 60s porque nunca lograba restaurar la sesión. La causa era una validación JS rota y un fix previo que la agravó.
**Cambios realizados**:
- `bot-furi/bot.js`: la validación de sesión ahora lee el contenido de `creds.json` (`me.id`) y compara con `MI_NUMERO`, usando **índice `[0]`** en vez de `.first`.
  - Primera reescritura usó `creds.json.me.id` pero con `.first` (propiedad inexistente en arrays de JS → `undefined`) → la validación fallaba siempre.
  - El número en `me.id` viene con sufijo de dispositivo: `5493786499129:1@s.whatsapp.net`. Se quita `@s.whatsapp.net` y se toma `split(':')[0]` para aislar el número puro `5493786499129`.
- Diagnóstico: `bot_sessions.session_data` en Supabase confirmó que `creds.json.me.id` = `5493786499129:1@s.whatsapp.net` y `MI_NUMERO` = `5493786499129` (coincidían).
- Local: build-show del bot conecta, verifica 12 categorías y termina limpio. Los errores "failed to decrypt message" en log son inofensivos (mensajes de estado).
**Lecciones**:
- Los arrays de JS NO tienen `.first` (propiedad de Dart). En JS hay que usar `[0]`. El `node --check` no lo detecta (es error en runtime).
- En CI no existe la carpeta `auth/` local (está en .gitignore): si la validación contra Supabase falla, el bot pide QR y muere por timeout. La restauración de sesión desde Supabase es crítica para CI.
- La vieja validación chequaba el número en los NOMBRES de archivo; la correcta es leer `creds.json.me.id`.
**Impacto**: `bot-furi/bot.js`, `docs/contexto/bot-whatsapp.md`
**Relacionado con**: D-10 (bot WhatsApp), errores-conocidos (sesión no coincide)

## [2026-08-06] - FEATURE - Reacciones, galería social, ticks de chat, quien valida metas y "visto" tipo WhatsApp
**Resumen**: Implementadas 8 mejoras de interacción de pareja. Se agregó la reacción `:0`, descripción+reacciones+comentarios por foto en galería, corrección del sistema de ticks de chat (faltaban columnas `delivered_at`/`read_at`), indicación de quién completó cada meta, y sistema de "visto" en Supabase para retos/cartas que solo swapean no-cumplidos y no-leídas. También se corrigió el contraste del popup de finanzas y el botón OK de edición en el pizarrón.
**Cambios realizados**:
- `lib/models/message.dart`: agregado `:0` a `defaultReactionEmojis` (ahora 6).
- `test/models/message_test.dart`: test actualizado a 6 reacciones.
- `lib/screens/finanzas/finanzas_screen.dart`: botón `INGRESO` del popup usa `_cIncome` (verde oscuro) en vez de `_c` (= fondo del dialog, invisible). Texto de botón activo en blanco para contraste.
- `lib/screens/pizarra/pizarra_screen.dart`: `_buildElement` recibe `id` consistente con el mapa de edición (antes el nuevo elemento sin ID usaba 0 y el OK fallaba); `_finishEditing` resuelve el elemento por `id` o `createdAt` y llama `updateContentLocal`. Notas ahora cumplen skill_visual: fondo sólido, borde = fondo, sin boxShadow, texto oscuro `#111111`, botón de confirmación como icono `Icons.check` (no texto "OK").
- `lib/providers/board_data_provider.dart`: nuevo `updateContentLocal(BoardElement el, String content)` para persistir/actualizar contenido en elementos recién creados (sin ID de BD aún); si tiene ID delega a `updateContent()`.
- `lib/providers/gallery_provider.dart`: `GalleryItem` con `description` y `reactions` (JSONB, mismo formato que messages); nuevo modelo `GalleryComment`; provider con `comments`, `updateDescription`, `toggleReaction`, `addComment`, `deleteComment`, `loadComments`.
- `lib/screens/galeria/galeria_screen.dart`: pantalla full-screen rediseñada con panel de detalle (descripción editable con dialog, reacciones al texto con tap, lista de comentarios con input y borrado). Se cargan comentarios al abrir la foto.
- `lib/screens/metas_screen.dart`: `_toggle` guarda `completed_by: AppState.myId` al completar (y null al desmarcar); la card muestra una insignia F/R de quién completó la meta.
- `lib/screens/nosotros_screen.dart`: `_loadPartnerLetter` solo presenta cartas no leídas por `myId` y las marca como vistas vía `seen_by`; `_partnerRetos` filtra solo no-cumplidos; `_markSeen` (agrega `myId` al array JSONB `seen_by`). `_buildCartasIcon` usa `seen_by` en vez de `is_opened`.
- `lib/providers/chat_provider.dart`: `markIncomingRead` ya escribe `delivered_at`/`read_at` (ver migración).
- Migraciones SQL nuevas en `supabase/`: `migration_gallery_comments.sql`, `migration_goals_completed_by.sql`, `migration_seen_system.sql`; ampliada `migration_chat_media_reactions.sql` con `delivered_at` y `read_at` (TIMESTAMPTZ).
- `bot-furi/bot.js`: validación de sesión reescrita — en vez chequear el número en los nombres de archivo, se lee el contenido de `creds.json` (`me.id` → `<pais><numero>:<dev>@s.whatsapp.net`) y se compara con `MI_NUMERO`.
- Tests 42 verdes, `flutter analyze` 0 errores.
**Lecciones**:
- Los ticks de "visto" del chat dependían de columnas que el modelo insertaba pero la BD no tenía (`delivered_at`/`read_at`): el update fallaba con PGRST204 y se tragaba con `catch (_) {}` → nunca salía el doble visto. Cualquier columna referenciada en `toMap`/update debe existir en la BD cloud.
- El "visto" entre personas debe vivir en Supabase (columna `seen_by` JSONB con array de user_id) para que la otra identidad sepa que ya fue leído; `letters.is_opened` ya no alcanza para diferenciar quién lo leyó.
- En un provider optimista, editar un elemento "recién creado" sin ID de BD requiere actualizar por referencia de objeto (`identical`/atributos únicos), no por `eq('id')`.
- La validación de sesión por nombre de archivo es frágil; la correcta es leer `creds.me.id`.
**Impacto**: 8 archivos en `lib/`, 4 migraciones SQL, `bot-furi/bot.js`, test.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual), errores-conocidos (ticks de chat resuelto)

---

## [2026-08-06] - BUGFIX - APK muestra pantalla negra en Android (sqflite FFI de desktop en móvil)
**Resumen**: Los APK compilados abrían pero quedaban en pantalla negra en el celular (mirado con ADB: proceso vivo pero sin frames). El `main.dart` forzaba `sqfliteFfiInit()` + `databaseFactoryFfiNoIsolate` en TODAS las plataformas. Estas llamadas son para desktop (cargan libsqlite3 por FFI); en Android esa librería la provee `sqlite3_flutter_libs`, que NO estaba en pubspec.yaml, por lo que `sqfliteFfiInit()`/`DatabaseHelper().database` lanzaban una excepción antes de `runApp` → pantalla negra silenciosa. Además, el APK instalado se había compilado con el `main.dart` viejo (commit `61ca588`, sin el manejo de errores con pantalla roja, agregado después a las 21:04) → el error no era visible.
**Cambios realizados**:
- `lib/main.dart`: el bloque `sqfliteFfiInit()`/`databaseFactoryFfiNoIsolate` ahora se ejecuta solo si `isDesktop` (`!kIsWeb && (windows || linux || macOS)`). En Android/iOS se deja el factory nativo de `sqflite` (default del plugin) sin override.
- Compilado APK release (63.4 MB, 74s), instalado via `adb install -r` en Xiaomi Redmi Note 10 (`vgbqzhbux8amkn5x`).
- Verificación: `adb logcat` sin errores `FATAL`/`sqlite`, proceso comp.furiapp.furi_app vivo, `BufferQueueProducer` reporta renderizado a ~60 fps, screencap con píxeles de color (pantalla ya no está negra).
- Tests 42 verdes, `flutter analyze` 0 errores (29 infos preexistentes).
**Lecciones**:
- `sqflite_common_ffi` es SOLO desktop (`sqlite3_flutter_libs` no viaja en Android iOS). Forzarlo en móvil rompe la app ANTES de `runApp` con pantalla negra, sin log si no se usa `runZonedGuarded`.
- Cuando un APK falla "en negro", el proceso puede estar vivo pero no renderizando; `BufferQueueProducer queueBuffer fps` en logcat y un screencap con análisis de píxeles confirman si dibuja.
- El manejo de errores de `main()` (pantalla roja con mensaje) es condición para diagnosticar estos casos; el APK compilado a las 20:04 NO lo tenía (se agregó a las 21:04), por eso el bug se vio como pantalla negra en lugar de pantalla roja con el error.
- El análisis de píxeles con System.Drawing (firmar samples de color) permite detectar "pantalla negra" sin ver la imagen (el modelo no puede leer imágenes, pero la app puede probar con ADB).
- Conveniencia: `pwsh` no está en PATH en esta máquina; correr `.\scripts\build-apk.ps1` directo desde la shell.
**Impacto**: `lib/main.dart`
**Relacionado con**: D-3 (SQLite local), errores-conocidos (pantalla negra APK resuelto), flujo-de-trabajo (build APK + adb install)

---

## [2026-08-05] - BUGFIX - Pizarra: nota nueva no se mueve hasta reabrir
**Resumen**: Al agregar una nota/foto/postit en la pizarra, no se podia arrastrar hasta salir y reabrir la pantalla. Era porque el `onPanUpdate` hacia `if (el.id != null) move(...)` y el ID llegaba recien cuando Supabase respondia el insert (delay de red). Mientras tanto, el movimiento se descartaba silenciosamente.
**Cambios realizados**:
- `board_data_provider.dart`: nuevo `moveLocal(BoardElement el, double x, double y)`. Si el elemento tiene ID, delega a `move()` (persiste, con throttle 300ms). Si no tiene ID (recién creado, esperando respuesta de BD), solo actualiza la copia local con `copyWith` + `notifyListeners()`. Identifica el elemento por `identical(e, el)` (referencia de objeto, no por ID).
- `pizarra_screen.dart`: `onPanUpdate` ahora llama `moveLocal(el, ...)` sin chequear `el.id`. El elemento arranca moviendose inmediatamente, sin esperar al ID de la BD.
- Tests 42 verdes, analyze 0 errores. Recompilados Windows + APK.
**Lecciones**:
- En apps optimistas (insert local primero, despues Supabase), el ID llega asincronamente. Hay que soportar drag/edicion sobre elementos "sin ID todavia" via referencias de objeto, no asumir que todo elemento trackeable ya tiene ID.
- `BoardDataProvider.move()` exige ID (usa `eq('id', id)` en la query Supabase). No se puede llamar con `id == null`. El `if (id == 0) return` es otra salvaguarda (ID provisional cuando fallback a timestamp). Encontrar el elemento por `identical()` es mas seguro que comparar por ID cuando puede ser null.
- El throttle de 300ms en `move()` no cumple para `moveLocal()` sin ID: los moves solo locales no persisten, no hay throttle. Cuando llega el ID desde la BD (realtime o `load()`), la copia local con x/y actualizada se reemplaza por la de la BD si la BD tiene la posicion vieja. Hay un edge case muy sutil: si moves una nota nueva antes de que el ID llegue y luego el realtime trae la posicion vieja, pisas el move optimista. Por ahora aceptamos esa race; en el futuro se podria mergear绳子保留 el pending move para reaplicar tras el realtime.
**Impacto**: `lib/providers/board_data_provider.dart` (nuevo `moveLocal`), `lib/screens/pizarra/pizarra_screen.dart` (`onPanUpdate` simplificado)
**Relacionado con**: D-2 (Supabase), D-3 (no toca SQLite), errores-conocidos (sin nuevos errores)

---

## [2026-08-05] - BUGFIX - Finanzas: bloque de ingreso invisible (mismo color que fondo)
**Resumen**: El bloque "Ingresos" en la pantalla de Finanzas era del mismo color verde brillante (`#00FF66`) que el fondo del Scaffold, por lo que se camuflaba y parecia que no existia. El bloque de gastos era rojo y se veia bien.
**Cambios realizados**:
- `finanzas_screen.dart`: nueva constante `_cIncome = Color(0xFF008844)` (verde oscuro). `_incomeBlock` ahora usa `_cIncome` (fondo=borde, redondo) en vez de `_c`. Texto blanco en vez de negro para mantener contraste con el verde oscuro.
- Mantiene asociacion verde=positivo/ingreso, distinto del fondo brillante. Cumple skill_visual (fondo=borde mismo color, solido, no negro puro, redondo).
- Recompilados Windows + APK. Tests 42 verdes, analyze 0 errores nuevos.
**Lecciones**:
- Cuando un Scaffold usa un color vibrante como background, los bloques internos no pueden usar el mismo color o se camuflan. Hay que usar un tono mas oscuro del mismo color (mantiene asociacion semantica) o un color de seccion distinto.
- `finanzas_screen` seguia la paleta de `convenciones.md` (seccion Finanzas = verde `#00FF66`), pero la paleta no aclara que el fondo del Scaffold debe ser DISTINTO del bloque de ingreso. Es un caso de colision interno que no estaba documentado.
**Impacto**: `lib/screens/finanzas/finanzas_screen.dart`
**Relacionado con**: D-4 (skill_visual), convenciones (colores por seccion)

---

## [2026-08-05] - BUGFIX - PostgrestException reply_content missing en messages
**Resumen**: Al hacer swipe para responder un mensaje y enviarlo, Supabase respondia `PGRST204: Could not find the "reply_content" column of "messages" in the schema cache`. La BD cloud tenia la tabla `messages` sin las columnas nuevas del feature chat (reply, reacciones, media). La migracion SQL anterior solo agregaba `attachment_name/mime/size` y `cloud_deleted`, faltaban 7 columnas mas.
**Cambios realizados**:
- `supabase/migration_chat_media_reactions.sql` ampliado con `ALTER TABLE messages ADD COLUMN IF NOT EXISTS` para las 7 columnas faltantes:
  - `reply_to_id BIGINT REFERENCES messages(id)` (FK al mensaje respuesta)
  - `reply_content TEXT` (preview del texto respondido)
  - `message_type TEXT DEFAULT 'text'` (text/image/voice/video/gif/document)
  - `attachment_url TEXT` (URL en bucket chat-media))
  - `starred BOOLEAN DEFAULT false`
  - `edited BOOLEAN DEFAULT false`
  - `reactions JSONB DEFAULT '{}'::jsonb` (formato `{"key": ["user-id"]}`)
- Las columnas `attachment_name/mime/size` y `cloud_deleted` ya estaban; el bucket `chat-media` y sus policies tambien (sin cambios).
- Migracion idempotente: usa `IF NOT EXISTS` en todos los `ALTER`, puede ejecutarse varias veces sin error.
- Pendiente: el usuario debe ejecutar el archivo en Supabase SQL Editor. No se puede automatizar desde el repo (no hay deploy automatico, y no se deben tocar credenciales de prod sin permiso).
**Lecciones**:
- Cuando un modelo Dart (Message.fromMap/toMap) referencia columnas que no existen en la BD cloud, el error llega como `PGRST204` (schema cache) en runtime, no en compile. Hay que mantener migracion + schema local + modelo sincronizados.
- La migracion anterior (`migration_chat_media_reactions.sql`) se habia quedado corta: solo cubria media, no reply ni reactions. Era el resultado de haber escrito la migracion antes de terminar el modelo.
- `IF NOT EXISTS` en ALTER COLUMN es la forma segura de hacer migraciones idempotentes en Postgres: no falla si la columna ya existe, permite re-ejecutar sin script de rollback.
- Antes de marcar un feature como done, conviene diffing `modelo.toMap` vs schema real de la BD. diferencia detectada aca: 7 columnas en codigo que no existian en cloud.
**Impacto**: `supabase/migration_chat_media_reactions.sql`
**Relacionado con**: errores-conocidos (PGRST204 resuelto), D-2 (Supabase backend), feature chat media (migracion completa)

---

## [2026-08-05] - BUGFIX - Swipe-to-reply: input tapado por teclado + sin snap suave
**Resumen**: Al hacer swipe para responder, el banner del reply compartia area con el TextField (mismo Container + Column), el input quedaba detras del teclado (no se manejaba `viewInsets`), y al soltar el swipe el mensaje saltaba a su posicion original sin animacion. Fix: banner separado en su propio Positioned, input siempre con `bottom: keyboard + 8` (responsive al teclado), y `AnimationController` para snap suave en `_SwipeToReply`.
**Cambios realizados**:
- `chat_screen.dart` build(): agregada llamada a `_replyBanner` en el Stack (condicion `if (chat.replyTo != null)`).
- `_inputArea` refactorizado: ya no arma `Column [banner, Expanded(input)]` con `top` / altura variable segun `hasReply`. Ahora usa `bottom: keyboard + 8` con `MediaQuery.of(context).viewInsets.bottom`, altura fija `h * 0.09`, solo el input con attach/mic/send. El banner ya no comparte area con el input.
- Nuevo `_replyBanner(w, h, chat)`: `Positioned` propio arriba del input (`bottom: keyboard + 8 + h * 0.09 + 4`). Visualmente separado del input por 4px. Color y forma igual al anterior.
- `_SwipeToReply` con `SingleTickerProviderStateMixin` + `AnimationController` (180ms). `_snapBack()` setea `_ctrl.value = _dx/_max` y llama `_ctrl.reverse()`; el listener actualiza `_dx` durante la animacion. `onHorizontalDragCancel` ahora tambien snapea (antes reseteaba a 0 de golpe). `onHorizontalDragStart` hace `_ctrl.stop()` antes de resetear para no pelear con animacion en curso.
- Recompilados Windows (0.75 MB) y APK (63.76 MB). Tests 42 verdes, analyze 0 errores (28 warnings/info preexistentes).
**Lecciones**:
- Cuando un input debe ajustarse al teclado, usar `bottom: MediaQuery.of(context).viewInsets.bottom + X` con `Positioned` es el patron estandar. Posicionar con `top: h * 0.875` falla apenas el teclado se abre (queda detras).
- Compartir un `Column` entre un banner y un input hace que se vean como un solo bloque del mismo color → el usuario no distingue donde tapar para escribir. Separar en `Positioned` distintos con gap visual resuelve ambiguedad.
- `AnimationController.reverse()` con un listener que actualiza el estado es la forma idomatica de animar snap-back en swipe gestures. Setear `_ctrl.value = from/_max` antes de `reverse()` hace que arranque desde la posicion actual del drag (no de 0).
- `onHorizontalDragCancel` se llama cuando el gesture recognizer pierde el gesto (e.g. otra gesture gana). Implementarlo con `_snapBack()` (no reseteo brusco) mantiene consistencia visual.
**Impacto**: `lib/screens/chat_screen.dart` (build + `_inputArea` + `_replyBanner` nuevo + `_SwipeToReply`)
**Relacionado con**: D-4 (skill_visual — sin cambios, mismo naranja/bordes), errores-conocidos (sin nuevos errores)

---

## [2026-08-05] - BUILD - Fix compileSdk + scripts de build para Windows y APK
**Resumen**: El APK release dejo de compilar tras agregar el feature chat media (deps nuevas: file_picker, video_player, record, open_filex, permission_handler). Se agrego un override de compileSdk 36 en subprojects y se crearon scripts de build para un solo comando. Daemon de Gradle deshabilitado para evitar hang en builds largos.
**Cambios realizados**:
- `android/build.gradle.kts`: nuevo bloque `subprojects { afterEvaluate { ... compileSdkVersion = "android-36" } }` que overridea el compileSdk de plugins legacy (file_picker 8.3.7 trae 34 hardcodeado, flutter_plugin_android_lifecycle exige >=36). Combinado con `evaluationDependsOn(":app")` en el mismo bloque para que el hook se registre antes de la evaluacion.
- `android/gradle.properties`: agregado `org.gradle.daemon=false` y bajado heap a `-Xmx6G -XX:MaxMetaspaceSize=2G`. Antes heap era 8G y daemon se colgaba en builds largos (timeout de Gradle daemon despues de ~13min).
- Nuevo `scripts/build-windows.ps1`: corre `flutter build windows --release`, verifica Flutter en PATH, reporta exe final y tamaño.
- Nuevo `scripts/build-apk.ps1`: corre `flutter build apk --release`, verifica Flutter y JAVA_HOME, reporta apk final y tamaño. No necesita `$env:GRADLE_OPTS` porque daemon=false ya esta en gradle.properties.
- Nuevo `scripts/build-all.ps1`: corre ambos scripts secuencialmente, reporta resumen con codigo de salida por cada uno.
- Output: Windows OK (`build\windows\x64\runner\Release\furi_app.exe`, 1.77 MB), APK OK (`build\app\outputs\flutter-apk\app-release.apk`, 63.8 MB). Tests 42 verdes, analyze 0 errores.
**Lecciones**:
- Los plugins Flutter que usan la API Groovy legacy (`apply plugin: 'com.android.library'` con `compileSdk 34` hardcodeado) NO respetan el `flutter.compileSdkVersion` de la app. Requieren override explicito en `subprojects { afterEvaluate { ... } }` a nivel raiz.
- En Gradle Kotlin DSL, la API legacy `com.android.build.gradle.LibraryExtension` esta deprecada y no expone `compileSdk`. Hay que usar `BaseExtension` con el setter `compileSdkVersion = "android-36"` (string con prefijo `android-`).
- `afterEvaluate` CANNOT ser registrado si el proyecto ya esta evaluado. El bloque `subprojects { }` de Flutter (`evaluationDependsOn(":app")`) fuerza la evaluacion. Solucion: meter ambos (afterEvaluate hook + evaluationDependsOn) en el mismo `subprojects { }` block, en ese orden.
- El daemon de Gradle tiene memory leaks acumulados en builds Flutter largos; `org.gradle.daemon=false` sube el tiempo de arranque pero garantiza builds estables.
- Para no tener que jugar con `$env:GRADLE_OPTS` cada vez, los settings van en `android/gradle.properties` (persistente) - los scripts ps1 solo llaman `flutter build`.
**Impacto**: `android/build.gradle.kts`, `android/gradle.properties`, `scripts/build-windows.ps1` (nuevo), `scripts/build-apk.ps1` (nuevo), `scripts/build-all.ps1` (nuevo)
**Relacionado con**: errores-conocidos (file_picker compileSdk), flujo-de-trabajo (build simplificado), D-3/D-2 (no toca Supabase ni SQLite)

---

## [2026-08-05] - FEATURE - Chat WhatsApp-like: reply, reacciones y media delete-on-download
**Resumen**: Chat reescrito con swipe-to-reply funcional en cualquier mensaje, reacciones por long-press (🥰😘😍 :v xD + custom, max 5), envio de imagen/video/audio/gif/archivo via Supabase Storage, y borrado del cloud al descargar (queda solo local en el dispositivo).
**Cambios realizados**:
- Bugfix swipe: usaba `d.delta.dx` (frame a frame ~1-5px) en vez de acumular offset; ademas solo permitia swipe en mensajes ajenos. Nuevo `_SwipeToReply` acumula drag, umbral 42px, icono reply detras, funciona en todos los mensajes.
- Modelo `Message` tipado completo: `replyToId` ahora `int?`, reacciones con `toggleReaction` (1 reaccion por usuario, max 5 keys), campos media (`attachmentName/Mime/Size`, `cloudDeleted`, `localPath`), helpers `previewText`/`needsCloudDownload`/`isMedia`.
- Nuevo `ChatProvider`: carga, realtime, send text/media, reacciones, mark read, download+delete cloud.
- Nuevo `ChatMediaService`: upload bucket `chat-media`, download a app docs, bind path local SQLite, delete storage.
- SQLite v5: tabla `chat_media_local` (message_id → local_path) para persistir media en dispositivo.
- `chat_screen.dart` reescrito: attach sheet (galeria/camara/video/archivo/gif), mic grabacion (`record`), long-press barra reacciones + dialog custom, burbujas con media player (imagen/gif, video, audio, open file), banner reply, estados loading/empty/error/data, skill_visual (sin negro puro, fondo=borde).
- Migracion SQL `supabase/migration_chat_media_reactions.sql`: columnas attachment_* + cloud_deleted, bucket privado `chat-media` + policies.
- Deps: `file_picker`, `path_provider`, `record`, `video_player`, `open_filex`, `permission_handler`.
- Tests TDD: 14 message + 4 chat_provider = 18 verdes.
**Lecciones**:
- GestureDetector horizontal + ListView vertical conviven si se acumula `delta.dx`; el bug clasico es asignar delta en vez de sumar.
- Media "efimera" en cloud: el emisor guarda local al enviar; el receptor descarga, guarda SQLite local y borra Storage + limpia `attachment_url`/`cloud_deleted=true`.
- `ChatProvider` scoped al screen (ChangeNotifierProvider en ChatScreen) evita estado global de conversacion.
**Impacto**: `lib/models/message.dart`, `lib/providers/chat_provider.dart` (nuevo), `lib/services/chat_media_service.dart` (nuevo), `lib/screens/chat_screen.dart`, `lib/database/database_helper.dart`, `pubspec.yaml`, `supabase_schema.sql`, `supabase/migration_chat_media_reactions.sql`, `android/.../AndroidManifest.xml`, `test/models/message_test.dart`, `test/providers/chat_provider_test.dart`
**Relacionado con**: D-2 (Supabase), D-4 (brutalista/skill_visual), errores-conocidos (chat swipe roto)

---

## [2026-08-05] - FEATURE - Rating dual por usuario + critica compartida en Favoritos
**Resumen**: Cada favorito ahora se califica con estrellas de forma independiente por Facu y por Rocio, ademas de tener una critica de texto compartida. Refactor visual completo de la pantalla para cumplir skill_visual.md (sin negro puro, fondo=borde, iconos en botones).
**Cambios realizados**:
- Modelo `FavoriteItem`: eliminado `rating` y `subtitle`, agregados `ratingFacu`, `ratingRocio`, `critica`. `copyWith` ahora permite actualizar cada rating por separado sin pisar el del otro. Getters nuevos: `averageRating`, `ratingFor(identity)`, `hasFacuRating`, `hasRocioRating`, `hasAnyRating`, `bothRated`.
- Provider `FavoritesProvider`: agregados `setRating(id, identity, value)`, `setCritica(id, texto)`, getters `allFavorited` y `averageRatingFor(category)`. Expuesto `setItemsForTest` con `@visibleForTesting` para tests de logica pura.
- Bugfix durante TDD: `toMap()` hacia `'user_id': AppState.myId ?? ''`, pisando el `userId` pasado al constructor. Ahora usa `userId ?? AppState.myId ?? ''`, preservando la autoria en `update()`.
- Schema SQL: `supabase_schema.sql` actualizado a la nueva forma. Creado `supabase/migration_favorites_dual_rating.sql` con `ALTER TABLE favorites` para migrar DBs existentes (incluye migrar `subtitle` -> `critica` y `rating` -> `rating_facu`, idempotente con `IF NOT EXISTS`).
- Screen `favoritos_screen.dart`: reescrito completo. Paleta nueva: `_bg #0A0A0A` (no puro negro), `_panel #1A0830` violeta oscuro, `_vc #9D00FF` primario, `_light #D4A8FF` lila, `_fav #FFD700` dorado para guardados, `_facuT` naranja, `_rocioT` rosa (iniciales F/R). Todos los elementos con `BoxDecoration` cumplen fondo=borde mismo color. Botones del modal reemplazados por iconos (`Icons.close`, `Icons.check`, `Icons.add`, etc.) — se elimino el texto decorativo "X" "OK" "+". Toggle "favorited" ahora usa `Icons.bookmark`/`bookmark_border` (consistente con bloque "GUARDADOS") en dorado.
- UI de card: muestra dos mini filas de rating (F + R con estrellas cada una), promedio si ambos calificaron, critica en preview de 1 linea.
- Nuevo modal de detalle al tap en la card: muestra critica editable multilinea, editores de rating para F y para R (cualquiera puede calificar), promedio, y botones para toggle favorited / eliminar / guardar.
- Modal de alta/edicion ahora incluye `Wrap` selector de categoria (permite cambiarla al editar). Botones de accion cerrados con icono en contenedor brutalist.
- Confirmacion de eliminacion via dialog con iconos `Icons.close`/`Icons.delete_outline`.
- Banner de error rojo (`_errorBanner`) muestra `pv.error` con boton cerrar; antes no habia feedback visual de errores.
- `initState` migrado de `Future.microtask` a `WidgetsBinding.instance.addPostFrameCallback` con guard `mounted` (silencia warning `use_build_context_synchronously`).
- Tests TDD: `test/models/favorite_item_test.dart` (10 tests) cubren serializacion, migracion legacy, copyWith por usuario, averageRating, ratingFor, hasRating. `test/providers/favorites_provider_test.dart` (7 tests) cubren byCategory, categories, wishlistCount, allFavorited, averageRatingFor. Total 17 tests nuevos, todos verdes.
**Lecciones**:
- La regla NO-NEGOCIABLE "fondo=borde mismo color" + "prohibido negro puro" obliga a usar tonos del mismo color base (violeta oscuro/claro) en vez de negro para los tiles — el contraste surge de tonos claros vs oscuros, no de bordes distintos.
- TDD encontro un bug real sutil: el `toMap()` que pisaba el `userId` en `update()`. El test que parecia solo de serializacion revelo el problema de preservacion de autoria.
- Para testear providers que dependen de Supabase, lo practico es exponer un setter `@visibleForTesting` y testear solo la logica sincrona pura (getters filtros/avg), sin mockear el cliente.
- `addPostFrameCallback` es mas idomatico que `Future.microtask` para lecturas de Provider en `initState` y silencia el linter de async gaps.
**Impacto**: `lib/providers/favorites_provider.dart`, `lib/screens/favoritos/favoritos_screen.dart`, `supabase_schema.sql`, `supabase/migration_favorites_dual_rating.sql` (nuevo), `test/models/favorite_item_test.dart` (nuevo), `test/providers/favorites_provider_test.dart` (nuevo)
**Relacionado con**: D-4 (estilo brutalista), nueva decision D-11 (rating dual por usuario), skill_visual.md (cumplimiento), errores-conocidos.md (negro puro remediado en esta screen)

---

## [2026-08-05] - FEATURE - Clases recurrentes por semana en vez de fechas fijas
**Resumen**: Las clases configuradas en el wizard ahora se guardan como horarios recurrentes por día de la semana y aparecen en todas las semanas del calendario
**Cambios realizados**:
- Texto del wizard cambiado de `Cuantas materias tienes esta semana?` a `Cuantas clases tienes a la semana?`
- `ClassSchedule` extendido con `endTime`, `professor`, `userId` y `color` para soportar toda la info del wizard
- `DatabaseHelper` migrado a v4: tabla `class_schedules` ahora tiene las columnas nuevas
- `ClassSetupWizard` guarda en `ClassScheduleProvider` (tabla `class_schedules`) en lugar de crear `Schedule` con fechas fijas de la semana actual
- `CalendarHomeScreen` carga `ClassScheduleProvider` y genera eventos "sintéticos" de tipo `Clase` para cada día de la semana, mostrándolos en cualquier semana del calendario
- `home_screen._checkClassSetup()` ahora verifica la tabla local `class_schedules` en vez de consultar Supabase, y recarga `ClassScheduleProvider` tras cerrar el wizard
- Agregado test `test/models/class_schedule_test.dart` para validar serialización y valores por defecto
**Lecciones**:
- El sistema anterior tenía dos modelos desconectados: `Schedule` (fecha fija) y `ClassSchedule` (recurrente). El wizard usaba el primero, lo que hacía que las clases desaparecieran al cambiar de semana
- Es más limpio que el wizard use directamente el modelo recurrente (`ClassSchedule`) y que el calendario "proyecte" esos horarios en cada semana
- `ClassSchedule` no se sincroniza con Supabase por ahora: vive solo en SQLite local
**Impacto**: `lib/models/class_schedule.dart`, `lib/database/database_helper.dart`, `lib/screens/calendar/class_setup_wizard.dart`, `lib/screens/calendar/calendar_home_screen.dart`, `lib/screens/home_screen.dart`, `test/models/class_schedule_test.dart`
**Relacionado con**: D-3 (SQLite local), D-4 (estilo brutalista — sin cambios visuales, solo texto), `skill_visual.md`

---

## [2026-08-05] - BUGFIX - ClassSetupWizard reaparecía siempre al iniciar la app
**Resumen**: El wizard de configuración de clases aparecía cada vez que se abría HomeScreen, incluso después de completarlo
**Cambios realizados**:
- `ScheduleProvider.addSchedule()` ahora sube schedules a Supabase además de SQLite local
- Antes: solo guardaba en SQLite local, pero `_checkClassSetup()` consultaba Supabase → nunca encontraba clases → wizard siempre aparecía
- El `date` se trunca a `YYYY-MM-DD` para coincidir con el formato esperado por Supabase
**Lecciones**:
- La persistencia dual (SQLite + Supabase) requiere sincronización bidireccional explícita
- Los schedules de tipo `'Clase'` nunca eran sincronizados por `SyncProvider` (solo manejaba `Fecha especial` y `Examen`)
**Impacto**: `lib/providers/schedule_provider.dart`
**Relacionado con**: D-3 (SQLite local), D-9 (SyncProvider)

---

## [2026-08-05] - FEATURE - Bot de WhatsApp para notificaciones proactivas
**Resumen**: Creación de bot que notifica por WhatsApp sobre actividad en todas las secciones de la app
**Cambios realizados**:
- Creado `bot-furi/` con Node.js + Baileys + Supabase
- Creadas tablas `bot_sessions` (persistencia sesion WhatsApp) y `bot_notificaciones` (tracking anti-duplicados)
- Bot notifica 12 categorías: schedules, anniversaries, moods, letters, challenges, goals, tasks, transactions, favorites, notes, gallery, timeline_events
- GitHub Actions workflow corre cada 30 min (`.github/workflows/bot-whatsapp.yml`)
- Sesion WhatsApp persiste en Supabase para sobrevivir entre ejecuciones CI
- Inicializado repositorio git y pusheado a GitHub
- **No notifica mensajes del chat** (ya tienen push via FCM)
**Lecciones**:
- Baileys v6+ es ESM-only, requiere `"type": "module"` en package.json
- Supabase Realtime en Node.js 20 requiere paquete `ws` como transport
- La sesión WhatsApp se guarda/restaura desde Supabase para CI efímero
**Impacto**: `bot-furi/`, `.github/workflows/bot-whatsapp.yml`, docs actualizados
**Relacionado con**: decision D-10, bot-whatsapp.md

---

## [2026-07-29] - DISCOVERY - Inicialización del Proyecto
**Resumen**: Configuración inicial de opencode y análisis del código base
**Cambios realizados**:
- Cuestionario de descubrimiento completado
- Análisis automático del repositorio
- Generación de 8 documentos de contexto + AGENTS.md + opencode.json
**Lecciones**:
- El proyecto tiene código funcional pero bugueado
- Solo la pantalla principal funciona correctamente
- Hay mucho código muerto (8 providers sin registrar, tablas faltantes)
- Se requiere TDD para adelante
**Impacto**: Base documental establecida para trabajo futuro
**Relacionado con**: Todos los archivos de contexto

---

## [2026-07-29] - REFACTOR - Limpieza de providers muertos y registro de providers faltantes
**Resumen**: Se eliminaron 6 providers rotos y se registraron ThemeProvider y MenuProvider
**Cambios realizados**:
- Eliminados: board_provider, canvas_drawing_provider, cork_note_provider, evaluation_provider, ingredient_provider, recipe_provider
- Registrados en main.dart: ThemeProvider, MenuProvider
- Creada tabla `menu_plans` en SQLite (DatabaseHelper v2)
- Arreglado `MenuProvider.getMenusByDate()` (usaba `_db.query()` inexistente)
- Escritos tests TDD para ThemeProvider y MenuProvider
**Lecciones**:
- Los 6 providers eliminados tenían imports a modelos que nunca existieron
- BoardProvider duplicaba funcionalidad de BoardDataProvider
- El código muerto ocultaba bugs (métodos que no existen en DatabaseHelper)
- SharedPreferences necesita `setMockInitialValues({})` en tests
**Impacto**: app_state.dart, main.dart, database_helper.dart, menu_provider.dart
**Relacionado con**: errores-conocidos.md, convenciones.md

---

## [2026-07-29] - REFACTOR - Transformación brutalista de todas las pantallas
**Resumen**: Se aplicó la guía de estilo brutalista a 18 screens (excepto HomeScreen)
**Cambios realizados**:
- Fondo unificado a `#0A0A0A` en todas las screens
- Eliminados todos los `BorderRadius.circular()` → bordes rectos 90°
- Eliminadas todas las `BoxShadow` → reemplazadas por bordes sólidos
- Eliminado `BoxShape.circle` → formas cuadradas
- 3 screens del calendario: eliminado estilo clay/neumorphism → brutalist
  - daily_events_screen: AppBar Material → brutalist, Card→Container, FAB→botón con borde
  - schedule_form_screen: clayCard → BoxDecoration brutalist, ElevatedButton→GestureDetector
  - class_board_screen: clayCard → BoxDecoration brutalist
- Eliminados imports muertos de `app_theme.dart` en screens que no lo usaban
- Reemplazado `context.textColor` → `Colors.white`, `context.secondaryColor` → `#00D4FF`
**Lecciones**:
- clayCard() y ThemeColors extension de app_theme.dart eran usados solo por 2 screens
- La transformación masiva con reemplazos globales es viable si se mantiene la lógica intacta
- ClipRRect necesita reemplazo manual por Container
**Impacto**: 18 archivos en lib/screens/
**Relacionado con**: convenciones.md, FURI_GUIA_ESTILO_BRUTALISTA.txt

---
