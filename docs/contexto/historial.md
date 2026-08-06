# Historial de Cambios y Aprendizajes

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
