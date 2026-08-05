# Historial de Cambios y Aprendizajes

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
