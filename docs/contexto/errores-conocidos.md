# Errores Conocidos de F.U.R.I

> **PROPÓSITO**: Este archivo es un registro de **lecciones aprendidas** — bugs que ya se
> resolvieron (o se están resolviendo) y las causas raíz que los provocaron, para **NO
> reintroducirlos** en el futuro. NO es una lista de tareas pendientes, ni un backlog de
> features. Antes de cada cambio de código, revisar aquí para evitar repetir los mismos
> errores. Los errores **activos/pendientes** que requieren acción se documentan en
> `docs/contexto/arquitectura.md` (sección "Lo que NO existe") y en `historial.md`.

### ~~CRÍTICA - Congelamiento y crash de la app al hacer scroll en Pinterest embebido (SurfaceTexture deadlock, OOM heap y reproducción automática de videos)~~ ✅ RESUELTO 2026-10-20
- **Dónde**: `lib/screens/galeria/pinterest_screen.dart`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`
- **Qué pasaba**: Al ingresar a Pinterest dentro de la aplicación, el usuario podía scrollear un momento, pero a los pocos segundos la aplicación se pausaba/congelaba completamente y se cerraba de golpe (crash / salida forzada al launcher de Android).
- **Causa raíz**:
  1. **Modo de renderizado por Texture Layer (TLHC)**: `WebViewWidget` usaba el modo predeterminado de renderizado sobre `SurfaceTexture`. Al scrollear un feed masivo e infinito con cientos de imágenes WebP/JPEG de alta resolución como Pinterest, la cola de buffers de Android (`GraphicBufferProducer`) se saturaba y desincronizaba con el Raster Thread de Flutter, produciendo un deadlock en `dequeueBuffer`/`eglSwapBuffers` que congelaba la interfaz y forzaba el cierre del proceso por el sistema.
  2. **Límite de memoria heap de la aplicación**: `AndroidManifest.xml` no tenía habilitado `android:largeHeap="true"`. Al navegar una aplicación web tan pesada, el uso de memoria sobrepasaba el heap estándar (128-192MB), disparando el Out-Of-Memory (OOM) killer del sistema operativo Android.
  3. **Agotamiento de decodificadores de hardware por video pins**: Los pins de video de Pinterest comenzaban a reproducirse automáticamente al entrar en el viewport. Al scrollear rápidamente, se instanciaban múltiples decodificadores de hardware (`MediaCodec`) simultáneos, excediendo el límite del chipset y colapsando el proceso GPU de Chromium.
  4. **Redirecciones a esquemas externos y tiendas**: Durante el scroll, Pinterest disparaba redirecciones a esquemas no capturados o a tiendas de apps (`play.google.com`).
  5. **Trampas modales y banners dinámicos**: Pinterest inyectaba modales y bloqueaba el scroll de `body` con `overflow: hidden`.
- **Fix**:
  1. **Hybrid Composition**: Se implementó `displayWithHybridComposition: true` mediante `AndroidWebViewWidgetCreationParams` de `webview_flutter_android`. El WebView nativo se integra directamente en la jerarquía de vistas de Android sin la penalización ni los deadlocks de buffer de `SurfaceTexture`.
  2. **Gesto directo instantáneo**: Se configuró `gestureRecognizers` con `Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new)` para que los toques y scrolls se despachen de forma inmediata y directa al navegador sin ambigüedades en la arena de gestos de Flutter.
  3. **Ampliación de Heap a 512MB**: Se agregó `android:largeHeap="true"` a `<application>` en `AndroidManifest.xml`.
  4. **Bloqueo de videos en segundo plano**: Se invocó `setMediaPlaybackRequiresUserGesture(true)` en `AndroidWebViewController` para impedir que los videos se reproduzcan sin interacción explícita del usuario.
  5. **Navegación estricta Web**: Se validó que solo se permita navegación con esquemas `http` y `https`, bloqueando cualquier esquema externo y suprimiendo redirecciones a tiendas de apps.
  6. **Limpieza continua con MutationObserver**: Se inyectó un `MutationObserver` y CSS para eliminar permanentemente banners de app upsell y asegurar `overflow-y: auto !important` en todo momento durante el scroll.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-10-20

### ~~MEDIA - No aparecía la botonera de música en la ventana de notificaciones de Android~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `android/app/src/main/AndroidManifest.xml`, `lib/services/notification_service.dart`, `lib/providers/music_player_provider.dart`
- **Qué pasaba**: Al reproducir música, no se mostraba la botonera con controles en la bandeja de notificaciones de Android.
- **Causa raíz**:
  1. En `AndroidManifest.xml` no estaba registrado `ActionBroadcastReceiver`.
  2. En Android 13+ (API 33+), se omitía la llamada a `requestNotificationsPermission()` para notificaciones locales, por lo que el SO descartaba la notificación.
  3. El canal `furi_music_channel` no se creaba al inicio y se usaba `Importance.low` y `MediaStyleInformation` sin MediaSession token, lo que en capas como MIUI / HyperOS minimizaba y ocultaba las acciones de la notificación.
- **Fix**:
  1. Se declaró `ActionBroadcastReceiver` en `AndroidManifest.xml`.
  2. Se invocó `requestNotificationsPermission()` y se registró el canal de música con `Importance.defaultImportance`.
  3. Se removió `MediaStyleInformation`, permitiendo que Android dibuje los botones de acción estándar (`NotificationCompat.Action`) de forma visible e interactiva.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~ALTA - Crash al entrar a Pinterest por redirección no controlada a intents externos~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/galeria/pinterest_screen.dart`
- **Qué pasaba**: Al entrar a la sección de Pinterest embebida, a los pocos segundos la pantalla se cerraba o expulsaba al usuario.
- **Causa raíz**: La página web móvil de Pinterest ejecuta scripts que intentan redirigir automáticamente al deep link de la app nativa o a la tienda (`intent://`, `pinterest://`, `market://`). Al no tener implementado un `onNavigationRequest` en `NavigationDelegate`, Android WebView intentaba cargarlos como URL estándar o disparaba errores de navegación y cierres no controlados.
- **Fix**: Se implementó `onNavigationRequest` en `PinterestScreen`, bloqueando de forma explícita cualquier esquema ajeno a la web (`intent://`, `pinterest://`, `market://`, `android-app://`).
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~ALTA - Pantalla roja con SQLite mismatch (UPDATE board_elements SET id = NULL)~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/providers/board_data_provider.dart`, `lib/models/board_element.dart`
- **Qué pasaba**: Aparecía una pantalla roja de crash con `DatabaseException(datatype mismatch (code 20 SQLITE_MISMATCH)) sql 'UPDATE board_elements SET id = NULL...'`.
- **Causa raíz**: Al sincronizar con Supabase o recibir payloads en tiempo real, `BoardElement.fromCloudRow` no tenía el `id` local de SQLite (quedaba en `null`). Al llamar a `db.update(_tableName, element.toMap(), ...)`, `toMap()` incluía `'id': null`. En SQLite, intentar actualizar una clave primaria autoincremental con `NULL` dispara error de mismatch. Además, las llamadas en `.then(...)` carecían de `.catchError`.
- **Fix**:
  1. `BoardElement.toMap({bool includeId = true})` omite la clave `'id'` si es nula.
  2. En todas las actualizaciones de SQLite (`_pullFromCloud`, `updateElement`, `_handleRealtimePayload`), se invoca con `includeId: false`.
  3. Se aseguraron bloques `try-catch` y `.catchError(...)` en todas las operaciones de persistencia en segundo plano.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~MEDIA - TimeoutException no capturado en TriviaProvider._loadAnswers provocaba pantalla roja~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/providers/trivia_provider.dart`, `lib/main.dart`
- **Qué pasaba**: Pantalla roja con `UNCAUGHT: TimeoutException after 0:00:08.000000: Future not completed en TriviaProvider._loadAnswers`.
- **Causa raíz**:
  1. En `TriviaProvider`, las funciones de recarga `_reloadAnswers()` y `_reloadQuestions()` eran ejecutadas como callbacks de Supabase Realtime sin `try-catch`.
  2. Al demorarse la red más de 8 segundos, el timeout lanzaba una excepción no capturada que llegaba a `runZonedGuarded` en `main.dart`.
  3. `runZonedGuarded` ejecutaba `runApp(_CrashApp(...))`, sustituyendo la app entera por la pantalla roja.
- **Fix**:
  1. Se protegieron `_loadQuestions()`, `_loadAnswers()`, `_reloadQuestions()` y `_reloadAnswers()` con `try-catch` y fallback automático a `LocalCache`.
  2. En `main.dart`, se implementó la bandera `appStarted`: los errores asíncronos posteriores al arranque se registran en logs sin tumbar la interfaz ni desmontar `FuriApp`.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Doble barra de control de música en la pantalla MusicScreen~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/widgets/furi_global_overlay.dart`, `lib/screens/music/music_screen.dart`, `lib/providers/music_player_provider.dart`
- **Qué pasaba**: Al reproducir una canción dentro de `MusicScreen`, aparecían simultáneamente dos barras de control de música superpuestas (la barra inferior completa de la pantalla y la barra flotante global de la aplicación).
- **Causa raíz**:
  1. `FuriGlobalOverlay` envuelve la app a nivel `MaterialApp.builder` y muestra una barra de música flotante en cualquier pantalla cuando hay una canción sonando.
  2. Para no mostrarse en `MusicScreen`, verificaba `appRouter.routerDelegate.currentConfiguration.uri.path.startsWith('/music')`.
  3. Sin embargo, al navegar con `context.push(RouterRoutes.music)`, GoRouter no actualiza esa propiedad en el root delegate a `/music` ni dispara reconstrucción en los builders fuera del Navigator. Como resultado, ambas barras se mostraban a la vez.
- **Fix**:
  1. Se implementó `isMusicScreenOpen` y `setMusicScreenOpen(bool)` en `MusicPlayerProvider`.
  2. `MusicScreen` activa esta bandera en `initState` y la desactiva en `dispose`.
  3. `FuriGlobalOverlay` ahora evalúa `musicPv.isMusicScreenOpen`, ocultando reactivamente la barra flotante al entrar a `MusicScreen` y mostrándola nuevamente al salir hacia cualquier otra pantalla.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Ícono de notificación aparecía como un cuadrado blanco en la barra superior de Android~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `android/app/src/main/res/drawable/ic_notification_fox.xml`, `android/app/src/main/AndroidManifest.xml`, `lib/services/notification_service.dart`
- **Qué pasaba**: Al llegar una notificación en Android, el ícono en la barra superior (status bar) y en la insignia se mostraba como un cuadrado blanco opaco sin forma reconocible.
- **Causa raíz**:
  1. En `notification_service.dart`, se configuró `AndroidInitializationSettings('@mipmap/ic_launcher')`.
  2. En Android 5.0+ (API 21+), el sistema operativo exige que los íconos de notificación sean monocromáticos sobre fondo transparente (`smallIcon`). Cualquier recurso que tenga un fondo opaco o forma rectangular completa es forzado por el rasterizador de Android a rellenar todos sus píxeles opacos en blanco puro, convirtiéndolo en un cuadrado.
  3. En `AndroidManifest.xml` no se había declarado `com.google.firebase.messaging.default_notification_icon`.
- **Fix**:
  1. Se diseñó el vector drawable `ic_notification_fox.xml` en `res/drawable/` con la silueta de un zorrito 🦊 y recortes transparentes con regla `evenOdd` (ojos, orejas y hocico huecos).
  2. Se configuró `notification_fox_color` (`#FF7A00`) en `colors.xml` para el tinte naranja de la insignia expandida.
  3. Se declararon los metadatos de ícono y color en `AndroidManifest.xml`.
  4. Se actualizó `notification_service.dart` para inicializar y despachar con `@drawable/ic_notification_fox` y color `#FF7A00`.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Notificaciones en el panel lateral estaban invertidas o autoreferenciadas~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/home_screen.dart` (`_NotificationPanel`), `lib/services/notification_service.dart`, tabla `notifications` (Supabase)
- **Qué pasaba**: Al entrar con el usuario Rocío, el panel lateral de notificaciones mostraba "Rocío registró una emoción", pero correspondía en realidad a las emociones de Facu. En general, se mostraban las acciones del propio usuario en lugar de las de la pareja.
- **Causa raíz**:
  1. En Supabase, varias filas históricas tenían `user_id = from_user` (asignadas al propio autor en lugar de a la pareja receptora).
  2. En `NotificationService._storePushNotification()`, el guardado de notificaciones estaba cableado con `user_id: AppState.myId`, por lo que al simular o recibir notificaciones generadas localmente, se guardaban para uno mismo.
  3. `_NotificationPanel` mostraba el `title` y `body` crudos de la tabla sin normalizar los nombres en caso de que vinieran nombrados en tercera persona con el nombre de la cuenta activa.
- **Fix**:
  1. **Supabase UPDATE**: Se migraron los registros de `notifications` para asignar el `user_id` al ID de la pareja y `from_user` al emisor real.
  2. **Persistencia coherente**: `NotificationService._storePushNotification()` comprueba `isAuthoredByMe` y almacena con `user_id = AppState.partnerId` cuando el evento fue generado por el usuario activo, y con `user_id = AppState.myId` cuando viene de la pareja.
  3. **Normalización en UI**: Se agregaron `_formatTitle()` y `_formatBody()` en `_NotificationPanelState`, reemplazando cualquier mención del nombre propio por `AppState.partnerName`, garantizando que en la cuenta de Facu siempre se lean los eventos de Rocío, y en la de Rocío los de Facu.
  4. En `nosotros_screen.dart`, se actualizó el título de sección de emoción de "Pareja" a `AppState.partnerName`.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Salto forzado hacia abajo al cargar mensajes antiguos en ChatScreen al hacer scroll hacia arriba~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/chat_screen.dart` (`_ChatViewState`), `lib/providers/chat_provider.dart`
- **Qué pasaba**: Al subir en el chat para leer mensajes viejos, la carga de los 100 mensajes anteriores expulsaba al usuario de vuelta hacia abajo (offset 0), impidiendo leer el historial de mensajes pasados.
- **Causa raíz**: En `_ChatViewState.build()`, se ejecutaba `if (chat.messages.length != _lastMsgCount) { _lastMsgCount = chat.messages.length; _scrollToBottom(); }`. Al ser una lista invertida (`reverse: true`), cargar mensajes viejos aumenta la longitud de la lista, activando incondicionalmente el auto-scroll hacia el final (mensajes nuevos). Además, `_hasMore` no se calculaba dinámicamente con base en los resultados del primer lote.
- **Fix**:
  1. `_ChatViewState` almacena `_lastNewestMessageId`. Solo hace `_scrollToBottom()` si es la primera carga (`_lastMsgCount == 0`) o si el ID del mensaje más reciente (`messages.last.id`) cambió (nuevo mensaje enviado o recibido en tiempo real).
  2. Al cargar mensajes viejos (`_messages.insertAll(0, older)`), el ID más reciente no cambia, por lo que la posición de scroll del usuario permanece completamente fija y estable.
  3. `_hasMore = newestFirst.length >= 100` y deduplicación por ID evitan peticiones redundantes.
  4. Indicador superior (`CircularProgressIndicator`) al cargar mensajes anteriores y banner sutil ("Inicio de los mensajes") al alcanzar el comienzo.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~ALTA - Preguntas de trivia/encuesta se reiniciaban en bucle infinito y reaparecían tras responderlas~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/providers/trivia_provider.dart`, `lib/screens/trivia/widgets/trivia_deck.dart`, `lib/screens/trivia/widgets/history_screen.dart`, tabla `question_answers` (Supabase)
- **Qué pasaba**: Al responder preguntas de la trivia o encuesta, nunca terminaban: seguían apareciendo en el mazo una y otra vez en bucle sin vaciarse ni pasar limpiamente al historial.
- **Causa raíz**:
  1. En Supabase, la tabla `question_answers` tenía un índice único `idx_question_answers_user_date` sobre `(user_id, date)`.
  2. En `TriviaProvider.submit()`, la mutación optimista local hacía `_answers.removeWhere((a) => a.userId == myId && a.date == _today())` y enviaba el upsert a Supabase con `onConflict: 'user_id,date'`.
  3. En consecuencia, si el usuario respondía una 2da pregunta el mismo día, la respuesta de la pregunta anterior era sobreescrita/eliminada tanto en Supabase como en la memoria local. La primera pregunta volvía a quedar sin respuesta (`unansweredQuestions`), reapareciendo de inmediato en el mazo de cartas y haciendo que nunca pudiera completarse el mazo de trivia.
  4. La deduplicación en caché (`_initFromCache`) y en Supabase (`_loadAnswers`) mapeaba por clave `"${userId}_${date}"`, descartando cualquier otra pregunta respondida el mismo día.
- **Fix**:
  1. **Migración DDL en Supabase**: Se eliminó el índice restrictivo `idx_question_answers_user_date` y se creó `CREATE UNIQUE INDEX idx_question_answers_user_question ON public.question_answers (user_id, question_id)`.
  2. **Persistencia por Pregunta**: En `TriviaProvider.submit()`, se actualizó el upsert a `onConflict: 'user_id,question_id'` y la mutación local a `_answers.removeWhere((a) => a.userId == myId && a.questionId == questionId)`. Cada pregunta respondida queda guardada permanentemente e intacta.
  3. **Deduplicación por Pregunta**: `_loadAnswers()` y `_initFromCache()` ahora mapean deduplicando por `"${userId}_${questionId}"`.
  4. **Consulta Específica de Respuestas**: Nuevos métodos `getMyAnswerForQuestion(int questionId)` y `getPartnerAnswerForQuestion(int questionId)`.
  5. **Mazo e Historial**: `TriviaDeck` consulta el estado por `questionId` y actualiza reactivamente en `didUpdateWidget`. Al agotar las preguntas, se muestra correctamente la pantalla vacía de felicitaciones (`EmptyScreen`) y todas las respuestas pasadas se listan en `HistoryScreen` ordenadas por fecha e id descendente.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Descargas de música perdidas al intentar descargar múltiples temas concurrentemente y bloqueo de búsqueda~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/music/music_screen.dart`, `lib/providers/music_player_provider.dart`, `lib/models/download_queue_item.dart`
- **Qué pasaba**:
  1. Si el usuario pulsaba "GUARDAR" en varias canciones de YouTube en la pantalla de música, solo la primera iniciaba y todas las demás pulsaciones eran descartadas silenciosamente sin advertencia.
  2. Al terminar la primera descarga, la interfaz forzaba un cambio de pestaña hacia la biblioteca (`setState(() => _currentTab = 0)`), expulsando al usuario de sus resultados de búsqueda.
- **Causa raíz**:
  1. El botón de guardar en los resultados validaba `(isAlreadySaved || pv.isDownloading) ? () {} : ...`. Con `_isDownloading` activo durante los 20-30 segundos que demora extraer y subir a Supabase, cualquier interacción subsiguiente era una función vacía.
  2. No existía estructura de cola ni despachador FIFO para encolar y procesar solicitudes asíncronas concurrentes.
- **Fix**:
  1. **Sistema de Cola Secuencial**: Modelo `DownloadQueueItem` y lista `_downloadQueue` en `MusicPlayerProvider`. El método `addToDownloadQueue` encola de inmediato y un worker secuencial `_processQueue` ejecuta las descargas una a una sin bloquear la interacción.
  2. **Estados en los Botones**: Cada tarjeta en los resultados muestra su estado real: "GUARDADO", "DESCARGANDO (% en vivo)", "EN COLA (#pos)" o "GUARDAR".
  3. **No Interrupción de Búsqueda**: Se eliminó la redirección forzada a la biblioteca; el usuario puede seguir explorando y encolando libremente.
  4. **Modal y Notificaciones**: BottomSheet modal interactivo para monitorear, cancelar o reintentar canciones en la cola, y notificaciones in-app flotantes al finalizar cada descarga en background.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~ALTA - Detección y bloqueo como Bot en Pinterest por inyección de scripts JavaScript en WebView~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/galeria/pinterest_screen.dart`
- **Qué pasaba**: Al intentar automatizar el login de Pinterest inyectando JavaScript sintético que completaba correo y contraseña y hacía clic en el botón de submit, Pinterest activaba sus escudos de seguridad (Cloudflare / Akamai), bloqueando el acceso con captchas y errores 403 por detección de bot.
- **Causa raíz**:
  1. Los scripts que llenan inputs en 0 milisegundos y disparan eventos sintéticos (`dispatchEvent(new Event('input'))`) carecen de flags confiables de interacción humana (`isTrusted === false`), siendo detectados inmediatamente por sistemas anti-bot modernos.
  2. Google OAuth no permite inicios de sesión dentro de WebViews embebidos (`403: disallowed_useragent`), y el sandbox de Android no permite transferir cookies de sesión desde la app externa de Google Chrome a un WebView embebido de una app de terceros.
- **Fix**:
  1. **Eliminación de Scripts de Inyección**: Se suprimieron por completo los scripts de autocompletado forzado que disparaban los detectores de bot.
  2. **Camuflaje con User-Agent Genuino**: Se configuró el User-Agent de Chrome Mobile moderno (`Chrome/128.0.0.0 Mobile Safari/537.36`) para que Pinterest lo trate como un navegador móvil real.
  3. **Barra Rápida de Credenciales F.U.R.I**: Se incorporó una barra superior con chips de 1 toque para copiar correo (`derrame_company@yahoo.com`) y contraseña (`Zapallo1234*`) al portapapeles con feedback táctil y visual. El pegado se realiza de manera humana y natural.
  4. **Persistencia Permanente de Sesión**: Gracias a la retención automática de cookies en SQLite por parte de `WebViewCookieManager`, una vez completado el inicio de sesión orgánico, la sesión permanece guardada permanentemente en la app y no vuelve a solicitar credenciales.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~ALTA - Pizarrón con sobrecarga CPU/GPU por lienzo infinito y conflicto de arrastre con teclados virtuales al tocar la nota~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/milanote/milanote_screen.dart`, `lib/screens/milanote/widgets/milanote_element_card.dart`, `lib/screens/milanote/painters/milanote_grid_painter.dart`
- **Qué pasaba**:
  1. Al mover notas desde cualquier parte, el teclado virtual del teléfono se abría inesperadamente, interrumpiendo el arrastre y trabando la pantalla. Se dependía de un drag handle incómodo.
  2. El pizarrón tenía un lienzo infinito virtual de 8000x8000 px con 4000 px de margen adicional (área de 256 millones de píxeles) que consumía excesiva GPU y CPU en móviles y PC, además de permitir que el usuario se perdiera en el vacío.
- **Causa raíz**:
  1. `MilanoteElementCard` mantenía `TextField`s montados activamente en la tarjeta todo el tiempo. Al tocar la nota para arrastrarla, `EditableText` consumía el `PointerDownEvent` e invocaba el teclado del sistema, provocando redibujados por `viewInsets` y cancelando el gesto de arrastre de Flutter.
  2. Un `InteractiveViewer` no restringido con `constrained: false` sobre un área descomunal de 8000x8000 px obligaba al motor gráfico a gestionar matrices y límites infinitos sin restricción física.
- **Fix**:
  1. **Desacoplamiento Arrastrar vs Editar**: Se crearon dos modos claros en la tarjeta. En modo normal (`_isEditing == false`), la tarjeta renderiza solo `Text` y un `GestureDetector` unificado: arrastrar desde cualquier píxel de la nota la mueve con 120 FPS sin abrir el teclado. Tocar una sola vez sin arrastrar (`onTap`) activa el modo edición (`_isEditing = true`), abriendo los `TextField`s y el teclado en la misma tarjeta con un botón "Listo" en la cabecera. Tocar fuera de la tarjeta desactiva la edición y guarda los cambios.
  2. **Lienzo Finito Acotado**: Tablero de dimensiones finitas (`2400 x 1600` px), bordes acotados (`boundaryMargin: EdgeInsets.all(60)`), cuadrícula de 3.750 puntos en lugar de 81.000, y clamping de todas las notas dentro de los límites del tablero.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Nombre y "en línea" solapados y montados encima del círculo de avatar en ChatScreen~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/chat_screen.dart` (`_buildAppBar`)
- **Qué pasaba**: El nombre de la pareja y el estado ("en línea" / "escribiendo...") estaban visualmente montados por encima del círculo del avatar del chat.
- **Causa raíz**: El `AppBar` definía `leadingWidth: 78`, pero dentro de `leading` colocaba un `Row` con `IconButton` (48px) + `CircleAvatar` (38px de diámetro) + padding de 8px = 94px. Los 16px excedentes desbordaban hacia el espacio del `title` (que por defecto en Material se posiciona en un offset fijo respecto a `leadingWidth`), haciendo que el texto del título se dibujara encima del borde derecho del avatar.
- **Fix**: Se reestructuró la cabecera: `leadingWidth: 44` conteniendo exclusivamente el botón de volver (`IconButton`), y se trasladó el `CircleAvatar` al widget `title` dentro de un `Row` con espaciado explícito (`SizedBox(width: 12)`) y `titleSpacing: 0`. Esto garantiza separación limpia e inequívoca de 12px entre el avatar y el texto y cero solapamiento.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~ALTA - Botones de notificación musical abrían la app en vez de controlar la música, usaban emojis y la música se cortaba al prender la pantalla~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/services/notification_service.dart`, `lib/providers/music_player_provider.dart`, `lib/services/sound_service.dart`, `lib/main.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/drawable/`
- **Qué pasaba**: 
  1. Al pulsar las teclas de Anterior, Play/Pausa o Siguiente en la notificación del celular, la notificación abría la app en primer plano en vez de pausar o cambiar de tema directamente en segundo plano.
  2. Los botones de la notificación mostraban emojis (`⏮️`, `▶️`, `⏸️`, `⏭️`) en lugar de iconos nativos multimedia.
  3. Al reproducir música con la pantalla apagada funcionaba, pero al volver a encender la pantalla del celular la música se cortaba o se apagaba automáticamente.
- **Causa raíz**:
  1. `AndroidNotificationAction` tenía configurado `showsUserInterface: true`, lo cual fuerza a Android a lanzar la Activity (`MainActivity`) en primer plano con un `PendingIntent.getActivity` en cada toque. Además, faltaba `onDidReceiveBackgroundNotificationResponse` con aislamiento `@pragma('vm:entry-point')` y comunicación por `IsolateNameServer`.
  2. Las acciones se definieron solo con strings de texto que contenían caracteres emoji unicode (`'⏮️'`, etc.) sin asociar recursos gráficos `DrawableResourceAndroidBitmap`.
  3. En `main.dart`, el listener del ciclo de vida `didChangeAppLifecycleState` invocaba incondicionalmente `SoundService().startBackgroundMusic()` al recibir `AppLifecycleState.resumed` (evento emitido cada vez que el celular prende la pantalla y reactiva la ventana). `SoundService` solicitaba foco de audio exclusivo `AndroidAudioFocus.gain` para reproducir el loop de ambiente `musicaDeFondo.mp3`, provocando que el sistema operativo Android le revocara el foco de audio a `MusicPlayerProvider._player` y detuviera de inmediato la canción. Además, `MusicPlayerProvider._player` no tenía configurado `AudioContext` con `stayAwake: true` ni permisos `WAKE_LOCK` y `FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
- **Fix**:
  1. Acciones de notificación con `showsUserInterface: false`, callback background `notificationTapBackground` con `@pragma('vm:entry-point')` y comunicación mediante puerto `IsolateNameServer` (`furi_music_isolate_port`).
  2. Creación de 4 vector drawables nativos de Material en `res/drawable/` (`ic_music_prev.xml`, `ic_music_play.xml`, `ic_music_pause.xml`, `ic_music_next.xml`), textos limpios sin emojis ("Anterior", "Pausar"/"Reproducir", "Siguiente") y `MediaStyleInformation` con visibilidad pública para pantalla de bloqueo.
  3. Bandera de exclusión `SoundService.isMusicPlaying` que impide que `SoundService().startBackgroundMusic()` arranque o robe el foco si el usuario está escuchando canciones. Configuración de `_mediaAudioContext` con `stayAwake: true`, `usageType: media`, `contentType: music`, `audioFocus: gain` y permisos `WAKE_LOCK`, `FOREGROUND_SERVICE` y `FOREGROUND_SERVICE_MEDIA_PLAYBACK` en `AndroidManifest.xml`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~ALTA - Sistema de vistos (ticks) roto y chat tosco sin diseño ni fluidez WhatsApp~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/models/message.dart`, `lib/providers/chat_provider.dart`, `lib/services/notification_service.dart`, `bot-furi/server.js`, `lib/screens/chat_screen.dart`, `lib/screens/chat/widgets/chat_message_tile.dart`
- **Qué pasaba**: El sistema de vistos no funcionaba correctamente: el doble check gris de entrega casi nunca se marcaba (porque solo se actualizaba si el destinatario ya tenía el chat abierto al instante del insert), los checks azules fallaban si `read` era true sin timestamp `readAt`, y el chat se sentía tosco (sin botón de volver, layout rígido con Stack y cálculo manual de teclado, fuentes cómic `Bangers` difíciles de leer).
- **Causa raíz**:
  1. `Message.tickState` solo validaba `readAt != null`. Mensajes con `read: true` caían a `delivered` o `sent`.
  2. `delivered_at` nunca se persistía en Supabase cuando el receptor recibía la notificación push en segundo plano (`_firebaseMessagingBackgroundHandler`), en primer plano (`_listenFCMForeground`) o en el listener global de Supabase. Además, `_insertMessage` no despachaba FCM push hacia la pareja.
  3. El servidor de Render 24/7 (`bot-furi/server.js`) no tenía suscripción realtime a la tabla `messages` para despachar los pushes de alta prioridad automáticamente a los dispositivos móviles.
  4. `ChatScreen` usaba `ResponsiveWrapper` con `Stack` rígido, `resizeToAvoidBottomInset: false` y matemáticas manuales de insets, atrapando los mensajes en un recuadro pequeño con sombras duras, sin botón de retroceso a la pantalla anterior y tipografía inadecuada para mensajería.
- **Fix**:
  1. `Message.tickState`: 1 check gris = enviado (`sent`); 2 checks grises = entregado al celular (`delivered`); 2 checks azules = leído/abierto en chat (`read`).
  2. `NotificationService.markMessageDelivered`: persiste `delivered_at = NOW()` en Supabase al recibir la notificación push (background y foreground) y al recibir el mensaje por el canal realtime.
  3. `ChatProvider`: despacha push nativo al insertar mensaje, marca entregados y leídos al cargar mensajes y al recibir en tiempo real con el chat abierto.
  4. Render 24/7 (`bot-furi/server.js`): suscripción realtime activa a la tabla `messages` que despacha notificaciones push de alta prioridad vía FCM v1 y nuevo endpoint `/api/mark-delivered`.
  5. `ChatScreen` rediseñado con estilo WhatsApp y estética F.U.R.I: `Scaffold` nativo con `resizeToAvoidBottomInset: true`, AppBar con botón atrás, avatar del partner, estado "escribiendo...", chips de fecha centrados ("HOY", "AYER"), barra de entrada con píldora, selector de emoji, adjuntos, cámara y botón circular mic/send, y burbujas con colas WhatsApp y tipografía legible `GoogleFonts.plusJakartaSans`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~ALTA - Reacción con emoji en galería bugea la foto y desaparece la imagen~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/providers/gallery_provider.dart` y `lib/screens/galeria/galeria_screen.dart`
- **Qué pasaba**: Al presionar una reacción de emoji en una foto de la galería, la imagen desaparecía o mostraba icono roto.
- **Causa raíz**: Supabase Realtime omite columnas grandes (TOAST) en eventos `UPDATE`. `remote.url` llegaba vacío y sobreescribía la imagen base64 local con `''`. Además, `base64Decode` recreaba una instancia de `MemoryImage` en cada render sin cachear, invalidando la identidad de la imagen en Flutter.
- **Fix**: Preservar `url` y `thumbnail` existentes si el payload remoto viene vacío, fallback directo a Supabase si falla la RPC, y caché de `ImageProvider` por URL en `GaleriaScreen`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~ALTA - Pizarra Milanote con lag severo, trabas y congelamiento al mover notas, listas y lienzo en celular y PC~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/milanote/painters/milanote_grid_painter.dart`, `lib/screens/milanote/milanote_screen.dart`, `lib/screens/milanote/widgets/milanote_element_card.dart`, `lib/screens/milanote/painters/connector_line_painter.dart`
- **Qué pasaba**: Al mover notas, listas o cualquier elemento, o al mover/desplazar el lienzo en celular y PC, se lagueaba severamente, se trababa, no se movía con fluidez y los elementos no respondían con comodidad.
- **Causa raíz**:
  1. `MilanoteGridPainter`: Dibujaba un lienzo de 8000x8000 en un bucle anidado `for (0..8000) for (0..8000)` ejecutando **81.796 llamadas a `canvas.drawCircle` en la CPU/GPU cada frame**, consumiendo 250MB+ de memoria de texturas y saturando la tasa de refresco a menos de 10 FPS.
  2. `InteractiveViewer` mantenía `panEnabled: true` mientras el usuario arrastraba una tarjeta: la arena de gestos de Flutter competía entre el paneo del lienzo y el arrastre de la tarjeta, provocando eventos de cancelación (`PointerCancelEvent`), saltos y bloqueos ("se traba").
  3. En cada micro-píxel de arrastre, `onDragUpdate` invocaba `pv.updatePositionLocal()`, lo que disparaba `notifyListeners()` en `BoardDataProvider`: **reconstruía la pantalla entera**, todas las tarjetas, campos de texto y el pintor de la cuadrícula de 81.000 círculos a 60/120 veces por segundo.
  4. Ninguna tarjeta ni la cuadrícula contaban con `RepaintBoundary`, invalidando el raster cache de toda la pantalla en cada frame.
- **Fix**:
  1. **Cuadrícula ultra-optimizada**: `MilanoteGridPainter` ahora consulta `canvas.getLocalClipBounds()` para recortar exclusivamente la ventana visible (~300 puntos en móvil, ~1.500 en escritorio) y los despacha a la GPU en una única llamada batch `canvas.drawPoints(PointMode.points, ...)`.
  2. **Aislamiento de gestos**: Durante el arrastre de cualquier elemento, `_isDraggingElement` bloquea `panEnabled` y `scaleEnabled` en `InteractiveViewer`, otorgando control 100% exclusivo al elemento sin interferencias de la arena de gestos.
  3. **Arrastre local 60/120 FPS**: `MilanoteElementCard` gestiona su desplazamiento `_dragLocalDx/Dy` localmente mediante su propio `setState`, elevando la tarjeta (`_isDragging` shadow boost) y actualizando las líneas de conexión en tiempo real vía `_activeDragNotifier` sin reconstruir el árbol global.
  4. **Persistencia limpia al soltar**: La posición y el ajuste a grilla (`_snap`) se envían a `BoardDataProvider` y SQLite/Supabase una sola vez al soltar (`onDragEnd`), eliminando el spam de I/O.
  5. **Capas de repintado aisladas**: Envoltorio `RepaintBoundary` tanto en la cuadrícula como en cada `MilanoteElementCard`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-19

### ~~MEDIA - Barras laterales del Home visibles sobre las tarjetas deslizables (Mazo)~~ ✅ RESUELTO 2026-10-19
- **Dónde**: `lib/screens/home_screen.dart`
- **Qué pasaba**: Al abrir el mazo de tarjetas (`_showDeck`), las barras laterales y tiradores de los cajones deslizables seguían viéndose por encima de las cartas.
- **Causa raíz**: Los cajones deslizables (`_buildBottomSlidingDrawer`, `_buildTopSlidingDrawer`) y elementos flotantes se renderizaban después de `DeckOverlay` en el `Stack`.
- **Fix**: Desmontar condicionalmente los cajones y elementos laterales con `if (!_showDeck && !_showPoemas)` para que la vista del mazo sea limpia y en pantalla completa.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-10-19

### ~~CRÍTICA - Notificaciones y reacciones llegaban al propio usuario que las realizaba (auto-notificación)~~ ✅ RESUELTO 2026-10-18
- **Dónde**: Supabase `device_tokens`, `NotificationService` (`lib/services/notification_service.dart`) y `ChatProvider` (`lib/providers/chat_provider.dart`)
- **Qué pasaba**: Cuando un usuario (Facu) realizaba una acción (crear un favorito, meta, nota, etc.) o reaccionaba a un mensaje en el chat, la notificación flotante le llegaba a su propio teléfono en lugar de a su pareja (Rocío).
- **Causa raíz**:
  1. En la tabla de Supabase `device_tokens`, el token FCM del teléfono físico de Facu (`dFQgPWMIQiy9...`) quedó registrado duplicado bajo ambos usuarios (`user_id = Facu` y `user_id = Rocío`), porque el índice único previo era compuesto `(user_id, token)`. Cuando Facu hacía una acción, los triggers de PostgreSQL enviaban el push a `partner_id` (Rocío); `send-push` consultaba los tokens de Rocío y encontraba el token del teléfono de Facu, entregándole la notificación a él mismo.
  2. En `NotificationService._storeToken`, no se eliminaban los registros del mismo token asociados a otros usuarios al iniciar sesión.
  3. En `NotificationService.startListening`, un listener en tiempo real sobre `UPDATE` en la tabla `messages` no verificaba el remitente y reaccionaba con `_showLocalNotification` ("Alguien reaccionó a tu mensaje") cada vez que se marcaban mensajes como leídos o se quitaba una reacción.
  4. En `startListeningNotifications`, el callback de inserciones en `notifications` volvía a invocar `_showLocalNotification`, duplicando avisos sonoros que el listener de FCM foreground ya había emitido.
- **Fix**:
  1. Se eliminó la fila duplicada en `device_tokens` en Supabase y se creó un índice único global `idx_device_tokens_token ON device_tokens(token)`.
  2. `_storeToken` ahora elimina preventivamente cualquier asociación previa del token con otros `user_id` antes de registrar o renovar.
  3. Se eliminó el listener defectuoso de `messages.update` en `startListening`.
  4. Se añadió `NotificationService.sendPushToPartner` y se integró en `ChatProvider.toggleReaction`, de modo que cuando un usuario reacciona a un mensaje de su pareja, se envía un push directo y exclusivo al celular de la pareja (con vista previa del mensaje y emoji), sin notificar jamás al autor de la reacción.
  5. En `startListeningNotifications`, se restringió `_showLocalNotification` a entornos desktop (donde FCM no corre nativo), eliminando avisos dobles en Android.
- **Lección**: Un token FCM de dispositivo móvil es único por terminal físico y jamás debe permitirse compartido entre diferentes cuentas de usuario en la base de datos. Las reacciones a mensajes deben notificar explícitamente al destinatario mediante push dirigido con el actor excluido.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-10-18

### ~~ALTA - MapaScreen mock sin mapa real y bloqueado en "Debes compartir tu ubicación" / "-- km"~~ ✅ RESUELTO 2026-10-18
- **Dónde**: `lib/screens/mapa_screen.dart` y `lib/providers/location_provider.dart`
- **Qué pasaba**: Al ingresar a la pantalla de mapa y apretar el botón de ubicación, la interfaz seguía mostrando "Comparti tu ubicacion para ver la distancia" / "Tu ubicacion no esta compartida", la distancia se quedaba en `-- km` sin calcular nada, y la pantalla solo contenía un icono estático de mapa (`Icons.map`) sin ningún mapa real ni trazado de línea.
- **Causa raíz**: (1) `MapaScreen` evaluaba `hasData = lpv.myLocation != null && lpv.partnerLocation != null`. Al tener solo un miembro registrado en `couple_locations` (o si la pareja no había emitido su GPS en la sesión), `hasData` era falso de forma permanente, apagando el swap y mostrando texto de falta de ubicación; (2) `MapaScreen` era un mockup de `LocaScreen` con un `Stack` de iconos estáticos y un `Container` de 60px simulando una línea, sin ningún motor de mapas real; (3) Si `AppState.myId` o `partnerId` estaban vacíos o pendientes de carga, `updateMyLocation` abortaba sin avisar al usuario.
- **Fix**: Integración de `flutter_map` con OpenStreetMap interactivo real, trazado de línea recta punteada (`StrokePattern.dashed`), marcadores de Facu y Rocío con punteros directos, cálculo ininterrumpido de distancia con `effectiveMyLocation` y `effectivePartnerLocation`, feedback visual inmediato al compartir GPS (SnackBar verde), y siembra de registro inicial de pareja en Supabase.
- **Lección**: Las vistas de distancia de pareja deben contar con ubicaciones de respaldo (última conocida o fallback) para no colapsar la UI ni anular el renderizado de la distancia cuando un miembro aún no ha sincronizado en vivo.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-10-18

### ~~ALTA - Descarga de música congelada en 15% (403 Forbidden / falta de PO Token en CDN)~~ ✅ RESUELTO 2026-10-14
- **Dónde**: `lib/services/music_download_service.dart` (`downloadAndUploadTrack`)
- **Qué pasaba**: Al descargar una canción desde YouTube, el indicador de progreso se clavaba en 15% indefinidamente y nunca terminaba de descargar ni de guardar en la nube.
- **Causa raíz**: Google Video CDN corta la conexión tras 1.048.576 bytes (1 MB exacto) con código HTTP 403 Forbidden si el cliente no proporciona un Proof of Origin / BotGuard token (PO Token). Al recibir 403, `youtube_explode_dart` reintentaba en bucle cerrado silencioso sin emitir chunks subsiguientes ni lanzar timeout hacia la UI.
- **Fix**: Se implementó un pipeline desacoplado con convertidor online primario de alta velocidad (`loader.to` / `savenow.to`) que entrega el archivo MP3 completo a 200 OK sin bloqueos de IP, y un fallback secundario a `youtube_explode_dart` protegido por timeouts estrictos (6s / 8s) para que nunca se cuelgue.
- **Lección**: Cualquier descarga de streams de audio de CDNs de terceros debe contar con timeouts por chunk y canales de descarga alternativos para no congelar la UI ante políticas anti-bot cambiantes de los proveedores.

### ~~ALTA - Syntax error 42601 cerca de END en supabase_schema.sql~~ ✅ RESUELTO 2026-10-14
- **Dónde**: supabase_schema.sql (líneas 147-159)
- **Qué pasaba**: Al correr el schema completo en Supabase SQL Editor, PostgreSQL devolvía ERROR: 42601: syntax error at or near "END" LINE 153: END;.
- **Causa raíz**: En bloques PL/pgSQL anidados EXCEPTION WHEN duplicate_object THEN NULL, la sentencia NULL en PL/pgSQL es un statement que exige terminador de sentencia ; (NULL;). Si falta el ;, el parser espera una continuación y falla al encontrarse inmediatamente con END;.
- **Fix**: Se colocó NULL; en las líneas 152 y 157.
- **Lección**: En PL/pgSQL (a diferencia de otros dialectos SQL), NULL como sentencia no-op requiere obligatoriamente punto y coma (NULL;).

### ~~ALTA - Día entrenado no podía desmarcarse (toggle de completado roto)~~ ✅ RESUELTO 2026-09-01
- **Dónde**: `lib/providers/workout_provider.dart` (`toggleCompletion`) + `lib/models/workout_completion.dart`
- **Qué pasaba**: tocar el badge F/R de un día marcado nunca lo desmarcaba. El call-site llama `toggleCompletion(userId, date)` **sin `routineId`** (`null`), pero el filtro del registro existente usaba `c.routineId == routineId` mientras `toMap()` persiste `routine_id: 0` para "sin rutina" y `fromMap` lo lee como `0`. `0 == null` es `false` → la rama de delete nunca corría y el día quedaba permanentemente "entrenado".
- **Fix**: normalizar ambos operandos `(c.routineId ?? 0) == (routineId ?? 0)`.
- **Lección**: un `toMap()` que normaliza `null` a `0` desincroniza la comparación en memoria (`fromMap` devuelve `0`, no `null`). Cualquier lookup por igualdad contra un valor persistido normalizado debe normalizar AMBOS operandos.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-09-01

### ~~ALTA - Carta de la pareja nunca aparecía en Nosotros (swap 📬 siempre vacío)~~ ✅ RESUELTO 2026-09-01
- **Dónde**: `lib/screens/nosotros_screen.dart` (`_loadPartnerLetter`)
- **Qué pasaba**: `_loadPartnerLetter()` llamaba `_markSeen()` ANTES de chequear `seen_by`, y `_markSeen` agrega `myId` a `record['seen_by']` (mapa local) → el chequeo posterior `contains(myId)` era SIEMPRE true → la función retornaba `null` siempre, y el swap de cartas de Nosotros nunca mostraba la carta de la pareja. Bonus: `_markSeen` hacía un UPDATE real a la BD en cada carga de la pantalla.
- **Fix**: chequear `seen_by` ANTES de marcar (solo marcar si aún no está leída).
- **Lección**: una mutación que es a la vez el "efecto" y la condición del chequeo debe ejecutarse DESPUÉS de leer el estado; el orden "chequear estado → mutar" evita que la propia mutación invalide el chequeo.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-09-01

### ALTA - Comentarios de workouts con last-write-wins (race "último write gana")~~ ✅ RESUELTO 2026-09-01
- **Dónde**: `lib/providers/workout_provider.dart` + BD cloud (`workout_*.social`)
- **Qué pasaba**: cada comentario se enviaba con el documento `social` COMPLETO (`.update(next.toMap())`). Dos comentarios simultáneos de Facu y Rocio al mismo ejercicio/rutina/reto se pisaban (el último update ganaba) — exactamente el mismo bug que la RPC de reacciones ya había resuelto (D-13), reintroducido en los comentarios.
- **Fix**: 2 RPC de Postgres con row-level lock (`SELECT ... FOR UPDATE`) `add_workout_comment` / `delete_workout_comment` (whitelist `workout_*`, bump `updated_at`, devuelven el `social` completo autoritativo). El provider hace optimistic + reconciliación (`_commentViaRpc` + `_applyCommentLog/Routine/Challenge`), preservando las reacciones locales. Migración integrada al schema maestro (sección 29c) y **ejecutada en prod** vía Management API.
- **Lección**: cualquier entidad embebida en un JSONB que se envía completo es last-write-wins; la defensa real es serializar en el origen (RPC con `FOR UPDATE`) y reconciliar contra el estado autoritativo del servidor. Al rewirear un método reusado para dos cosas (workout `social` = reacciones + comentarios) hay que tocar SOLO la rama de comentarios.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-09-01

### ~~MEDIA - Notas solo-locales (la pareja no veía las notas del otro)~~ ✅ RESUELTO 2026-09-01 (decisión D-15)
- **Dónde**: `lib/providers/notes_provider.dart` + SQLite local
- **Qué pasaba**: las notas vivían SOLO en SQLite local (`notes` del dispositivo); cada dispositivo veía solo las suyas y la pareja no tenía forma de compartirlas (gap de la app de pareja).
- **Fix**: sync completo con Supabase con el patrón de `ScheduleProvider` — SQLite v11 (`cloud_id`/`synced`/`user_id`), `_pushUnsyncedToCloud` (insert + re-push dirty), `_pullFromCloud` (merge por `cloudId`, borrar locales sin fila cloud), `add/update/delete` local + cloud, realtime `notes_sync`. Tabla cloud `notes` ganó `title` + RLS `full_access_notes` + publicación realtime. Migración integrada al schema maestro (sección 14) y **ejecutada en prod** vía Management API.
- **Lección**: una tabla cloud puede existir sin estar definida en el schema maestro (la `notes` solo la referenciaban triggers de push). Antes de sincronizar contra ella, verificar sus columnas reales y usar `ADD COLUMN IF NOT EXISTS`/`CREATE TABLE IF NOT EXISTS`. Y cuando la entidad local usa camelCase pero la nube snake_case, armar mapas locales EXPLÍCITOS (no reusar `toMap()` contra la DB local).
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-09-01

### ALTA - Sync de clases con último-write-gana (edición de la pareja se pisaba)~~ ✅ RESUELTO 2026-09-01
- **Dónde**: `lib/providers/class_schedule_provider.dart` + SQLite `class_schedules`
- **Qué pasaba**: a diferencia de `ScheduleProvider`, el sync de clases no comparaba `updated_at`: el pull y el realtime aplicaban la fila cloud autoritativamente y el push subía sin chequear la versión cloud → "último que escribe, gana" entre ambos dispositivos (una edición de A podía pisar la de B, y viceversa). Además `class_schedules` no tenía timestamps locales.
- **Fix**: SQLite v12 (`updatedAt TEXT`), modelo con `updatedAt`, y merge por recencia espejando `schedules`: `_pushToSupabase` no sobrescribe si la cloud es más nueva; `_pullFromCloud`/realtime solo aplican la cloud cuando es más nueva (o la local no tiene timestamp).
- **Lección**: cualquier sync cloudId + dirty-flag que no compare timestamps es último-write-gana latente. El patrón del proyecto (schedules) es `cloudId + synced + updatedAt + merge por recencia`; una tabla nueva que sincronice debe espejarlo o reintroducirá este bug.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-09-01

### ALTA - Maestro diverge de prod para `notes` (user_id UUID vs TEXT) + realtime incompleto~~ ✅ RESUELTO 2026-09-01 (schema)
- **Dónde**: `supabase_schema.sql`
- **Qué pasaba**: el master declaraba `notes.user_id UUID REFERENCES profiles` (con `pinned`) mientras prod/migración usan `TEXT`; y el master solo publicaba realtime de `notifications`/`chat_typing`/`notes` (el resto solo en migraciones). Una DB reconstruida solo con el master quedaría: (a) con INSERT a `notes` roto (42883 por el cast uuid→text del trigger) y (b) sin sync en vivo en casi toda la app.
- **Fix**: master alineado a `notes.user_id TEXT` (sin `pinned`), `notify_note_insert` con `::text`, y sección realtime con `FOREACH ARRAY` agregando las ~22 tablas que la app suscribe.
- **Lección**: el master DEBE espejar 1:1 lo que ejecuta prod; si una columna/tabla solo vive en una migración suelta, una DB fresca queda rota. Auditoría del master = comparar con las migraciones + el `.select`/realtime real del código Dart.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-09-01 (schema)

### ALTA - No se pueden crear retos ni metas (trigger push FCM rompe el INSERT)
- **Dónde**: `supabase/migration_push_categories.sql` y BD cloud (`challenges`, `goals`)
- **Qué pasa**: el INSERT a `challenges` (retos) y `goals` (metas) falla. La app lo traga con `catch`
  ("No se pudo guardar el reto"). El error real del servidor (reproducido por REST) es PostgreSQL
  `42883`: `function furi_notify_partner(uuid, unknown, text, jsonb) does not exist`.
- **Causa raíz**: los triggers `AFTER INSERT` `notify_challenge_insert()` y `notify_goal_insert()`
  llaman `furi_notify_partner(NEW.couple_id, ...)`. `NEW.couple_id` es `uuid` y la función espera
  `text`; PostgreSQL NO hace cast implícito `uuid→text` para resolver el overload → el trigger lanza
  → falla TODO el INSERT. moods/workout usan `::text` (por eso funcionaban).
- **Fix**: cast explícito `furi_notify_partner(NEW.couple_id::text, ...)` en ambos triggers
  (aplicado en `migration_push_categories.sql`).
- **Pendiente**: ~~ejecutar `supabase/migration_fix_goal_challenge_push_cast.sql` (CREATE OR REPLACE)
  en el SQL Editor de prod~~ ✅ EJECUTADO 2026-09-01.
- **Lección**: pasar un `uuid` a un parámetro `text` de una función no resuelve el overload en
  PostgreSQL — se necesita `::text` explícito. Cualquier trigger que pase una columna `uuid` a un
  helper de texto debe castearla. Y un "catch" en la app oculta el error SQL: reproducir el INSERT
  por REST con la anon key (RLS full-access) muestra el error del servidor al instante.

### ALTA - Tokens FCM muertos (`UNREGISTERED`) acumulados en `device_tokens`
- **Dónde**: `supabase/functions/send-push/index.ts` + tabla `device_tokens`
- **Qué pasa**: La Edge Function mandaba push a TODOS los tokens históricos de un usuario, incluidos los vencidos (`UNREGISTERED`) por reinstalar la app o cambiar de perfil. Esos tokens nunca se borraban → se reintentaba a ciegas y el usuario afectado (Rocio) dejaba de recibir push sin error visible. Además `device_tokens` acumulaba duplicados por usuario.
- **Fix**: `send-push` ahora filtra `created_at >= ahora-90d` y al recibir `UNREGISTERED` borra el row (RLS full-access). `supabase/migration_device_tokens_unique.sql` agrega `idx_device_tokens_user_token` (único por user+token) para dedupe. Ver historial 2026-08-28 (Push FCM).
- **Lección**: Los tokens FCM se podan SOLO en el servidor al recibir `UNREGISTERED`; el cliente no sabe que venció hasta que la app se reabra. Si un dispositivo no reabre la app, su token queda muerto y ese usuario no recibe push (no es bug de código, es higiene de tokens).
- **Pendiente**: ~~el deploy de `send-push` es manual (`supabase functions deploy send-push`)~~ ✅ DEPLOYADO 2026-08-28 vía Management API (`POST /v1/projects/{ref}/functions/deploy?slug=send-push`, PAT `sbp_...`). La poda en la nube ya está activa. **Redeploy 2026-09-01 → v7**: el service account de Firebase salió del código a `FIREBASE_SERVICE_ACCOUNT` (secreto de la Edge Function, seteado con `scripts/deploy-send-push.ps1`); el PAT quedó en GH Secret `SUPABASE_ACCESS_TOKEN` y `scripts/.env`. Ver historial 2026-09-01 (send-push vía Management API).
- **Prioridad**: ~~ALTA~~ → MITIGADO 2026-08-28 (deploy de la función completado)

### ~~ALTA - Pantallas blancas en APK release (Logros/Metas)~~ 🟡 MITIGADO CON SKIA (validar en celular)
- **Dónde**: `lib/screens/logros/logros_screen.dart`, `lib/screens/metas_screen.dart` + render Flutter en Android
- **Qué pasa**: En el APK release (Windows andaba), Logros/Metas se veían en blanco. Diagnóstico (ver `documentacion/PANTALLAS_BLANCAS_Y_BUILD_ANDROID.md`): excepción de build/layout tragada en release, o pantalla sin frame por bugs de **Impeller** del motor (Flutter 3.44). El fondo de ventana de Android era blanco (`?android:colorBackground`).
- **Fixes aplicados**: (1) **desactivar Impeller** en `AndroidManifest.xml` (`EnableImpeller=false`) → vuelve a Skia; (2) **fondo de ventana oscuro** `#0D0D0D` en `values/styles.xml` + `values-night/styles.xml`; (3) `LocaArranger.arrange` con guarda de dimensión 0 (evita NaN); (4) lectura de `LocalCache` dentro de try/catch en metas/retos/cartas. **(5) Fix de raíz en `loca_arranger.dart` 2026-08-28**: la guarda inicial no alcanzaba — con muchos ítems la subdivisión deja nodos bajo `minW` y `f.clamp(minW/node.width, (node.width-minW)/node.width)` con `lower>upper` generaba hijos de ancho negativo → NaN en `double.clamp`. Ahora el corte chequea `lo<=hi` y si no, parte al medio (`f=0.5`), garantizando dimensiones siempre positivas y finitas. Tests 2026-08-28 lo cubren (cantidad 20..200 + pesos sesgados).
- **Lección**: En release las excepciones de build que no pasan por `runZonedGuarded` son invisibles; una excepción de `paint()` de un `CustomPainter` solo se logea y no dibuja la capa → fondo. El `?:bg` blanco del tema Android es lo que hace que una pantalla sin frame se vea BLANCA: poner `windowBackground` oscuro + desactivar Impeller es el fix estándar para estos bugs.
- **Pendiente**: revalidar en el celular real con `adb logcat`; re-activar Impeller al subir de Flutter.
- **Prioridad**: ~~ALTA~~ → MITIGADO 2026-08-28

### ~~CRÍTICA - Reacciones simultáneas al mismo ítem se pisaban (race de "último write gana")~~ ✅ RESUELTO 2026-08-26
- **Dónde**: `lib/providers/chat_provider.dart`, `gallery_provider.dart`, `workout_provider.dart`, `deck_provider.dart`, `board_provider_v2.dart` + Supabase
- **Qué pasaba**: Cada provider enviaba el mapa `reactions` (o el `data`/`social` completo) en cada update. Dos reacciones simultáneas de Facu y Rocio al mismo ítem hacían que el último `.update()` en llegar pisara al anterior (BUG 2 CRÍTICO de la auditoría del pizarrón). El merge client-side en realtime era solo un parche: no garantizaba consistencia en el servidor.
- **Fix**: Se movió el merge al servidor con **2 RPC de Postgres** y row-level lock (`SELECT ... FOR UPDATE`): `toggle_reaction` (forma `{key:[uid]}`, whitelist de tablas/columnas, max 5 keys) y `react_deck_card` (forma `{uid:emoji}` del mazo). Los 5 providers llaman a la RPC como vía de escritura y reconcilian con la respuesta autoritativa. Board usa un método dedicado `react()` para no reintroducir el race vía el push de documento completo.
- **Lección**: Un UPDATE que envía un JSONB completo es inherentemente last-write-wins. Para garantizar consistencia ante concurrencia hay que serializar en el origen (RPC con `FOR UPDATE`), no mergear en el cliente. La RPC debe replicar EXACTO el toggle de Dart (incluido devolver el estado ORIGINAL intacto cuando se alcanza el límite de 5 keys, chequeado ANTES de mutar).
- **Lección adicional**: `jsonb_set(target, path, new_value)` requiere `path` como `text[]`, no `text`. La sintaxis `'{' || key || '}'` genera un string que PostgreSQL NO convierte implícitamente a `text[]`; `ARRAY[key]` crea el array nativo. Además, `updated_at` no existe en `messages` — el UPDATE dinámico no debe hardcodearlo.
- **Pendiente**: ~~Ejecutar migración~~ ✅ EJECUTADO 2026-08-31.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-26 (código) + fix adicional 2026-08-31 (migration)

### ~~MEDIA - Build de Windows fallaba con TRK0005 o LNK1104 tras agregar un plugin nativo~~ ✅ RESUELTO 2026-08-17
- **Dónde**: `flutter build windows --release` (entorno de build local)
- **Qué pasaba**: Al agregar `flutter_timezone` (plugin con código nativo), CMake debía regenerar los .vcxproj y rebuildeaa; sin el entorno MSVC activado el build moría con `TRK0005: no se encontró CL.exe`. Además, si la app (`furi_app.exe`) está abierta, el linker no puede sobrescribir el exe: `LNK1104: no se puede abrir el archivo ...\furi_app.exe`.
- **Fix**: activar `D:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat amd64` antes del build (plugins nuevos → rebuild CMake → TRK0005) y cerrar el proceso `furi_app` antes de compilar (LNK1104).
- **Lección**: TRK0005 no es permanente: reaparece cada vez que un plugin nuevo fuerza el rebuild de CMake. Y el exe hereda el lock del proceso en ejecución — verificar con `Get-Process furi_app` antes de buildear.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-08-17

### ~~CRÍTICA - Calendario no compartía eventos entre usuarios~~ ✅ RESUELTO 2026-08-14
- **Dónde**: `lib/providers/schedule_provider.dart`, `lib/providers/class_schedule_provider.dart`
- **Qué pasaba**: Cada dispositivo solo veía los eventos guardados en su SQLite local. `loadSchedules()` nunca leía Supabase, `updateSchedule`/`deleteSchedule` no sincronizaban, y el INSERT de `addSchedule` fallaba en silencio: `color` ARGB (4286262670) excede el `INTEGER` de Postgres → error 22003 tragado por try/catch → nada llegaba a la nube. La tabla cloud tampoco tenía `user_id`.
- **Fix**: Sync bidireccional completo con merge por `cloudId` (columna nueva en SQLite v8 + índice único), realtime en ambas tablas, `update/delete` por cloudId como PK cloud, `userId: AppState.identity` al crear eventos, y migración SQL (`user_id` + `color` BIGINT + publicación realtime). Mismo patrón que el fix de `class_schedules` (color BIGINT) del 2026-08-08.
- **Lección**: El id local de SQLite nunca coincide con el BIGSERIAL de Supabase — persistir un `cloudId` aparte. Y ante "no se comparte", verificar primero si el INSERT cloud está fallando por rango de tipos (22003) antes de tocar la lógica de sync.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-14 (ejecutar `supabase/migration_schedules_sync.sql` en prod)

### ~~ALTA - StatefulBuilder resetea variables en dialogs de color~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/note/note_background_editor.dart` y `lib/screens/pizarra_v2/note/note_color_editor.dart`
- **Qué pasaba**: Los pickers de color para gradientes usaban `StatefulBuilder` con `Color picked = current;` dentro del builder. Cada rebuild del dialog reseteaba `picked` a `current`, perdiendo el color seleccionado. Al aceptar, el color era el inicial.
- **Fix**: Usar `StatefulWidget` propio (`GradientColorPicker`) con estado interno `_picked` que no se resetea entre rebuilds.
- **Lección**: `StatefulBuilder` recrea variables locales en cada invocación del builder; para estado que debe persistir entre frames, usar un `StatefulWidget` dedicado.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~ALTA - Memory leak: TextEditingController sin dispose~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/note/note_background_editor.dart:284`
- **Qué pasaba**: `TextField(controller: TextEditingController(text: ...))` creaba un nuevo controller en cada rebuild sin hacer dispose del anterior. Cada `setState` acumulaba controllers.
- **Fix**: `late final TextEditingController _patCtrl` inicializado en `initState`, actualizado vía `.text` en `didUpdateWidget`, con `dispose()`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~ALTA - Fonts no cargaban de Google Fonts~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/note/note_card_modal.dart` y `lib/screens/pizarra_v2/note/note_font_editor.dart`
- **Qué pasaba**: Nombres de fuente sin espacios (`'OpenSans'` en vez de `'Open Sans'`) y `fontFamily:` en `TextStyle` sin usar `GoogleFonts.getFont()`. Las fuentes nunca cargaban.
- **Fix**: Nombres corregidos + usar `GoogleFonts.getFont(fontName)` en los `TextField` del modal y en los chips del editor.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~ALTA - LateInitializationError en notificaciones locales en Windows~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/services/notification_service.dart:181`
- **Qué pasaba**: `_localNotifications.show()` lanzaba `LateInitializationError: Field '_instance' has not been initialized` en Windows porque `flutter_local_notifications` no tiene soporte completo en desktop.
- **Fix**: `_showLocalNotification` envuelta en `try-catch` + guard `if (!_initialized) return`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~MEDIA - Audio recorder no detenía al cerrar + archivos temporales huérfanos~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/note/note_audio_recorder.dart`
- **Qué pasaba**: Si se cerraba el modal mientras grababa, el `AudioRecorder` no se detenía y el archivo `.m4a` quedaba en `Directory.systemTemp`.
- **Fix**: `_recorder.stop()` en `dispose()` si está grabando + `_cleanupTempFile()` que borra el archivo si no se guardó.
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-08-12

### ~~ALTA - Canvas del pizarrón con boundaryMargin infinito causa bugs de render~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/pizarra_screen_v2.dart`
- **Qué pasaba**: `boundaryMargin: EdgeInsets.all(double.infinity)` y `SizedBox(width: 50000, height: 50000)` causaban inestabilidad en el `InteractiveViewer` en ciertas plataformas (Android low-end).
- **Fix**: Cambiado a `boundaryMargin: 5000` y `SizedBox(10000, 10000)`.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~CRÍTICA - Modificaciones offline de elementos existentes no se sincronizan~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/providers/board_provider_v2.dart`
- **Qué pasaba**: Editar un elemento ya sincronizado mientras se estaba offline guardaba el cambio en SQLite pero nunca lo subía a Supabase al volver online. El flag `synced` quedaba en 1 (de la sincronización inicial) y `_pushUnsyncedToCloud` solo busaba `synced=0`.
- **Fix**: `update()` y `moveLocal()` ahora marcan `synced=0` cuando están offline o cuando el cloud write falla. `_pushUnsyncedToCloud()` diferencia entre INSERT (sin id cloud) y UPDATE (con id cloud, modificado offline).
- **Lección**: Un elemento ya sincronizado tiene `synced=1`. Tras modificarlo offline hay que marcarlo explícitamente `synced=0` o el cambio nunca se retratará. `_pushUnsyncedToCloud` debe hacer UPDATE (no INSERT) para elementos que ya tienen id cloud.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-12

### ~~CRÍTICA - Reacciones simultáneas se pisan (race condition)~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/providers/board_provider_v2.dart` (realtime callback)
- **Qué pasaba**: Si Facu y Rocio reaccionaban con el mismo emoji casi al mismo tiempo, el `data` JSONB completo se enviaba en cada update y el último en llegar a Supabase pisaba al anterior. Solo una reacción quedaba.
- **Fix**: El callback de realtime ahora mergeea las reacciones del cloud con las locales (union de user_ids por key) en vez de reemplazar el data completo.
- **Lección**: El `data` JSONB se envía entero en cada update — dos updates concurrentes pisan el campo completo. El merge union de user_ids por key preserva ambas reacciones.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-12

### ~~CRÍTICA - Borrado de elemento no limpia conectores que lo referencian~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/providers/board_provider_v2.dart` (`delete()`)
- **Qué pasaba**: Al eliminar un elemento con conectores apuntando a él, los conectores quedaban huérfanos (invisibles pero en la BD).
- **Fix**: `delete()` ahora busca y elimina en cascada los conectores cuyo `fromId` o `toId` apuntan al elemento borrado (memoria + SQLite + cloud).
- **Lección**: Los conectores referencian elementos por `fromId`/`toId` en `data` JSONB — borrar un elemento sin limpiar sus conectores deja conectores fantasma.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-12

### ~~ALTA - Drag del elemento jitter con pan events rápidos~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/pizarra_screen_v2.dart`
- **Qué pasaba**: `onPanUpdate` usaba `el.x` (snapshot del build) + delta del frame actual. Si entre pan events no llegaba un rebuild, todos los events acumulaban delta sobre la posición vieja causando jitter.
- **Fix**: Usar `_liveElement(pv, el).x` y `.y` del elemento vivo en vez del snapshot.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~ALTA - isLocked se guarda pero nunca se valida~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/providers/board_provider_v2.dart`
- **Qué pasaba**: El modelo tenía `isLocked` y la BD lo persistía, pero `update()` y `moveLocal()` nunca verificaban este flag.
- **Fix**: Ambos métodos ahora chequean `isLocked` y retornan early si el elemento está bloqueado.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~ALTA - Búsqueda solo busca en el tablero actual~~ ✅ RESUELTO 2026-08-12
- **Dónde**: `lib/screens/pizarra_v2/widgets/board_search_panel.dart`
- **Qué pasaba**: `BoardSearchPanel` recibía `pv.elements` filtrado por `board_id`. No encontraba elementos en sub-tableros.
- **Fix**: `BoardSearchPanel` ahora recibe `provider` (BoardProviderV2), carga el pool cross-board en `initState` con `loadSearchPool()`. `_goToElement` cambia al tablero del elemento si está en otro board.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-12

### ~~ALTA - APK release compilaba "√ Built" pero quedaba SIN FIRMAR al quitar el signingConfig~~ ✅ RESUELTO 2026-08-10
- **Dónde**: `android/app/build.gradle.kts` (buildType release)
- **Qué pasaba**: Tras eliminar el keystore propio (firma CN=Furi) y dejar el buildType release **sin** `signingConfig`, el build compilaba "√ Built" pero el APK salía **completamente sin firmar**: `apksigner verify` → `DOES NOT VERIFY: Missing META-INF/MANIFEST.MF`, sin bloque de firma v2 (el EOCD del ZIP no tenía APK Signing Block) y META-INF sin `MANIFEST.MF`/`CERT.RSA`. El `app-debug.apk` del mismo proyecto sí verificaba (v2 scheme: true), así que no era del entorno: AGP simplemente no hizo el fallback automático a la firma debug en este proyecto.
- **Fix**: `release { signingConfig = signingConfigs.getByName("debug") }` explícito en `android/app/build.gradle.kts` → `apksigner verify --verbose` da `Verifies` con `v2 scheme: true`, signer `CN=Android Debug`.
- **Lección**: un APK "√ Built" puede no estar firmado; Android lo rechaza en la instalación con "aplicación no instalada" (o parsing error). Después de tocar cualquier config de firma hay que verificar SIEMPRE con `apksigner.bat verify --print-certs build\app\outputs\flutter-apk\app-release.apk` ANTES de mandárselo a un celular. No asumir el fallback de AGP a la firma debug.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-10

### ~~ALTA - Bot WhatsApp: "No hay sesión guardada" todo el día (SUPABASE_KEY invalidada, no era sesión)~~ ✅ RESUELTO 2026-08-08
- **Dónde**: `bot-furi/.env` + GitHub secret `SUPABASE_KEY`
- **Qué pasaba**: Cada corrida de CI (desde ~15:28 UTC) decía "No hay sesion guardada en Supabase", mostraba QR y moría por timeout. La sesión de WhatsApp estaba INTACTA en `bot_sessions` (104 claves, `creds.json` presente, `updated_at` 10:24 UTC ese mismo día). La causa: la `SUPABASE_KEY` del bot (local y CI) era la service role key vieja, invalidada por Supabase → toda query respondía `Unregistered API key`/`Invalid API key` → `loadSessionFromSupabase()` interpretaba el error como "no hay sesión" → pedía QR.
- **Fix**: usar una service role key nueva (provista por el usuario) en `.env` y en el secret `SUPABASE_KEY` de GitHub. La key vieja fue invalidada por Supabase ("Unregistered API key"). Verificado local (`node bot.js`: "Sesion cargada desde Supabase" → "Conectado a WhatsApp") y en CI manual. La sesión de WhatsApp jamás se reescaneó: seguía intacta en `bot_sessions`.
- **Lección**: un "No hay sesion guardada" NO siempre es sesión vencida — primero probar una query a `bot_sessions` con la key del `.env`. Si da `Invalid API key`/`Unregistered API key`, es la key, no el QR. No reescanear QR hasta descartar la key.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-08

### ~~ALTA - ClassSetupWizard aparecía siempre aunque la app nunca pudo subir las clases a Supabase (color fuera de rango)~~ ✅ RESUELTO 2026-08-08
- **Dónde**: `supabase/migration_class_schedules.sql` + tabla cloud `class_schedules`
- **Qué pasaba**: Las clases configuradas en el wizard se guardaban solo en SQLite local; ningún insert llegaba a la tabla cloud (quedó en `count = 0`). La causa: la columna `color` en la BD cloud era `INTEGER` (max 2147483647) pero `className` manda el color ARGB `0xFF7B2D8E` = **4286262670**, fuera de rango → Supabase responde `22003: value "4286262670" is out of range for type integer` y `_pushToSupabase()` (try/catch) lo traga silenciosamente → `cloudId` nunca se asigna → el sync nunca completa.
- **Fix**: `ALTER TABLE class_schedules ALTER COLUMN color TYPE BIGINT` (la migración idempotente ya lo incluye; `supabase_schema.sql` ahora crea `color BIGINT`).
- **Nota**: verificado con INSERT directo a la API REST (anon key) reproduciendo exactamente el error 22003. Con la columna en BIGINT, el próximo `loadSchedules()` (al abrir la app) sube las clases locales con `cloudId == null` automáticamente.
- **Prioridad**: ~~ALTA~~ → RESUELTO 2026-08-08 (ejecutar migración en prod)

### ~~ALTA - Bot WhatsApp: mensajes en cola que no se entregan (migración LID de WhatsApp)~~ ✅ RESUELTO 2026-08-11
- **Dónde**: `bot-furi/bot.js` + `lids.json` (nuevo)
- **Qué pasaba**: El bot "enviaba" (sendMessage resolvía) pero nadie recibía. Causa raíz: desde ~2026-08-10 WhatsApp migró el enrutamiento de contactos a IDs de dispositivo vinculado (`@lid`). Enviar al JID con número normal (`549...@s.whatsapp.net`) resolvía sin error pero el servidor NO entregaba (pérdida silenciosa, sin receipt). Síntoma observable: el log mostraba "sending message to 3 devices" (cuando antes decía 4) el día de la migración, y los ACKs dejaron de llegar. **No era** la sesión desincronizada ni las claves de cifrado: la sesión tenía las claves LID y aún así no entregaba — el bloqueo era del JID destino, no de las claves.
- **Fix**: (1) Resolver LIDs con `sock.onWhatsApp(numero)` en una **conexión descartable** (`resolverLidsSolo()`) que se ejecuta ANTES de la conexión principal. `onWhatsApp()` devuelve `lid: "83189842346022@lid"` (con sufijo incluido) pero puede romper el stream (`stream:error xml-not-well-formed`, bug de Baileys reproducible 2 de 3 veces); al ejecutarlo en una conexión aparte la conexión principal queda sana. (2) Cachear LIDs en `lids.json` (persistido, gitignored) para no depender de llamar a onWhatsApp en cada corrida. (3) `enviarMensaje()` usa SOLO el cache de LIDs (nunca llama onWhatsApp en la conexión principal). (4) `esperarAck()` hace flush periódico del event buffer de Baileys cada 2s para liberar `messages.update` retenidos durante `AwaitingInitialSync`. (5) Los LIDs se guardan normalizados (con `@lid`) y se usan directamente como JID destino en `sendMessage`.
- **Verificación**: mood de prueba → mensaje enviado al JID LID de Facu (`83189842346022@lid`) → ACK `status=4` (leído) → registro marcado en `bot_notificaciones` → limpieza del dato de prueba.
- **Lección**: El fix definitivo NO era re-vincular WhatsApp (borrar `auth/` + re-escanear QR): esa sesión tenía las claves LID de los contactos y aún así no entregaba. El bloqueo era del JID destino, no de las claves de cifrado. Los LIDs de los contactos NO están embebidos en la sesión — se obtienen con una query a WhatsApp (`onWhatsApp`), y una vez resueltos se cachean para no repetir la query (que puede romper el stream).

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
- **Nota**: Para DBs ya existentes en prod, ejecutar las migraciones en `supabase/` (`migration_class_schedules.sql`, `migration_gallery_comments.sql`, `migration_goals_completed_by.sql`, `migration_seen_system.sql`, `migration_favorites_dual_rating.sql`, `migration_chat_media_reactions.sql`). ~~**Todas las migraciones ejecutadas en SQL Editor** ✅ 2026-08-31.
- **Prioridad**: ~~CRÍTICA~~ → RESUELTO 2026-08-06 (schema master listo; todas las migraciones ejecutadas en SQL Editor ✅ 2026-08-31)

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

### ~~MEDIA - Sin sistema de rutas~~ ✅ RESUELTO 2026-08-26
- **Dónde**: `lib/screens/` (navegación con push/pop directo)
- **Qué pasaba**: Navigator.of(context).push(MaterialPageRoute(...)) en todas partes — sin rutas nombradas centralizadas, difícil navegación profunda y testing.
- **Fix**: Implementado **GoRouter** (`lib/router.dart`) con route table centralizado de 22 rutas + `MaterialApp.router`. Los ~30 push dispersos se rewiringaron a `context.push`/`context.go` (ver historial 2026-08-26).
- **Prioridad**: ~~MEDIA~~ → RESUELTO 2026-08-26

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

### ~~MIGRACIONES~~ ✅ TODAS EJECUTADAS EN SQL EDITOR — 2026-08-31
- **Qué pasaba**: El repo contenía ~24 archivos de migración SQL en `supabase/` que nunca se ejecutaron en el entorno de producción de Supabase. Sin la ejecución, las tablas, columnas, RLS policies, realtime subscriptions y Edge Function triggers no existían en la nube, lo que hacía que funcionalidades como push FCM a goals/challenges, reacciones en chat, sync de calendario entre usuarios, clases recurrentes en Supabase, y el webhook de tiempo real del bot WhatsApp **no operaran**.
- **Fix**: Se ejecutaron **todas las migraciones** en el SQL Editor de Supabase en una sesión única el 2026-08-31:
  - `migration_schedules_sync.sql` — sync de eventos con user_id + color BIGINT + realtime
  - `migration_class_schedules.sql` — tabla class_schedules en cloud + color BIGINT
  - `migration_push_categories.sql` — 18 triggers AFTER INSERT para push FCM a todos los tipos
  - `migration_board_v2.sql` — tablas board_elements_v2 + boards + realtime
  - `migration_reaction_rpc.sql` — RPCs toggle_reaction + react_deck_card con row-level lock
  - `migration_chat_media_reactions.sql` — 7 columnas nuevas en messages + delivered_at/read_at
  - `migration_gallery_comments.sql` — tabla gallery_comments + realtime
  - `migration_goals_completed_by.sql` — columna completed_by en goals
  - `migration_seen_system.sql` — columna seen_by en letters + challenges
  - `migration_favorites_dual_rating.sql` — rating_facu/rating_rocio/critica + migración legacy
  - `migration_trivia.sql` — options JSONB + guess en question_answers
  - `migration_rewards.sql` — tablas couple_rewards + couple_points
  - `migration_couple_achievements.sql` — tabla couple_achievements
  - `migration_couple_locations.sql` — tabla couple_locations + haversine
  - `migration_bot_webhook.sql` — función furi_trigger_bot() + triggers pg_net
  - `migration_device_tokens_unique.sql` — índice único device_tokens
  - `migration_chat_typing.sql` — tabla chat_typing + realtime
  - `migration_notifications_realtime.sql` — tabla notifications en supabase_realtime
  - `migration_board_milanote.sql` — bucket board-media + columnas z/data
  - `supabase/schema.sql` — schema maestro consolidado con TODAS las tablas
  - `supabase/functions/send-push/index.ts` — deploy vía Management API (v5, poda UNREGISTERED)
  - `bot-furi/bot.js` — LID fix + ventana dinámica + persistencia de LIDs en session_data
- **Lección**: Las migraciones SQL son inútiles si no se ejecutan en prod. El código Dart referencia tablas/columnas/RPCs que no existen sin la ejecución. Había ~19 items marcados como "Pendiente: ejecutar en SQL Editor" en errores-conocidos.md e historial.md — todos resueltos.
- **Impacto**: Todas las funcionalidades de Supabase ahora operan en la nube. Push FCM → goals/challenges ✓, reacciones en chat ✓, sync calendario entre usuarios ✓, clases en Supabase ✓, webhook pg_net ✓, racha de pareja ✓, logros ✓, recompensas ✓, trivia ✓, mapa/distancia ✓.
- **Prioridad**: ~~MIGRACIONES PENDIENTES~~ → ✅ TODAS EJECUTADAS 2026-08-31
