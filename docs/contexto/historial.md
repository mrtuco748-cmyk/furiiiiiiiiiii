# Historial de Cambios y Aprendizajes

## [2026-08-28] - BUGFIX - Push FCM + Bot WhatsApp: mensajes no llegaban (limpieza de tokens y ventana dinámica del bot)
**Resumen**: Auditoría completa del pipeline de notificaciones. Se encontró que (a) los push FCM no llegaban a Rocio porque su token FCM estaba vencido (no se re-registraba) y la tabla `device_tokens` acumulaba 20 tokens muertos (`UNREGISTERED`); (b) el bot de WhatsApp perdía eventos en silencio porque el cron de GitHub Actions corre con retrasos de 6-12h y consultaba una ventana fija de 1h, dejando fuera lo ocurrido entre corridas. Ambos corregidos.
**Cambios realizados**:
- `supabase/functions/send-push/index.ts`: ahora hace `select id, token, platform` filtrando `created_at >= ahora - 90d` y, al enviar, si FCM responde `UNREGISTERED` elimina ese row de `device_tokens` (RLS full-access). Antes mandaba a tokens muertos y no limpiaba. Verificado E2E: `POST /functions/v1/send-push` devolvió 200 al token vigente (id 21, Facu).
- `lib/services/notification_service.dart`: `registerTokenAfterLogin`/`_storeToken` (insert-if-absent) — ya funcionaba; se beneficiará del índice único para upserts futuros. Rocio no tenía token vigente (último 11/08) → por eso no recibía nada; al reabrir la app se re-registra solo.
- `supabase/migration_device_tokens_unique.sql` (nuevo): `CREATE UNIQUE INDEX idx_device_tokens_user_token ON device_tokens(user_id, token)` (dedupe de tokens duplicados por usuario). Reflejado en `supabase_schema.sql`.
- `bot-furi/bot.js`: (1) **ventana dinámica** — persiste `last_run_at` en `bot_sessions.session_data` y consulta eventos `desde = max(last_run_previo, ahora-24h)` en vez de fija 1h, corrigiendo la pérdida silenciosa por retraso de cron (log "Ventana de deteccion: desde 2026-08-28T18:02:05.307Z"). (2) **LIDs persistidos en `bot_sessions.session_data.lids`** (se cargan desde Supabase; ya no depende de `lids.json` en CI efímero). `saveSessionToSupabase()` extra tras `verificarYNotificar` para persistir la marca. Verificado E2E: insert de mood de prueba → bot envió y confirmó ACK a 5493786513637 ("Mensaje enviado y confirmado") → dato de prueba borrado.
- Limpieza inmediata: se eliminaron 20 rows muertos de `device_tokens` (quedó solo id 21, Facu).
**Lecciones**:
- FCM legacy API fue removido (jun 2024) → obligatorio HTTP v1 con service account; la Edge Function ya usa v1 (correcto). Los tokens `UNREGISTERED` NUNCA se podaban: hay que borrarlos en el servidor al recibir el error, o se siguen reintentando a ciegas.
- Un token FCM vence cuando se reinstala la app o se cambia el perfil; si el dispositivo no reabre la app, el token queda muerto y ese usuario deja de recibir push hasta volver a abrir. No es un bug de código, es higiene de tokens.
- El cron de GitHub Actions `*/30` NO garantiza cada 30 min en repos gratuitos: puede correr con 6-12h de retraso. Una ventana fija de 1h entonces pierde eventos. La ventana dinámica (desde la última corrida, con tope de 24h) es la cura.
- `bot_sessions` es el único estado persistente en CI efímero: cualquier marca que deba sobrevivir entre corridas (LIDs, last_run_at) debe ir ahí, no a archivos locales gitignados.
**Pendiente (acción manual del usuario)**: el deploy de la Edge Function `send-push` NO se pudo hacer desde esta máquina (no hay `supabase` CLI ni `SUPABASE_ACCESS_TOKEN`). Ejecutar en local: `supabase functions deploy send-push`. Sin esto, la poda de tokens en la nube no está activa (el código quedó listo).
**Impacto**: `supabase/functions/send-push/index.ts`, `supabase/migration_device_tokens_unique.sql` (nuevo), `supabase_schema.sql`, `bot-furi/bot.js`, `lib/services/notification_service.dart`, docs.
**Relacionado con**: D-7 (FCM), D-10 (bot), errores-conocidos (sin nuevos críticos), bot-whatsapp.md.

---

## [2026-08-28] - BUGFIX - Sync calendario/clases: cambios de la pareja bajan + ediciones offline no se pierden
**Resumen**: Auditando el sync calendario↔Supabase se encontraron 2 bugs de consistencia que explicaban "la pareja edita una clase y a mi no me llega" y "edito sin internet y mi cambio nunca sube". Ambos corregidos y reflejados en el schema master.
**Cambios realizados**:
- `lib/providers/class_schedule_provider.dart`: el callback de realtime (`payload.eventType == 'UPDATE'`) ignoraba el cambio de la pareja (solo insertaba si no existía localmente). Ahora actualiza la fila local por `cloudId` (autoritativo), igual que el merge de `schedules`. Antes: las ediciones de la otra persona en una clase existente no se descargaban.
- `lib/database/database_helper.dart`: migración a v9. Nueva columna `synced INTEGER NOT NULL DEFAULT 1` en `schedules` y `class_schedules` (mismo patrón dirty-flag que `board_elements_v2`), y `cloud_id` + índice único en `board_elements_v2`. Los CREATE de ambas tablas incluyen `synced`.
- `lib/providers/schedule_provider.dart`: `_pushUnsyncedToCloud()` ahora también re-sube filas con `synced = 0` (no solo las sin `cloudId`); `updateSchedule()` marca `synced = 0` si el push a la nube falla (offline) y `synced = 1` al confirmar → la próxima carga con internet re-intenta y no pierde la edición.
- `lib/providers/class_schedule_provider.dart`: `_syncUnsyncedToSupabase()` ahora selecciona `cloudId IS NULL OR synced = 0` y re-sube ambas; `updateSchedule()` marca `synced = 0` si `_pushToSupabase` devuelve null.
- `supabase_schema.sql`: agregada la sección 18a `board_elements_v2` (espejo del schema SQLite local, sin la columna `cloud_id` que es solo-local) con índice, RLS `full_access_board_elements_v2` y GRANTs. Antes la tabla solo existía en `migration_board_v2.sql`, así que una DB creada solo con el schema master no tenía el pizarrón v2 en la nube. `boards` ya estaba en el master.
**Lecciones**:
- Un callback de realtime que solo hace INSERT-ignore silencia las UPDATE de la pareja: hay que aplicar el cambio remoto por la PK cloud (igual que el pull inicial). El merge por `updatedAt` del pull de `schedules` ya lo hacía; el realtime de clases no.
- El patrón dirty-flag (`synced`) es la forma robusta de no perder ediciones offline: el push fallido marca la fila, y la próxima carga la re-intenta (insert si no tiene cloudId, update si ya lo tiene). Sin esto, un UPDATE offline a una fila ya sincronizada quedaba "limpia" para siempre.
- El schema master debe contener TODAS las tablas que usa el código; si una solo vive en una migración suelta, una DB fresca (o reconstruida) queda sin ella y el sync falla en silencio.
**Impacto**: `class_schedule_provider.dart`, `schedule_provider.dart`, `database_helper.dart`, `supabase_schema.sql`, docs.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), errores-conocidos (sync calendario), glosario.

## [2026-08-28] - BUGFIX - Tanda 1: flujo de datos Supabase → pantalla (finanzas, cartas, trivia, racha, nosotros, galería)
**Resumen**: Auditoría completa del flujo de datos (providers + screens) encontró 6 bugs que explicaban "no se muestra / no llega" en varias secciones. Todos corregidos.
**Cambios realizados**:
- `lib/providers/finances_provider.dart`: era el ÚNICO provider CRUD sin RealtimeChannel → lo que cargaba la pareja no aparecía hasta reabrir la pantalla. Agregado canal `finances_realtime` sobre `transactions` con recarga silenciosa (`_reload` sin estado loading, para no parpadear). Además se quitó `.limit(100)`: con >100 transacciones las viejas desaparecían para siempre del balance y del gráfico (`period: year/all` sumaba solo las últimas 100).
- `lib/screens/letters_screen.dart`: los `catchError` convertían CUALQUIER error de Supabase en bandeja vacía, y encima el cache local (`cache_letters_inbox/sent`) se pisaba con `[]` al fallar la red → "mis cartas desaparecieron" incluso offline. Ahora: los errores de fetch propagan al catch, el cache SOLO se escribe con datos reales, y si no hay datos ni cache se muestra el estado de error + tile de reintento (cloud_off).
- `lib/providers/trivia_provider.dart`: (1) carrera de siembra — si ambos abrían Trivia con el banco vacío, ambos insertaban las 10 preguntas → banco duplicado y marcador desalineado. Fix: doble chequeo antes del insert + `_dedupeQuestions()` idempotente (deja el id más bajo por texto de pregunta, limpia duplicados históricos). (2) La rama "migración de schema viejo" leía `options` de un `select('id')` → siempre null y nunca migraba; ahora `_completeMissingOptions()` pide `id, question, options` y completa opciones faltantes matcheando por texto contra el banco.
- `lib/providers/couple_provider.dart`: `_reload()` hacía `clear()` + `addAll` sobre la lista compartida — dos eventos realtime casi simultáneos (mood + completion, normal un día activo) se cruzaban: duplicados y racha 🔥 que parpadeaba/mostraba mal. Fix: los fetch llenan listas LOCALES y se asignan atómicamente; recarga serializada con guard `_reloading` + `_reloadQueued` (no se pierde ningún evento).
- `lib/screens/nosotros_screen.dart`: TODOS los errores (carga y mutaciones) iban a `debugPrint` → sin internet parecía que la pareja no hizo nada y tocar emoción/pregunta "no hacía nada". Fix: contador de fallos en `_loadAll` — si fallan ≥3 queries (o el catch exterior), SnackBar "Sin conexión"; las 3 mutaciones (`_addMood`, `_answerQuestion`, `_sendNewQuestion`) ahora muestran `AppFeedback.error`.
- `lib/providers/gallery_provider.dart` + `lib/screens/galeria/galeria_screen.dart`: (1) **`loadComments` nunca se llamaba desde la UI** → los comentarios de las fotos NUNCA se mostraban (bug no detectado en la auditoría inicial, apareció al verificar). Se conecta al abrir la foto fullscreen. (2) Realtime sobre `gallery_comments`: si la pareja comenta una foto que ya tengo cargada, se refrescan en vivo (antes había que cerrar y reabrir). (3) `delete()` con catch totalmente silencioso → ahora setea `_error` y la pantalla muestra SnackBar ("borré la foto y reaparece" sin explicación → ahora avisa). (4) Tile de carga (hourglass) mientras carga sin cache — antes la pantalla se veía idéntica a "no hay fotos" y a "rompió".
**Lecciones**:
- "El último catch en la cadena" decide lo que ve el usuario: un `catchError((_) => [])` convierte fallo de red en dato vacío, y escribir cache DESPUÉS de ese catchError pisa datos buenos con vacíos. El cache local debe escribirse SOLO con fetch exitoso.
- Un método de provider que nadie llama es un feature entero faltante (loadComments existía, estaba testeado en el provider y jamás se invocaba desde la pantalla): al auditar "no se muestra X", verificar que el camino UI → provider → query esté CONECTADO de punta a punta, no solo que el método exista.
- Un provider CRUD sin realtime en una app de pareja es un bug de producto, no una omisión: cada provider nuevo debería copiar el patrón load + subscribe + reload silencioso (finanzas fue el último que quedó afuera).
- El `clear()` + `await Future.wait(addAll)` sobre una lista de instancia es una carrera esperando realtime: fetch a listas locales y asignación atómica única.
- Los `limit(N)` "de protección" en queries de listado truncan silenciosamente historiales y cálculos agregados (balance/gráfico) — si la tabla crece, paginar en vez de limitar.
**Impacto**: `finances_provider.dart`, `letters_screen.dart`, `trivia_provider.dart`, `couple_provider.dart`, `nosotros_screen.dart`, `gallery_provider.dart`, `galeria_screen.dart`, docs.
**Relacionado con**: D-2 (Supabase), errores-conocidos (patrón catch silencioso), LocalCache (offline-first), análisis de uso en pareja.

## [2026-08-28] - BUGFIX - Los títulos de las cartas no se veían en los bloques del mosaico
**Resumen**: En la sección de Cartas, los bloques del mosaico "loca" no mostraban el título de las cartas (ni el icono). En `_letterChild`, el título y el icono usaban `_letterIconColor()`, que para cartas NO selladas devolvía `_letterColor()` — el MISMO color que el fondo del bloque (`e.color`). El título se pintaba del mismo color sobre el mismo color → invisible (rosa `_cInbox` sobre rosa, o morado oscuro `_cRead` sobre morado).
**Cambios realizados**:
- `lib/screens/letters_screen.dart`: `_letterIconColor()` para cartas no selladas ahora devuelve `Colors.white` (contraste), consistente con el preview de contenido que ya usaba `Colors.white`. Las selladas siguen con `_black` (visible sobre ámbar `_cSealed`).
**Lecciones**:
- El contraste dentro de un bloque brutalista (fondo == borde sólido de un solo color) requiere que el contenido (icono/título) use un color DISTINTO al del bloque. Devolver el mismo color para "contenido" y "fondo" los funde. El `resultado` de `_letterColor` es para el fondo del bloque; el color del contenido debe ser de contraste (blanco), no una referencia al fondo.
**Impacto**: `letters_screen.dart`, docs.

## [2026-08-28] - BUGFIX - Botón back de Android cerraba la app en vez de cerrar overlays/menús
**Resumen**: Al apretar el back del celular, si había un menú/popup en pantalla que NO era una ruta del Navigator (overlays dibujados con `Stack`), el sistema operativo salía de la app entera en lugar de cerrar ese overlay. Se interceptó el back con `PopScope` en los 2 puntos compartidos que concentran el problema: el kit "loca" (13+ pantallas de mosaico) y el Home (mazo, poemas, panel de notificaciones, match).
**Cambios realizados**:
- `lib/widgets/loca_screen.dart`: el build se envuelve en `PopScope(canPop: _openPanel == null && !_busy)`; si hay un panel swink abierto, el back llama `_close()` (cierra el panel) y bloquea el pop (no se sale de la pantalla).
- `lib/screens/home_screen.dart`: el `_BrutalGrid` se envuelve en `PopScope(canPop: !_notifDrawer && !_showDeck && !_showPoemas && pendingMatch == null)`. Nuevo `_handleBack()` que cierra en orden de prioridad: panel de notificaciones → mazo → poemas → match (`consumeMatch`). Solo cuando no queda ningún overlay deja escapar el back (volver a la pantalla anterior o salir de la app).
- Tests: suite **238 verdes**, `flutter analyze` sin errores nuevos (20 issues = baseline; el único `curly_braces` de home_screen:620 es pre-existente en `_markAllRead`).
**Lecciones**:
- El botón back de Android solo conoce rutas del Navigator. Los overlays/menús "locos" (paneles swink de LocaScreen, mazo, drawer) viven en un `Stack` interno sin registro de navegación, así que en la pantalla raíz el back sale de la app directo. La cura es `PopScope` en el STATE que posee esos flags: `canPop` false mientras haya overlay abierto + `onPopInvokedWithResult` que lo cierra (y no hace `Navigator.pop`).
- En Flutter 3.44 usar `onPopInvokedWithResult(didPop, _)` (el `onPopInvoked` está deprecado); siempre chequear `if (didPop) return;` antes de manejar.
- `canPop` debe re-leerse del provider cuando el overlay se controla desde afuera (match del mazo vive en `DeckProvider.pendingMatch`): usar `context.read` en el getter para que `consumeMatch()` dispare rebuild y el back deje de bloquear.
- Los `if (x) { ...; return; }` de una sola línea disparan `curly_braces_in_flow_control_structures`; usar bloques.
**Impacto**: `loca_screen.dart`, `home_screen.dart`, docs.
**Relacionado con**: D-4 (skill_visual), glosario (pantalla "loca", mazo), errores-conocidos (sin nuevos).

## [2026-08-28] - BUGFIX - Pantallas blancas en release (Logros/Metas): guardas en arranger + cache local a prueba de fallos
**Resumen**: En el APK release, Logros y Metas (y pantallas con cache local) se veían en blanco. Hipótesis raíz: una excepción de build tragada en release — (1) `LocaArranger.arrange` divide por ancho/alto y si la pantalla llega con alto 0 (transición) genera NaN → excepción de layout; (2) la lectura de cache local (`LocalCache`) corría FUERA de try en metas/retos/cartas → si SharedPreferences fallaba, la pantalla reventaba en blanco en Android.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: `arrange` ahora retorna vacío si `width <= 0 || height <= 0 || cantidad < 1` (evita división por cero → NaN → pantalla blanca).
- `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`: la lectura de `LocalCache` queda dentro de try/catch (si SharedPreferences falla, no rompe la pantalla).
- Tests: suite **238 verdes**, analyze sin errores.
**Nota honesta**: no pude reproducir en un dispositivo Android real; apliqué estas guardas defensivas (la causa más probable de "blanca en release"), pero conviene validar en el emulador/celular del usuario con logs si persiste.
**Impacto**: `loca_arranger.dart`, `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`, docs.

## [2026-08-28] - FEATURE - Trivia con aspecto de mazo apilado (tipo tarjetas de poemas)
**Resumen**: La pantalla de Trivia ahora se presenta como un MAZO apilado de cards (degradado, Bangers, sin borde) estilado como el mazo de tarjetas. El tile de Trivia abre un overlay a pantalla completa.
**Cambios realizados**:
- `lib/screens/trivia/trivia_screen.dart`: el tile de Trivia ahora usa `onTap` para abrir `TriviaDeckOverlay` (antes abría un panel). Nuevo widget `TriviaDeckOverlay`: cards apiladas (2 detrás con offset/escala/escala de opacidad) de las preguntas del banco (`provider.questions`); se desliza a izquierda/derecha para navegar; la card frontal muestra la pregunta + chips de "Tu respuesta" y "Predicción" + Confirmar (`provider.submit`). Marca "respondida" persistida (icono check en el tile).
- La marca "respondida" del tile se mantiene.
- Tests: suite **238 verdes**, analyze sin errores.
**Lecciones**:
- Para el efecto "mazo", dibujar las cards de atrás con offset/scale/opacity decrecientes y la frontal delante; el gesto `onHorizontalDragEnd` decide avanzar/retroceder por `primaryVelocity`.
- `LocaEntry.panel` ya no abría la trivia (ahora es `onTap`); mantener `panels` con el panel viejo (sin uso) es código muerto aceptable, o se puede quitar.
**Pendiente**: pantallas blancas de Logros/Metas en APK (sesión dedicada).
**Impacto**: `trivia_screen.dart`, docs.

## [2026-08-28] - BUGFIX/FEATURE - Sonido en Android real + bloques de finanzas cuadrados
**Resumen**: (1) El sonido seguía sin oírse en Android: el fix de ruta anterior dejó `_assetPrefix = 'Assets/sounds/'` y como los calls pasan `'sounds/click.wav'`, la ruta se DOBLAVA (`Assets/sounds/sounds/click.wav`) → clave inválida → silencio. (2) Los bloques del mosaico de finanzas salían muy estirados/delgados.
**Cambios realizados**:
- `lib/services/sound_service.dart`: `_assetPrefix` → `'Assets/'` (los calls ya incluyen `sounds/...`, así el resultado final es `Assets/sounds/click.wav`, la clave correcta que busca Android).
- `lib/widgets/loca_screen.dart`: nuevo `LocaEntry.weight` (opcional) para repartir bloques más cuadrados en el arranger.
- `lib/screens/finanzas/finanzas_screen.dart`: pesos fijos (`saldo/ingresos/gastos/gráfico`=3, transacciones=2.5, historial/agregar=2) → bloques más equilibrados y cuadrados.
- Tests: suite **238 verdes**, analyze sin errores.
**Lecciones**:
- Al corregir un path con prefijo hay que verificar la concatenación final: `'Assets/sounds/' + 'sounds/click.wav'` duplica el segmento (no suena en Android). El call ya lleva `sounds/...`, así que el prefijo correcto es `'Assets/'`.
**Pendiente**: Trivia "mazo apilado" (apilar preguntas como las tarjetas del deck) y pantallas blancas de Logros/Metas en APK (sesión dedicada).
**Impacto**: `sound_service.dart`, `loca_screen.dart`, `finanzas_screen.dart`, docs.

## [2026-08-28] - BUGFIX/UX - Pizarra: notas se ven con su estilo real (fuente, color, imagen) en el canvas
**Resumen**: El `_noteBody` del pizarrón renderizaba las notas como cards genéricas (monospace, sin imagen), ignorando el estilo que el usuario define en el modal (fuente, tamaño, color, alineación, negrita/italica/subrayado, imagen). El guardado ya persistía ese estilo (`el.fontFamily`, `el.textColor`, `el.fontSize`, `data['imagePath']`, etc.) — el problema era el render simplificado.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart` `_noteBody`: ahora aplica `el.fontFamily`, `el.textColor`, `el.fontSize` (escalado para la card), `el.textAlign`, `el.isBold/isItalic/isUnderline`, y renderiza la `imagePath` de la nota (Image.file con errorBuilder). Se mantienen forma, gradiente (lineal/radial) y borde.
- Quedan pendientes para sesión dedicada (exactitud total): patrones de fondo (12), tipos de borde (6) y audio dentro de la nota en el canvas.
- Lección de proceso: NO editar archivos Dart con `Set-Content`/PowerShell (~colapsó el archivo a una línea); usar siempre el editor. Se recuperó con `git checkout -- <archivo>` y se reaplicó el cambio correctamente.
**Impacto**: `pizarra_screen_v2.dart`, docs.

## [2026-08-28] - FEATURE/UX - Chat sin flecha, Home: swap de mini-iconos (mazo primero), mazo con Historial (sin la X)
**Resumen**: Ajustes de navegación y accesos pedidos por el usuario.
**Cambios realizados**:
- `lib/screens/chat_screen.dart`: se quita la flecha de volver del header del chat (volver por gesto/sistema).
- `lib/screens/home_screen.dart`: en la fila de mini-iconos se intercambian el 1º y el 3º: ahora el **mazo general** (`Icons.style`, nuevo `_openMazo`) es el 1º, Trivia quedó al medio, y Poemas (`auto_stories`) pasó al 3º.
- `lib/screens/mazo/deck_overlay.dart`: se quita la **X de la esquina** cuando hay tarjetas y en su lugar queda un botón de **Historial** (`Icons.history`) que abre `DeckHistorySheet` (re-deslizar incluido). La X (cerrar) se mantiene solo cuando no hay tarjetas (vacío) para no quedar atrapado.
- Tests: suite **238 verdes**, `flutter analyze` sin errores (baseline).
**Lecciones**:
- Para no dejar al usuario atrapado en un overlay de pantalla completa de solo-swipe, al reemplazar el botón de cierre por otro hay que conservar una salida al menos en el estado vacío.
- `showDeckHistorySheet` recibe `onReswipe`; para re-deslizar dentro del overlay hay que setear el estado de re-swipe del overlay.
**Pendiente**: Trivia "crear/sin historial" (agregar pregunta + últimas 5 + historial) y pizarra: persistir notas + render idéntico al modal (sesión dedicada).
**Impacto**: `chat_screen.dart`, `home_screen.dart`, `deck_overlay.dart`, docs.

## [2026-08-28] - BUGFIX/UX - Swipe izquierdo del Home (panel notif) + título grande en cartas
**Resumen**: El botón de la columna izquierda del Home no deslizaba con mouse/dedo para abrir el panel de notificaciones; el gesto no ganaba la arena. Además las cartas en el mosaico mostraban poco el título.
**Cambios realizados**:
- `lib/screens/home_screen.dart`: `LeftButtons` pasó de StatelessWidget a **StatefulWidget** (`_LeftButtonsState`) con arrastre robusto en el tile superior: `onHorizontalDragStart/Update` acumulan `_dragDx`, y `onHorizontalDragEnd` abre el panel si `dx > 60` o `primaryVelocity > 250`. El tile superior ahora usa `GestureDetector` (tap + drag) sin `TapTile` anidado (evita que el tap externo gane y cancele el drag). `onHorizontalDragCancel` resetea.
- `lib/screens/letters_screen.dart`: en el mosaico, el título de cada carta ahora se muestra **grande** (fontSize 21, hasta 3 líneas) en vez de 15/1 línea.
- Tests: suite **238 verdes**, `flutter analyze` sin errores.
**Lecciones**:
- Un `HorizontalDragGestureRecognizer` con SOLO `onHorizontalDragEnd` puede no ganar la arena frente al tap (no reclama durante el movimiento): hace falta `onHorizontalDragUpdate` (o `onStart`) que acumule y haga que el recognizer entre y gane; luego se decide en `onEnd` con umbral de desplazamiento + velocidad.
- Anidar un `TapTile` (con su GestureDetector) dentro del GestureDetector que maneja el drag hace que el tap pueda robar el gesto; para un swipe robusto conviene un único GestureDetector con `onTap`+drag en el tile.
**Impacto**: `home_screen.dart`, `letters_screen.dart`, docs.

## [2026-08-28] - BUGFIX - Sync de calendario entre usuarios: eventos y clases compartidos (RLS + publicación realtime)
**Resumen**: El usuario reportó que los eventos (`schedules`) y las clases (`class_schedules`) no se veían entre Facu y Rocio. El código de los providers ya trae TODAS las filas cloud (`select('*')`) y hace merge por `cloudId`, así que el origen estaba en la DB desplegada: o el RLS no era permisivo en esas tablas o no estaban en la publicación realtime.
**Cambios realizados**:
- Verificación: `schedule_provider.dart` y `class_schedule_provider.dart` ya hacen `_pushUnsyncedToCloud` + `_pullFromCloud` (pull de todas las filas) + realtime `schedules_sync` / `class_schedules_sync`. `calendar_home_screen.dart` carga ambos en `initState` (`loadSchedules`). No hacía falta tocar el código.
- `supabase/migration_schedule_class_sync.sql` (nuevo): idempotente — `DROP`+`CREATE POLICY "full_access_schedules"` y `"full_access_class_schedules"` (FOR ALL USING true), `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`, `GRANT` a anon/authenticated, y `ALTER PUBLICATION supabase_realtime ADD TABLE schedules` / `class_schedules`. **PENDIENTE ejecutar en SQL Editor** → es lo que hace que ambos usuarios vean los eventos/clases del otro.
- Builds: `app-release.apk` (93.7 MB) y `furi_app.exe` recompilados con todo el código nuevo (verificado por strings en `app.so`). Fix para build de Windows sin daemon: pasar el entorno MSVC (`vcvarsall.bat amd64`) vía un `.cmd` temporal (evita el `&&` inválido de PowerShell 5.1).
**Lecciones**:
- Cuando el provider ya hace pull de TODAS las filas pero el otro usuario no ve nada, sospechar primero RLS/publicación realtime en la DB desplegada (no el código): un `DROP POLICY`+`CREATE full_access` + `ADD TABLE` a `supabase_realtime` es la cura idempotente.
- Verificar que un build incluye el código nuevo grepeando un string de UI del binario (`app.so`), no nombres de métodos (Dart los minifica en AOT).
**Pendiente**: en el SQL Editor, ejecutar `supabase/migration_schedule_class_sync.sql`; replicar `LocalCache` a las secciones basadas en provider.
**Impacto**: `migration_schedule_class_sync.sql` (nuevo), builds exe+apk, docs.

## [2026-08-27] - FEATURE/UX - Home: se quita la campana de notificaciones y el botón superior izquierdo abre un panel deslizante de notificaciones
**Resumen**: En el Home se eliminó el botón de campana (notificaciones) que estaba pegado al de configuración, y el botón superior izquierdo (columna izquierda) ahora se desliza hacia la derecha para abrir, con animación dinámica, un panel de notificaciones que entra desde la izquierda.
**Cambios realizados**:
- `lib/screens/home_screen.dart`: se quita `notificationBadge` (la campana junto a settings); el bloque de settings queda solo con el icono de engranaje y abre Configuración.
- Se elimina el contador `_unreadNotifications` y el método `_openNotifications` (ruta `notifications` queda sin entrada desde Home).
- El botón superior de `LeftButtons` ahora acepta `onSwipeRight`: al deslizar a la derecha (>250 vx) abre el panel de notificaciones.
- Nuevo `_NotificationPanel` (StatefulWidget) que entra con `SlideTransition` desde la izquierda + backdrop oscuro (controlado por `_drawerCtrl` con `easeOutCubic`). Lista notificaciones (`NotificationService.getNotifications`), estados loading/error/empty/data, en cada item abre el detalle y lo marca leído; botón "todas leídas" y cerrar.
- Tests: suite **238 verdes**, `flutter analyze` sin errores (20 issues baseline/info).
**Lecciones**:
- Un gesto horizontal (swipe right) no dispara el tap del `TapTile` interno si no lo "acepta" (dragging supera el slop); por eso el drawer se abre en `onHorizontalDragEnd` con `primaryVelocity`, sin necesidad de conflicto con el tap de confeti.
- Para un panel que entra desde un costado, `SlideTransition` con curva `easeOutCubic` + un `AnimatedBuilder` sobre un `AnimationController` propio es suficiente y no depende de page-route.
**Pendiente**: replicar `LocalCache` al resto de secciones basadas en provider (favoritos, finanzas, galería, logros, recompensas, notificaciones, mapa).
**Impacto**: `home_screen.dart`, docs. La ruta `/notifications` sigue existiendo en el router (sin entrada desde Home).
**Relacionado con**: D-4 (skill_visual), análisis de uso en pareja.

## [2026-08-27] - FEATURE - Cache local offline-first (piloto metas/retos/cartas): sin "carga" al entrar + sync en segundo plano
**Resumen**: Primera entrega del cache local offline-first. Se creó un helper reutilizable `LocalCache` (SharedPreferences JSON, "últimos datos conocidos") y se aplicó a metas, retos y cartas: al entrar se muestra el cache al instante (sin tile/spinner de carga), y después se sincroniza con Supabase guardando lo nuevo. Los writes siguen refrescando el cache vía el `_load()` que ya corre al final.
**Cambios realizados**:
- `lib/services/local_cache.dart` (nuevo): `LocalCache.getList/setList/remove` — cache por key (`cache_<tabla>`) en SharedPreferences como JSON de `List<Map>`.
- `metas_screen.dart` (`cache_metas`): `_loadMetas` primero muestra el cache si `_metas` está vacío, luego fetch + `setList`. Al ser los writes → `_loadMetas()`, el cache se refresca solo.
- `retos_screen.dart` (`cache_retos`): ídem; además el tile de carga queda cubierto por el cache-first.
- `letters_screen.dart` (`cache_letters_inbox`/`cache_letters_sent`): `_loadLetters` muestra cache de ambas listas + `setList` tras el fetch.
- Tests: suite **238 verdes**, `flutter analyze` baseline (19 issues, sin errores).
**Lecciones**:
- Un "últimos datos conocidos" en SharedPreferences JSON es un primer paso de bajo riesgo para el offline-first, sin tocar SQLite ni el merge del realtime: al entrar mostrás el cache y re-reemplazás con el fetch. No bufferear escrituras offline todavía.
- En retos había un `}` doble tras el edit (rompía el archivo): al cambiar un método completo conviene revisar el cierre (dos `}` seguidos → estructura rota; `dart analyze <archivo>` puntual lo detecta rápido).
- Plan: replicar `LocalCache` al resto de secciones (favoritos, finanzas, galería, logros, recompensas, notificaciones, mapa) con su key propia.
**Pendiente**: replicar el cache al resto de secciones; para el offline "escribir sin internet" real habría que pasar a SQLite con cola de dirty + merge (sesión dedicada).
**Impacto**: `local_cache.dart` (nuevo), `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`, docs.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite/offline), análisis de uso en pareja.

## [2026-08-27] - FEATURE - Trivia "respondida" + feedback/undo AppFeedback en finanzas, cartas, favoritos y recompensas
**Resumen**: Cierre de pendientes de la tanda anterior sobre "feeling": la Trivia ahora se marca como respondida (check + swap al marcador), y se extendió el patrón `AppFeedback` (guardado/celebración/undo) a finanzas, cartas, favoritos y recompensas.
**Cambios realizados**:
- `lib/screens/trivia/trivia_screen.dart`: el tile "Trivia" pasa a `Icons.check_circle` verde cuando `pv.myAnswerToday != null` (ya respondí hoy) → **marcada como respondida**.
- `lib/screens/finanzas/finanzas_screen.dart`: al guardar transacción → `AppFeedback.saved('Transacción guardada')`; nuevo `_deleteTransaction()` borra con `AppFeedback.deleted(... UNDO)` que reinserta la transacción.
- `lib/screens/letters_screen.dart`: al enviar carta → `AppFeedback.saved('Carta enviada')` (con guard `mounted`).
- `lib/screens/favoritos/favoritos_screen.dart`: al guardar/editar favorito → `AppFeedback.saved('Guardado')`.
- `lib/screens/recompensas/rewards_screen.dart`: al crear recompensa → `saved`; al marcar cumplida → `success(... celebration: true)`.
- Nota: un `flutter analyze` full puede reportar una CASCADA de errores espurios de `undefined_method`/`expected_token` en un archivo que está bien (stale cache del daemon): al correr `flutter analyze <archivo>` puntual da 1 sola línea correcta. Ante esa cascada, debuggear con analyze de archivo puntual, no asumir que el archivo está roto.
- Tests: suite **238 verdes**, `flutter analyze` baseline (19 issues pre-existentes, sin errores).
**Lecciones**:
- Marcar "respondida" de la trivia es mostrar el estado de `myAnswerToday` del provider (ya era data); basta cambiar el icono del tile según ese estado, no hace falta lógica nueva.
- El `AppFeedback.saved` tras un `await` dispara `use_build_context_synchronously`: proteger con `if (mounted)` para no sumar warnings.
- Extender `AppFeedback` es trivial: misma firma probada en metas; cada pantalla solo importa el helper y lo llama en las acciones de guardado/borrado/cumplido.
**Pendiente**: cache local offline-first general + quitar el "carga" visual al entrar (grande, sesión dedicada); `AppFeedback`/undo en pizarra (borrado complejo por conectores).
**Impacto**: `trivia_screen.dart`, `finanzas_screen.dart`, `letters_screen.dart`, `favoritos_screen.dart`, `rewards_screen.dart`, docs.
**Relacionado con**: D-4 (skill_visual), D-2 (Supabase), análisis de uso en pareja.

## [2026-08-27] - BUGFIX/UX - Sin tile de carga al entrar a las secciones "loca" + cartas muestran título y preview en el bloque
**Resumen**: El usuario pidió que al entrar a cada sección no se vea una animación/indicador de carga. Se eliminaron los tiles de ampolleta (`Icons.hourglass_top`) que aparecían mientras cargaba data de Supabase en TODAS las pantallas "loca". Además, las cartas recibidas ahora muestran su título Y un poco del contenido dentro del bloque del mosaico (antes solo el título).
**Cambios realizados**:
- Eliminado el `LocaEntry(icon: Icons.hourglass_top, ...)` de carga en: `retos_screen.dart`, `metas_screen.dart`, `notifications_screen.dart`, `galeria_screen.dart`, `trivia_screen.dart`, `favoritos_screen.dart`, `finanzas_screen.dart`, `rewards_screen.dart`, `logros_screen.dart`.
- Retos y metas: quitado el campo `_loading` y sus asignaciones (quedaba sin uso tras borrar el tile). El estado de error (`cloud_off`) se mantiene.
- `letters_screen.dart`: nuevo `childBuilder` (`_letterChild`) en las cartas del mosaico que renderiza icono de estado + título (Bangers 15) + preview de hasta 40 caracteres del contenido (2 líneas). Las selladas solo muestran título (no spoilean contenido). Se agregó import de `widgets/brutal_style.dart`.
- No se tocó el auto-swap (el usuario eligió solo el spinner/ampolleta de carga).
**Lecciones**:
- Los tiles de carga como `LocaEntry` eran estáticos (sin animación real) pero el usuario los percibe como "animación de carga": la solución fue no mostrarlos y dejar solo los estados error/empty/data.
- Al quitar un tile condicional, revisar que el campo de estado que lo gatillaba (`_loading`) no quede huérfano (analyzer `unused_field`).
- Para mostrar contenido en un bloque "loca" junto a ítems que usan `label`, usar `childBuilder` (tiene prioridad sobre el icono+label por defecto y convive con el peso del arranger por `label`).
**Impacto**: 10 screens, `lib/widgets/` sin cambios, docs.
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE/BUGFIX - Consistencia visual Rocio, pizarra/calendario/flecha, "X más nuevos + historial" (cartas/metas/retos/finanzas), tapToSwap y marca de vista local
**Resumen**: Segunda tanda del polish. Se unificó el look "apagado" al entrar como Rocio (antes algunos bloques quedaban brillantes), se quitaron pasos intermedios y flechas innecesarias, se arregló el recorte del calendario, y se montó el sistema de "solo las X más nuevas + historial" en cartas (6), metas (8), retos (5) y finanzas (6). Se agregó el swap al tocar y la marca de "vista" local en cartas.
**Cambios realizados**:
- **Brilloso como Rocio**: `lib/theme/app_theme.dart` nuevo `identityTheme(t)` = mutea si `AppState.identity == 'Rocio'`. `lib/widgets/loca_screen.dart` lo aplica centralmente en `build` → **todos** los mosaicos/menús/submenús lucen apagados igual que el resto (antes usaban el tema lleno).
- **Pizarra directa**: `home_screen.dart` `_openPizarra` ahora entra a `RouterRoutes.pizarra` (canvas) sin pasar por el mosaico.
- **Calendario cortado**: `calendar_home_screen.dart` el mes usaba `GridView` con `NeverScrollable` y `childAspectRatio` → recortaba la 6ª semana abajo. Reemplazado por grilla de semanas `Expanded` que reparte la altura disponible → mes completo siempre visible.
- **Flecha de volver**: eliminada de la barra de 3 corazones del `LocaScreen` (todas las secciones). La vuelta queda por gesto/teclado/sistema.
- **tapToSwap**: `LocaScreen` nuevo `LocaEntry.tapToSwap` → al tocar un bloque con `swapBuilder` fuerza mostrar su info al instante (`_forceSwap`). Aplicado en `finanzas_screen.dart` a saldo/ingresos/gastos.
- **Favoritos → guardados**: el tile "guardados" ahora abre un panel swink (lista de `allFavorited`); se eliminó el toggle `_showOnlyFavorited` muerto.
- **Cartas (6 + historial)**: `letters_screen.dart` muestra solo las 6 recibidas más recientes; tile "enviadas" → **"historial"** que lista Recibidas y Enviadas en secciones separadas. **Marca de "vista" local**: `_readLocal` en SharedPreferences (`readLetter-{id}`) para reflejar la leída al instante; `_markReadLocal` al abrir cartas.
- **Metas (8) / Retos (5) + historial**: `metas_screen.dart` y `retos_screen.dart` muestran 8/5 ítems en su orden + tile "historial" con panel que lista todas como cards (toggle done).
- **Finanzas (6 + historial)**: `finanzas_screen.dart` muestra las 6 transacciones más recientes + tile "historial" con todas (editar/borrar inline).
- **Metas feedback/undo** (de la tanda anterior): celebración al cumplir, "Meta guardada", borrado con DESHACER vía `AppFeedback`.
- Tests: suite **238 verdes**, `flutter analyze` baseline (issues pre-existentes; sin errores en archivos tocados).
**Lecciones**:
- El tema brillante por sección era inconsistente: el muteo por identidad debe ser **central** (en el scaffold compartido `LocaScreen`), no por pantalla, o algunas quedan brillantes.
- Un `GridView` con `NeverScrollableScrollPhysics` + `childAspectRatio` recorta el contenido que excede el alto: para algo que debe verse SIEMPRE completo (un mes), es mejor repartir las filas con `Expanded` y dejar que las celdas se achiquen.
- Marcar "visto" de forma local (SharedPreferences) da respuesta instantánea sin depender del round-trip de la nube; se puede complementar con el `seen_by` cloud.
- El sistema "X más nuevos + historial" mantiene el mosaico liviano cuando un listado crece: cap con `.take(X)` para el mosaico + un tile "historial" que muestra todo en un panel.
- `d.globalPosition` del toque es la fuente confiable para posicionar efectos (confeti) sobre el botón.
**Pendiente**: cache local offline-first general + quitar el "carga" visual al entrar (grande); trivias "respondidas" (marcado local); extender `AppFeedback` a favoritos/finanzas/cartas/recompensas/pizarra.
**Impacto**: `app_theme.dart`, `loca_screen.dart`, `home_screen.dart`, `calendar_home_screen.dart`, `favoritos_screen.dart`, `finanzas_screen.dart`, `letters_screen.dart`, `metas_screen.dart`, `retos_screen.dart`, docs.
**Relacionado con**: D-4 (skill_visual), D-2 (Supabase), análisis de uso en pareja.

## [2026-08-27] - FEATURE+BUGFIX - Polish de uso real: sonido en Android, confeti donde se toca, chat con "escribiendo..."/scroll infinito, feedback/undo en metas y limpieza de botones muertos
**Resumen**: Primera tanda del análisis de uso serio en pareja. Se corrigieron bugs de confianza (botones muertos, sonido que solo sonaba en PC, confeti que aparecía en la esquina), se agregó feeling (indicador "escribiendo...", scroll infinito del chat, celebración al cumplir metas, confirmación y deshacer), y se limpió código muerto.
**Cambios realizados**:
- `lib/services/sound_service.dart`: **fix del sonido en Android**. Los assets viven en `Assets/sounds/` (declarado en pubspec), así la clave real (case-sensitive) es `Assets/sounds/click.wav`, pero el código usaba `AssetSource('sounds/click.wav')`. En PC `audioplayers_windows` resuelve por filesystem e igual lo encontraba; en **Android el asset manager busca la clave exacta y falla en silencio → nada de sonido**. Se agrega `_assetPrefix = 'Assets/sounds/'` y `AssetSource(_asset('...'))`.
- `lib/services/settings_service.dart`: `SettingsService().init()` **nunca se llamaba** en `main.dart` → los prefs de sonido no se cargaban. Se agrega la llamada en `main()`.
- `lib/screens/settings_screen.dart`: el tile "Sonidos" era un placeholder sin acción → ahora es un **toggle funcional** (StatefulWidget): muestra volumen_on/off, persiste con `setEnableSound`, y al activar reproduce `success()` como feedback.
- **Botones muertos** (confianza): `lib/screens/home_screen.dart` — el mini-icono "Mazo" (`Icons.style`) era `onTap: () {}`; ahora dispara confeti (sigue sin navegación, decisión del usuario). "Estudio" sigue decorativo. **Código muerto eliminado**: `providers/tasks_provider.dart` (TasksProvider) y las pantallas huérfanas `question_screen.dart`, `mood_screen.dart`, `notes_screen.dart`, `pizarra/pizarra_screen.dart` (v1).
- **Confeti posicionado** (bug): `home_screen.dart` — el confeti salía SIEMPRE en la esquina. Causas: `_confettiAt` usaba `context.findRenderObject().localToGlobal()` (descolocaba) y varios botones pasaban `(0,0)`. Fix: normalización por pantalla en `_confettiColorsFor` + nuevo `_confettiGlobal(Offset)` que usa `d.globalPosition` del toque (confiable) en los botones chicos (pesa/finanzas/favoritos/modos/mini-iconos/columna izquierda). Los `block` grandes siguen con centro de canvas.
- `lib/screens/login_screen.dart` + `lib/widgets/loca_screen.dart`: el Login no mostraba carga ni bloqueaba dobles toques → `LocaEntry.onTapAsync` (nuevo) + overlay de spinner mientras corre `_login`.
- `lib/providers/chat_provider.dart` + `lib/screens/chat_screen.dart`: (1) **scroll infinito** — el chat cargaba solo los últimos 100; la lista pasó a `reverse: true` (nuevo abajo) para que el paginado ancle la vista, y `loadOlderMessages()` prepara páginas anteriores al llegar al tope. (2) **"escribiendo..."** — nueva tabla `chat_typing` (user_id PK, is_typing, updated_at) con `subscribeTyping()` (realtime), `notifyTyping(bool)` con auto-clear a 1.5s, y banner "escribiendo…" en pantalla. `supabase/migration_chat_typing.sql` **PENDIENTE ejecutar en SQL Editor**.
- `lib/widgets/app_feedback.dart` (nuevo): helper global de SnackBar brutalista (success/saved/deleted con UNDO/error).
- `lib/screens/metas_screen.dart`: al cumplir una meta → celebración (`AppFeedback.success(celebration: true)`); guardar → "Meta guardada"; borrar → **SnackBar con DESHACER** (`_restoreMeta` reinserta).
- Tests: suite **238 verdes**, `flutter analyze` 19-20 issues (baseline, todos pre-existentes; sin errores en archivos tocados).
**Lecciones**:
- "El sonido suena en PC pero no en Android": antes de tocar el plugin, verificar que la **ruta del asset coincida EXACTO con la declarada en pubspec** (`Assets/sounds/` incluye `Assets/`). En desktop el plugin resuelve por filesystem y camufla el bug; Android exige la clave exacta.
- Un `SettingsService()` singleton con `init()` que nadie llama es un toggle "roto" aceptado: al no cargar prefs, `_enableSound` quedaba en default true y el toggle no persistía. Revisar que cada servicio que lee SharedPreferences tenga su `init()` en `main()`.
- El confeti "en la esquina" era doble culpa: `localToGlobal` con el RenderBox equivocado + varios callbacks pasando `(0,0)`. `d.globalPosition` del gesto es la fuente confiable de posición y no depende de boxes.
- Paginar historial de chat "hacia arriba" con `reverse: true` (nuevo abajo) hace que el prepend de mensajes viejos **ancle la vista sin saltar** — mucho más simple que medir alturas de items de altura variable.
- Un "deshacer" de borrado en tablas sin soft-delete se resuelve reinsertando la fila (se pierde el id original, se gana la recuperación). Para metas/retos es aceptable y da control al usuario.
**Pendiente**: ejecutar `supabase/migration_chat_typing.sql` en SQL Editor (sin eso, `notifyTyping`/`subscribeTyping` fallan en la nube). Extender el patrón de feedback/undo/celebración a favoritos, finanzas, cartas, recompensas y pizarra (mismo `AppFeedback`).
**Impacto**: `sound_service.dart`, `settings_service.dart`, `settings_screen.dart`, `main.dart`, `home_screen.dart`, `login_screen.dart`, `loca_screen.dart`, `chat_provider.dart`, `chat_screen.dart`, `app_feedback.dart` (nuevo), `metas_screen.dart`, `migration_chat_typing.sql` (nuevo), 5 archivos de código muerto eliminados, docs.
**Relacionado con**: D-4 (skill_visual), D-2 (Supabase realtime), errores-conocidos (sin nuevos), análisis de uso en pareja.

## [2026-08-27] - FEATURE - Calendario minimalista, clases en franja semanal, ejercicios con biblioteca/mejora/stats, mazo en 3 y fix favoritos
**Resumen**: Cuatro mejoras pedidas por el usuario: (1) el menú de agregar de Favoritos mostraba 10 categorías y ahora solo las 4 en uso; (2) calendario y clases rediseñados con estética moderna-minimalista (celdas neutras, hoy/selección en acento cian, clase con barra de color + hora protagonista, franja semanal arriba); (3) ejercicios: rutinas ahora llevan ejercicios de una BIBLIOTECA (nombres ya registrados, chips con autollenado de última sesión), logs editables, botón "mejorar" (nuevo registro pre-cargado), stats de avance (primero/último/Δ) e historial de mejora por ejercicio; (4) el botón del mazo en Home se dividió en 3 (Poemas → deck filtrado, Trivia, y tercero Mazo general).
**Cambios realizados**:
- `favoritos_screen.dart`: `_catSelector` limita el picker a movie/series/game/music.
- `calendar_home_screen.dart`: grilla minimalista (quité colores arcoíris por día) — celdas neutras `#122433`, hoy = borde cian, seleccionado = cian lleno, dots de eventos, nav con iconos + "volver a hoy".
- `class_board_screen.dart`: `_weekStrip` (LUN..DOM con hoy/selección) arriba + agenda full-width con barra de color del tipo, hora grande y profesor.
- `ejercicios_screen.dart`: `_libraryChips` (chips de `distinctExerciseNames`), `_dialogNewLog` soporta `existing` (editar vía `updateLog`), `_promptItem` reusa chips, `_dialogNewRoutine` ahora crea rutina con items (chips de biblioteca con autollenado de la última sesión + "+ ejercicio"), detalle de log con botones editar/mejorar, `_improvementBlock` (PRIMERO/ÚLTIMO/AVANCE + historial completo por fecha seriesxreps@peso).
- `deck_overlay.dart`: param `category` (filtra pendientes; fallback a todas). `home_screen.dart`: bloque mazo → 3 mini-botones (menu_book poemas / school trivia / style mazo).
- Tests suite **238 verdes**, analyze sin issues nuevos.
**Lecciones**:
- El autollenado de la rutina desde la biblioteca (última sesión: series/reps/peso/descanso) hace el setup del plan semanal natural y consistente con los logs: mismo origen de datos.
- `WorkoutLog.loggedOn` es no-nullable: usar `?.`/`??` ahí dispara `dead_null_aware_expression` (lo atrapó el analyzer).
- La grilla de calendario "minimalista" = menos color por celda (neutra) y acento solo en HOY/SELECCIÓN/eventos: el ruido era los 12 colores por día.
- **BUILD RÁPIDO (no hace falta `flutter clean`)**: para refrescar el ápice de Dart alcanza con borrar `build\windows\x64\runner\Release\data\app.so` + `\.dart_tool\flutter_build` y correr `flutter build windows --release` (~2 min vs 20+ con clean). El exe runner no cambia (solo código C++), la BD de `Release\.dart_tool\sqflite_common_ffi` tampoco se toca. Verificado por markers en `app.so` (router viejo ausente / features nuevas presentes).
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE - Tiles legibles (icono+título, tamaño por texto) + mosaico en las 4 pantallas restantes
**Resumen**: Según feedback, los bloques "solo cuadrado con icono" no se entendían. Ahora cada tile muestra su icono de estado + el TÍTULO del ítem debajo, y el arranger reparte el área en proporción a la cantidad de texto (más texto → bloque más grande), manteniendo el mosaico desordenado. Además se aplicó el mosaico a las 4 pantallas que faltaban (Chat, Calendario, Pizarra, Ejercicios) con wrappers de entrada.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: `arrange()` acepta `weights` por ítem — el slicing reparte el área proporcional a los pesos (con jitter de seed y fracción acotada 0.4–0.6 para mantener rectángulos equilibrados).
- `lib/widgets/loca_screen.dart`: `LocaEntry.label` (título corto) → el tile renderiza `icono + título` en Bangers (2 líneas, ellipsis); pesos automáticos `1 + len/14` (clamp 1–8).
- Labels cargados en las 13 pantallas: títulos de retos/metas/cartas/recompensas/notificaciones/logros, descripción de transacciones, categorías de favoritos (pelis/series/juegos/música), saldo/ingresos/gastos, Facu/Rocio, etc.
- `lib/screens/mosaico_wrappers.dart` (nuevo): `ChatMosaicoScreen`, `CalendarMosaicoScreen` (calendario+clases), `PizarraMosaicoScreen`, `EjerciciosMosaicoScreen` (4 tiles Hoy/Ejercicios/Retos/Stats). Home y Nosotros navegan a los wrappers; el contenido funcional original queda detrás (rutas viejas intactas). `EjerciciosScreen` gana `initialTab`.
- Tests: `loca_arranger_test` +2 (pesos → bloque más grande; sin pesos balanceado). Suite **238 verdes**.
**Lecciones**:
- "Que se entienda qué es cada bloque" ≠ texto grande: icono de estado + título chico en Bangers debajo es suficiente, y el título alimenta el tamaño (peso) del bloque → la legibilidad y la variación de tamaño salen de los mismos datos.
- La fracción de corte debe acotarse (0.4–0.6) aunque el peso lo pida, o se generan bloques tira; el peso se aplica suave.
- Para pantallas con input/canvas (chat, grilla, canvas, tabs), el mosaico es una capa de entrada (wrapper) que reusa la pantalla funcional: no hay que reescribir la funcionalidad para tener el look.
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE - Sistema "Loca" extendido a 13 pantallas + mosaico apilado con espacio y columna de acciones fija
**Resumen**: Continuación de la transformación visual. Se refinó el mosaico (columnas apiladas masonry con espacio entre bloques, sin rotaciones) y se fijaron los botones de acción (+, escribir, enviadas, gps) en una COLUMNA LATERAL fija (mismo lugar y tamaño; los ítems se adaptan). Se convirtieron 9 pantallas más al patrón "loca": Notificaciones, Logros, Recompensas, Configuración, Login, Trivia, Finanzas, Favoritos y Galería.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: reescrito a "columnas apiladas" (masonry) — distribuye en hasta 4 columnas de ancho variable y apila bloques de altura variable dentro de cada una; rotación siempre 0 (sin tiles torcidos); dims mínimos 12%.
- `lib/widgets/loca_screen.dart`: gap (4–12px) entre bloques vía inset; `LocaEntry.isAction` + columna lateral derecha fija (`_actionColumn`) donde viven los botones de acción con tamaño fijo. `LocaEntry.panels` con `(context, close)`.
- Pantallas convertidas: **Notificaciones** (1 tile × notificación leída/no leída + "marcar todas" lateral), **Logros** (tile × logro desbloqueado/bloqueado + swap "X/N" + cajita lateral), **Recompensas** (tile × recompensa cumplida/pendiente + swap de saldo + alta lateral), **Configuración** (tiles cambiar-sesión/sonido), **Login** (Facu rojo/Rocio violeta full-screen), **Trivia** (tile swap al marcador + juego completo en panel), **Finanzas** (tiles balance/ingreso/gasto con swap + gráfico en panel + 1 tile × transacción + alta lateral), **Favoritos** (tile × categoría → panel con lista + swap de guardados + alta lateral), **Galería** (mosaico de fotos con thumbnail + subir lateral + detalle fullscreen).
- Tests: suite **236 verdes** (sin cambios de comportamiento; arranger ya testeado). `flutter analyze` baseline.
**Lecciones**:
- Un UNA pantalla "loca" de datos se traduce "N tiles homogéneos": cada ítem es a la vez el "visto/no visto" (check/círculo/leída/candado) y el botón que abre SOLO ese ítem. Los modales de detalle/edición existentes se reusan tal cual (sólo cambia la entrada).
- Las pantallas interactivas (Chat, Calendario, Pizarra, Ejercicios) NO caben en "icono + swink" sin perder funcionalidad (input/grilla/canvas): quedan con su UI funcional; proponer envolverlas en tiles que abran su contenido a fullscreen.
- El `flutter build windows --release` incremental no refresca `app.so` (stale): cada cambio de Dart exige `flutter clean` + rebuild completo (ver entrada anterior).
**Aprendizaje build**: cerrar `furi_app.exe` antes de linkear (LNK1104).
**Impacto**: `loca_arranger.dart`, `loca_screen.dart`, 9 screens, docs. Exe recompilado y BD local restaurada.
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE - Piloto "loca" iterado: un bloque por ítem (visto/no visto) en lugar de "un botón lista todo"
**Resumen**: Ajuste del piloto según feedback: el usuario no quería un único botón-icono que abriera la lista entera, sino **UN bloque-icono gigante por cada reto/meta/carta** repartido en el mosaico, con icono de estado "visto/no visto" (check = hecho/leída, círculo = pendiente, candado = carta sellada) y al apretar un ítem se abre SÓLO ese ítem en el panel.
**Cambios realizados**:
- `lib/widgets/loca_screen.dart`: `LocaEntry` gana `childBuilder` (contenido custom del bloque, p. ej. icono de estado) además de `icon`/`swapBuilder`.
- `lib/screens/retos_screen.dart`: 1 tile por reto (check_circle hecho / radio_button_unchecked pendiente, colores de paleta ciclando por índice) + tiles loading (hourglass) / error (cloud_off, tap=reintentar) / "+" crear. Panel por reto (solo ese reto): título + autor + acciones toggle/editar/borrar.
- `lib/screens/metas_screen.dart`: igual (check/hecho, trofeo de autor).
- `lib/screens/letters_screen.dart`: 1 tile por carta recibida con estado de leída (`mark_email_read`/`markunread`) y selladas (candado ámbar); tile Enviadas (panel con lista) y tile "+" escribir. Panel por carta (título+cuerpo, o candado "se podrá abrir…" si sellada).
- Loading/error ahora son tiles visibles (icon-only) en el mosaico, no banners de texto.
**Lecciones**:
- `flutter build windows --release` INCREMENTAL devuelve "√ Built" pero NO regenera `data/app.so` con los cambios de Dart (el snapshot queda stale; verificado grepeando strings del binario). Solo `flutter clean` + rebuild garantiza el código nuevo. El `app.so` limpio respondió también por UTF-16 para acentos (los check ASCII como los channel strings bastan para validar).
- El símbolo de estado como tile único (check/círculo/candado) comunica "visto/no visto" sin texto y cada panel de detalle es 1:1 con su tile: mismo índice en `entries` y `panels`.
**Impacto**: 1 widget + 3 screens. Suite **236 verdes**. `flutter analyze` baseline. Exe Windows recompilado con clean (verificado: channel strings + `LocaArranger` + diseño por-ítem presentes en `app.so`).
**Relacionado con**: skill-pantallas regla 10, D-4.

## [2026-08-27] - FEATURE - Sistema "Loca" estilo Nosotros + piloto en 4 pantallas (fase 1 de la transformación visual)
**Resumen**: Se creó el kit compartido para convertir TODAS las pantallas (excepto Home y Mazo) al sistema de la pantalla Nosotros: mosaico de bloques-icono gigantes que ocupa todo el lienzo, cero texto a simple vista, swaps automáticos sobre el contenido y paneles swink para leer/manipular los datos. Como piloto se rediseñaron Retos, Metas, Cartas y Mapa; el patrón queda listo para replicar al resto.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart` (nuevo): `LocaRect` + `LocaArranger.arrange(width, height, cantidad, seed)` — mosaico determinístico que divide el lienzo en N bloques sin solapamiento (slicing recursivo aleatorio con semilla, corta preferentemente la dimensión larga y clampa contra micro-tiras <12%), con rotaciones de la paleta brutalista (0 o ±0.06/±0.12 rad). Ocupación del 100% del lienzo.
- `lib/widgets/loca_screen.dart` (nuevo): `LocaEntry` (icon + color + panel/onTap + swapBuilder), `LocaScreen` (fondo ConcretePainter + header con volver/corazones sin texto + entradas distribuidas por seed + backdrop + paneles swink con animación scale/opacity de 400ms tipo Nosotros), `LocaScreen.panel` (shell brutalista) y `LocaScreen.closeIcon`.
- `lib/screens/retos_screen.dart`: reescrito a LocaScreen — bloque bandera (swap con el próximo reto, abre panel con lista toggle/editar/borrar) + bloque "+" (dialog de crear). Realtime nuevo en `challenges`.
- `lib/screens/metas_screen.dart`: reescrito a LocaScreen — bloque trofeo (swap con la próxima meta, panel con lista) + "+". Realtime nuevo en `goals`.
- `lib/screens/letters_screen.dart`: reescrito a LocaScreen — Recibidas (swap con último correo), Enviadas, Escribir (mantiene la vista de composición completa con programación de apertura). Se eliminaron las pestañas texto.
- `lib/screens/mapa_screen.dart`: reescrito a LocaScreen — bloque mapa (swap con "X km", panel con distancia/pines/estado) + botón GPS (compartir/ingreso manual).
- Tests TDD: `test/widgets/loca_arranger_test.dart` (8): cantidad exacta, partición total sin overlap, dentro del lienzo, determinismo por seed, seeds distintos → distribuciones distintas, rotaciones de paleta, sin micro-tiras, aspect acotado.
- Docs: `skill-pantallas.md` (regla 10 "Sistema Loca"), `glosario.md` (pantalla "loca"), `arquitectura.md` (widgets).
**Lecciones**:
- El slicing recursivo aleatorio con semilla da "loca" garantizando: (a) mayoría de la long axis para no degradar en tiras, (b) clamp de dimensión mínima 12% para bloques usables, (c) rotaciones chicas (±0.12 rad) que se ven orgánicas pero no rompen la hit-target. El arranger es lógica pura testeable — misma técnica que CoupleStats/WorkoutStats.
- Cero texto "a simple vista" NO significa cero texto: el contenido llega en el swap (títulos de retos/metas, preview de cartas, distancia) y en los paneles (listas, textos de cartas). Es una capa de presentación (la entrada es solo iconos) que reusa la lógica CRUD existente.
- `LocaScreen.panels` son builders con firma `(context, close)` para que el contenido interno pueda cerrar el swink (botón X); el estado de apertura vive en el widget compartido, no en cada pantalla.
- El swap auto-programado exige que el builder lea el estado vivo (la pantalla provee `swapBuilder` con los datos actuales), así al recargar por realtime el swap muestra el ítem nuevo.
- `LocaArranger` NO debe solapar bloques: el mosaico + rotaciones ya se ve "loco" y evita pelea de taps en las zonas de intersección.
**Pendiente**: replicar el patrón a las demás pantallas (settings, notifications, trivia, finanzas, galería, favoritos, ejercicios, logros, rewards, chat, calendar, pizarra, login) en tandas, validando con el usuario.
**Impacto**: `loca_arranger.dart` (nuevo), `loca_screen.dart` (nuevo), 4 screens reescritas, 1 test nuevo (8 casos). Suite **236 verdes** (antes 228). `flutter analyze` 23 (baseline, sin errores nuevos).
**Relacionado con**: D-4 (estilo brutalista / skill_visual), convenciones (solo iconos), skill-pantallas regla 10, FURI-Nosotros-Skill (swink/swap), glosario.

## [2026-08-27] - REFACTOR - Estilo "Nosotros" unificado en todas las pantallas (excepto Home y Mazo)
**Resumen**: Refinamiento profundo de TODAS las pantallas navegables (excepto Home, excluida por el usuario, y Mazo, que conserva su diseño deliberado de degradados sin bordes) para alinearlas 100% al sistema de estilo de la pantalla Nosotros: fondo ConcretePainter, tipografía Bangers, bloques brutalistas (borde==relleno, esquinas redondeadas, sombra negra dura), y TapTile en todo lo tappable. Se detectó que la mayoría de pantallas ya usaban este sistema parcialmente; el trabajo cubrió las brechas y pulió la consistencia.
**Cambios realizados**:
- `lib/widgets/brutal_style.dart` (nuevo): `BrutalStyle` con helpers estáticos `bg`, `fillIcon`, `card`, `block`, `clip`, `iconAction` — extrae y generaliza `btnBlock`/`fillIcon`/`bg` que vivían hardcodeados en `nosotros_screen.dart` para que todas las pantallas compartan el mismo sistema.
- **Chat** (`chat_screen.dart`, `chat/widgets/*`): `fontFamily monospace` → Bangers w900, `GestureDetector` → `TapTile`, sombras duras en header/banners/input, botones +/mic/enviar → TapTile.
- **Calendario** (calendar_home, daily_events, schedule_form, class_board, class_setup): fondos semitransparentes → sólidos, negro puro → `#0D0D0D`, `monospace` → Bangers, `GestureDetector` → `TapTile`, borde==relleno en cards (el setup wizard además pasó de fondo verde plano a ConcretePainter + cian #00D4FF de sección).
- **Ejercicios / Galería / Favoritos / Finanzas**: ejercicios ganó el fondo ConcretePainter (era el gap crítico) + sombras duras en paneles; galería/favoritos/finanzas ganaron borde==relleno + sombra dura en bloques; finanzas y favoritos convirtieron texto decorativo de diálogos (X/OK/Gasto→Ingreso) en iconos y acciones a TapTile.
- **Notes / Question / Mapa / Notifications / Settings / Login / Mood**: reemplazado `fontFamily: 'monospace'` restante por GoogleFonts.bangers.
- **Logros / Recompensas / Trivia**: ya usaban `BrutalStyle.bg`; se limpiaron los `monospace` residuales a Bangers.
- **Pizarra v1 + Pizarra v2 (solo UI circundante)**: pizarra v1 ganó fondo ConcretePainter + header/herramientas con bloque estándar; pizarra v2 convirtió botones/hints/banners/diálogos a Bangers + TapTile conservando intacto el grid del canvas, el InteractiveViewer y los renderers.
- `nosotros_screen.dart`: solo limpieza de warnings (sin cambios funcionales).
**Lecciones**:
- Antes de una migración masiva de estilo, hacer un grep de brechas (ConcretePainter / Bangers / TapTile por archivo): la mayoría de pantallas ya compartían el sistema y el trabajo real era cerrar las brechas (fondos faltantes, `monospace` residuales, semitransparentes, negro puro).
- `ConcretePainter` está detrás de `BrutalStyle.bg`; verificar por `BrutalStyle.bg` y no textualmente por `ConcretePainter` (las pantallas nuevas lo usan a través del helper).
- Los errores de compilación introducidos por cambios paralelos fueron 2 y triviales («const» mal puesto en un `SnackBar` con `GoogleFonts.bangers` y en un `Positioned.fill` con `CustomPaint`). Validate siempre con `flutter analyze` después de batches paralelos.
- Conservar diseños deliberados documentados: el mazo (degradados sin borde) y el canvas de la pizarra v2 (grid + pan/zoom) no se tocan; solo la UI circundante.
**Impacto**: `widgets/brutal_style.dart` (nuevo), ~25 archivos de pantallas, `nosotros_screen.dart` (limpieza). Suite **228 tests verdes**, `flutter analyze` sin errores (22 issues, bajo el baseline 23).
**Relacionado con**: D-4 (estilo brutalista / skill_visual), convenciones (solo iconos), skill-pantallas.

## [2026-08-26] - FEATURE - Fase 1: puntos automáticos, mapa/distancias y más logros 🪙📍🏅
**Resumen**: Primera tanda de la "capa de juego/unicidad" (Fase 1). Se automatizó la ganancia de puntos (antes `RewardsProvider.addPoints` era un hook sin llamar), se hizo real la pantalla de Mapa/Distancia (era un placeholder de 2.3 km falso), y se amplió la colección de logros de pareja de 8 a 13. El aviso del bot de logro desbloqueado (1.1) ya estaba implementado (categorías #21/#22 de bot.js).
**Cambios realizados**:
- **1.2 Puntos automáticos** (`rewards_provider.dart`): nuevo `awardOnce(userId, reason, delta)` IDEMPOTENTE — consulta si la razón ya fue aplicada a ese usuario antes de insertar (el ledger `couple_points` no tiene constraint único), evitando duplicados por realtime/reintentos. Hooks al action-site (no en realtime): mood registrado en `nosotros_screen._addMood` (+1, `mood-$fecha`), día de entrenamiento marcado en `ejercicios_screen._markBtn` (+2, `workout-$fecha`), match del mazo en `home_screen` al cerrar el overlay (match +5 a AMBOS, `match-$cardId`). Cada provider se captura ANTES del await (evita `use_build_context_synchronously`).
- **1.3 Mapa/Distancia real** (+`geolocator`): modelo `lib/models/couple_location.dart` (`CoupleLocation` + `distanceKm` haversine pura testeable), `LocationProvider` (carga/upsert realtime en `couple_locations` PK user_id, `coupleDistanceKm`), tabla `couple_locations` (migración + schema master, **pendiente ejecutar en SQL Editor**), `mapa_screen.dart` reescrito — botón "Actualizar ubicación" usa GPS (geolocator) con fallback a entrada manual en desktop/denegado; muestra distancia + estado por usuario.
- **1.4 Más logros** (`couple_achievement.dart` / provider): `AchievementSnapshot` +5 campos (moodCoupleStreak, totalWorkouts, bothSharedLocation, hasFulfilledReward, bothAnsweredTrivia) y 5 logros nuevos: `mood_streak_7`, `workouts_50`, `location_shared`, `reward_fulfilled`, `trivia_day`. Provider computa los nuevos campos (racha de ánimo solo-moods con `CoupleStats.streakFor`, conteo de completions, consultas a `couple_locations`/`couple_rewards`/`question_answers`). El álbum usa `CoupleAchievements.all.length` → "X de 13" se actualizó solo.
- `main.dart`: + `LocationProvider` (20º provider).
- Tests TDD: `couple_location_test.dart` (5: haversine BA→Córdoba ~647 km, mismo punto=0, falta dato=0, round-trip, fecha ausente) + `couple_achievement_test.dart` (+5 para los logros nuevos). Suite total **228 verdes** (antes 218). `flutter analyze` 22 (baseline, sin errores). `node --check bot.js` OK.
**Lecciones**:
- El hook de puntos debe vivir en el ACTION-SITE (escritura), nunca en un callback realtime: el realtime dispara por cada cambio de fila y duplicaría puntos. `awardOnce` con chequéo por `reason` es la red de seguridad contra reintentos/doble-dispositivo.
- `distanceKm` por haversine da distancia en LÍNEA RECTA: Buenos Aires→Córdoba da ~647 km, no los ~695 de ruta. Para asserts usar el valor haversine real, no la distancia vial.
- La pestaña "Mapa" era un placeholder con valor hardcodeado; para el fallback de GPS en desktop/permiso-denegado, un diálogo manual de lat/lng es suficiente y evita romper el build de Windows (geolocator tiene soporte limitado en desktop).
- `coupled_achievements` claves UNIQUE + `AchievementSnapshot` con defaults 0/false hacen que sumar logros nuevos no rompa los tests existentes de `earnedCodes` (el snapshot vacío sigue → isEmpty).
- El bot ya tenía la categoría de logro (1.1): confirmar lo existente antes de "implementar" de nuevo (historiel/rewards ya lo documentaba como #21/#22).
**Pendiente**: ejecutar `supabase/migration_couple_locations.sql` en SQL Editor (para que el mapa funcione contra la nube). Verificar build de Windows tras sumar `geolocator` (plugin nativo → puede exigir `vcvarsall.bat amd64` con TRK0005, según errores-conocidos).
**Impacto**: `rewards_provider.dart`, `nosotros_screen.dart`, `ejercicios_screen.dart`, `home_screen.dart`, `couple_location.dart` (nuevo), `location_provider.dart` (nuevo), `mapa_screen.dart`, `couple_achievement.dart`, `couple_achievements_provider.dart`, `main.dart`, `pubspec.yaml` (+geolocator), `supabase/migration_couple_locations.sql` (nuevo), `supabase_schema.sql`, 2 tests nuevos, docs.
**Relacionado con**: D-2 (Supabase), D-8 (points/recompensas), Fase 1 del roadmap, FURI-Nosotros-Skill (distancia), glosario.

## [2026-08-26] - FEATURE - Router GoRouter (último ítem de la Fase 0 del roadmap)
**Resumen**: Se reemplazó la navegación con `Navigator.push(MaterialPageRoute)` dispersa (~30 call sites en 8 archivos) por un **route table centralizado con GoRouter**. El arranque login/home deja de usar `home:` en MaterialApp y se resuelve con un `redirect` basado en sesión.
**Cambios realizados**:
- `pubspec.yaml`: + `go_router: ^17.5.0`.
- `lib/router.dart` (nuevo): `appRouter` (GoRouter) + `RouterRoutes` (consts de ruta) + `navigatorKey` (movido desde main.dart). 22 rutas: login, home, settings, notifications, nosotros, calendar, trivia, finanzas, galeria, favoritos, pizarra, ejercicios, logros, rewards, chat, retos, cartas, metas, mapa, scheduleForm, dailyEvents, classBoard, classSetup. Las pantallas que reciben `AppMode` lo toman por `state.extra` (helper `_mode(state)` con fallback `AppMode.dark`). `redirect` gatea `/`, `/login` y `/home` según `AppState.myId` (corre dentro de runApp, ya con sesión cargada → no se pudo usar `initialLocation`, que se evaluaría en top-level antes de `loadSession`).
- `lib/main.dart`: `MaterialApp` → **`MaterialApp.router(routerConfig: appRouter)`** (Flutter 3.44 separó el router en el constructor `.router`; el base ya NO acepta `routerConfig`). Eliminado `navigatorKey` local y el parámetro `startDirect` de `FuriApp` (el redirect resuelve login/home). Escape→maybePop sigue usando `navigatorKey` (ahora de router.dart).
- Rewire de todos los push: `home_screen.dart` (11), `calendar_home_screen.dart` (5, +`context.push<bool>(classSetup)` con resultado), `daily_events_screen.dart` (3, con inicial+schedule por extra), `nosotros_screen.dart` (5), `logros_screen.dart` (1), `login_screen.dart` (`context.go('/home')` en vez de `pushReplacement`), `settings_screen.dart` (`context.go('/login')` en vez de `pushAndRemoveUntil`). Los flujos que devuelven resultado (`_checkClassSetup` bool; editar form con `Schedule` por `extra`) usan `context.push`, que propaga el `pop`. Poda de imports de pantallas que quedaron sin uso directo (los referencias ahora el router).
- Tests: suite **218 verdes** (widget_test + providers_test siguen pasando: `FuriApp()` → redirect a `/login` sin sesión). `flutter analyze` 22 (por debajo del baseline 23, gracias a la poda de imports sin uso).
**Lecciones**:
- En Flutter 3.44 (y +3.10) `routerConfig` NO es un parámetro del constructor base de `MaterialApp`: es de **`MaterialApp.router`**. El error `The named parameter 'routerConfig' isn't defined` era REAL, pero parecía un glitch del analyzer porque aparecía/desaparecía intermitentemente (cache del daemon durante el warmup); la confirmación definitiva la dio el compilador en `flutter test`, no el analyzer solo.
- `initialLocation` en GoRouter se evalúa al construir el `final` top-level del módulo de router (antes de `main()` y antes de `AppState.loadSession()`), así que a esa altura `AppState.myId` aún es null → arrancaría siempre en `/login` para usuarios ya logueados. La solución es un `redirect` (corre dentro de `runApp`, con la sesión ya cargada por `main()`).
- Los screens que reciben objetos (AppMode, Schedule, DateTime) no se pueden ruteear por string: se pasan por `state.extra` y el builder hace el cast/despacho (`is Schedule → ScheduleFormScreen(schedule:)`, `is DateTime → ...(initialDate:)`). Los flujos con retorno tipado (`push<bool>`) se cubren con `context.push<T>`, que propaga el resultado del `pop`.
- La app antes importaba pantallas solo para navegar a ellas; con el router centralizado esas pantallas las importa `router.dart`, así que se pudaron los imports directos que quedaron sin uso (por eso analyze bajó de 23 a 22).
- `navigatorKey` debe vivir donde se construye el router (router.dart) y pasarse a `GoRouter`, para que el callback Escape→maybePop apunte al mismo Navigator que GoRouter crea.
**Pendiente**: ninguno. (Al no haber deep-links reales ni auth, el router no requiere config extra; si se agregan rutas, sumarlas a `RouterRoutes` + tabla de `appRouter`.)
**Impacto**: `pubspec.yaml`, `router.dart` (nuevo), `main.dart`, 8 screens, docs.
**Relacionado con**: D-14 (router), Fase 0 del roadmap, errores-conocidos (sin sistema de rutas RESUELTO).

## [2026-08-26] - FEATURE - Merge atómico de reacciones en Postgres (RPC server-side, Fase 0)
**Resumen**: Último ítem grande de la Fase 0 (junto al router). Se eliminó la race condition de "último write gana" en las reacciones: antes cada provider enviaba el mapa `reactions` completo en cada update, y dos reacciones simultáneas (Facu + Rocio) al mismo ítem pisaban la del otro (BUG 2 CRÍTICO de la auditoría del pizarrón). Ahora el merge ocurre DENTRO de Postgres con row-level lock (`SELECT ... FOR UPDATE`), y los providers hacen optimistic local + reconciliación con la respuesta autoritativa de la RPC.
**Cambios realizados**:
- `supabase/migration_reaction_rpc.sql` (nuevo): 2 RPC idempotentes + GRANT a anon/authenticated:
  - `toggle_reaction(target_table, target_col, row_id, reaction_key, user_id)`: forma `{key:[uid]}`, max 5 keys, toggle on/off (1 reacción por usuario, se quita de todas las keys y se agrega/quita de la key objetivo). Espejo exacto de `Message.toggleReaction`/`BoardSocialData.withToggledReaction`. Whitelist estricta de `(tabla, columna)` para evitar SQL injection en identificadores dinámicos; cubre `messages.reactions`, `gallery.reactions`, `workout_*.social` y `board_elements_v2.data`. Bump de `updated_at` solo donde la columna existe. **PENDIENTE ejecutar en SQL Editor**.
  - `react_deck_card(row_id, user_id, reaction)`: forma `{uid:emoji}` (mazo), `jsonb_set` atómico + bump `updated_at`.
- `supabase_schema.sql`: RPCs (#29a/29b) agregadas al schema master (mismo origen que `notify_new_message`).
- `lib/providers/chat_provider.dart`, `gallery_provider.dart`, `workout_provider.dart`, `deck_provider.dart`, `board_provider_v2.dart`: rewire de las escrituras de reacciones para llamar a la RPC en vez de `.update({...reactions})` con mapa completo. Mantienen optimistic en memoria + rollback a `_error` en fallo y reconcilian contra el mapa autoritativo devuelto por la RPC.
  - workout: nuevo helper `_reactViaRpc()` (usa `_reactViaRpc`); solo los métodos de reacción (`toggleLogReaction/Routine/Challenge`) cambian — los de comentarios siguen por el update de documento.
  - board: nuevo método `BoardProviderV2.react()` para **no** disparar el push de documento completo (que reintroduciría el race); `board_element_options.dart` llama `pv.react(...)` en vez de `pv.update(...)`.
  - deck: `react()` usa `react_deck_card`; el `reactLocal` optimista (que setea `_pendingMatch`/match) se conserva.
- Tests: `test/services/reaction_merge_contract_test.dart` (nuevo, 6 tests) que documenta en lógica pura el contrato que la RPC DEBE replicar (dos usuarios misma key se preservan, toggle off, mover entre keys, max 5 keys, reemplazo deck, match). Suite total 218 verdes (antes 212). `flutter analyze` 23 (baseline, sin errores; el único en archivos tocados es `gallery_provider.dart:110` preexistente).
**Lecciones**:
- El merge client-side en realtime (que ya existía como parche) NO garantiza consistencia en el servidor: el UPDATE final con el mapa completo siempre puede pisar al concurrente. La RPC con `FOR UPDATE` serializa fila a fila y es la defensa real en el origen.
- Las reacciones viven en **3 formatos distintos** (messages/gallery/board/workout = `{key:[uid]}`; deck = `{uid:emoji}`), así que no hay un RPC genérico de una talla: uno cubre la forma A con whitelist de tablas/columnas y otro la B.
- En el límite de 5 keys, `toggleReaction` de Dart devuelve el mapa ORIGINAL intacto (no el mutado): el SQL debe chequear el límite ANTES de mutar, o devolvería un estado al que ya le quitó la reacción al usuario aunque no persistió.
- Al rewirear un método que el codebase reusa para DOS cosas (workout `social` = reacciones + comentarios), NO hay que reemplazar el método completo: solo la rama de reacciones. Los comentarios siguen por el update de documento.
- En board no alcanza con cambiar el link al RPC: había que un método dedicado (`react`) para que el `pv.update` (que pushea el `data` entero con debounce) no sobrescriba el merge atómico con el mapa local.
- `flutter analyze` degradó netbook warnings (dead_code/dead_null_aware) por usar `myId ?? ''` donde `myId` ya es no-nullable en chat/workout; `AppState.myId` (nullable) sí lo necesita.
**Pendiente**: ejecutar `supabase/migration_reaction_rpc.sql` en SQL Editor de Supabase (sin esto, los providers rompen al intentar `rpc('toggle_reaction'...`). La equivalencia del merge quedó testeada en lógica pura, pero la RPC en sí no tiene harness en la suite.
**Impacto**: 2 RPC + schema master, 4 providers + board react, 1 widget board, 1 test nuevo, docs.
**Relacionado con**: D-2 (Supabase), BUG 2 CRÍTICO (auditoría pizarrón v2), Fase 0 del roadmap, glosario (reacción).

## [2026-08-26] - REFACTOR - Chat: separación por widgets (reduce chat_screen de 1359 a ~700 líneas)
**Resumen**: Fase 0 del roadmap. `chat_screen.dart` era el cuelo de botella citado en arquitectura.md. Se extrajeron todos los widgets presentacionales (que no dependen del estado del controller) a archivos dedicados, dejando en `chat_screen.dart` solo el controller de lógica (enviar/adjuntar/grabar/reacciones) + layout (header, msg area, input, banner de reply, banner de error).
**Cambios realizados**:
- `lib/screens/chat/chat_style.dart` (nuevo): paleta compartida `ChatStyle` (antes constantes privadas de chat_screen: primary, bg, panel, inputBg, darkText, errorBg, mediaBg).
- `lib/screens/chat/widgets/chat_react_chip.dart` (nuevo): `ChatReactChip` (chip de emoji/`+`).
- `lib/screens/chat/widgets/chat_swipe_to_reply.dart` (nuevo): `ChatSwipeToReply` (swipe acumulado).
- `lib/screens/chat/widgets/chat_reactions_row.dart` (nuevo): `ChatReactionsRow`.
- `lib/screens/chat/widgets/chat_media_body.dart` (nuevo): `ChatMediaBody` + `_ChatLocalMediaView` + `_ChatVideoThumb` + `_ChatAudioPlayerTile` (media: descargable/local, video, audio, archivo).
- `lib/screens/chat/widgets/chat_message_tile.dart` (nuevo): `ChatMessageTile` (burbuja con reply/ticks/reacciones).
- `lib/screens/chat_screen.dart`: reescrito para usar los widgets extraídos; eliminadas las definiciones movidas. Misma ruta (`lib/screens/chat_screen.dart`) → ninguna referencia del resto de la app cambió.
**Lecciones**:
- Un refactor de extracción es seguro si MUEVE clases enteras (sin renombrarlas salvo el prefijo `_` → público) y deja la ruta pública del archivo original intacta: cero cambios en los callers.
- La paleta compartida evita duplicar constantes privadas por archivo; al mover widgets, las constantes de estilo deben viajar a un archivo estilo (`ChatStyle`) o cada widget re-declara las suyas.
- Verificar con `flutter analyze` + suite completa después del refactor: 212 tests verdes, sin cambios de comportamiento.
**Impacto**: `chat/chat_style.dart` (nuevo), `chat/widgets/*` (5 nuevos), `chat_screen.dart`. Suite 212 verdes, analyze baseline.
**Relacionado con**: Fase 0 del roadmap, convenciones (widgets separados, UIN).

## [2026-08-26] - FEATURE - Puntos y Recompensas de pareja 🪙 (cajita de deseos)
**Resumen**: Última pieza de la capa de juego. El álbum de Logros ahora da acceso a una "cajita de deseos": recompensas físicas que cuestan puntos y se marcan como cumplidas, con un libro de puntos (libro mayor, deltas positivos/negativos) y balances por usuario. Los avisos del bot ganan 2 categorías nuevas: logro desbloqueado (a ambos) y resultado de la trivia del día.
**Cambios realizados**:
- `lib/models/rewards.dart` (nuevo): `CoupleReward` (id, title, emoji, cost, fulfilled, createdBy) con fromMap/toMap/copyWith, `PointsEntry` (userId, reason, delta, createdAt), y `PointsStats` lógica pura: `balanceOf`, `total`, `pointsEarned`.
- `lib/providers/rewards_provider.dart` (nuevo): CRUD de recompensas (`addReward`, `deleteReward`, `toggleFulfilled`) + `addPoints` (hook para automatizar ganancia de puntos en el futuro), balances (`myBalance`, `totalEarned`), pendientes/cumplidas. Realtime en ambas tablas. Registrado en `main.dart` (19º provider).
- `supabase/migration_rewards.sql` (nuevo): tablas `couple_rewards` y `couple_points` + índices + RLS full access + publicación realtime + GRANTs. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: tablas #24c + índices + RLS + policies.
- `lib/screens/recompensas/rewards_screen.dart` (nuevo): balance (saldo/total/cumplidas), lista de recompensas (cumplidas se marcan en verde), dialog de alta, estados loading/empty/error/data, brutalista. Acceso desde el header de `LogrosScreen` (botón regalo 🎁).
- `lib/screens/logros/logros_screen.dart`: botón de acceso a Recompensas.
- `bot-furi/bot.js`: categoría #21 logro desbloqueado (`couple_achievements.awarded_at` en la última hora → a AMBOS, con emoji/título vía `descripcionLogro`) y categoría #22 trivia (`question_answers` del día con los 2 miembros → aviso "¿quién conoce más?"). Tracking `logro-{code}`/`trivia-{date}`.
- Tests TDD: `test/models/rewards_test.dart` (7). Suite total 212 verdes (antes 205). `flutter analyze` sin issues nuevos (23 preexistentes). `node --check bot.js` OK.
**Lecciones**:
- El balance de puntos es lógica pura (`PointsStats`) y la ganancia es un libro mayor (`PointsEntry` con deltas), así el "gasto" de recompensas es solo un delta negativo; no hay que tocar el schema para gastar.
- La automatización de ganancia de puntos (sumar al hacer mood/entrenar/match) es un hook `addPoints` que el provider ya expone; por ahora la cajita funciona con recompensas y balances calculados en vivo.
**Pendiente**: automatizar la ganancia de puntos desde acciones reales (llamar `addPoints` desde providers de mood/workout/match).
**Impacto**: `rewards.dart` (nuevo), `rewards_provider.dart` (nuevo), `migration_rewards.sql` (nuevo), `supabase_schema.sql`, `rewards_screen.dart` (nuevo), `logros_screen.dart`, `main.dart`, `bot-furi/bot.js`, `rewards_test.dart` (nuevo), `bot-whatsapp.md`, `glosario.md`, docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot), logros (entrada previa), glosario.

## [2026-08-26] - FEATURE - Trivia de pareja 🎯 (pregunta del día: respondés + predecís)
**Resumen**: Juego diario de "cuánto conocés a tu pareja". Cada día hay una pregunta con opciones; cada uno elige su respuesta y predice la de la otra. Cuando ambos responden, se revela el marcador acumulado de predicciones acertadas ("quién conoce más a quién"). Reusa las tablas `daily_questions`/`question_answers` que estaban vacías. Entrada desde el botón del Home (`Icons.school`, antes sin función).
**Cambios realizados**:
- `lib/models/trivia.dart` (nuevo): `TriviaQuestion` (id, question, options) con fromMap/toMap, `TriviaAnswer` (id, questionId, userId, answer, guess, date), `TriviaQuestionBank` (10 preguntas de pareja con 4 opciones), y `TriviaStats` lógica pura: `scoreFor` (un punto por cada predicción que acierta la respuesta real de la pareja), `bothAnsweredFor`, `questionForDay` (selección por índice según día del año).
- `lib/providers/trivia_provider.dart` (nuevo): siembra el banco en `daily_questions` si está vacío, carga preguntas + todas las respuestas (puntaje acumulado), expone `todayQuestion`/`todayAnswers`/`myAnswerToday`/`bothAnsweredToday`/`myScore`/`partnerScore`/`scoreboard`, `submit()` con delete-then-insert (permite re-responder el día). Realtime en `question_answers`. Registrado en `main.dart` (18º provider).
- `supabase/migration_trivia.sql` (nuevo): `daily_questions.options JSONB`, `question_answers.guess TEXT`, índices y publicación realtime de `question_answers`. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: columnas `options` y `guess` en el CREATE master.
- `lib/screens/trivia/trivia_screen.dart` (nuevo): pregunta del día, chips de opciones para "Tu respuesta" y "Predecí a tu pareja", botón confirmar (se habilita con ambas), estado despues de responder (permite actualizar), marcador cuando ambos contestaron, header con scoreboard, estados loading/error/empty/data, brutalista.
- `lib/main.dart`: registrado `TriviaProvider`. `lib/screens/home_screen.dart`: `_openEstudio` ahora abre `TriviaScreen(mode: _mode)` (el botón Icons.school antes no hacía nada).
- Tests TDD: `test/models/trivia_test.dart` (12). Suite total 205 verdes (antes 193). `flutter analyze` sin issues nuevos (23 preexistentes).
**Lecciones**:
- El `date` de `question_answers` (DATE, default CURRENT_DATE) viene como ISO sin zona y en `fromMap` hay que guardarlo como String para comparar contra el día local (`_today()`) sin desfases.
- Filtrar "respuestas de hoy" por columna `date` (String dd-aa) es más simple que parsear `created_at`; el modelo debe persistir ese campo.
- `TapTile` compartido exige `onTap` no-null: para un botón deshabilitable hay que pasar `() {}` y deshabilitar solo visual/metodo, no `null`.
- Reusar tablas vacías (`daily_questions`/`question_answers`) además de respetar el esquema evita migraciones nuevas de tablas.
**Pendiente**: aviso del bot WhatsApp del resultado diario de trivia (o lectura del marcador).
**Impacto**: `trivia.dart` (nuevo), `trivia_provider.dart` (nuevo), `migration_trivia.sql` (nuevo), `supabase_schema.sql`, `trivia_screen.dart` (nuevo), `main.dart`, `home_screen.dart`, `trivia_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot PENDIENTE), glosario.

## [2026-08-26] - FEATURE - FURI del mes 🃏 (memoria del mazo)
**Resumen**: Los matches del mazo ("FURI!!") ahora dejan memoria: el mazo muestra el "FURI del mes" (el match más reciente con categoría+preview+mes), el conteo de FURIs del mes y la fecha del primer FURI de la pareja. El historial del mazo ganó un banner conmemorativo.
**Cambios realizados**:
- `lib/models/deck_memory.dart` (nuevo): `DeckMemory.latestMatch` (match más reciente por updatedAt), `firstMatch` (el primero), `matchesInMonth` (conteo por mes), `summary` (descripción legible). Lógica pura testeable.
- `lib/screens/mazo/deck_history_sheet.dart`: nuevo banner "FURI del mes" arriba del historial (fondo degradado de la categoría, emoji, resumen, "N este mes", "Primer FURI: fecha"); se oculta si no hay matches.
- Tests TDD: `test/models/deck_memory_test.dart` (6). Suite total 187 verdes. `flutter analyze` sin issues nuevos.
**Lecciones**:
- Reusar `DeckCard.isMatch` y `updatedAt` como timestamp del match (cuando se actualizó la reacción) da la memoria sin tocar el schema.
- `DeckCard.updatedAt` no es const y `matchesInMonth` compara con `DateTime.now()` — hay que pasar el mes explícito para mantener el test determinístico.
**Impacto**: `deck_memory.dart` (nuevo), `deck_history_sheet.dart`, `deck_memory_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), mazo (entrada previa), glosario.

## [2026-08-26] - FEATURE - Cartas con apertura programada 💌 + entrega ceremonial por bot
**Resumen**: Las cartas de la pareja ahora pueden programar su apertura. Si se elige una fecha de apertura, la carta queda "sellada" (🔒) para el destinatario hasta ese día: se ve el título pero el contenido no se revela, ni en la lista ni en Nosotros. El bot de WhatsApp no spoilea las cartas selladas al crearse y, cuando llega el momento, las "entrega" con un mensaje ceremonial a quien debía recibirlas.
**Cambios realizados**:
- `lib/models/letter.dart`: nuevo `Letter.isSealed({scheduledOpen, isIncoming, now})` — lógica pura: una carta está sellada cuando tiene `scheduled_open` futuro y es carta recibida (el autor siempre lee la suya).
- `lib/screens/letters_screen.dart`: estado `_scheduledOpen` en el compositor + barra "Programar apertura" (picker de fecha, se guarda `scheduled_open` en el INSERT, se resetea al enviar/cancelar). `_isSealed`/`_showSealed`: cards selladas muestran candado + "se abre el dd/mm/yyyy" y abren un diálogo de sobre sellado (no el contenido). Cuerpo de la carta y barra de programación ajustados para no superponerse.
- `lib/screens/nosotros_screen.dart`: `_loadPartnerLetter` ahora ignora cartas selladas (`scheduled_open` futuro) y no las marca como vistas.
- `bot-furi/bot.js`: categoría #4 LETTERS ignora cartas futuras (no spoilear). Nueva categoría 4b "entrega ceremonial": consulta cartas cuyo `scheduled_open` cayó en la última hora (`.gte(haceUnaHora).lte(ahora)`) y avisa al destinatario con `💌 ... tu carta "... " acaba de abrirse`. Tracking `letteropen-{id}-{fecha}`.
- Tests TDD: `test/models/letter_test.dart` (5). Suite total 187 verdes (antes 182). `flutter analyze` sin issues nuevos (23 preexistentes). `node --check bot.js` OK.
**Lecciones**:
- El modelo `Letter` ya tenía `scheduled_open` pero nada lo usaba: faltaba el "puente" entre el campo, el compositor (no lo guardaba) y el gating (nadie lo validaba). El campo por sí solo no es la feature.
- El gating por "sellado" debe ser por ROL, no solo por fecha: si no, el autor no podría releer la carta que escribió. `isIncoming` (¿to_user = yo?) + fecha futura = sellada; una carta propia siempre se puede leer.
- Las fechas de apertura se guardan en UTC (`toUtc().toIso8601String()`) y el bot compara contra `ahora.toISOString()` (también UTC) — coherencia de zona evitada.
- El bot ya tenía tracking anti-duplicado por `(tabla, registro_id)`: reusé el mismo patrón para la entrega ceremonial con key distinta (`letteropen-`) para no colisionar con la de "nueva" (`letter-`).
**Impacto**: `letter.dart`, `letters_screen.dart`, `nosotros_screen.dart`, `bot-furi/bot.js`, `letter_test.dart` (nuevo), `bot-whatsapp.md`, `glosario.md`, docs.
**Relacionado con**: D-2 (Supabase), D-10 (bot), D-4 (skill_visual), errores-conocidos (sin nuevos), glosario (carta sellada).

## [2026-08-26] - FEATURE - Logros de pareja 🏅 (colección de insignias desbloqueables)
**Resumen**: Segunda pieza de la capa de juego/unicidad. La pareja desbloquea logros (insignias) al cumplir hitos: registraron mood ambos, entrenaron ambos, primer FURI!! del mazo, rachas de pareja (3/7 días y mejor racha 14+), y cantidad de mensajes (100/1000). Se muestran en una pantalla "álbum" a la que se accede tocando el chip 🔥 de racha del Home. Las reglas son datos y la evaluación es lógica pura testeable (mismo patrón que `CoupleStats`).
**Cambios realizados**:
- `lib/models/couple_achievement.dart` (nuevo): `CoupleAchievement` (code, emoji, title, description), `AchievementSnapshot` (coupleStreak, bestCoupleStreak, bothLoggedMood, bothWorkedOut, hasDeckMatch, totalMessages) con `copyWith`, `EarnedAchievement` (fromMap/toMap), y `CoupleAchievements` con 8 definiciones + `byCode` + `earnedCodes(snapshot)` (lógica pura).
- `lib/providers/couple_achievements_provider.dart` (nuevo): `load()` carga los ya otorgados, construye el snapshot (queries a `moods`, `workout_completions`, `messages.count()`, `deck_cards` reacciones), calcula los códigos obtenidos, e inserta los nuevos (guard por UNIQUE + diferencia de sets). Expone `earnedCodes`, `collected`, `remaining`. Realtime en `couple_achievements` (el otro dispositivo ve los logros al instante). Sin cache local. Registrado en `main.dart` (17º provider).
- `supabase/migration_couple_achievements.sql` (nuevo): tabla `couple_achievements` (id, achievement_code UNIQUE, awarded_at, created_at) + índice + RLS full access + publicación realtime + GRANTs. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: tabla `couple_achievements` (#24b) + índice + RLS + policy.
- `lib/screens/logros/logros_screen.dart` (nuevo): álbum en grilla 2 columnas con contador "X de 8 desbloqueados"; logros desbloqueados a color del tema, pendientes desvanecidos con candado 🔒; estados loading/error/data; skill_visual (fondo=borde, redondo, sombra brutalista, sin negro puro); reutiliza `TapTile` compartido (animación + sonido).
- `lib/screens/home_screen.dart`: el chip 🔥 de racha ahora es tappable (`coupleTile` con `onTap`) y abre `LogrosScreen(mode: _mode)`. Nuevo método `_openLogros()`.
- Tests TDD: `test/models/couple_achievement_test.dart` (16). Suite total 182 verdes (antes 166). `flutter analyze` sin issues nuevos (los 23 preexistentes).
**Lecciones**:
- Persistir los logros otorgados en una tabla (`couple_achievements`) es mejor que evaluarlos en vivo cada vez: da historial, sync entre dispositivos y base para el bot. La evaluación (`earnedCodes(snapshot)`) sigue siendo lógica pura testeable; el provider solo arma el snapshot.
- El `messages.count()` de postgrest devuelve `int` directo (`PostgrestFilterBuilder<int>`), no hace falta traer las filas — clave para contar mensajes sin peso.
- Guard de duplicados natural: la columna es UNIQUE y el provider inserta solo los códigos que faltan (`earnedNow.difference(earnedCodes)`), así repetir `load()` es idempotente.
- El match del mazo ya lo resuelve `DeckCard.isMatch` (≥2 reacciones todas 'encanta'); reutilicé la regla en el provider en vez de reimplementarla.
**Pendiente**: aviso del bot WhatsApp de logro desbloqueado (categoría nueva leyendo `couple_achievements.awarded_at` de la última hora → a ambos). Ver Fase 2.x del roadmap.
**Impacto**: `couple_achievement.dart` (nuevo), `couple_achievements_provider.dart` (nuevo), `migration_couple_achievements.sql` (nuevo), `supabase_schema.sql`, `logros_screen.dart` (nuevo), `main.dart`, `home_screen.dart`, `couple_achievement_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot PENDIENTE), racha de pareja (entrada previa 2026-08-26), glosario.

## [2026-08-26] - FEATURE - Racha de pareja 🔥 (días consecutivos en que ambos están activos)
**Resumen**: Se agregó la "racha de pareja" como nueva capa de juego del Home: días consecutivos en que AMBOS miembros de la pareja estuvieron activos (registraron mood o completaron un entrenamiento). Es el primer entregable del roadmap de "capa de juego/unicidad" y usa el patrón ya probado de `WorkoutStats` (lógica pura testeable) + `WorkoutProvider` (Supabase + realtime sin cache local).
**Cambios realizados**:
- `lib/models/couple_stats.dart` (nuevo): `CoupleActivity` (userId + día, `fromMap` tolerante a `date`/`completed_on`/`created_at`) y `CoupleStats` con lógica pura: `activeByDay` (agrupa por día → set de usuarios activos), `bothActiveDays` (días donde TODOS los miembros están activos), `streakFor` (racha actual terminando hoy o ayer, mismo criterio que `WorkoutStats.streakFor`), `bestStreak` (racha más larga), `isBothActiveOn`.
- `lib/providers/couple_provider.dart` (nuevo): `CoupleProvider` carga `moods` + `workout_completions` (solo `user_id` + fecha), unifica en actividades, calcula `bothDays` = días con ambos (`members: {myId, partnerId}`), y expone `coupleStreak`, `bestCoupleStreak`, `todayActive`. Realtime en ambas tablas (recarga por evento). Registrado como provider global.
- `lib/main.dart`: import + `ChangeNotifierProvider(create: (_) => CoupleProvider())`.
- `lib/screens/home_screen.dart`: `_BrutalGridState.initState` carga `CoupleProvider` post-frame; nuevo widget `coupleTile` (chip 🔥 + número con `GoogleFonts.bangers`, fondo=borde color del tema, sombra brutalista) posicionado en la esquina superior derecha con `Consumer<CoupleProvider>`, sin alterar la grilla.
- Tests TDD: `test/models/couple_stats_test.dart` (14 tests). Suite total 166 verdes (antes 152). `flutter analyze` sin issues nuevos (los 23 son preexistentes).
**Lecciones**:
- Espejar `WorkoutStats` es el camino correcto: agregar lógica de "racha" requiere la misma estructura de días consecutivos terminando en hoy/ayer (el día en curso no cuenta hasta completarse).
- La "racha de pareja" NO puede calcularse con una tabla propia (habría que escribir cada día); se deriva de señales existentes con `user_id` + fecha. Moods es la señal diaria más confiable (ambos la registran en Nosotros); workout_completions la refuerza.
- El Home es una grilla brutalista muy ajustada: un widget nuevo NO debe romper el layout; un chip flotante posicionado con `Consumer` en el Stack evita tocar las coordenadas de los bloques.
- Ojo al escribir providers por primera vez: `Identical`/`a == a` en un `removeWhere` es un bug silencioso (siempre true → borra todo); revisar el código resultante antes de correr.
**Pendiente**: aviso del bot WhatsApp de "racha de pareja rota" (requiere calcular ambos-miembros-activos en JS → requerimiento no trivial, dejar para próxima iteración).
**Impacto**: `couple_stats.dart` (nuevo), `couple_provider.dart` (nuevo), `main.dart`, `home_screen.dart`, `couple_stats_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), patrón WorkoutStats/WorkoutProvider, glosario (nuevo concepto racha de pareja).

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
- `lib/screens/mazo/deck_style.dart` (nuevo): estilo por categoría (emoji, label, **degradado 3 colores**) y por reacción (label, **degradado 3 colores**, icono, dirección).
- `lib/screens/mazo/deck_overlay.dart` (nuevo): overlay encima del Home con stack de 3 tarjetas (escala descendente), drag en 4 direcciones con sello de reacción, rotación progresiva, snap-back y salida animada (160ms) → `pv.react()`. **Solo botón X cerrar en header** (sin botones de acción abajo). **Tarjetas sin borde** (degradado puro, borderRadius 32), **mÃ¡s delgadas y altas** (75% ancho × 92% alto), fuente **Bangers** blanco tamaño 28. Etiquetas de reacción al deslizar **sin borde** (solo degradado + Bangers blanco). CategorÃ­a **POEMAS**: degradado rojo-rosa-rojo.
- `lib/screens/mazo/create_deck_card_modal.dart` (nuevo): dialog con chips de las 8 categorías (fondo=borde, check en la seleccionada), TextField multilinea (max 1000), botÃ³n guardar con icono check que se habilita al escribir (listener del controller).
- `lib/screens/mazo/deck_history_sheet.dart` (nuevo): bottom sheet con las tarjetas ya deslizadas: mi reacción + reacciones de la pareja + botÃ³n re-deslizar (vuelve al overlay en modo re-swipe de esa tarjeta).
- `lib/screens/mazo/deck_match_overlay.dart` (nuevo): pantalla "FURI!!" gigante en color de la categoría + tarjeta + confetti (flutter_confetti) + botÃ³n seguir. No dice "match" (pedido del usuario).
- `lib/screens/home_screen.dart`: `_initDeck()` en initState (post frame: load + abrir overlay si hay pendientes); `_openMazo()` en el bloque con iconos ▶/🖼️/▶ del Home (antes decorativo); Stack del Home ahora monta `DeckOverlay` (si `_showDeck`) y `DeckMatchOverlay` vía `Consumer<DeckProvider>` cuando hay `pendingMatch` (encima de todo, incluso sin deck abierto).
- `bot-furi/bot.js`: categoría #14 `deck_cards` (tarjeta nueva en última hora → avisa a la pareja del creador, con categoría y preview de 90 chars) y categoría #15 `deck match` (reactions con >=2 valores todos 'encanta' y updated_at en última hora → avisa a AMBOS con "🃏 *FURI!!*"). Tracking keys `deck-{id}` y `deckmatch-{id}`.
- Tests TDD: `test/models/deck_card_test.dart` (12 tests) + `test/providers/deck_provider_test.dart` (13 tests). Total 25 nuevos, todos verdes.
**Lecciones**:
- El JSONB de reacciones se envía entero en cada update: dos reacciones simultáneas (Facu y Rocio) se pisan. El fix usado (como en el pizarrón): merge en el callback realtime con las reacciones locales ganando para el mismo user (`mergedFromCloud`), porque mi UPDATE en vuelo aún no está en el server y un `load()` completo lo borraría de la vista.
- La detección de match debe ser por TRANSICIÓN (local no-match → merged match), no por estado: si no, cada reload/realtime de una carta ya matcheada volvería a disparar la pantalla "FURI!!".
- `pendingFor(null)` devuelve todas las cartas (sin identidad cargada no se puede filtrar) — útil para tests.
- Un `showDialog`/bottom sheet que se habilita según el texto necesita `_ctrl.addListener(() => setState(() {}))`; evaluar `_ctrl.text` una sola vez en el build deja el botón congelado.
- **Degradados de 3 colores por categoría**: IDEAS (rojo-amarillo-naranja), CHISTES (morado-amarillo-fucsia), POEMAS (rojo-rosa-rojo), RECETAS (verde-amarillo-verde), RETOS (rojo-naranja-fucsia), RANDOM (morado-amarillo-cian), SUEÑO (azul-celeste-violeta), ME PASÓ (rojo-amarillo-fucsia). Reacciones también con degradados de 3 colores.
- **Sin bordes en tarjetas ni sellos**: el degradado es el fondo y el borde se camufla eliminando `Border.all`.
- **Bangers + blanco**: fuente consistente con el resto de la app, tamaño grande para legibilidad.
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
