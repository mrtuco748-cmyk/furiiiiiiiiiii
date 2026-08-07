# Errores Conocidos de F.U.R.I

> **PROPÓSITO**: Este archivo es un registro de **lecciones aprendidas** — bugs que ya se
> resolvieron (o se están resolviendo) y las causas raíz que los provocaron, para **NO
> reintroducirlos** en el futuro. NO es una lista de tareas pendientes, ni un backlog de
> features. Antes de cada cambio de código, revisar aquí para evitar repetir los mismos
> errores. Los errores **activos/pendientes** que requieren acción se documentan en
> `docs/contexto/arquitectura.md` (sección "Lo que NO existe") y en `historial.md`.

### ~~ALTA - Sync de clases usaba el id local de SQLite como PK cloud~~ ✅ RESUELTO
- **Dónde**: `lib/providers/class_schedule_provider.dart` + `lib/database/database_helper.dart`
- **Qué pasaba**: Las clases se sincronizaban a Supabase usando `eq('id', idLocalDeSQLite)` para update/delete, pero Supabase asigna su propio BIGSERIAL (id distinto al autoincremental local). Como las clases viejas jamás se habían subido, quedaban solo en SQLite y el bot no las conocía; además los update/delete apuntaban a filas que no existen.
- **Fix**: SQLite v6 agrega `cloudId` a `class_schedules`. El provider guarda el id cloud devuelto por el insert y lo usa como PK cloud. `_syncUnsyncedToSupabase()` (dentro de `loadSchedules()`) sube cualquier clase con `cloudId == null`.
- **Nota**: Para que el bot vea las clases ya configuradas, alcanza con abrir la app una vez (el sync sube las que faltan).
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-06

### ~~ALTA - Bot WhatsApp timeout en GitHub Actions (validación de sesión rota)~~ ✅ RESUELTO
- **Dónde**: `bot-furi/bot.js` (`loadSessionFromSupabase`)
- **Qué pasaba**: En GitHub Actions el bot moría por timeout de 60s porque nunca restauraba la sesión desde Supabase. La validación de sesión usaba `Object.keys(session).some(f => f.includes(MI_NUMERO))` (chequeaba el número en los NOMBRES de archivo) y, tras reescribirla, se usó `split(':').first` — `.first` no existe en arrays de JS, devuelve `undefined` → la validación fallaba siempre → pedía QR (imposible en CI) → timeout.
- **Fix**: Validar por contenido: leer `creds.json.me.id` (`5493786499129:1@s.whatsapp.net`), quitar `@s.whatsapp.net` y tomar `split(':')[0]`. Confirma que el número puro coincide con `MI_NUMERO`.
- **Nota**: Verificado localmente: "Sesion cargada desde Supabase" → conecta → verifica → finaliza. Los logs "failed to decrypt message" son inofensivos (estados de WhatsApp).
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-06

### ~~MEDIA - Doble tick de "visto" del chat nunca aparecía~~ ✅ RESUELTO
- **Dónde**: `lib/providers/chat_provider.dart` (`markIncomingRead`) + BD cloud `messages`
- **Qué pasaba**: Al abrir el chat, el mensaje no mostraba doble check (leído). `markIncomingRead()` actualizaba `read: true` y `read_at`, pero las columnas `delivered_at`/`read_at` no existían en la tabla `messages` de la BD cloud → el update fallaba con PGRST204 y se tragaba el error con `catch (_) {}` → el doble visto nunca se propagaba.
- **Fix**: `supabase/migration_chat_media_reactions.sql` ampliado con `ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ` y `read_at TIMESTAMPTZ`. Idempotente.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-08-06 (falta ejecutar migracion en prod)

### ~~CRÍTICA - APK muestra pantalla negra en Android~~ ✅ RESUELTO
- **Dónde**: `lib/main.dart` + `pubspec.yaml`
- **Qué pasaba**: Los APK release abrían pero quedaban en pantalla negra en el celular. `main.dart` ejecutaba `sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfiNoIsolate` (motor SQLite de desktop por FFI) en TODAS las plataformas. En Android, `sqlite3_flutter_libs` (que provee `libsqlite3.so`) no estaba en pubspec → `DatabaseHelper().database` lanzaba antes de `runApp`, y como el APK se había compilado con el `main.dart` viejo sin manejo de errores, no se veía pantalla roja sino negro silencioso.
- **Fix**: `sqfliteFfiInit()`/`databaseFactoryFfiNoIsolate` ahora corren solo si `isDesktop` (`!kIsWeb && (windows|linux|macOS)`). En Android/iOS se usa el factory nativo de `sqflite` por defecto. Recompilado APK + instalado vía ADB verificado (proceso vivo, 60 fps, píxeles de color).
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-06

### ~~CRÍTICA - PGRST204 columnas faltantes en messages~~ ✅ RESUELTO
- **Dónde**: `supabase/migration_chat_media_reactions.sql` (incompleto) + BD cloud
- **Qué pasaba**: Al hacer swipe para responder y enviar, Supabase respondia `PostgresException: Could not find the "reply_content" column of "messages" in the schema cache (PGRST204)`. La tabla `messages` en la BD cloud tenia solo las columnas originales (id, from_user, to_user, content, read, timestamps), faltaban las 7 columnas nuevas del feature chat media+reply+reacciones.
- **Fix**: `migration_chat_media_reactions.sql` ampliado con 7 `ALTER TABLE messages ADD COLUMN IF NOT EXISTS` para `reply_to_id`, `reply_content`, `message_type`, `attachment_url`, `starred`, `edited`, `reactions`. Idempotente.
- **Nota**: La misma migración se amplió después con `delivered_at`/`read_at` (TIMESTAMPTZ) para el sistema de doble tick de "visto" — ver error "ticks de chat".
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-05 (migracion lista; falta ejecucion en prod)

### ~~ALTA - APK no compila por choque de compileSdk entre plugins~~ ✅ RESUELTO
- **Dónde**: `android/build.gradle.kts` + plugin `file_picker 8.3.7`
- **Qué pasaba**: Tras agregar el feature chat media (file_picker, video_player, record, open_filex, permission_handler), el APK fallaba con "Dependency ':flutter_plugin_android_lifecycle' requires compile against version 36 or later, :file_picker is currently compiled against android-34". El plugin file_picker 8.3.7 hardcodea `compileSdk 34` (API Groovy legacy), pero flutter_plugin_android_lifecycle (SDK 36 nuevo) lo exige >=36.
- **Fix**: Bloque `subprojects { afterEvaluate { extensions.findByName("android")?.let { if (it is com.android.build.gradle.BaseExtension) it.compileSdkVersion = "android-36" } }; project.evaluationDependsOn(":app") }` en `android/build.gradle.kts`. Overridea el compileSdk de todos los plugins legacy.
- **Nota**: Si se sube `file_picker` a una version que use compileSdk 36, este bloque pasa a ser no-op (redundante). Se puede quitar entonces.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-05

### ~~MEDIA - Gradle daemon desaparece en builds APK largos~~ ✅ RESUELTO
- **Dónde**: `android/gradle.properties`
- **Qué pasaba**: `flutter build apk --release` fallaba despues de 13min con "Gradle build daemon disappeared unexpectedly (it may have been killed or may have crashed)". Daemon tenia heap 8G y memory leaks acumulados.
- **Fix**: `org.gradle.daemon=false` en `android/gradle.properties` + heap bajado a 6G/2G metaspace. Cada build levanta su propio proceso Gradle (mas lento ~30s pero estable).
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-08-05

### ~~CRÍTICA - Chat no muestra mensajes cuando hay más de 100~~ ✅ RESUELTO
- **Dónde**: `lib/screens/chat_screen.dart` (`_loadMessages`)
- **Qué pasaba**: La query usaba `.order('created_at', ascending: true).limit(100)` → traía los 100 mensajes MÁS VIEJOS. Al superar los 100 mensajes totales, los nuevos nunca aparecían al abrir el chat (parecía que "no se enviaban ni recibían", aunque sí se guardaban en Supabase)
- **Fix**: Orden descendente + `limit(100)` y se invierte la lista en Dart para mantener orden cronológico en pantalla
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-03 (APK release recompilado con el fix)

### ~~CRÍTICA - JAVA_HOME inválido impide compilar APK~~ ✅ RESUELTO
- **Dónde**: Variable de entorno `JAVA_HOME` → `C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot` (ya no existe)
- **Qué pasaba**: `flutter build apk` fallaba con "JAVA_HOME is set to an invalid directory"
- **Fix**: Variables de entorno `JAVA_HOME` (Usuario y Sistema) actualizadas a `D:\jdk17\jdk17`. `flutter doctor` confirma toolchain Android OK
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-03

### ~~CRÍTICA - BoardProvider llama a método inexistente~~ ✅ RESUELTO
- **Dónde**: `lib/providers/board_provider.dart` (archivo eliminado)
- **Qué pasa**: Era duplicado de BoardDataProvider y llamaba a `_db.getBoards()` inexistente
- **Fix**: Eliminado el archivo por completo
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-07-29

### ~~CRÍTICA - 8 providers sin registrar en main.dart~~ ✅ RESUELTO
- **Dónde**: `lib/main.dart` (antes 11 providers, ahora 13)
- **Qué pasa**: 6 providers rotos fueron eliminados (board, canvas_drawing, cork_note, evaluation, ingredient, recipe). ThemeProvider y MenuProvider fueron registrados.
- **Fix**: Eliminados 6, registrados 2 útiles. Total: 13 providers activos.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-07-29

### ~~CRÍTICA - 8+ tablas Supabase faltan en schema SQL~~ ✅ RESUELTO
- **Dónde**: `supabase_schema.sql` vs `lib/providers/`
- **Qué pasaba**: Tablas como `transactions`, `tasks`, `photos`, `albums`, `board_elements`, `study_sessions`, `timeline_events`, `schedules` se usan en código pero no estaban definidas en el schema SQL, o las columnas nuevas vivían solo en migraciones sueltas y no en el schema maestro.
- **Fix**: `supabase_schema.sql` consolidado como schema master completo e idempotente. Ya definía `transactions`, `tasks`, `favorites`, `board_elements`, `study_sessions`, `gallery`, `timeline_events`, `schedules`, `notes`, `custom_questions`, etc. Se agregaron al CREATE las tablas nuevas `class_schedules` y `gallery_comments` (con índices + RLS + policies), y las columnas nuevas `gallery.description`, `gallery.reactions`, `goals.completed_by`, `letters.seen_by`, `challenges.seen_by`.
- **Nota**: Para DBs ya existentes en prod, ejecutar las migraciones en `supabase/` (`migration_class_schedules.sql`, `migration_gallery_comments.sql`, `migration_goals_completed_by.sql`, `migration_seen_system.sql`, `migration_favorites_dual_rating.sql`, `migration_chat_media_reactions.sql`).
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-06 (schema master listo; falta ejecutar migraciones en prod)

### ALTA - API key de Gemini con placeholder incorrecto
- **Dónde**: `lib/services/ai_config.dart:3` y `lib/services/ai_service.dart:16-18`
- **Qué pasa**: `AiService.init()` chequea `apiKey == 'AQUI_TU_API_KEY_DE_GEMINI'` pero el valor real es `'AQ.Ab8RN6KLaJG8B-rUu6Vsk4WV9QdCfZFVndHN2cYAaCDvL15QjA'`
- **Por qué es problema**: La IA no se inicializa porque el chequeo nunca pasa
- **Solución temporal**: Cambiar el chequeo a la key real
- **Fix permanente**: Mover la API key a un archivo .env o variable de entorno
- **Prioridad**: ALTA

### ALTA - Sin tests automatizados
- **Dónde**: `test/` (solo 1 widget test genérico)
- **Qué pasa**: No hay tests unitarios ni de integración
- **Por qué es problema**: Cualquier cambio puede romper funcionalidad sin detección
- **Solución temporal**: Manual testing
- **Fix permanente**: Implementar TDD — tests antes que código
- **Prioridad**: ALTA

### ~~MEDIA - Sin manejo de errores en llamadas Supabase~~ 🟡 PARCIALMENTE RESUELTO
- **Dónde**: Múltiples providers
- **Qué pasaba**: `catch (_) {}` sin logging, sin feedback al usuario
- **Fix parcial**: Se reemplazaron los `catch (_) {}` silenciosos por `developer.log` con contexto en `chat_provider.dart` (markIncomingRead/Delivered), `chat_media_service.dart` (deleteFromCloud), `chat_screen.dart` (sendText/sendMedia), `home_screen.dart`, `calendar_home_screen.dart`, `metas_screen.dart`, `retos_screen.dart`. Se dejan silenciosos (intencional) `sound_service.dart` y el parse de color de la pizarra (no-Supabase).
- **Pendiente**: feedback visual al usuario (banners) en screens; se conserva solo el patrón de `_error` ya existente en los providers CRUD.
- **Prioridad**: ~~MEDIA~~ → PARCIAL 2026-08-06

### MEDIA - chat_screen.dart demasiado grande
- **Dónde**: `lib/screens/chat_screen.dart` (699 líneas)
- **Qué pasa**: Una sola función build() con toda la lógica del chat
- **Por qué es problema**: Difícil de mantener, testear, y modificar
- **Solución temporal**: Ninguna
- **Fix permanente**: Refactorizar en widgets más pequeños y separar lógica
- **Prioridad**: MEDIA

### MEDIA - Sin sistema de rutas
- **Dónde**: `lib/screens/` (navegación con push/pop directo)
- **Qué pasa**: Navigator.of(context).push(MaterialPageRoute(...)) en todas partes
- **Por qué es problema**: Dificulta navegación profunda, testing, y deep links
- **Solución temporal**: Ninguna
- **Fix permanente**: Implementar GoRouter o Navigator 2.0
- **Prioridad**: MEDIA

### ~~BAJA - Sin git history~~ ✅ RESUELTO
- **Dónde**: Raíz del proyecto
- **Qué pasaba**: No existía repositorio git
- **Fix**: `git init` + push a GitHub + GitHub Actions CI/CD funcional
- **Prioridad**: ~~BAJA~~ → RESUELTO 2026-08-05

### ~~CRÍTICA - ClassSetupWizard aparece siempre aunque ya se completó~~ ✅ RESUELTO
- **Dónde**: `lib/screens/home_screen.dart:69-80` y `lib/providers/schedule_provider.dart:23-27`
- **Qué pasaba**: `_checkClassSetup()` consultaba Supabase por schedules `type='Clase'`, pero `ScheduleProvider.addSchedule()` solo guardaba en SQLite local. Las clases nunca llegaban a Supabase, así que el wizard siempre se mostraba.
- **Fix**: `addSchedule()` ahora inserta en Supabase (`schedules`) además de en SQLite local
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-05

### ~~MEDIA - Swipe-to-reply del chat no funcionaba~~ ✅ RESUELTO
- **Dónde**: `lib/screens/chat_screen.dart` (antes)
- **Qué pasaba**: `onHorizontalDragUpdate` hacía `_swipeOffset = d.delta.dx.clamp(0,80)` (delta por frame, nunca llegaba al umbral 40). Solo habilitado en mensajes ajenos.
- **Fix**: Widget `_SwipeToReply` acumula `delta.dx`, umbral 42, funciona en cualquier mensaje. 2026-08-05
- **Prioridad**: ~~MEDIA~~ → RESUELTO

### ~~MEDIA - FavoriteItem.toMap() pisaba userId en update()~~ ✅ RESUELTO
- **Dónde**: `lib/providers/favorites_provider.dart` (`FavoriteItem.toMap`)
- **Qué pasaba**: `toMap()` hacía `'user_id': AppState.myId ?? ''`, ignorando el `userId` pasado al constructor. Al editar (`update()`), el autor original se sobrescribía con el usuario activo, perdiendo la autoría del favorito.
- **Cómo se detectó**: Test TDD de serialización en `test/models/favorite_item_test.dart` que validaba `userId == 'facu-uuid'` falló (recibió `''`).
- **Fix**: `'user_id': userId ?? AppState.myId ?? ''` — preserva el `userId` del constructor y solo usa `AppState.myId` como fallback.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-08-05

### ~~BAJA - Estilo brutalista no implementado consistentemente~~ ✅ RESUELTO
- **Dónde**: 18 screens transformadas
- **Qué pasa**: Se unificaron backgrounds a #0A0A0A, bordes rectos, sin sombras
- **Fix**: Transformación brutalista completa. Pendiente: reemplazar texto decorativo por iconos (Regla #4)
- **Prioridad**: ~~BAJA~~ → RESUELTO 2026-07-29
