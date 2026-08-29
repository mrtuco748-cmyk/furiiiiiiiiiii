# Historial de Cambios y Aprendices y Aprendizajes

## [2026-08-29] - BUGFIX - Pizarra v2: fixes de sincronizaci�n y race conditions

**Resumen**: Auditor�a completa del provider BoardProviderV2 y widget BoardElementOptions corrigiendo 8 bugs cr�ticos/altos que afectaban la consistencia de datos en tiempo real, eliminaci�n de elementos, reacciones y manejo de estado offline.

**Cambios realizados**:

1. **`isLocked` validation** (`board_provider_v2.dart:moveLocal()`, `update()`, `delete()`) - Bloquea ediciones/moves/deletes en elementos bloqueados (`isLocked == true`), evitando modificaciones no autorizadas.

2. **Cascade-delete for connectors** - `delete()` ahora elimina conectores cuyos `fromId`/`toId` apuntan al elemento borrado, evitando conectores huérfanos invisibles en la BD.

3. **Cascade-delete for comments** - `delete()` ahora elimina comentarios que reply (directa o transitivamente) al elemento borrado usando nuevos m�todos `_findCommentsRepliedTo()` y `_findCommentsRepliedToHelper()`.

4. **Partial merge in `_syncFromCloud()`** - Cambio de reemplazo completo a merge parcial que preserva campos sucios locales (x, y, title, color, priority, z, updatedAt) cuando elemento est� `synced=0` (modificado offline), evitando que ediciones offline se pierdan.

5. **Reaction limit feedback** (`board_element_options.dart:react()`) - SnackBar "Máximo 5 reacciones por elemento" cuando se alcanza el l�mite, `setSheetState(() {})` para refrescar sheet, try-catch con SnackBar de error en fallo del servidor.

6. **SQL migration executed** - `supabase/migration_reaction_rpc.sql`: creaci�n de RPCs `toggle_reaction` y `react_deck_card` con row-level lock para merge at�mico de reacciones JSONB, resolviendo la race condition donde dos usuarios reaccionando simultneamente pisaban el cambio del otro.

7. **Drag jitter fix** - Ya presente en c�digo: `onPanUpdate` usa `_liveElement(pv, el)` en vez del snapshot `el`, previniendo jitter en drags r�pidos.

8. **Local `_commentsOf` helper** - Agregado a `board_provider_v2.dart` para extraer comentarios del datos del elemento (reemplazando referencia a `BoardSocialData.commentsOf` que ten�a problemas de dependencia circular).

9. **`synced` column added to Supabase schema** - Agregado a `supabase_schema.sql` y `supabase/migration_board_v2.sql` (idempotente con chequeo `IF NOT EXISTS` usando bloque `DO $$ ... $$`).

**Archivos modificados**:
- `lib/providers/board_provider_v2.dart` - L�gica principal del provider
- `supabase/migration_board_v2.sql` - Migraci�n para DBs existentes
- `supabase_schema.sql` - Esquema maestro en la nube
- `lib/screens/pizarra_v2/widgets/board_element_options.dart` - UI de reacciones

**Lecciones**:
- El merge client-side en realtime (parche previo) NO garantiza consistencia en el servidor: el UPDATE final con mapa completo siempre puede pisar al concurrente. La RPC con `FOR UPDATE` es la defensa real en el origen.
- `isLocked` se persist�a pero nunca se validaba - agregar el check en `update()` y `moveLocal()` es suficiente (el delete ya lo ten�a con confirmaci�n UI).
- El pattern dirty-flag (`synced`) es robusto para no perder ediciones offline: el push fallido marca la fila, y la siguiente carga la re-intenta.
- `BoardSocialData` tiene problemas de importaci�n circular - es m�s seguro agregar helpers locales en el provider.
- `flutter analyze` deja de reportar `undefined_identifier` despu�s de reemplazar `BoardSocialData.commentsOf` con helper propio `_commentsOf`.

**Impacto**: `lib/providers/board_provider_v2.dart`, `supabase/migration_board_v2.sql`, `supabase_schema.sql`, `lib/screens/pizarra_v2/widgets/board_element_options.dart`.

# Historial de Cambios y Aprendizes y Aprendizajes

**Resumen**: Se corrigi� el panel de notificaciones para que est� oculto por defecto y solo aparezca con animaci�n al deslizar el bot�n superior izquierdo. Se agreg� un panel de acceso r�pido configurable (engranaje) con iconos personalizables. Se elimin� el color verde lima de la secci�n de Ejercicios. Se restaur� settings_screen.dart corrupto por PowerShell.

**Cambios realizados**:
- lib/screens/home_screen.dart: _NotificationPanel ahora retorna SizedBox.shrink() cuando no est� visible; se agreg� _notifPanelKey, _openNotificationDrawer() con l�gica de apertura/cierre, m�todos _openShortcutPanel()/_closeShortcutPanel(), _NotificationPanel constructor acepta Key? y m�todo refresh(), _ShortcutPanel widget con grid de accesos r�pidos y bot�n de configuraci�n, _scBtn() y _scItem() helpers para el panel de accesos, _openShortcutConfig() y _navigateToShortcut() en _BrutalGridState, _saveShortcut() para persistir atajo en SharedPreferences, _handleBack y _canPop actualizados para incluir _shortcutPanelOpen.
- lib/screens/home_screen.dart: bot�n de ejercicios cambiado de Color(0xFF39FF14) (verde lima) a t.e.
- lib/screens/ejercicios/ejercicios_screen.dart: _lima (Color(0xFF39FF14)) reemplazado por _cyan (Color(0xFF00D4FF)); _panel, _panelLight, _darkText cambiados de verdes a tonos cian/azul oscuro para eliminar verde de la secci�n.
- lib/screens/settings_screen.dart: restaurado desde git (el PowerShell Set-Content anterior lo hab�a corrompido agregando entradas fantasma de Volumen M�sica, Volumen Efectos, Tema y Configurar Atajo con referencias a _openShortcutConfig inexistente).
- test/models/couple_achievement_test.dart: las pruebas de earnedCodes ya usaban contains() en vez de sets exactos; el snapshot combinado usa datos correctos. Todos los 55 tests pasan.

**Lecciones**: El panel de notificaciones y el de acceso r�pido comparten el patr�n de overlay con SizedBox.shrink() condicional + GlobalKey para el refresh. El color verde #39FF14 es para el bot�n de ejercicios (pesa) y el acento de la secci�n, pero no para el fondo del panel o del header. El archivo settings_screen.dart fue corrompido por el PowerShell Set-Content de la sesi�n anterior, que colaps� la estructura del archivo; restaurar desde git resolvi� el problema.

**Impacto**: lib/screens/home_screen.dart, lib/screens/ejercicios/ejercicios_screen.dart, lib/screens/settings_screen.dart, test/models/couple_achievement_test.dart, docs/contexto/historial.md.
## [2026-08-29] - BUGFIX - Notificaciones no se actualizan en tiempo real ni se almacenan en tabla notifications

**Resumen**: El panel de notificaciones no mostraba las notificaciones nuevas. La tabla 
otifications no tenia suscripcion realtime, las notificaciones push recibidas por FCM no se almacenaban en la tabla, y el panel no se refrescaba automaticamente.

**Cambios realizados**:
- lib/services/notification_service.dart: agregado _notifChannel y onNewNotification callback, metodo startListeningNotifications(), _storePushNotification() para guardar push en la tabla, startListening() ahora llama a startListeningNotifications().
- lib/screens/home_screen.dart: _NotificationPanelState conecta onNewNotification a _load() para auto-refrescar.
- supabase/migration_notifications_realtime.sql (nuevo): agrega 
otifications a supabase_realtime.
- supabase_schema.sql: agregado ALTER PUBLICATION supabase_realtime ADD TABLE notifications.

**Lecciones**: sin realtime en 
otifications el panel no se actualiza. Los push FCM deben persistirse en la tabla 
otifications.

**Impacto**: lib/services/notification_service.dart, lib/screens/home_screen.dart, supabase/migration_notifications_realtime.sql, supabase_schema.sql.

## [2026-08-28] - BUGFIX - M�sica de fondo se detiene al background/exit

**Resumen**: Se a�adi� manejo del ciclo de vida de la aplicaci�n usando `WidgetsBindingObserver`. Ahora la m�sica de fondo se detiene cuando la app se env�a al background o se cierra, y se reanuda al volver a primer plano.

**Cambios realizados**:
- `lib/main.dart`: convertido `FuriApp` a `StatefulWidget`, implementado `WidgetsBindingObserver`. A�adido `didChangeAppLifecycleState` que llama a `SoundService().stopBackgroundMusic()` en estados `paused`/`detached` y a `SoundService().startBackgroundMusic()` en `resumed`. Registrado y removido el observer en `initState`/`dispose`.
- `lib/services/sound_service.dart`: comentarios actualizados para clarificar el uso de `_bgPlayer` (m�sica de fondo) y `_player` (efectos sonoros).

**Lecciones**:
- `WidgetsBindingObserver` es la forma recomendada en Flutter para responder a eventos de ciclo de vida del app en Android/iOS.
- Detener la m�sica en `paused` evita reproducci�n no deseada cuando el usuario abandona la app.
- Reiniciar en `resumed` restaura la experiencia sin intervenci�n del usuario.

**Impacto**: `lib/main.dart`, `lib/services/sound_service.dart`.

**Relacionado con**: BUGFIX - M�sica de fondo cortada por SFX, FEATURE - UI lifecycle handling, docs/contexto/arquitectura.md (secci�n ciclo de vida).


## [2026-08-28] - BUGFIX - Notas en pizarra v2 no aparec�an hasta deslizar el dedo
**Resumen**: Las notas de la pizarra no se mostraban inicialmente al cargar. Esto ocurr�a por una descoordinaci�n de sistemas de coordenadas: `_visibleRect` (usado para la virtualizaci�n) se calculaba en un espacio sin el desplazamiento din�mico de `worldBounds`, mientras que `_elementVisible` comparaba contra las coordenadas absolutas. Al deslizar el dedo, un error de redondeo o actualizaci�n del transform destrababa la vista, pero la culling function cortaba los elementos inicialmente.
**Cambios realizados**:
- `pizarra_screen_v2.dart`: 
  - Se a�adi� un `Transform.translate` con `Offset(world.left, world.top)` envolviendo al `SizedBox` del `InteractiveViewer`.
  - Se cambi� `boundaryMargin` a `EdgeInsets.all(double.infinity)` para permitir paneo infinito seguro.
  - Se modific� `_elementVisible` para restar `world.left` y `world.top` a las coordenadas del elemento al instanciar su `Rect`, alineando correctamente ambos sistemas de coordenadas.
**Lecciones**:
- Al usar Virtualizaci�n + InteractiveViewer + Bounds din�micos, el viewport devuelto por la matriz de transformaci�n del viewer y las coordenadas absolutas de los elementos deben referenciarse al mismo origen.
**Impacto**: `lib/screens/pizarra_v2/pizarra_screen_v2.dart`.
**Relacionado con**: Errores conocidos, pizarra v2.

## [2026-08-28] - FEATURE - Panel de notificaciones y bot�n de atajo en HomeScreen
**Resumen**: Se redise�� el comportamiento de los botones del bloque izquierdo del Home. El bot�n superior (amarillo) ahora abre el panel de notificaciones directamente al tocarlo (en vez de deslizar). El panel se dimension� para ocupar exactamente la altura del bot�n superior. El bot�n inferior (cyan) se transform� en un "atajo r�pido" configurable.
**Cambios realizados**:
- `home_screen.dart`:
  - Se modific� `LeftButtons` para recibir `onTopTap`, `onBottomTap`, `shortcutIcon` y `onShortcutConfigTap`.
  - El panel de notificaciones `_notificationDrawer` se ajust� para posicionarse a la derecha de la barra izquierda y tener un alto igual al bot�n superior.
  - Se agreg� l�gica en `_BrutalGridState` (SharedPreferences) para guardar y cargar `home_shortcut_route`.
  - Se agreg� `_openShortcutConfig` con un `AlertDialog` estilo F.U.R.I. (bordes s�lidos redondeados) para elegir entre las opciones de la app (Mazo, Poemas, Ejercicios, Finanzas, Calendario, etc).
  - El bot�n inferior muestra un gran `+` cuando no hay atajo configurado, o el icono elegido con un `+` peque�o en la esquina para poder cambiarlo.
**Lecciones**:
- Al restringir un panel (como el de notificaciones) para que encaje en el espacio exacto de otro widget, calcular el alto basado en los mismos m�rgenes `(leftBlockHeight - 6) / 2` mantiene todo alineado sin usar LayoutBuilders extra�os.
**Impacto**: `lib/screens/home_screen.dart`.
**Relacionado con**: Experiencia de usuario, notificaciones.

## [2026-08-28] - BUGFIX - Sync de calendario/clases entre usuarios (migraci�n combinada ejecutada en prod)
**Resumen**: Las clases y eventos no se guardaban en Supabase ni se ve�an entre Facu y Rocio (cada dispositivo solo ve�a lo suyo). El c�digo Dart ya hacia push/pull/realtime con las columnas correctas, as� que la causa era la DB: `schedules` sin `user_id`, `color` en `INTEGER` (rechazaba el ARGB 4286262670 con 22003), y ambas tablas sin RLS permisivo ni en la publicaci�n realtime. Se combinaron las 3 migraciones sueltas en un �nico `.sql` idempotente para ejecutar manualmente en el SQL Editor.
**Cambios realizados**:
- `supabase/migration_calendar_full.sql` (nuevo): ORDER correcto e idempotente � (1) `CREATE TABLE class_schedules` + `color BIGINT` + �ndice; (2) `ALTER schedules ADD user_id` + `color BIGINT` + ambas a `supabase_realtime`; (3) RLS `full_access` + `GRANT` anon/authenticated + `ADD TABLE` realtime con manejo `duplicate_object`. Une `migration_schedules_sync.sql`, `migration_class_schedules.sql` y `migration_schedule_class_sync.sql`.
- Verificaci�n previa: `flutter analyze` de `schedule_provider.dart`/`class_schedule_provider.dart` sin errores; el token legacy `sbp_` autentica el proyecto (GET 200) pero el endpoint `database/query` de la Management API exige un PAT JWT (el legacy da 401), por eso se opt� por SQL para correr manualmente.
**Lecciones**:
- El endpoint `database/query` de la Management API NO acepta el API key legacy `sbp_...` (sin puntos): da `401 JWT could not be decoded`. Para correr DDL v�a API hay que generar un PAT en formato JWT (con puntos) o usar la connection string de la BD. El `functions/deploy` s� acepta el legacy.
- Cuando el provider ya hace pull de TODAS las filas y el otro usuario no ve nada, el origen es RLS/publicaci�n realtime en la DB, no el c�digo: un `DROP POLICY`+`CREATE full_access` + `ADD TABLE` a `supabase_realtime` lo resuelve.
**Impacto**: `supabase/migration_calendar_full.sql` (nuevo), historial. Docs.
**Relacionado con**: D-2 (Supabase), errores-conocidos (sync calendario), glosario.

## [2026-08-28] - BUGFIX - M�sica de fondo cortada por SFX (audioplayers 6.8.1)
**Resumen**: Al entrar a una pantalla o tocar un bot�n (TapTile dispara `SoundService().click()`), la m�sica de fondo en bucle se cortaba. Causa: el reproductor de SFX y el de fondo son dos `AudioPlayer` separados; en Android el SFX ped�a foco de audio exclusivo (`gain`) por defecto, lo que pausaba al reproductor de fondo.
**Cambios realizados**:
- `lib/services/sound_service.dart`: se crearon dos `AudioContext` expl�citos y se aplican con `setAudioContext` antes de cada `play()`:
  - `_sfxContext`: `AudioContextAndroid(audioFocus: AndroidAudioFocus.gainTransientMayDuck)` ? el SFX "ducka" (baja un instante) la m�sica en vez de pausarla; en iOS `AVAudioSessionCategory.playback` + `mixWithOthers`.
  - `_bgContext`: `AudioContextAndroid(audioFocus: AndroidAudioFocus.gain)` + iOS `mixWithOthers` para mantener el loop.
  - `_play()` ahora hace `setAudioContext(_sfxContext)` antes del `play`; `startBackgroundMusic()` lo hace con `_bgContext`.
- API corregida a la superficie real de `audioplayers 6.8.1` / `audioplayers_platform_interface 7.2.0`: par�metro `audioFocus` (no `focus`), `iOS` (no `ios`), y valores `AndroidAudioFocus.gain` / `AndroidAudioFocus.gainTransientMayDuck` (no `requestGain*`).
**Lecciones**:
- En `AudioContextAndroid` de audioplayers 6.8.1 el campo es `audioFocus` y el enum usa nombres sin prefijo `request` (`gainTransientMayDuck`, `gain`). El param del `AudioContext` para iOS es `iOS` (case-sensitive), no `ios`.
- Dos `AudioPlayer` distintos comparten el `AudioManager` de Android: si el SFX no pide `gainTransientMayDuck`, el sistema le da foco exclusivo y pausa el reproductor de fondo. El ducking es la cura.
- `setAudioContext` debe llamarse antes de `play()` en cada reproductor; no basta con setearlo una vez global.
**Impacto**: `lib/services/sound_service.dart`, docs.

## [2026-08-28] - FEATURE - Trivia: crear preguntas + historial de respuestas en la pantalla "loca"
**Resumen**: La pantalla de Trivia (sistema "loca") solo permit�a responder la pregunta del d�a. Se agregaron dos tiles nuevos: "Agregar" (crear una pregunta con 4 opciones) y "Historial" (lista de mis respuestas con la predicci�n, la respuesta real de la pareja y si acert�). Todo sincronizado en tiempo real.
**Cambios realizados**:
- `lib/providers/trivia_provider.dart`: nuevo `addQuestion({question, options})` (insert en `daily_questions` + recarga local + retorna bool); `_reloadQuestions()` + segundo `onPostgresChanges` en `_subscribeRealtime()` sobre `_qTable` (realtime de preguntas).
- `lib/screens/trivia/trivia_screen.dart`: entries `Agregar` (panel 1) e `Historial` (panel 2) con `label`; `_addQuestionPanel` (header + `_AddQuestionPanel` StatefulWidget: textarea pregunta + 4 campos opci�n + bot�n check que valida =2 opciones y llama `addQuestion`, con `AppFeedback.saved/error`); `_historyPanel` lista mis `question_answers` (orden por fecha desc) con `_historyRow` que muestra pregunta, mi respuesta, mi predicci�n, respuesta de la pareja y badge "Acertaste!/No acertaste" cuando ambos respondieron.
- Tests: `test/models/trivia_test.dart` (12) en verde; `flutter analyze` sin issues en los 2 archivos.
**Lecciones**:
- Un panel de LocaScreen puede recibir un formulario completo (StatefulWidget interno) sin romper el patr�n swink; el `close` del builder cierra el panel.
- `separatorBuilder` de `ListView.separated` exige firma `(BuildContext, int)`; un lambda de un par�metro no es asignable en el analyzer estricto de Flutter 3.44.
- `AppFeedback.saved/error` requieren `BuildContext` como primer argumento (no solo el texto).
**Impacto**: `trivia_provider.dart`, `trivia_screen.dart`, docs.

## [2026-08-28] - FEATURE - Cache local offline-first: Tanda 2 #4 (favoritos/recompensas/notificaciones/galer�a/logros/mapa)
**Resumen**: Continuaci�n de la Tanda 2 de auditor�a. Se extendi� el `LocalCache` (helper de "�ltimos datos conocidos" en SharedPreferences) a las 6 secciones que faltaban: Favoritos, Recompensas, Notificaciones, Galer�a, Logros de pareja y Mapa/Distancia. Al entrar, cada secci�n muestra el cache instant�neamente (sin tile/spinner de carga) y luego sincroniza con Supabase sobrescribiendo el cache con los datos frescos. Todo en Dart, sin migraciones SQL.
**Cambios realizados**:
- `lib/services/local_cache.dart`: `getList` ahora devuelve `List<Map>` NO-nulable (vac�o `[]` si no hay cache / error) para simplificar todos los call sites (antes devolv�a `List?` y obligaba a null-checks).
- `lib/providers/favorites_provider.dart`: `load()` siembra `_items` desde `cache_favorites` antes del fetch; tras el fetch exitoso hace `LocalCache.setList('cache_favorites', _items.map(toMap))`.
- `lib/providers/rewards_provider.dart`: `load()` siembra `_rewards` (desde `cache_rewards`) y `_points` (desde `cache_points`) antes del fetch; persiste ambos tras `_loadRewards`/`_loadPoints`.
- `lib/providers/gallery_provider.dart`: `load()` siembra `_items` desde `cache_gallery`; persiste tras fetch.
- `lib/providers/couple_achievements_provider.dart`: `load()` siembra `_earned` desde `cache_logros`; persiste tras `_loadEarned`.
- `lib/providers/location_provider.dart`: `load()` siembra `_locations` desde `cache_locations`; persiste tras fetch (eliminado el comentario "Sin cache local").
- `lib/services/notification_service.dart`: `getNotifications()` (service est�tico, usado por Home y Notificaciones) ahora siembra desde `cache_notifications` y devuelve el cache al instante mientras refresca en background (`_refreshNotificationsCache`); en fallo de red devuelve el cache.
**Lecciones**:
- El cache local offline-first a nivel de provider/service es un primer paso de bajo riesgo: mostr�s el cache y lo reemplaz�s con el fetch. No bufferea escrituras offline (eso queda para SQLite+dirty-flag en otra sesi�n).
- `LocalCache.getList` no-nulable evita repetici�n de `?.`/`!` en los 6 call sites y mata los `unchecked_use_of_nullable_value` del analyzer.
- Las notificaciones viven en un `NotificationService` (no en un provider), as� que el cache se aplic� en el m�todo est�tico `getNotifications` con refresco en background en vez de bloquear el await.
- Las 6 secciones ya ten�an realtime (Tanda 1 / Tanda 2 #1-#3), as� que el cache es solo la capa de "entrada instant�nea"; el realtime sigue cubriendo los cambios en vivo.
**Nota de validaci�n (correcci�n de una falsa alarma)**: al revisar, los 2 "errores de compilaci�n" reportados (`sound_service.dart` con `focus`/`ios` y `trivia_screen.dart` con `separatorBuilder: (_)`) NO exist�an en el c�digo real � ambos archivos ya usaban la sintaxis correcta (`audioFocus`/`iOS` y `separatorBuilder: (c, i)`). Eran un **kernel de compilaci�n en cach�** de una versi�n anterior de los archivos. Al re-ejecutar `flutter test` se forz� la recompilaci�n y el suite carg� completo: **243 tests en verde**. No hubo que editar c�digo para ello. El `flutter analyze` de los 7 archivos tocados por este cambio pasa limpio (solo `avoid_print` info preexistentes en notification_service).
**Impacto**: `local_cache.dart`, `favorites_provider.dart`, `rewards_provider.dart`, `gallery_provider.dart`, `couple_achievements_provider.dart`, `location_provider.dart`, `notification_service.dart`, docs.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite/offline), Tanda 2 #1-#3, an�lisis de uso en pareja.

## [2026-08-28] - BUGFIX - Swinks y swaps no reproduc�an sonido
**Resumen**: Las transiciones swink (apertura de panel en las pantallas "loca") y swap (intercambio icono?contenido de `SwapWidget`) no emit�an ning�n sonido. El m�todo `SoundService.swoosh()` exist�a pero nunca se invocaba.
**Cambios realizados**:
- `lib/widgets/swap_widget.dart`: `_showSwapContent()` ahora llama `SoundService().swoosh()` al mostrar el contenido del swap (cubre todas las pantallas que usan `SwapWidget`, incluida Nosotros).
- `lib/widgets/loca_screen.dart`: `_open()` (apertura del panel swink) ahora llama `SoundService().swoosh()`.
**Lecciones**:
- Los m�todos de sonido que nadie invoca son silencio asegurado: un `swoosh()` definido pero sin call site no suena. Para que un efecto de UI tenga audio, el widget que ejecuta la transici�n debe disparar el `SoundService` expl�citamente (el `TapTile` solo dispara `click()` en el tap, no en la animaci�n de apertura/swap).
- El `onSwapShow` de `SwapWidget` es un callback de datos (cargar el �tem a mostrar), no de audio; el sonido va aparte del callback.
**Impacto**: `swap_widget.dart`, `loca_screen.dart`, docs.

## [2026-08-28] - FEATURE - Push FCM para TODAS las categor�as (adicional al bot de WhatsApp)
**Resumen**: El usuario pidi� que, adem�s de los avisos por WhatsApp del bot, llegue una notificaci�n push FCM a la pareja para cada categor�a: cartas, retos, eventos, clases, favoritos/pelis-juegos, emociones, metas, notas, fotos, tareas, transacciones, timeline, mazo, custom_questions y workout_*. Se cre� una migraci�n SQL que replica el patr�n de `notify_new_message()` (`pg_net` ? `/functions/v1/send-push`) con triggers `AFTER INSERT` por tabla.
**Cambios realizados**:
- `supabase/migration_push_categories.sql` (nuevo, idempotente): helpers `furi_push` (env�a a un UUID concreto v�a `send-push`), `furi_resolve_partner` (mapea el autor a la pareja: si el `user_id` es UUID usa `profiles.partner_id`, si es texto identidad `'Facu'/'Rocio'` usa `profiles.name` � confirmado con el usuario), `furi_notify_partner` (pareja del autor), `furi_notify_couple` (ambos miembros por `couple_id`, para goals/challenges), `furi_notify_all` (todos los perfiles, para logros). 18 triggers `AFTER INSERT` sobre `letters` (al `to_user`), `moods`, `goals`, `challenges`, `custom_questions` (al `to_user`), `notes`, `tasks`, `transactions`, `favorites`, `gallery`, `timeline_events`, `schedules`, `class_schedules`, `deck_cards`, `couple_achievements`, `workout_logs`, `workout_completions`, `workout_challenges`. Cada push lleva `data.type` para que la app enrute.
- Sigue usando la anon key publishable hardcodeada (igual que `notify_new_message`) y el endpoint `send-push` ya desplegado (versi�n 5).
**Lecciones**:
- El autor vive en dos formatos distintos: UUID (`user_id REFERENCES profiles`) en unas tablas y texto identidad (`AppState.identity`) en otras (notes, tasks, transactions, favorites, gallery, timeline_events, schedules, class_schedules, deck_cards). Para llegar al token FCM (que se registra con el UUID de `profiles`) hay que resolver la pareja; `furi_resolve_partner` prueba UUID y cae a `profiles.name`.
- Los `couple_id` de goals/challenges referencian a UNO de los dos profiles; los dos miembros se obtienen como `{couple_id, partner_id de ese profile}`.
- `net.http_post` es fire-and-forget (igual que el trigger de chat): el trigger no espera respuesta, as� no bloquea el INSERT.
**Pendiente (acci�n manual del usuario)**: ejecutar `supabase/migration_push_categories.sql` en el SQL Editor de Supabase. Sin esto, solo el chat dispara push (el trigger `notify_new_message` ya exist�a). El bot de WhatsApp sigue cubriendo lo mismo por su lado.
**Impacto**: `supabase/migration_push_categories.sql` (nuevo), docs. No toca c�digo Dart (el cliente ya registra `device_tokens` con `AppState.myId`).
**Relacionado con**: D-7 (FCM), D-2 (Supabase), errores-conocidos (send-push deployado), bot-whatsapp.md.

## [2026-08-28] - BUGFIX - Deploy de Edge Function send-push (Management API, sin supabase CLI)
**Resumen**: La tarea pendiente de la tanda de Push FCM (2026-08-28) era desplegar `send-push` a Supabase, sin lo cual la poda de tokens `UNREGISTERED` no corr�a en la nube. No hay `supabase` CLI en esta m�quina, as� que se us� la Management API (`POST /v1/projects/{ref}/functions/deploy?slug=send-push`) con el PAT de cuenta.
**Cambios realizados**:
- La API de deploy espera `multipart/form-data` con dos partes: `metadata` (JSON `{"name","entrypoint_path":"index.ts","verify_jwt":false}`) y `file` cuyo **contenido es el c�digo fuente literal** de `index.ts` (filename `index.ts`, `Content-Type: application/typescript`). NO se debe empaquetar un tar.gz ni un zip: el servidor lee el `file` como el source del entrypoint (un zip subido como `file` se interpret� como el source y dio `Could not be parsed: PK...`). Funciona: `STATUS 201`, `status: ACTIVE`, `version: 5`.
- `supabase/functions/send-push/index.ts` ya filtra tokens `created_at >= ahora-90d` y poda `UNREGISTERED` al recibir el error de FCM (c�digo de la tanda previa).
**Lecciones**:
- El Management API de deploy de Edge Functions toma el `file` como el source del entrypoint, no como un archivo comprimido: subir el `.ts` como texto plano. Empaquetar zip/tar.gz dispara "Failed to bundle (Could not be parsed: PK...)" porque el binario del zip se trata como el c�digo.
- El API key de gesti�n es el `sbp_...` (PAT de cuenta), distinto de la `SUPABASE_KEY` (service/anon) usada por el cliente/el bot.
- `entrypoint_path` relativo al `file` subido (`index.ts`), no a una carpeta.
**Impacto**: `supabase/functions/send-push/index.ts` (ya existente), deploy en prod. Cierra el pendiente de la entrada 2026-08-28 (Push FCM).
**Relacionado con**: D-7 (FCM), errores-conocidos (tokens FCM muertos ? ahora con poda en la nube activa).

## [2026-08-28] - BUGFIX - Tanda 2: realtime no pisa estado optimista (favoritos/recompensas/chat/pizarra)
**Resumen**: Tanda 1 cubri� 6 bugs de flujo de datos (finanzas, cartas, trivia, racha, nosotros, galer�a). Tanda 2 corrige 3 bugs restantes donde el realtime o el debounce pisaban el estado local optimista o dejaban timers colgados. Todo en Dart (sin migraciones SQL).
**Cambios realizados**:
- `lib/providers/favorites_provider.dart` + `rewards_provider.dart`: el callback de realtime (`applyRealtimeRow`/`_mergeOne`/`_mergeReward`/`_mergeEntry`) ahora hace MERGE por fila en vez de `clear()+add` � no pisa el estado local optimista de la otra pantalla (antes favoritos/recompensas parpadeaban y perd�an el item que estabas editando al recibir el realtime de la pareja). 3 tests nuevos en `favorites_provider_test` verifican el merge.
- `lib/providers/chat_provider.dart`: (1) **race de init** � `init()` ahora suscribe `subscribeRealtime()` + `subscribeTyping()` ANTES de `loadMessages()`, as� los mensajes que llegan durante la carga no se pierden y el listener queda armado aunque el fetch tarde; (2) **load no pisa realtime** � `loadMessages()` hace merge por `id` (mapa `byId`) en vez de `clear()+add`, conservando los mensajes que ya llegaron por realtime; (3) **"escribiendo�" eterno** � `subscribeTyping` arranca un `Timer` de 4s por cada `is_typing=true` que auto-limpia `_partnerTyping` si no llega un refresco (antes el banner quedaba pegado si el `is_typing=false` de la pareja se perd�a en la red); el timer se cancela en `dispose()`. `flutter analyze` + `chat_provider_test` (4 tests) en verde.
- `lib/providers/board_provider_v2.dart`: (1) **delete sin control** � `delete()` ahora cancela el debounce pendiente del elemento (y lo saca de `_dirtyElements`) y solo borra en cloud si el elemento alguna vez se sincroniz� (`el.cloudId != null`), evitando writes a una fila ya borrada (que la recreaba) en elementos puramente locales/optimistas; (2) **move pisado por realtime** � se agreg� `_dirtyElements` (Set de ids con cambio local pendiente). `moveLocal`/`update` marcan el id dirty y lo desmarcan al confirmar el write cloud; el callback de realtime UPDATE, si el id est� dirty, preserva la x/y local (no pisa el drag en curso) y deja que el debounce retrase el valor autoritativo. Esto evita que un echo de realtime "rompa" el arrastre. `flutter analyze` sin issues.
- Tests: favorites 3 nuevos + chat 4 (todos verdes). Analyze global sin errores nuevos.
**Lecciones**:
- Un callback de realtime que hace `clear()+add` sobre la lista compartida es una carrera esperando a que la UI recargue: siempre mergear por PK (id) y asignar at�micamente.
- Suscribir el realtime DESPU�S del fetch es una race: si el mensaje llega durante la carga, el listener no existe y se pierde. Suscribir primero, luego cargar.
- Un indicador "escribiendo�" basado solo en `is_typing=false` es fr�gil: la red puede perder ese evento. Hay que usar un timeout de seguridad que auto-limpie.
- El `data`/posici�n de un elemento arrastrado puede ser pisado por el echo de realtime de su propio update; marcar dirty y preservar x/y local hasta confirmar el write soluciona el "drag roto".
- `cloudId` es getter ? no se promociona null dentro de `if`; capturarlo en variable local antes de usar en `.eq('id', cloudId)`.
**Impacto**: `favorites_provider.dart`, `rewards_provider.dart`, `chat_provider.dart`, `board_provider_v2.dart`, `test/providers/favorites_provider_test.dart` (3 nuevos), `test/providers/chat_provider_test.dart` (4), docs.
**Relacionado con**: Tanda 1 (flujo de datos), errores-conocidos (patr�n catch silencioso), D-2 (Supabase realtime).

## [2026-08-28] - BUGFIX - LocaArranger: crash por NaN en double.clamp con muchos �tems (subdivisi�n bajo minW)
**Resumen**: El fix previo de "pantallas blancas" (guarda `width<=0 || height<=0 || cantidad<1` al inicio de `arrange`) NO cubr�a el caso real del stack trace reportado (`double.clamp` en `loca_arranger.dart:77`). Con muchos �tems (o pesos sesgados) la subdivisi�n recursiva deja nodos con ancho/alto MENOR que `minW` (p. ej. 125 < 140). Entonces `f.clamp(minW/node.width, (node.width-minW)/node.width)` tiene `lower > upper`, devuelve un factor que produce un hijo de ancho NEGATIVO, y la siguiente divisi�n por ese ancho degenera en NaN ? `double.clamp` lanza y la pantalla "loca" revienta. Las pantallas de mosaico (Logros, Metas, Finanzas, etc.) que usan el arranger eran las afectadas.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: en el corte horizontal y vertical, se calcula `lo = minW/node.width` y `hi = (node.width-minW)/node.width`; si `lo <= hi` se aplica el clamp (ambos hijos quedan >= minW y positivos), y si `lo > hi` (nodo ya m�s chico que 2*minW) se parte al medio (`f = 0.5`) aceptando bloques m�s chicos que minW pero SIEMPRE con dimensi�n estrictamente positiva y finita. Tambi�n se protege la suma de pesos (`(wA+wB) > 0 ? wA/sum : 0.5`) para evitar divisi�n por cero si alg�n peso fuera 0.
- `test/widgets/loca_arranger_test.dart`: 2 tests nuevos � "muchos �tems en lienzo chico" (cantidad 20..200) y "pesos sesgados extremos" (60 �tems, 1 peso 1000x) � ambos verifican que todas las dimensiones son > 0 y finitas (antes tiraban NaN/negativo). Los tests existentes (cantidad <= 8) no alcanzaban porque con pocos �tems el ancho nunca baja de minW.
- Tests: los 12 del archivo en verde. `flutter analyze` sin errores en el archivo.
**Lecciones**:
- La guarda inicial del arranger no basta: el caso patol�gico ocurre DENTRO del bucle de subdivisi�n, no en el argumento de entrada. Hay que garantizar que cada corte produzca hijos de dimensi�n estrictamente positiva (factor `f` siempre en (0,1)) aunque eso signifique relajar `minW` en nodos muy chicos.
- `f.clamp(lower, upper)` con `lower > upper` no lanza pero devuelve un valor fuera de rango que luego genera geometr�a inv�lida; conviene chequear `lo <= hi` antes de clampar.
- Para reproductibilidad de crashes de mosaico, los tests deben usar `cantidad` grande (>= 20) y pesos sesgados, no solo 1..8.
**Impacto**: `loca_arranger.dart`, `test/widgets/loca_arranger_test.dart`, docs.
**Relacionado con**: errores-conocidos (pantallas blancas/arranger), skill_visual, glosario.

## [2026-08-28] - BUGFIX - Push FCM + Bot WhatsApp: mensajes no llegaban (limpieza de tokens y ventana din�mica del bot)
**Resumen**: Auditor�a completa del pipeline de notificaciones. Se encontr� que (a) los push FCM no llegaban a Rocio porque su token FCM estaba vencido (no se re-registraba) y la tabla `device_tokens` acumulaba 20 tokens muertos (`UNREGISTERED`); (b) el bot de WhatsApp perd�a eventos en silencio porque el cron de GitHub Actions corre con retrasos de 6-12h y consultaba una ventana fija de 1h, dejando fuera lo ocurrido entre corridas. Ambos corregidos.
**Cambios realizados**:
- `supabase/functions/send-push/index.ts`: ahora hace `select id, token, platform` filtrando `created_at >= ahora - 90d` y, al enviar, si FCM responde `UNREGISTERED` elimina ese row de `device_tokens` (RLS full-access). Antes mandaba a tokens muertos y no limpiaba. Verificado E2E: `POST /functions/v1/send-push` devolvi� 200 al token vigente (id 21, Facu).
- `lib/services/notification_service.dart`: `registerTokenAfterLogin`/`_storeToken` (insert-if-absent) � ya funcionaba; se beneficiar� del �ndice �nico para upserts futuros. Rocio no ten�a token vigente (�ltimo 11/08) ? por eso no recib�a nada; al reabrir la app se re-registra solo.
- `supabase/migration_device_tokens_unique.sql` (nuevo): `CREATE UNIQUE INDEX idx_device_tokens_user_token ON device_tokens(user_id, token)` (dedupe de tokens duplicados por usuario). Reflejado en `supabase_schema.sql`.
- `bot-furi/bot.js`: (1) **ventana din�mica** � persiste `last_run_at` en `bot_sessions.session_data` y consulta eventos `desde = max(last_run_previo, ahora-24h)` en vez de fija 1h, corrigiendo la p�rdida silenciosa por retraso de cron (log "Ventana de deteccion: desde 2026-08-28T18:02:05.307Z"). (2) **LIDs persistidos en `bot_sessions.session_data.lids`** (se cargan desde Supabase; ya no depende de `lids.json` en CI ef�mero). `saveSessionToSupabase()` extra tras `verificarYNotificar` para persistir la marca. Verificado E2E: insert de mood de prueba ? bot envi� y confirm� ACK a 5493786513637 ("Mensaje enviado y confirmado") ? dato de prueba borrado.
- Limpieza inmediata: se eliminaron 20 rows muertos de `device_tokens` (qued� solo id 21, Facu).
**Lecciones**:
- FCM legacy API fue removido (jun 2024) ? obligatorio HTTP v1 con service account; la Edge Function ya usa v1 (correcto). Los tokens `UNREGISTERED` NUNCA se podaban: hay que borrarlos en el servidor al recibir el error, o se siguen reintentando a ciegas.
- Un token FCM vence cuando se reinstala la app o se cambia el perfil; si el dispositivo no reabre la app, el token queda muerto y ese usuario deja de recibir push hasta volver a abrir. No es un bug de c�digo, es higiene de tokens.
- El cron de GitHub Actions `*/30` NO garantiza cada 30 min en repos gratuitos: puede correr con 6-12h de retraso. Una ventana fija de 1h entonces pierde eventos. La ventana din�mica (desde la �ltima corrida, con tope de 24h) es la cura.
- `bot_sessions` es el �nico estado persistente en CI ef�mero: cualquier marca que deba sobrevivir entre corridas (LIDs, last_run_at) debe ir ah�, no a archivos locales gitignados.
**Pendiente (acci�n manual del usuario)**: el deploy de la Edge Function `send-push` NO se pudo hacer desde esta m�quina (no hay `supabase` CLI ni `SUPABASE_ACCESS_TOKEN`). Ejecutar en local: `supabase functions deploy send-push`. Sin esto, la poda de tokens en la nube no est� activa (el c�digo qued� listo).
**Impacto**: `supabase/functions/send-push/index.ts`, `supabase/migration_device_tokens_unique.sql` (nuevo), `supabase_schema.sql`, `bot-furi/bot.js`, `lib/services/notification_service.dart`, docs.
**Relacionado con**: D-7 (FCM), D-10 (bot), errores-conocidos (sin nuevos cr�ticos), bot-whatsapp.md.

---

## [2026-08-28] - BUGFIX - Sync calendario/clases: cambios de la pareja bajan + ediciones offline no se pierden
**Resumen**: Auditando el sync calendario?Supabase se encontraron 2 bugs de consistencia que explicaban "la pareja edita una clase y a mi no me llega" y "edito sin internet y mi cambio nunca sube". Ambos corregidos y reflejados en el schema master.
**Cambios realizados**:
- `lib/providers/class_schedule_provider.dart`: el callback de realtime (`payload.eventType == 'UPDATE'`) ignoraba el cambio de la pareja (solo insertaba si no exist�a localmente). Ahora actualiza la fila local por `cloudId` (autoritativo), igual que el merge de `schedules`. Antes: las ediciones de la otra persona en una clase existente no se descargaban.
- `lib/database/database_helper.dart`: migraci�n a v9. Nueva columna `synced INTEGER NOT NULL DEFAULT 1` en `schedules` y `class_schedules` (mismo patr�n dirty-flag que `board_elements_v2`), y `cloud_id` + �ndice �nico en `board_elements_v2`. Los CREATE de ambas tablas incluyen `synced`.
- `lib/providers/schedule_provider.dart`: `_pushUnsyncedToCloud()` ahora tambi�n re-sube filas con `synced = 0` (no solo las sin `cloudId`); `updateSchedule()` marca `synced = 0` si el push a la nube falla (offline) y `synced = 1` al confirmar ? la pr�xima carga con internet re-intenta y no pierde la edici�n.
- `lib/providers/class_schedule_provider.dart`: `_syncUnsyncedToSupabase()` ahora selecciona `cloudId IS NULL OR synced = 0` y re-sube ambas; `updateSchedule()` marca `synced = 0` si `_pushToSupabase` devuelve null.
- `supabase_schema.sql`: agregada la secci�n 18a `board_elements_v2` (espejo del schema SQLite local, sin la columna `cloud_id` que es solo-local) con �ndice, RLS `full_access_board_elements_v2` y GRANTs. Antes la tabla solo exist�a en `migration_board_v2.sql`, as� que una DB creada solo con el schema master no ten�a el pizarr�n v2 en la nube. `boards` ya estaba en el master.
**Lecciones**:
- Un callback de realtime que solo hace INSERT-ignore silencia las UPDATE de la pareja: hay que aplicar el cambio remoto por la PK cloud (igual que el pull inicial). El merge por `updatedAt` del pull de `schedules` ya lo hac�a; el realtime de clases no.
- El patr�n dirty-flag (`synced`) es la forma robusta de no perder ediciones offline: el push fallido marca la fila, y la pr�xima carga la re-intenta (insert si no tiene cloudId, update si ya lo tiene). Sin esto, un UPDATE offline a una fila ya sincronizada quedaba "limpia" para siempre.
- El schema master debe contener TODAS las tablas que usa el c�digo; si una solo vive en una migraci�n suelta, una DB fresca (o reconstruida) queda sin ella y el sync falla en silencio.
**Impacto**: `class_schedule_provider.dart`, `schedule_provider.dart`, `database_helper.dart`, `supabase_schema.sql`, docs.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), errores-conocidos (sync calendario), glosario.

## [2026-08-28] - BUGFIX - Tanda 1: flujo de datos Supabase ? pantalla (finanzas, cartas, trivia, racha, nosotros, galer�a)
**Resumen**: Auditor�a completa del flujo de datos (providers + screens) encontr� 6 bugs que explicaban "no se muestra / no llega" en varias secciones. Todos corregidos.
**Cambios realizados**:
- `lib/providers/finances_provider.dart`: era el �NICO provider CRUD sin RealtimeChannel ? lo que cargaba la pareja no aparec�a hasta reabrir la pantalla. Agregado canal `finances_realtime` sobre `transactions` con recarga silenciosa (`_reload` sin estado loading, para no parpadear). Adem�s se quit� `.limit(100)`: con >100 transacciones las viejas desaparec�an para siempre del balance y del gr�fico (`period: year/all` sumaba solo las �ltimas 100).
- `lib/screens/letters_screen.dart`: los `catchError` convert�an CUALQUIER error de Supabase en bandeja vac�a, y encima el cache local (`cache_letters_inbox/sent`) se pisaba con `[]` al fallar la red ? "mis cartas desaparecieron" incluso offline. Ahora: los errores de fetch propagan al catch, el cache SOLO se escribe con datos reales, y si no hay datos ni cache se muestra el estado de error + tile de reintento (cloud_off).
- `lib/providers/trivia_provider.dart`: (1) carrera de siembra � si ambos abr�an Trivia con el banco vac�o, ambos insertaban las 10 preguntas ? banco duplicado y marcador desalineado. Fix: doble chequeo antes del insert + `_dedupeQuestions()` idempotente (deja el id m�s bajo por texto de pregunta, limpia duplicados hist�ricos). (2) La rama "migraci�n de schema viejo" le�a `options` de un `select('id')` ? siempre null y nunca migraba; ahora `_completeMissingOptions()` pide `id, question, options` y completa opciones faltantes matcheando por texto contra el banco.
- `lib/providers/couple_provider.dart`: `_reload()` hac�a `clear()` + `addAll` sobre la lista compartida � dos eventos realtime casi simult�neos (mood + completion, normal un d�a activo) se cruzaban: duplicados y racha ?? que parpadeaba/mostraba mal. Fix: los fetch llenan listas LOCALES y se asignan at�micamente; recarga serializada con guard `_reloading` + `_reloadQueued` (no se pierde ning�n evento).
- `lib/screens/nosotros_screen.dart`: TODOS los errores (carga y mutaciones) iban a `debugPrint` ? sin internet parec�a que la pareja no hizo nada y tocar emoci�n/pregunta "no hac�a nada". Fix: contador de fallos en `_loadAll` � si fallan =3 queries (o el catch exterior), SnackBar "Sin conexi�n"; las 3 mutaciones (`_addMood`, `_answerQuestion`, `_sendNewQuestion`) ahora muestran `AppFeedback.error`.
- `lib/providers/gallery_provider.dart` + `lib/screens/galeria/galeria_screen.dart`: (1) **`loadComments` nunca se llamaba desde la UI** ? los comentarios de las fotos NUNCA se mostraban (bug no detectado en la auditor�a inicial, apareci� al verificar). Se conecta al abrir la foto fullscreen. (2) Realtime sobre `gallery_comments`: si la pareja comenta una foto que ya tengo cargada, se refrescan en vivo (antes hab�a que cerrar y reabrir). (3) `delete()` con catch totalmente silencioso ? ahora setea `_error` y la pantalla muestra SnackBar ("borr� la foto y reaparece" sin explicaci�n ? ahora avisa). (4) Tile de carga (hourglass) mientras carga sin cache � antes la pantalla se ve�a id�ntica a "no hay fotos" y a "rompi�".
**Lecciones**:
- "El �ltimo catch en la cadena" decide lo que ve el usuario: un `catchError((_) => [])` convierte fallo de red en dato vac�o, y escribir cache DESPU�S de ese catchError pisa datos buenos con vac�os. El cache local debe escribirse SOLO con fetch exitoso.
- Un m�todo de provider que nadie llama es un feature entero faltante (loadComments exist�a, estaba testeado en el provider y jam�s se invocaba desde la pantalla): al auditar "no se muestra X", verificar que el camino UI ? provider ? query est� CONECTADO de punta a punta, no solo que el m�todo exista.
- Un provider CRUD sin realtime en una app de pareja es un bug de producto, no una omisi�n: cada provider nuevo deber�a copiar el patr�n load + subscribe + reload silencioso (finanzas fue el �ltimo que qued� afuera).
- El `clear()` + `await Future.wait(addAll)` sobre una lista de instancia es una carrera esperando realtime: fetch a listas locales y asignaci�n at�mica �nica.
- Los `limit(N)` "de protecci�n" en queries de listado truncan silenciosamente historiales y c�lculos agregados (balance/gr�fico) � si la tabla crece, paginar en vez de limitar.
**Impacto**: `finances_provider.dart`, `letters_screen.dart`, `trivia_provider.dart`, `couple_provider.dart`, `nosotros_screen.dart`, `gallery_provider.dart`, `galeria_screen.dart`, docs.
**Relacionado con**: D-2 (Supabase), errores-conocidos (patr�n catch silencioso), LocalCache (offline-first), an�lisis de uso en pareja.

## [2026-08-28] - BUGFIX - Los t�tulos de las cartas no se ve�an en los bloques del mosaico
**Resumen**: En la secci�n de Cartas, los bloques del mosaico "loca" no mostraban el t�tulo de las cartas (ni el icono). En `_letterChild`, el t�tulo y el icono usaban `_letterIconColor()`, que para cartas NO selladas devolv�a `_letterColor()` � el MISMO color que el fondo del bloque (`e.color`). El t�tulo se pintaba del mismo color sobre el mismo color ? invisible (rosa `_cInbox` sobre rosa, o morado oscuro `_cRead` sobre morado).
**Cambios realizados**:
- `lib/screens/letters_screen.dart`: `_letterIconColor()` para cartas no selladas ahora devuelve `Colors.white` (contraste), consistente con el preview de contenido que ya usaba `Colors.white`. Las selladas siguen con `_black` (visible sobre �mbar `_cSealed`).
**Lecciones**:
- El contraste dentro de un bloque brutalista (fondo == borde s�lido de un solo color) requiere que el contenido (icono/t�tulo) use un color DISTINTO al del bloque. Devolver el mismo color para "contenido" y "fondo" los funde. El `resultado` de `_letterColor` es para el fondo del bloque; el color del contenido debe ser de contraste (blanco), no una referencia al fondo.
**Impacto**: `letters_screen.dart`, docs.

## [2026-08-28] - BUGFIX - Bot�n back de Android cerraba la app en vez de cerrar overlays/men�s
**Resumen**: Al apretar el back del celular, si hab�a un men�/popup en pantalla que NO era una ruta del Navigator (overlays dibujados con `Stack`), el sistema operativo sal�a de la app entera en lugar de cerrar ese overlay. Se intercept� el back con `PopScope` en los 2 puntos compartidos que concentran el problema: el kit "loca" (13+ pantallas de mosaico) y el Home (mazo, poemas, panel de notificaciones, match).
**Cambios realizados**:
- `lib/widgets/loca_screen.dart`: el build se envuelve en `PopScope(canPop: _openPanel == null && !_busy)`; si hay un panel swink abierto, el back llama `_close()` (cierra el panel) y bloquea el pop (no se sale de la pantalla).
- `lib/screens/home_screen.dart`: el `_BrutalGrid` se envuelve en `PopScope(canPop: !_notifDrawer && !_showDeck && !_showPoemas && pendingMatch == null)`. Nuevo `_handleBack()` que cierra en orden de prioridad: panel de notificaciones ? mazo ? poemas ? match (`consumeMatch`). Solo cuando no queda ning�n overlay deja escapar el back (volver a la pantalla anterior o salir de la app).
- Tests: suite **238 verdes**, `flutter analyze` sin errores nuevos (20 issues = baseline; el �nico `curly_braces` de home_screen:620 es pre-existente en `_markAllRead`).
**Lecciones**:
- El bot�n back de Android solo conoce rutas del Navigator. Los overlays/men�s "locos" (paneles swink de LocaScreen, mazo, drawer) viven en un `Stack` interno sin registro de navegaci�n, as� que en la pantalla ra�z el back sale de la app directo. La cura es `PopScope` en el STATE que posee esos flags: `canPop` false mientras haya overlay abierto + `onPopInvokedWithResult` que lo cierra (y no hace `Navigator.pop`).
- En Flutter 3.44 usar `onPopInvokedWithResult(didPop, _)` (el `onPopInvoked` est� deprecado); siempre chequear `if (didPop) return;` antes de manejar.
- `canPop` debe re-leerse del provider cuando el overlay se controla desde afuera (match del mazo vive en `DeckProvider.pendingMatch`): usar `context.read` en el getter para que `consumeMatch()` dispare rebuild y el back deje de bloquear.
- Los `if (x) { ...; return; }` de una sola l�nea disparan `curly_braces_in_flow_control_structures`; usar bloques.
**Impacto**: `loca_screen.dart`, `home_screen.dart`, docs.
**Relacionado con**: D-4 (skill_visual), glosario (pantalla "loca", mazo), errores-conocidos (sin nuevos).

## [2026-08-28] - BUGFIX - Pantallas blancas en release (Logros/Metas): guardas en arranger + cache local a prueba de fallos
**Resumen**: En el APK release, Logros y Metas (y pantallas con cache local) se ve�an en blanco. Hip�tesis ra�z: una excepci�n de build tragada en release � (1) `LocaArranger.arrange` divide por ancho/alto y si la pantalla llega con alto 0 (transici�n) genera NaN ? excepci�n de layout; (2) la lectura de cache local (`LocalCache`) corr�a FUERA de try en metas/retos/cartas ? si SharedPreferences fallaba, la pantalla reventaba en blanco en Android.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: `arrange` ahora retorna vac�o si `width <= 0 || height <= 0 || cantidad < 1` (evita divisi�n por cero ? NaN ? pantalla blanca).
- `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`: la lectura de `LocalCache` queda dentro de try/catch (si SharedPreferences falla, no rompe la pantalla).
- Tests: suite **238 verdes**, analyze sin errores.
**Nota honesta**: no pude reproducir en un dispositivo Android real; apliqu� estas guardas defensivas (la causa m�s probable de "blanca en release"), pero conviene validar en el emulador/celular del usuario con logs si persiste.
**Impacto**: `loca_arranger.dart`, `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`, docs.

## [2026-08-28] - FEATURE - Trivia con aspecto de mazo apilado (tipo tarjetas de poemas)
**Resumen**: La pantalla de Trivia ahora se presenta como un MAZO apilado de cards (degradado, Bangers, sin borde) estilado como el mazo de tarjetas. El tile de Trivia abre un overlay a pantalla completa.
**Cambios realizados**:
- `lib/screens/trivia/trivia_screen.dart`: el tile de Trivia ahora usa `onTap` para abrir `TriviaDeckOverlay` (antes abr�a un panel). Nuevo widget `TriviaDeckOverlay`: cards apiladas (2 detr�s con offset/escala/escala de opacidad) de las preguntas del banco (`provider.questions`); se desliza a izquierda/derecha para navegar; la card frontal muestra la pregunta + chips de "Tu respuesta" y "Predicci�n" + Confirmar (`provider.submit`). Marca "respondida" persistida (icono check en el tile).
- La marca "respondida" del tile se mantiene.
- Tests: suite **238 verdes**, analyze sin errores.
**Lecciones**:
- Para el efecto "mazo", dibujar las cards de atr�s con offset/scale/opacity decrecientes y la frontal delante; el gesto `onHorizontalDragEnd` decide avanzar/retroceder por `primaryVelocity`.
- `LocaEntry.panel` ya no abr�a la trivia (ahora es `onTap`); mantener `panels` con el panel viejo (sin uso) es c�digo muerto aceptable, o se puede quitar.
**Pendiente**: pantallas blancas de Logros/Metas en APK (sesi�n dedicada).
**Impacto**: `trivia_screen.dart`, docs.

## [2026-08-28] - BUGFIX/FEATURE - Sonido en Android real + bloques de finanzas cuadrados
**Resumen**: (1) El sonido segu�a sin o�rse en Android: el fix de ruta anterior dej� `_assetPrefix = 'Assets/sounds/'` y como los calls pasan `'sounds/click.wav'`, la ruta se DOBLAVA (`Assets/sounds/sounds/click.wav`) ? clave inv�lida ? silencio. (2) Los bloques del mosaico de finanzas sal�an muy estirados/delgados.
**Cambios realizados**:
- `lib/services/sound_service.dart`: `_assetPrefix` ? `'Assets/'` (los calls ya incluyen `sounds/...`, as� el resultado final es `Assets/sounds/click.wav`, la clave correcta que busca Android).
- `lib/widgets/loca_screen.dart`: nuevo `LocaEntry.weight` (opcional) para repartir bloques m�s cuadrados en el arranger.
- `lib/screens/finanzas/finanzas_screen.dart`: pesos fijos (`saldo/ingresos/gastos/gr�fico`=3, transacciones=2.5, historial/agregar=2) ? bloques m�s equilibrados y cuadrados.
- Tests: suite **238 verdes**, analyze sin errores.
**Lecciones**:
- Al corregir un path con prefijo hay que verificar la concatenaci�n final: `'Assets/sounds/' + 'sounds/click.wav'` duplica el segmento (no suena en Android). El call ya lleva `sounds/...`, as� que el prefijo correcto es `'Assets/'`.
**Pendiente**: Trivia "mazo apilado" (apilar preguntas como las tarjetas del deck) y pantallas blancas de Logros/Metas en APK (sesi�n dedicada).
**Impacto**: `sound_service.dart`, `loca_screen.dart`, `finanzas_screen.dart`, docs.

## [2026-08-28] - BUGFIX/UX - Pizarra: notas se ven con su estilo real (fuente, color, imagen) en el canvas
**Resumen**: El `_noteBody` del pizarr�n renderizaba las notas como cards gen�ricas (monospace, sin imagen), ignorando el estilo que el usuario define en el modal (fuente, tama�o, color, alineaci�n, negrita/italica/subrayado, imagen). El guardado ya persist�a ese estilo (`el.fontFamily`, `el.textColor`, `el.fontSize`, `data['imagePath']`, etc.) � el problema era el render simplificado.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart` `_noteBody`: ahora aplica `el.fontFamily`, `el.textColor`, `el.fontSize` (escalado para la card), `el.textAlign`, `el.isBold/isItalic/isUnderline`, y renderiza la `imagePath` de la nota (Image.file con errorBuilder). Se mantienen forma, gradiente (lineal/radial) y borde.
- Quedan pendientes para sesi�n dedicada (exactitud total): patrones de fondo (12), tipos de borde (6) y audio dentro de la nota en el canvas.
- Lecci�n de proceso: NO editar archivos Dart con `Set-Content`/PowerShell (~colaps� el archivo a una l�nea); usar siempre el editor. Se recuper� con `git checkout -- <archivo>` y se reaplic� el cambio correctamente.
**Impacto**: `pizarra_screen_v2.dart`, docs.

## [2026-08-28] - FEATURE/UX - Chat sin flecha, Home: swap de mini-iconos (mazo primero), mazo con Historial (sin la X)
**Resumen**: Ajustes de navegaci�n y accesos pedidos por el usuario.
**Cambios realizados**:
- `lib/screens/chat_screen.dart`: se quita la flecha de volver del header del chat (volver por gesto/sistema).
- `lib/screens/home_screen.dart`: en la fila de mini-iconos se intercambian el 1� y el 3�: ahora el **mazo general** (`Icons.style`, nuevo `_openMazo`) es el 1�, Trivia qued� al medio, y Poemas (`auto_stories`) pas� al 3�.
- `lib/screens/mazo/deck_overlay.dart`: se quita la **X de la esquina** cuando hay tarjetas y en su lugar queda un bot�n de **Historial** (`Icons.history`) que abre `DeckHistorySheet` (re-deslizar incluido). La X (cerrar) se mantiene solo cuando no hay tarjetas (vac�o) para no quedar atrapado.
- Tests: suite **238 verdes**, `flutter analyze` sin errores (baseline).
**Lecciones**:
- Para no dejar al usuario atrapado en un overlay de pantalla completa de solo-swipe, al reemplazar el bot�n de cierre por otro hay que conservar una salida al menos en el estado vac�o.
- `showDeckHistorySheet` recibe `onReswipe`; para re-deslizar dentro del overlay hay que setear el estado de re-swipe del overlay.
**Pendiente**: Trivia "crear/sin historial" (agregar pregunta + �ltimas 5 + historial) y pizarra: persistir notas + render id�ntico al modal (sesi�n dedicada).
**Impacto**: `chat_screen.dart`, `home_screen.dart`, `deck_overlay.dart`, docs.

## [2026-08-28] - BUGFIX/UX - Swipe izquierdo del Home (panel notif) + t�tulo grande en cartas
**Resumen**: El bot�n de la columna izquierda del Home no deslizaba con mouse/dedo para abrir el panel de notificaciones; el gesto no ganaba la arena. Adem�s las cartas en el mosaico mostraban poco el t�tulo.
**Cambios realizados**:
- `lib/screens/home_screen.dart`: `LeftButtons` pas� de StatelessWidget a **StatefulWidget** (`_LeftButtonsState`) con arrastre robusto en el tile superior: `onHorizontalDragStart/Update` acumulan `_dragDx`, y `onHorizontalDragEnd` abre el panel si `dx > 60` o `primaryVelocity > 250`. El tile superior ahora usa `GestureDetector` (tap + drag) sin `TapTile` anidado (evita que el tap externo gane y cancele el drag). `onHorizontalDragCancel` resetea.
- `lib/screens/letters_screen.dart`: en el mosaico, el t�tulo de cada carta ahora se muestra **grande** (fontSize 21, hasta 3 l�neas) en vez de 15/1 l�nea.
- Tests: suite **238 verdes**, `flutter analyze` sin errores.
**Lecciones**:
- Un `HorizontalDragGestureRecognizer` con SOLO `onHorizontalDragEnd` puede no ganar la arena frente al tap (no reclama durante el movimiento): hace falta `onHorizontalDragUpdate` (o `onStart`) que acumule y haga que el recognizer entre y gane; luego se decide en `onEnd` con umbral de desplazamiento + velocidad.
- Anidar un `TapTile` (con su GestureDetector) dentro del GestureDetector que maneja el drag hace que el tap pueda robar el gesto; para un swipe robusto conviene un �nico GestureDetector con `onTap`+drag en el tile.
**Impacto**: `home_screen.dart`, `letters_screen.dart`, docs.

## [2026-08-28] - BUGFIX - Sync de calendario entre usuarios: eventos y clases compartidos (RLS + publicaci�n realtime)
**Resumen**: El usuario report� que los eventos (`schedules`) y las clases (`class_schedules`) no se ve�an entre Facu y Rocio. El c�digo de los providers ya trae TODAS las filas cloud (`select('*')`) y hace merge por `cloudId`, as� que el origen estaba en la DB desplegada: o el RLS no era permisivo en esas tablas o no estaban en la publicaci�n realtime.
**Cambios realizados**:
- Verificaci�n: `schedule_provider.dart` y `class_schedule_provider.dart` ya hacen `_pushUnsyncedToCloud` + `_pullFromCloud` (pull de todas las filas) + realtime `schedules_sync` / `class_schedules_sync`. `calendar_home_screen.dart` carga ambos en `initState` (`loadSchedules`). No hac�a falta tocar el c�digo.
- `supabase/migration_schedule_class_sync.sql` (nuevo): idempotente � `DROP`+`CREATE POLICY "full_access_schedules"` y `"full_access_class_schedules"` (FOR ALL USING true), `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`, `GRANT` a anon/authenticated, y `ALTER PUBLICATION supabase_realtime ADD TABLE schedules` / `class_schedules`. **PENDIENTE ejecutar en SQL Editor** ? es lo que hace que ambos usuarios vean los eventos/clases del otro.
- Builds: `app-release.apk` (93.7 MB) y `furi_app.exe` recompilados con todo el c�digo nuevo (verificado por strings en `app.so`). Fix para build de Windows sin daemon: pasar el entorno MSVC (`vcvarsall.bat amd64`) v�a un `.cmd` temporal (evita el `&&` inv�lido de PowerShell 5.1).
**Lecciones**:
- Cuando el provider ya hace pull de TODAS las filas pero el otro usuario no ve nada, sospechar primero RLS/publicaci�n realtime en la DB desplegada (no el c�digo): un `DROP POLICY`+`CREATE full_access` + `ADD TABLE` a `supabase_realtime` es la cura idempotente.
- Verificar que un build incluye el c�digo nuevo grepeando un string de UI del binario (`app.so`), no nombres de m�todos (Dart los minifica en AOT).
**Pendiente**: en el SQL Editor, ejecutar `supabase/migration_schedule_class_sync.sql`; replicar `LocalCache` a las secciones basadas en provider.
**Impacto**: `migration_schedule_class_sync.sql` (nuevo), builds exe+apk, docs.

## [2026-08-27] - FEATURE/UX - Home: se quita la campana de notificaciones y el bot�n superior izquierdo abre un panel deslizante de notificaciones
**Resumen**: En el Home se elimin� el bot�n de campana (notificaciones) que estaba pegado al de configuraci�n, y el bot�n superior izquierdo (columna izquierda) ahora se desliza hacia la derecha para abrir, con animaci�n din�mica, un panel de notificaciones que entra desde la izquierda.
**Cambios realizados**:
- `lib/screens/home_screen.dart`: se quita `notificationBadge` (la campana junto a settings); el bloque de settings queda solo con el icono de engranaje y abre Configuraci�n.
- Se elimina el contador `_unreadNotifications` y el m�todo `_openNotifications` (ruta `notifications` queda sin entrada desde Home).
- El bot�n superior de `LeftButtons` ahora acepta `onSwipeRight`: al deslizar a la derecha (>250 vx) abre el panel de notificaciones.
- Nuevo `_NotificationPanel` (StatefulWidget) que entra con `SlideTransition` desde la izquierda + backdrop oscuro (controlado por `_drawerCtrl` con `easeOutCubic`). Lista notificaciones (`NotificationService.getNotifications`), estados loading/error/empty/data, en cada item abre el detalle y lo marca le�do; bot�n "todas le�das" y cerrar.
- Tests: suite **238 verdes**, `flutter analyze` sin errores (20 issues baseline/info).
**Lecciones**:
- Un gesto horizontal (swipe right) no dispara el tap del `TapTile` interno si no lo "acepta" (dragging supera el slop); por eso el drawer se abre en `onHorizontalDragEnd` con `primaryVelocity`, sin necesidad de conflicto con el tap de confeti.
- Para un panel que entra desde un costado, `SlideTransition` con curva `easeOutCubic` + un `AnimatedBuilder` sobre un `AnimationController` propio es suficiente y no depende de page-route.
**Pendiente**: replicar `LocalCache` al resto de secciones basadas en provider (favoritos, finanzas, galer�a, logros, recompensas, notificaciones, mapa).
**Impacto**: `home_screen.dart`, docs. La ruta `/notifications` sigue existiendo en el router (sin entrada desde Home).
**Relacionado con**: D-4 (skill_visual), an�lisis de uso en pareja.

## [2026-08-27] - FEATURE - Cache local offline-first (piloto metas/retos/cartas): sin "carga" al entrar + sync en segundo plano
**Resumen**: Primera entrega del cache local offline-first. Se cre� un helper reutilizable `LocalCache` (SharedPreferences JSON, "�ltimos datos conocidos") y se aplic� a metas, retos y cartas: al entrar se muestra el cache al instante (sin tile/spinner de carga), y despu�s se sincroniza con Supabase guardando lo nuevo. Los writes siguen refrescando el cache v�a el `_load()` que ya corre al final.
**Cambios realizados**:
- `lib/services/local_cache.dart` (nuevo): `LocalCache.getList/setList/remove` � cache por key (`cache_<tabla>`) en SharedPreferences como JSON de `List<Map>`.
- `metas_screen.dart` (`cache_metas`): `_loadMetas` primero muestra el cache si `_metas` est� vac�o, luego fetch + `setList`. Al ser los writes ? `_loadMetas()`, el cache se refresca solo.
- `retos_screen.dart` (`cache_retos`): �dem; adem�s el tile de carga queda cubierto por el cache-first.
- `letters_screen.dart` (`cache_letters_inbox`/`cache_letters_sent`): `_loadLetters` muestra cache de ambas listas + `setList` tras el fetch.
- Tests: suite **238 verdes**, `flutter analyze` baseline (19 issues, sin errores).
**Lecciones**:
- Un "�ltimos datos conocidos" en SharedPreferences JSON es un primer paso de bajo riesgo para el offline-first, sin tocar SQLite ni el merge del realtime: al entrar mostr�s el cache y re-reemplaz�s con el fetch. No bufferear escrituras offline todav�a.
- En retos hab�a un `}` doble tras el edit (romp�a el archivo): al cambiar un m�todo completo conviene revisar el cierre (dos `}` seguidos ? estructura rota; `dart analyze <archivo>` puntual lo detecta r�pido).
- Plan: replicar `LocalCache` al resto de secciones (favoritos, finanzas, galer�a, logros, recompensas, notificaciones, mapa) con su key propia.
**Pendiente**: replicar el cache al resto de secciones; para el offline "escribir sin internet" real habr�a que pasar a SQLite con cola de dirty + merge (sesi�n dedicada).
**Impacto**: `local_cache.dart` (nuevo), `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`, docs.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite/offline), an�lisis de uso en pareja.

## [2026-08-27] - FEATURE - Trivia "respondida" + feedback/undo AppFeedback en finanzas, cartas, favoritos y recompensas
**Resumen**: Cierre de pendientes de la tanda anterior sobre "feeling": la Trivia ahora se marca como respondida (check + swap al marcador), y se extendi� el patr�n `AppFeedback` (guardado/celebraci�n/undo) a finanzas, cartas, favoritos y recompensas.
**Cambios realizados**:
- `lib/screens/trivia/trivia_screen.dart`: el tile "Trivia" pasa a `Icons.check_circle` verde cuando `pv.myAnswerToday != null` (ya respond� hoy) ? **marcada como respondida**.
- `lib/screens/finanzas/finanzas_screen.dart`: al guardar transacci�n ? `AppFeedback.saved('Transacci�n guardada')`; nuevo `_deleteTransaction()` borra con `AppFeedback.deleted(... UNDO)` que reinserta la transacci�n.
- `lib/screens/letters_screen.dart`: al enviar carta ? `AppFeedback.saved('Carta enviada')` (con guard `mounted`).
- `lib/screens/favoritos/favoritos_screen.dart`: al guardar/editar favorito ? `AppFeedback.saved('Guardado')`.
- `lib/screens/recompensas/rewards_screen.dart`: al crear recompensa ? `saved`; al marcar cumplida ? `success(... celebration: true)`.
- Nota: un `flutter analyze` full puede reportar una CASCADA de errores espurios de `undefined_method`/`expected_token` en un archivo que est� bien (stale cache del daemon): al correr `flutter analyze <archivo>` puntual da 1 sola l�nea correcta. Ante esa cascada, debuggear con analyze de archivo puntual, no asumir que el archivo est� roto.
- Tests: suite **238 verdes**, `flutter analyze` baseline (19 issues pre-existentes, sin errores).
**Lecciones**:
- Marcar "respondida" de la trivia es mostrar el estado de `myAnswerToday` del provider (ya era data); basta cambiar el icono del tile seg�n ese estado, no hace falta l�gica nueva.
- El `AppFeedback.saved` tras un `await` dispara `use_build_context_synchronously`: proteger con `if (mounted)` para no sumar warnings.
- Extender `AppFeedback` es trivial: misma firma probada en metas; cada pantalla solo importa el helper y lo llama en las acciones de guardado/borrado/cumplido.
**Pendiente**: cache local offline-first general + quitar el "carga" visual al entrar (grande, sesi�n dedicada); `AppFeedback`/undo en pizarra (borrado complejo por conectores).
**Impacto**: `trivia_screen.dart`, `finanzas_screen.dart`, `letters_screen.dart`, `favoritos_screen.dart`, `rewards_screen.dart`, docs.
**Relacionado con**: D-4 (skill_visual), D-2 (Supabase), an�lisis de uso en pareja.

## [2026-08-27] - BUGFIX/UX - Sin tile de carga al entrar a las secciones "loca" + cartas muestran t�tulo y preview en el bloque
**Resumen**: El usuario pidi� que al entrar a cada secci�n no se vea una animaci�n/indicador de carga. Se eliminaron los tiles de ampolleta (`Icons.hourglass_top`) que aparec�an mientras cargaba data de Supabase en TODAS las pantallas "loca". Adem�s, las cartas recibidas ahora muestran su t�tulo Y un poco del contenido dentro del bloque del mosaico (antes solo el t�tulo).
**Cambios realizados**:
- Eliminado el `LocaEntry(icon: Icons.hourglass_top, ...)` de carga en: `retos_screen.dart`, `metas_screen.dart`, `notifications_screen.dart`, `galeria_screen.dart`, `trivia_screen.dart`, `favoritos_screen.dart`, `finanzas_screen.dart`, `rewards_screen.dart`, `logros_screen.dart`.
- Retos y metas: quitado el campo `_loading` y sus asignaciones (quedaba sin uso tras borrar el tile). El estado de error (`cloud_off`) se mantiene.
- `letters_screen.dart`: nuevo `childBuilder` (`_letterChild`) en las cartas del mosaico que renderiza icono de estado + t�tulo (Bangers 15) + preview de hasta 40 caracteres del contenido (2 l�neas). Las selladas solo muestran t�tulo (no spoilean contenido). Se agreg� import de `widgets/brutal_style.dart`.
- No se toc� el auto-swap (el usuario eligi� solo el spinner/ampolleta de carga).
**Lecciones**:
- Los tiles de carga como `LocaEntry` eran est�ticos (sin animaci�n real) pero el usuario los percibe como "animaci�n de carga": la soluci�n fue no mostrarlos y dejar solo los estados error/empty/data.
- Al quitar un tile condicional, revisar que el campo de estado que lo gatillaba (`_loading`) no quede hu�rfano (analyzer `unused_field`).
- Para mostrar contenido en un bloque "loca" junto a �tems que usan `label`, usar `childBuilder` (tiene prioridad sobre el icono+label por defecto y convive con el peso del arranger por `label`).
**Impacto**: 10 screens, `lib/widgets/` sin cambios, docs.
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE/BUGFIX - Consistencia visual Rocio, pizarra/calendario/flecha, "X m�s nuevos + historial" (cartas/metas/retos/finanzas), tapToSwap y marca de vista local
**Resumen**: Segunda tanda del polish. Se unific� el look "apagado" al entrar como Rocio (antes algunos bloques quedaban brillantes), se quitaron pasos intermedios y flechas innecesarias, se arregl� el recorte del calendario, y se mont� el sistema de "solo las X m�s nuevas + historial" en cartas (6), metas (8), retos (5) y finanzas (6). Se agreg� el swap al tocar y la marca de "vista" local en cartas.
**Cambios realizados**:
- **Brilloso como Rocio**: `lib/theme/app_theme.dart` nuevo `identityTheme(t)` = mutea si `AppState.identity == 'Rocio'`. `lib/widgets/loca_screen.dart` lo aplica centralmente en `build` ? **todos** los mosaicos/men�s/submen�s lucen apagados igual que el resto (antes usaban el tema lleno).
- **Pizarra directa**: `home_screen.dart` `_openPizarra` ahora entra a `RouterRoutes.pizarra` (canvas) sin pasar por el mosaico.
- **Calendario cortado**: `calendar_home_screen.dart` el mes usaba `GridView` con `NeverScrollable` y `childAspectRatio` ? recortaba la 6� semana abajo. Reemplazado por grilla de semanas `Expanded` que reparte la altura disponible ? mes completo siempre visible.
- **Flecha de volver**: eliminada de la barra de 3 corazones del `LocaScreen` (todas las secciones). La vuelta queda por gesto/teclado/sistema.
- **tapToSwap**: `LocaScreen` nuevo `LocaEntry.tapToSwap` ? al tocar un bloque con `swapBuilder` fuerza mostrar su info al instante (`_forceSwap`). Aplicado en `finanzas_screen.dart` a saldo/ingresos/gastos.
- **Favoritos ? guardados**: el tile "guardados" ahora abre un panel swink (lista de `allFavorited`); se elimin� el toggle `_showOnlyFavorited` muerto.
- **Cartas (6 + historial)**: `letters_screen.dart` muestra solo las 6 recibidas m�s recientes; tile "enviadas" ? **"historial"** que lista Recibidas y Enviadas en secciones separadas. **Marca de "vista" local**: `_readLocal` en SharedPreferences (`readLetter-{id}`) para reflejar la le�da al instante; `_markReadLocal` al abrir cartas.
- **Metas (8) / Retos (5) + historial**: `metas_screen.dart` y `retos_screen.dart` muestran 8/5 �tems en su orden + tile "historial" con panel que lista todas como cards (toggle done).
- **Finanzas (6 + historial)**: `finanzas_screen.dart` muestra las 6 transacciones m�s recientes + tile "historial" con todas (editar/borrar inline).
- **Metas feedback/undo** (de la tanda anterior): celebraci�n al cumplir, "Meta guardada", borrado con DESHACER v�a `AppFeedback`.
- Tests: suite **238 verdes**, `flutter analyze` baseline (issues pre-existentes; sin errores en archivos tocados).
**Lecciones**:
- El tema brillante por secci�n era inconsistente: el muteo por identidad debe ser **central** (en el scaffold compartido `LocaScreen`), no por pantalla, o algunas quedan brillantes.
- Un `GridView` con `NeverScrollableScrollPhysics` + `childAspectRatio` recorta el contenido que excede el alto: para algo que debe verse SIEMPRE completo (un mes), es mejor repartir las filas con `Expanded` y dejar que las celdas se achiquen.
- Marcar "visto" de forma local (SharedPreferences) da respuesta instant�nea sin depender del round-trip de la nube; se puede complementar con el `seen_by` cloud.
- El sistema "X m�s nuevos + historial" mantiene el mosaico liviano cuando un listado crece: cap con `.take(X)` para el mosaico + un tile "historial" que muestra todo en un panel.
- `d.globalPosition` del toque es la fuente confiable para posicionar efectos (confeti) sobre el bot�n.
**Pendiente**: cache local offline-first general + quitar el "carga" visual al entrar (grande); trivias "respondidas" (marcado local); extender `AppFeedback` a favoritos/finanzas/cartas/recompensas/pizarra.
**Impacto**: `app_theme.dart`, `loca_screen.dart`, `home_screen.dart`, `calendar_home_screen.dart`, `favoritos_screen.dart`, `finanzas_screen.dart`, `letters_screen.dart`, `metas_screen.dart`, `retos_screen.dart`, docs.
**Relacionado con**: D-4 (skill_visual), D-2 (Supabase), an�lisis de uso en pareja.

## [2026-08-27] - FEATURE+BUGFIX - Polish de uso real: sonido en Android, confeti donde se toca, chat con "escribiendo..."/scroll infinito, feedback/undo en metas y limpieza de botones muertos
**Resumen**: Primera tanda del an�lisis de uso serio en pareja. Se corrigieron bugs de confianza (botones muertos, sonido que solo sonaba en PC, confeti que aparec�a en la esquina), se agreg� feeling (indicador "escribiendo...", scroll infinito del chat, celebraci�n al cumplir metas, confirmaci�n y deshacer), y se limpi� c�digo muerto.
**Cambios realizados**:
- `lib/services/sound_service.dart`: **fix del sonido en Android**. Los assets viven en `Assets/sounds/` (declarado en pubspec), as� la clave real (case-sensitive) es `Assets/sounds/click.wav`, pero el c�digo usaba `AssetSource('sounds/click.wav')`. En PC `audioplayers_windows` resuelve por filesystem e igual lo encontraba; en **Android el asset manager busca la clave exacta y falla en silencio ? nada de sonido**. Se agrega `_assetPrefix = 'Assets/sounds/'` y `AssetSource(_asset('...'))`.
- `lib/services/settings_service.dart`: `SettingsService().init()` **nunca se llamaba** en `main.dart` ? los prefs de sonido no se cargaban. Se agrega la llamada en `main()`.
- `lib/screens/settings_screen.dart`: el tile "Sonidos" era un placeholder sin acci�n ? ahora es un **toggle funcional** (StatefulWidget): muestra volumen_on/off, persiste con `setEnableSound`, y al activar reproduce `success()` como feedback.
- **Botones muertos** (confianza): `lib/screens/home_screen.dart` � el mini-icono "Mazo" (`Icons.style`) era `onTap: () {}`; ahora dispara confeti (sigue sin navegaci�n, decisi�n del usuario). "Estudio" sigue decorativo. **C�digo muerto eliminado**: `providers/tasks_provider.dart` (TasksProvider) y las pantallas hu�rfanas `question_screen.dart`, `mood_screen.dart`, `notes_screen.dart`, `pizarra/pizarra_screen.dart` (v1).
- **Confeti posicionado** (bug): `home_screen.dart` � el confeti sal�a SIEMPRE en la esquina. Causas: `_confettiAt` usaba `context.findRenderObject().localToGlobal()` (descolocaba) y varios botones pasaban `(0,0)`. Fix: normalizaci�n por pantalla en `_confettiColorsFor` + nuevo `_confettiGlobal(Offset)` que usa `d.globalPosition` del toque (confiable) en los botones chicos (pesa/finanzas/favoritos/modos/mini-iconos/columna izquierda). Los `block` grandes siguen con centro de canvas.
- `lib/screens/login_screen.dart` + `lib/widgets/loca_screen.dart`: el Login no mostraba carga ni bloqueaba dobles toques ? `LocaEntry.onTapAsync` (nuevo) + overlay de spinner mientras corre `_login`.
- `lib/providers/chat_provider.dart` + `lib/screens/chat_screen.dart`: (1) **scroll infinito** � el chat cargaba solo los �ltimos 100; la lista pas� a `reverse: true` (nuevo abajo) para que el paginado ancle la vista, y `loadOlderMessages()` prepara p�ginas anteriores al llegar al tope. (2) **"escribiendo..."** � nueva tabla `chat_typing` (user_id PK, is_typing, updated_at) con `subscribeTyping()` (realtime), `notifyTyping(bool)` con auto-clear a 1.5s, y banner "escribiendo�" en pantalla. `supabase/migration_chat_typing.sql` **PENDIENTE ejecutar en SQL Editor**.
- `lib/widgets/app_feedback.dart` (nuevo): helper global de SnackBar brutalista (success/saved/deleted con UNDO/error).
- `lib/screens/metas_screen.dart`: al cumplir una meta ? celebraci�n (`AppFeedback.success(celebration: true)`); guardar ? "Meta guardada"; borrar ? **SnackBar con DESHACER** (`_restoreMeta` reinserta).
- Tests: suite **238 verdes**, `flutter analyze` 19-20 issues (baseline, todos pre-existentes; sin errores en archivos tocados).
**Lecciones**:
- "El sonido suena en PC pero no en Android": antes de tocar el plugin, verificar que la **ruta del asset coincida EXACTO con la declarada en pubspec** (`Assets/sounds/` incluye `Assets/`). En desktop el plugin resuelve por filesystem y camufla el bug; Android exige la clave exacta.
- Un `SettingsService()` singleton con `init()` que nadie llama es un toggle "roto" aceptado: al no cargar prefs, `_enableSound` quedaba en default true y el toggle no persist�a. Revisar que cada servicio que lee SharedPreferences tenga su `init()` en `main()`.
- El confeti "en la esquina" era doble culpa: `localToGlobal` con el RenderBox equivocado + varios callbacks pasando `(0,0)`. `d.globalPosition` del gesto es la fuente confiable de posici�n y no depende de boxes.
- Paginar historial de chat "hacia arriba" con `reverse: true` (nuevo abajo) hace que el prepend de mensajes viejos **ancle la vista sin saltar** � mucho m�s simple que medir alturas de items de altura variable.
- Un "deshacer" de borrado en tablas sin soft-delete se resuelve reinsertando la fila (se pierde el id original, se gana la recuperaci�n). Para metas/retos es aceptable y da control al usuario.
**Pendiente**: ejecutar `supabase/migration_chat_typing.sql` en SQL Editor (sin eso, `notifyTyping`/`subscribeTyping` fallan en la nube). Extender el patr�n de feedback/undo/celebraci�n a favoritos, finanzas, cartas, recompensas y pizarra (mismo `AppFeedback`).
**Impacto**: `sound_service.dart`, `settings_service.dart`, `settings_screen.dart`, `main.dart`, `home_screen.dart`, `login_screen.dart`, `loca_screen.dart`, `chat_provider.dart`, `chat_screen.dart`, `app_feedback.dart` (nuevo), `metas_screen.dart`, `migration_chat_typing.sql` (nuevo), 5 archivos de c�digo muerto eliminados, docs.
**Relacionado con**: D-4 (skill_visual), D-2 (Supabase realtime), errores-conocidos (sin nuevos), an�lisis de uso en pareja.

## [2026-08-27] - FEATURE - Calendario minimalista, clases en franja semanal, ejercicios con biblioteca/mejora/stats, mazo en 3 y fix favoritos
**Resumen**: Cuatro mejoras pedidas por el usuario: (1) el men� de agregar de Favoritos mostraba 10 categor�as y ahora solo las 4 en uso; (2) calendario y clases redise�ados con est�tica moderna-minimalista (celdas neutras, hoy/selecci�n en acento cian, clase con barra de color + hora protagonista, franja semanal arriba); (3) ejercicios: rutinas ahora llevan ejercicios de una BIBLIOTECA (nombres ya registrados, chips con autollenado de �ltima sesi�n), logs editables, bot�n "mejorar" (nuevo registro pre-cargado), stats de avance (primero/�ltimo/?) e historial de mejora por ejercicio; (4) el bot�n del mazo en Home se dividi� en 3 (Poemas ? deck filtrado, Trivia, y tercero Mazo general).
**Cambios realizados**:
- `favoritos_screen.dart`: `_catSelector` limita el picker a movie/series/game/music.
- `calendar_home_screen.dart`: grilla minimalista (quit� colores arco�ris por d�a) � celdas neutras `#122433`, hoy = borde cian, seleccionado = cian lleno, dots de eventos, nav con iconos + "volver a hoy".
- `class_board_screen.dart`: `_weekStrip` (LUN..DOM con hoy/selecci�n) arriba + agenda full-width con barra de color del tipo, hora grande y profesor.
- `ejercicios_screen.dart`: `_libraryChips` (chips de `distinctExerciseNames`), `_dialogNewLog` soporta `existing` (editar v�a `updateLog`), `_promptItem` reusa chips, `_dialogNewRoutine` ahora crea rutina con items (chips de biblioteca con autollenado de la �ltima sesi�n + "+ ejercicio"), detalle de log con botones editar/mejorar, `_improvementBlock` (PRIMERO/�LTIMO/AVANCE + historial completo por fecha seriesxreps@peso).
- `deck_overlay.dart`: param `category` (filtra pendientes; fallback a todas). `home_screen.dart`: bloque mazo ? 3 mini-botones (menu_book poemas / school trivia / style mazo).
- Tests suite **238 verdes**, analyze sin issues nuevos.
**Lecciones**:
- El autollenado de la rutina desde la biblioteca (�ltima sesi�n: series/reps/peso/descanso) hace el setup del plan semanal natural y consistente con los logs: mismo origen de datos.
- `WorkoutLog.loggedOn` es no-nullable: usar `?.`/`??` ah� dispara `dead_null_aware_expression` (lo atrap� el analyzer).
- La grilla de calendario "minimalista" = menos color por celda (neutra) y acento solo en HOY/SELECCI�N/eventos: el ruido era los 12 colores por d�a.
- **BUILD R�PIDO (no hace falta `flutter clean`)**: para refrescar el �pice de Dart alcanza con borrar `build\windows\x64\runner\Release\data\app.so` + `\.dart_tool\flutter_build` y correr `flutter build windows --release` (~2 min vs 20+ con clean). El exe runner no cambia (solo c�digo C++), la BD de `Release\.dart_tool\sqflite_common_ffi` tampoco se toca. Verificado por markers en `app.so` (router viejo ausente / features nuevas presentes).
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE - Tiles legibles (icono+t�tulo, tama�o por texto) + mosaico en las 4 pantallas restantes
**Resumen**: Seg�n feedback, los bloques "solo cuadrado con icono" no se entend�an. Ahora cada tile muestra su icono de estado + el T�TULO del �tem debajo, y el arranger reparte el �rea en proporci�n a la cantidad de texto (m�s texto ? bloque m�s grande), manteniendo el mosaico desordenado. Adem�s se aplic� el mosaico a las 4 pantallas que faltaban (Chat, Calendario, Pizarra, Ejercicios) con wrappers de entrada.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: `arrange()` acepta `weights` por �tem � el slicing reparte el �rea proporcional a los pesos (con jitter de seed y fracci�n acotada 0.4�0.6 para mantener rect�ngulos equilibrados).
- `lib/widgets/loca_screen.dart`: `LocaEntry.label` (t�tulo corto) ? el tile renderiza `icono + t�tulo` en Bangers (2 l�neas, ellipsis); pesos autom�ticos `1 + len/14` (clamp 1�8).
- Labels cargados en las 13 pantallas: t�tulos de retos/metas/cartas/recompensas/notificaciones/logros, descripci�n de transacciones, categor�as de favoritos (pelis/series/juegos/m�sica), saldo/ingresos/gastos, Facu/Rocio, etc.
- `lib/screens/mosaico_wrappers.dart` (nuevo): `ChatMosaicoScreen`, `CalendarMosaicoScreen` (calendario+clases), `PizarraMosaicoScreen`, `EjerciciosMosaicoScreen` (4 tiles Hoy/Ejercicios/Retos/Stats). Home y Nosotros navegan a los wrappers; el contenido funcional original queda detr�s (rutas viejas intactas). `EjerciciosScreen` gana `initialTab`.
- Tests: `loca_arranger_test` +2 (pesos ? bloque m�s grande; sin pesos balanceado). Suite **238 verdes**.
**Lecciones**:
- "Que se entienda qu� es cada bloque" ? texto grande: icono de estado + t�tulo chico en Bangers debajo es suficiente, y el t�tulo alimenta el tama�o (peso) del bloque ? la legibilidad y la variaci�n de tama�o salen de los mismos datos.
- La fracci�n de corte debe acotarse (0.4�0.6) aunque el peso lo pida, o se generan bloques tira; el peso se aplica suave.
- Para pantallas con input/canvas (chat, grilla, canvas, tabs), el mosaico es una capa de entrada (wrapper) que reusa la pantalla funcional: no hay que reescribir la funcionalidad para tener el look.
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE - Sistema "Loca" extendido a 13 pantallas + mosaico apilado con espacio y columna de acciones fija
**Resumen**: Continuaci�n de la transformaci�n visual. Se refin� el mosaico (columnas apiladas masonry con espacio entre bloques, sin rotaciones) y se fijaron los botones de acci�n (+, escribir, enviadas, gps) en una COLUMNA LATERAL fija (mismo lugar y tama�o; los �tems se adaptan). Se convirtieron 9 pantallas m�s al patr�n "loca": Notificaciones, Logros, Recompensas, Configuraci�n, Login, Trivia, Finanzas, Favoritos y Galer�a.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart`: reescrito a "columnas apiladas" (masonry) � distribuye en hasta 4 columnas de ancho variable y apila bloques de altura variable dentro de cada una; rotaci�n siempre 0 (sin tiles torcidos); dims m�nimos 12%.
- `lib/widgets/loca_screen.dart`: gap (4�12px) entre bloques v�a inset; `LocaEntry.isAction` + columna lateral derecha fija (`_actionColumn`) donde viven los botones de acci�n con tama�o fijo. `LocaEntry.panels` con `(context, close)`.
- Pantallas convertidas: **Notificaciones** (1 tile � notificaci�n le�da/no le�da + "marcar todas" lateral), **Logros** (tile � logro desbloqueado/bloqueado + swap "X/N" + cajita lateral), **Recompensas** (tile � recompensa cumplida/pendiente + swap de saldo + alta lateral), **Configuraci�n** (tiles cambiar-sesi�n/sonido), **Login** (Facu rojo/Rocio violeta full-screen), **Trivia** (tile swap al marcador + juego completo en panel), **Finanzas** (tiles balance/ingreso/gasto con swap + gr�fico en panel + 1 tile � transacci�n + alta lateral), **Favoritos** (tile � categor�a ? panel con lista + swap de guardados + alta lateral), **Galer�a** (mosaico de fotos con thumbnail + subir lateral + detalle fullscreen).
- Tests: suite **236 verdes** (sin cambios de comportamiento; arranger ya testeado). `flutter analyze` baseline.
**Lecciones**:
- Un UNA pantalla "loca" de datos se traduce "N tiles homog�neos": cada �tem es a la vez el "visto/no visto" (check/c�rculo/le�da/candado) y el bot�n que abre SOLO ese �tem. Los modales de detalle/edici�n existentes se reusan tal cual (s�lo cambia la entrada).
- Las pantallas interactivas (Chat, Calendario, Pizarra, Ejercicios) NO caben en "icono + swink" sin perder funcionalidad (input/grilla/canvas): quedan con su UI funcional; proponer envolverlas en tiles que abran su contenido a fullscreen.
- El `flutter build windows --release` incremental no refresca `app.so` (stale): cada cambio de Dart exige `flutter clean` + rebuild completo (ver entrada anterior).
**Aprendizaje build**: cerrar `furi_app.exe` antes de linkear (LNK1104).
**Impacto**: `loca_arranger.dart`, `loca_screen.dart`, 9 screens, docs. Exe recompilado y BD local restaurada.
**Relacionado con**: skill-pantallas regla 10, D-4, glosario (pantalla "loca").

## [2026-08-27] - FEATURE - Piloto "loca" iterado: un bloque por �tem (visto/no visto) en lugar de "un bot�n lista todo"
**Resumen**: Ajuste del piloto seg�n feedback: el usuario no quer�a un �nico bot�n-icono que abriera la lista entera, sino **UN bloque-icono gigante por cada reto/meta/carta** repartido en el mosaico, con icono de estado "visto/no visto" (check = hecho/le�da, c�rculo = pendiente, candado = carta sellada) y al apretar un �tem se abre S�LO ese �tem en el panel.
**Cambios realizados**:
- `lib/widgets/loca_screen.dart`: `LocaEntry` gana `childBuilder` (contenido custom del bloque, p. ej. icono de estado) adem�s de `icon`/`swapBuilder`.
- `lib/screens/retos_screen.dart`: 1 tile por reto (check_circle hecho / radio_button_unchecked pendiente, colores de paleta ciclando por �ndice) + tiles loading (hourglass) / error (cloud_off, tap=reintentar) / "+" crear. Panel por reto (solo ese reto): t�tulo + autor + acciones toggle/editar/borrar.
- `lib/screens/metas_screen.dart`: igual (check/hecho, trofeo de autor).
- `lib/screens/letters_screen.dart`: 1 tile por carta recibida con estado de le�da (`mark_email_read`/`markunread`) y selladas (candado �mbar); tile Enviadas (panel con lista) y tile "+" escribir. Panel por carta (t�tulo+cuerpo, o candado "se podr� abrir�" si sellada).
- Loading/error ahora son tiles visibles (icon-only) en el mosaico, no banners de texto.
**Lecciones**:
- `flutter build windows --release` INCREMENTAL devuelve "v Built" pero NO regenera `data/app.so` con los cambios de Dart (el snapshot queda stale; verificado grepeando strings del binario). Solo `flutter clean` + rebuild garantiza el c�digo nuevo. El `app.so` limpio respondi� tambi�n por UTF-16 para acentos (los check ASCII como los channel strings bastan para validar).
- El s�mbolo de estado como tile �nico (check/c�rculo/candado) comunica "visto/no visto" sin texto y cada panel de detalle es 1:1 con su tile: mismo �ndice en `entries` y `panels`.
**Impacto**: 1 widget + 3 screens. Suite **236 verdes**. `flutter analyze` baseline. Exe Windows recompilado con clean (verificado: channel strings + `LocaArranger` + dise�o por-�tem presentes en `app.so`).
**Relacionado con**: skill-pantallas regla 10, D-4.

## [2026-08-27] - FEATURE - Sistema "Loca" estilo Nosotros + piloto en 4 pantallas (fase 1 de la transformaci�n visual)
**Resumen**: Se cre� el kit compartido para convertir TODAS las pantallas (excepto Home y Mazo) al sistema de la pantalla Nosotros: mosaico de bloques-icono gigantes que ocupa todo el lienzo, cero texto a simple vista, swaps autom�ticos sobre el contenido y paneles swink para leer/manipular los datos. Como piloto se redise�aron Retos, Metas, Cartas y Mapa; el patr�n queda listo para replicar al resto.
**Cambios realizados**:
- `lib/widgets/loca_arranger.dart` (nuevo): `LocaRect` + `LocaArranger.arrange(width, height, cantidad, seed)` � mosaico determin�stico que divide el lienzo en N bloques sin solapamiento (slicing recursivo aleatorio con semilla, corta preferentemente la dimensi�n larga y clampa contra micro-tiras <12%), con rotaciones de la paleta brutalista (0 o �0.06/�0.12 rad). Ocupaci�n del 100% del lienzo.
- `lib/widgets/loca_screen.dart` (nuevo): `LocaEntry` (icon + color + panel/onTap + swapBuilder), `LocaScreen` (fondo ConcretePainter + header con volver/corazones sin texto + entradas distribuidas por seed + backdrop + paneles swink con animaci�n scale/opacity de 400ms tipo Nosotros), `LocaScreen.panel` (shell brutalista) y `LocaScreen.closeIcon`.
- `lib/screens/retos_screen.dart`: reescrito a LocaScreen � bloque bandera (swap con el pr�ximo reto, abre panel con lista toggle/editar/borrar) + bloque "+" (dialog de crear). Realtime nuevo en `challenges`.
- `lib/screens/metas_screen.dart`: reescrito a LocaScreen � bloque trofeo (swap con la pr�xima meta, panel con lista) + "+". Realtime nuevo en `goals`.
- `lib/screens/letters_screen.dart`: reescrito a LocaScreen � Recibidas (swap con �ltimo correo), Enviadas, Escribir (mantiene la vista de composici�n completa con programaci�n de apertura). Se eliminaron las pesta�as texto.
- `lib/screens/mapa_screen.dart`: reescrito a LocaScreen � bloque mapa (swap con "X km", panel con distancia/pines/estado) + bot�n GPS (compartir/ingreso manual).
- Tests TDD: `test/widgets/loca_arranger_test.dart` (8): cantidad exacta, partici�n total sin overlap, dentro del lienzo, determinismo por seed, seeds distintos ? distribuciones distintas, rotaciones de paleta, sin micro-tiras, aspect acotado.
- Docs: `skill-pantallas.md` (regla 10 "Sistema Loca"), `glosario.md` (pantalla "loca"), `arquitectura.md` (widgets).
**Lecciones**:
- El slicing recursivo aleatorio con semilla da "loca" garantizando: (a) mayor�a de la long axis para no degradar en tiras, (b) clamp de dimensi�n m�nima 12% para bloques usables, (c) rotaciones chicas (�0.12 rad) que se ven org�nicas pero no rompen la hit-target. El arranger es l�gica pura testeable � misma t�cnica que CoupleStats/WorkoutStats.
- Cero texto "a simple vista" NO significa cero texto: el contenido llega en el swap (t�tulos de retos/metas, preview de cartas, distancia) y en los paneles (listas, textos de cartas). Es una capa de presentaci�n (la entrada es solo iconos) que reusa la l�gica CRUD existente.
- `LocaScreen.panels` son builders con firma `(context, close)` para que el contenido interno pueda cerrar el swink (bot�n X); el estado de apertura vive en el widget compartido, no en cada pantalla.
- El swap auto-programado exige que el builder lea el estado vivo (la pantalla provee `swapBuilder` con los datos actuales), as� al recargar por realtime el swap muestra el �tem nuevo.
- `LocaArranger` NO debe solapar bloques: el mosaico + rotaciones ya se ve "loco" y evita pelea de taps en las zonas de intersecci�n.
**Pendiente**: replicar el patr�n a las dem�s pantallas (settings, notifications, trivia, finanzas, galer�a, favoritos, ejercicios, logros, rewards, chat, calendar, pizarra, login) en tandas, validando con el usuario.
**Impacto**: `loca_arranger.dart` (nuevo), `loca_screen.dart` (nuevo), 4 screens reescritas, 1 test nuevo (8 casos). Suite **236 verdes** (antes 228). `flutter analyze` 23 (baseline, sin errores nuevos).
**Relacionado con**: D-4 (estilo brutalista / skill_visual), convenciones (solo iconos), skill-pantallas regla 10, FURI-Nosotros-Skill (swink/swap), glosario.

## [2026-08-27] - REFACTOR - Estilo "Nosotros" unificado en todas las pantallas (excepto Home y Mazo)
**Resumen**: Refinamiento profundo de TODAS las pantallas navegables (excepto Home, excluida por el usuario, y Mazo, que conserva su dise�o deliberado de degradados sin bordes) para alinearlas 100% al sistema de estilo de la pantalla Nosotros: fondo ConcretePainter, tipograf�a Bangers, bloques brutalistas (borde==relleno, esquinas redondeadas, sombra negra dura), y TapTile en todo lo tappable. Se detect� que la mayor�a de pantallas ya usaban este sistema parcialmente; el trabajo cubri� las brechas y puli� la consistencia.
**Cambios realizados**:
- `lib/widgets/brutal_style.dart` (nuevo): `BrutalStyle` con helpers est�ticos `bg`, `fillIcon`, `card`, `block`, `clip`, `iconAction` � extrae y generaliza `btnBlock`/`fillIcon`/`bg` que viv�an hardcodeados en `nosotros_screen.dart` para que todas las pantallas compartan el mismo sistema.
- **Chat** (`chat_screen.dart`, `chat/widgets/*`): `fontFamily monospace` ? Bangers w900, `GestureDetector` ? `TapTile`, sombras duras en header/banners/input, botones +/mic/enviar ? TapTile.
- **Calendario** (calendar_home, daily_events, schedule_form, class_board, class_setup): fondos semitransparentes ? s�lidos, negro puro ? `#0D0D0D`, `monospace` ? Bangers, `GestureDetector` ? `TapTile`, borde==relleno en cards (el setup wizard adem�s pas� de fondo verde plano a ConcretePainter + cian #00D4FF de secci�n).
- **Ejercicios / Galer�a / Favoritos / Finanzas**: ejercicios gan� el fondo ConcretePainter (era el gap cr�tico) + sombras duras en paneles; galer�a/favoritos/finanzas ganaron borde==relleno + sombra dura en bloques; finanzas y favoritos convirtieron texto decorativo de di�logos (X/OK/Gasto?Ingreso) en iconos y acciones a TapTile.
- **Notes / Question / Mapa / Notifications / Settings / Login / Mood**: reemplazado `fontFamily: 'monospace'` restante por GoogleFonts.bangers.
- **Logros / Recompensas / Trivia**: ya usaban `BrutalStyle.bg`; se limpiaron los `monospace` residuales a Bangers.
- **Pizarra v1 + Pizarra v2 (solo UI circundante)**: pizarra v1 gan� fondo ConcretePainter + header/herramientas con bloque est�ndar; pizarra v2 convirti� botones/hints/banners/di�logos a Bangers + TapTile conservando intacto el grid del canvas, el InteractiveViewer y los renderers.
- `nosotros_screen.dart`: solo limpieza de warnings (sin cambios funcionales).
**Lecciones**:
- Antes de una migraci�n masiva de estilo, hacer un grep de brechas (ConcretePainter / Bangers / TapTile por archivo): la mayor�a de pantallas ya compart�an el sistema y el trabajo real era cerrar las brechas (fondos faltantes, `monospace` residuales, semitransparentes, negro puro).
- `ConcretePainter` est� detr�s de `BrutalStyle.bg`; verificar por `BrutalStyle.bg` y no textualmente por `ConcretePainter` (las pantallas nuevas lo usan a trav�s del helper).
- Los errores de compilaci�n introducidos por cambios paralelos fueron 2 y triviales (�const� mal puesto en un `SnackBar` con `GoogleFonts.bangers` y en un `Positioned.fill` con `CustomPaint`). Validate siempre con `flutter analyze` despu�s de batches paralelos.
- Conservar dise�os deliberados documentados: el mazo (degradados sin borde) y el canvas de la pizarra v2 (grid + pan/zoom) no se tocan; solo la UI circundante.
**Impacto**: `widgets/brutal_style.dart` (nuevo), ~25 archivos de pantallas, `nosotros_screen.dart` (limpieza). Suite **228 tests verdes**, `flutter analyze` sin errores (22 issues, bajo el baseline 23).
**Relacionado con**: D-4 (estilo brutalista / skill_visual), convenciones (solo iconos), skill-pantallas.

## [2026-08-26] - FEATURE - Fase 1: puntos autom�ticos, mapa/distancias y m�s logros ??????
**Resumen**: Primera tanda de la "capa de juego/unicidad" (Fase 1). Se automatiz� la ganancia de puntos (antes `RewardsProvider.addPoints` era un hook sin llamar), se hizo real la pantalla de Mapa/Distancia (era un placeholder de 2.3 km falso), y se ampli� la colecci�n de logros de pareja de 8 a 13. El aviso del bot de logro desbloqueado (1.1) ya estaba implementado (categor�as #21/#22 de bot.js).
**Cambios realizados**:
- **1.2 Puntos autom�ticos** (`rewards_provider.dart`): nuevo `awardOnce(userId, reason, delta)` IDEMPOTENTE � consulta si la raz�n ya fue aplicada a ese usuario antes de insertar (el ledger `couple_points` no tiene constraint �nico), evitando duplicados por realtime/reintentos. Hooks al action-site (no en realtime): mood registrado en `nosotros_screen._addMood` (+1, `mood-$fecha`), d�a de entrenamiento marcado en `ejercicios_screen._markBtn` (+2, `workout-$fecha`), match del mazo en `home_screen` al cerrar el overlay (match +5 a AMBOS, `match-$cardId`). Cada provider se captura ANTES del await (evita `use_build_context_synchronously`).
- **1.3 Mapa/Distancia real** (+`geolocator`): modelo `lib/models/couple_location.dart` (`CoupleLocation` + `distanceKm` haversine pura testeable), `LocationProvider` (carga/upsert realtime en `couple_locations` PK user_id, `coupleDistanceKm`), tabla `couple_locations` (migraci�n + schema master, **pendiente ejecutar en SQL Editor**), `mapa_screen.dart` reescrito � bot�n "Actualizar ubicaci�n" usa GPS (geolocator) con fallback a entrada manual en desktop/denegado; muestra distancia + estado por usuario.
- **1.4 M�s logros** (`couple_achievement.dart` / provider): `AchievementSnapshot` +5 campos (moodCoupleStreak, totalWorkouts, bothSharedLocation, hasFulfilledReward, bothAnsweredTrivia) y 5 logros nuevos: `mood_streak_7`, `workouts_50`, `location_shared`, `reward_fulfilled`, `trivia_day`. Provider computa los nuevos campos (racha de �nimo solo-moods con `CoupleStats.streakFor`, conteo de completions, consultas a `couple_locations`/`couple_rewards`/`question_answers`). El �lbum usa `CoupleAchievements.all.length` ? "X de 13" se actualiz� solo.
- `main.dart`: + `LocationProvider` (20� provider).
- Tests TDD: `couple_location_test.dart` (5: haversine BA?C�rdoba ~647 km, mismo punto=0, falta dato=0, round-trip, fecha ausente) + `couple_achievement_test.dart` (+5 para los logros nuevos). Suite total **228 verdes** (antes 218). `flutter analyze` 22 (baseline, sin errores). `node --check bot.js` OK.
**Lecciones**:
- El hook de puntos debe vivir en el ACTION-SITE (escritura), nunca en un callback realtime: el realtime dispara por cada cambio de fila y duplicar�a puntos. `awardOnce` con chequ�o por `reason` es la red de seguridad contra reintentos/doble-dispositivo.
- `distanceKm` por haversine da distancia en L�NEA RECTA: Buenos Aires?C�rdoba da ~647 km, no los ~695 de ruta. Para asserts usar el valor haversine real, no la distancia vial.
- La pesta�a "Mapa" era un placeholder con valor hardcodeado; para el fallback de GPS en desktop/permiso-denegado, un di�logo manual de lat/lng es suficiente y evita romper el build de Windows (geolocator tiene soporte limitado en desktop).
- `coupled_achievements` claves UNIQUE + `AchievementSnapshot` con defaults 0/false hacen que sumar logros nuevos no rompa los tests existentes de `earnedCodes` (el snapshot vac�o sigue ? isEmpty).
- El bot ya ten�a la categor�a de logro (1.1): confirmar lo existente antes de "implementar" de nuevo (historiel/rewards ya lo documentaba como #21/#22).
**Pendiente**: ejecutar `supabase/migration_couple_locations.sql` en SQL Editor (para que el mapa funcione contra la nube). Verificar build de Windows tras sumar `geolocator` (plugin nativo ? puede exigir `vcvarsall.bat amd64` con TRK0005, seg�n errores-conocidos).
**Impacto**: `rewards_provider.dart`, `nosotros_screen.dart`, `ejercicios_screen.dart`, `home_screen.dart`, `couple_location.dart` (nuevo), `location_provider.dart` (nuevo), `mapa_screen.dart`, `couple_achievement.dart`, `couple_achievements_provider.dart`, `main.dart`, `pubspec.yaml` (+geolocator), `supabase/migration_couple_locations.sql` (nuevo), `supabase_schema.sql`, 2 tests nuevos, docs.
**Relacionado con**: D-2 (Supabase), D-8 (points/recompensas), Fase 1 del roadmap, FURI-Nosotros-Skill (distancia), glosario.

## [2026-08-26] - FEATURE - Router GoRouter (�ltimo �tem de la Fase 0 del roadmap)
**Resumen**: Se reemplaz� la navegaci�n con `Navigator.push(MaterialPageRoute)` dispersa (~30 call sites en 8 archivos) por un **route table centralizado con GoRouter**. El arranque login/home deja de usar `home:` en MaterialApp y se resuelve con un `redirect` basado en sesi�n.
**Cambios realizados**:
- `pubspec.yaml`: + `go_router: ^17.5.0`.
- `lib/router.dart` (nuevo): `appRouter` (GoRouter) + `RouterRoutes` (consts de ruta) + `navigatorKey` (movido desde main.dart). 22 rutas: login, home, settings, notifications, nosotros, calendar, trivia, finanzas, galeria, favoritos, pizarra, ejercicios, logros, rewards, chat, retos, cartas, metas, mapa, scheduleForm, dailyEvents, classBoard, classSetup. Las pantallas que reciben `AppMode` lo toman por `state.extra` (helper `_mode(state)` con fallback `AppMode.dark`). `redirect` gatea `/`, `/login` y `/home` seg�n `AppState.myId` (corre dentro de runApp, ya con sesi�n cargada ? no se pudo usar `initialLocation`, que se evaluar�a en top-level antes de `loadSession`).
- `lib/main.dart`: `MaterialApp` ? **`MaterialApp.router(routerConfig: appRouter)`** (Flutter 3.44 separ� el router en el constructor `.router`; el base ya NO acepta `routerConfig`). Eliminado `navigatorKey` local y el par�metro `startDirect` de `FuriApp` (el redirect resuelve login/home). Escape?maybePop sigue usando `navigatorKey` (ahora de router.dart).
- Rewire de todos los push: `home_screen.dart` (11), `calendar_home_screen.dart` (5, +`context.push<bool>(classSetup)` con resultado), `daily_events_screen.dart` (3, con inicial+schedule por extra), `nosotros_screen.dart` (5), `logros_screen.dart` (1), `login_screen.dart` (`context.go('/home')` en vez de `pushReplacement`), `settings_screen.dart` (`context.go('/login')` en vez de `pushAndRemoveUntil`). Los flujos que devuelven resultado (`_checkClassSetup` bool; editar form con `Schedule` por `extra`) usan `context.push`, que propaga el `pop`. Poda de imports de pantallas que quedaron sin uso directo (los referencias ahora el router).
- Tests: suite **218 verdes** (widget_test + providers_test siguen pasando: `FuriApp()` ? redirect a `/login` sin sesi�n). `flutter analyze` 22 (por debajo del baseline 23, gracias a la poda de imports sin uso).
**Lecciones**:
- En Flutter 3.44 (y +3.10) `routerConfig` NO es un par�metro del constructor base de `MaterialApp`: es de **`MaterialApp.router`**. El error `The named parameter 'routerConfig' isn't defined` era REAL, pero parec�a un glitch del analyzer porque aparec�a/desaparec�a intermitentemente (cache del daemon durante el warmup); la confirmaci�n definitiva la dio el compilador en `flutter test`, no el analyzer solo.
- `initialLocation` en GoRouter se eval�a al construir el `final` top-level del m�dulo de router (antes de `main()` y antes de `AppState.loadSession()`), as� que a esa altura `AppState.myId` a�n es null ? arrancar�a siempre en `/login` para usuarios ya logueados. La soluci�n es un `redirect` (corre dentro de `runApp`, con la sesi�n ya cargada por `main()`).
- Los screens que reciben objetos (AppMode, Schedule, DateTime) no se pueden ruteear por string: se pasan por `state.extra` y el builder hace el cast/despacho (`is Schedule ? ScheduleFormScreen(schedule:)`, `is DateTime ? ...(initialDate:)`). Los flujos con retorno tipado (`push<bool>`) se cubren con `context.push<T>`, que propaga el resultado del `pop`.
- La app antes importaba pantallas solo para navegar a ellas; con el router centralizado esas pantallas las importa `router.dart`, as� que se pudaron los imports directos que quedaron sin uso (por eso analyze baj� de 23 a 22).
- `navigatorKey` debe vivir donde se construye el router (router.dart) y pasarse a `GoRouter`, para que el callback Escape?maybePop apunte al mismo Navigator que GoRouter crea.
**Pendiente**: ninguno. (Al no haber deep-links reales ni auth, el router no requiere config extra; si se agregan rutas, sumarlas a `RouterRoutes` + tabla de `appRouter`.)
**Impacto**: `pubspec.yaml`, `router.dart` (nuevo), `main.dart`, 8 screens, docs.
**Relacionado con**: D-14 (router), Fase 0 del roadmap, errores-conocidos (sin sistema de rutas RESUELTO).

## [2026-08-26] - FEATURE - Merge at�mico de reacciones en Postgres (RPC server-side, Fase 0)
**Resumen**: �ltimo �tem grande de la Fase 0 (junto al router). Se elimin� la race condition de "�ltimo write gana" en las reacciones: antes cada provider enviaba el mapa `reactions` completo en cada update, y dos reacciones simult�neas (Facu + Rocio) al mismo �tem pisaban la del otro (BUG 2 CR�TICO de la auditor�a del pizarr�n). Ahora el merge ocurre DENTRO de Postgres con row-level lock (`SELECT ... FOR UPDATE`), y los providers hacen optimistic local + reconciliaci�n con la respuesta autoritativa de la RPC.
**Cambios realizados**:
- `supabase/migration_reaction_rpc.sql` (nuevo): 2 RPC idempotentes + GRANT a anon/authenticated:
  - `toggle_reaction(target_table, target_col, row_id, reaction_key, user_id)`: forma `{key:[uid]}`, max 5 keys, toggle on/off (1 reacci�n por usuario, se quita de todas las keys y se agrega/quita de la key objetivo). Espejo exacto de `Message.toggleReaction`/`BoardSocialData.withToggledReaction`. Whitelist estricta de `(tabla, columna)` para evitar SQL injection en identificadores din�micos; cubre `messages.reactions`, `gallery.reactions`, `workout_*.social` y `board_elements_v2.data`. Bump de `updated_at` solo donde la columna existe. **PENDIENTE ejecutar en SQL Editor**.
  - `react_deck_card(row_id, user_id, reaction)`: forma `{uid:emoji}` (mazo), `jsonb_set` at�mico + bump `updated_at`.
- `supabase_schema.sql`: RPCs (#29a/29b) agregadas al schema master (mismo origen que `notify_new_message`).
- `lib/providers/chat_provider.dart`, `gallery_provider.dart`, `workout_provider.dart`, `deck_provider.dart`, `board_provider_v2.dart`: rewire de las escrituras de reacciones para llamar a la RPC en vez de `.update({...reactions})` con mapa completo. Mantienen optimistic en memoria + rollback a `_error` en fallo y reconcilian contra el mapa autoritativo devuelto por la RPC.
  - workout: nuevo helper `_reactViaRpc()` (usa `_reactViaRpc`); solo los m�todos de reacci�n (`toggleLogReaction/Routine/Challenge`) cambian � los de comentarios siguen por el update de documento.
  - board: nuevo m�todo `BoardProviderV2.react()` para **no** disparar el push de documento completo (que reintroducir�a el race); `board_element_options.dart` llama `pv.react(...)` en vez de `pv.update(...)`.
  - deck: `react()` usa `react_deck_card`; el `reactLocal` optimista (que setea `_pendingMatch`/match) se conserva.
- Tests: `test/services/reaction_merge_contract_test.dart` (nuevo, 6 tests) que documenta en l�gica pura el contrato que la RPC DEBE replicar (dos usuarios misma key se preservan, toggle off, mover entre keys, max 5 keys, reemplazo deck, match). Suite total 218 verdes (antes 212). `flutter analyze` 23 (baseline, sin errores; el �nico en archivos tocados es `gallery_provider.dart:110` preexistente).
**Lecciones**:
- El merge client-side en realtime (que ya exist�a como parche) NO garantiza consistencia en el servidor: el UPDATE final con el mapa completo siempre puede pisar al concurrente. La RPC con `FOR UPDATE` serializa fila a fila y es la defensa real en el origen.
- Las reacciones viven en **3 formatos distintos** (messages/gallery/board/workout = `{key:[uid]}`; deck = `{uid:emoji}`), as� que no hay un RPC gen�rico de una talla: uno cubre la forma A con whitelist de tablas/columnas y otro la B.
- En el l�mite de 5 keys, `toggleReaction` de Dart devuelve el mapa ORIGINAL intacto (no el mutado): el SQL debe chequear el l�mite ANTES de mutar, o devolver�a un estado al que ya le quit� la reacci�n al usuario aunque no persisti�.
- Al rewirear un m�todo que el codebase reusa para DOS cosas (workout `social` = reacciones + comentarios), NO hay que reemplazar el m�todo completo: solo la rama de reacciones. Los comentarios siguen por el update de documento.
- En board no alcanza con cambiar el link al RPC: hab�a que un m�todo dedicado (`react`) para que el `pv.update` (que pushea el `data` entero con debounce) no sobrescriba el merge at�mico con el mapa local.
- `flutter analyze` degrad� netbook warnings (dead_code/dead_null_aware) por usar `myId ?? ''` donde `myId` ya es no-nullable en chat/workout; `AppState.myId` (nullable) s� lo necesita.
**Pendiente**: ejecutar `supabase/migration_reaction_rpc.sql` en SQL Editor de Supabase (sin esto, los providers rompen al intentar `rpc('toggle_reaction'...`). La equivalencia del merge qued� testeada en l�gica pura, pero la RPC en s� no tiene harness en la suite.
**Impacto**: 2 RPC + schema master, 4 providers + board react, 1 widget board, 1 test nuevo, docs.
**Relacionado con**: D-2 (Supabase), BUG 2 CR�TICO (auditor�a pizarr�n v2), Fase 0 del roadmap, glosario (reacci�n).

## [2026-08-26] - REFACTOR - Chat: separaci�n por widgets (reduce chat_screen de 1359 a ~700 l�neas)
**Resumen**: Fase 0 del roadmap. `chat_screen.dart` era el cuelo de botella citado en arquitectura.md. Se extrajeron todos los widgets presentacionales (que no dependen del estado del controller) a archivos dedicados, dejando en `chat_screen.dart` solo el controller de l�gica (enviar/adjuntar/grabar/reacciones) + layout (header, msg area, input, banner de reply, banner de error).
**Cambios realizados**:
- `lib/screens/chat/chat_style.dart` (nuevo): paleta compartida `ChatStyle` (antes constantes privadas de chat_screen: primary, bg, panel, inputBg, darkText, errorBg, mediaBg).
- `lib/screens/chat/widgets/chat_react_chip.dart` (nuevo): `ChatReactChip` (chip de emoji/`+`).
- `lib/screens/chat/widgets/chat_swipe_to_reply.dart` (nuevo): `ChatSwipeToReply` (swipe acumulado).
- `lib/screens/chat/widgets/chat_reactions_row.dart` (nuevo): `ChatReactionsRow`.
- `lib/screens/chat/widgets/chat_media_body.dart` (nuevo): `ChatMediaBody` + `_ChatLocalMediaView` + `_ChatVideoThumb` + `_ChatAudioPlayerTile` (media: descargable/local, video, audio, archivo).
- `lib/screens/chat/widgets/chat_message_tile.dart` (nuevo): `ChatMessageTile` (burbuja con reply/ticks/reacciones).
- `lib/screens/chat_screen.dart`: reescrito para usar los widgets extra�dos; eliminadas las definiciones movidas. Misma ruta (`lib/screens/chat_screen.dart`) ? ninguna referencia del resto de la app cambi�.
**Lecciones**:
- Un refactor de extracci�n es seguro si MUEVE clases enteras (sin renombrarlas salvo el prefijo `_` ? p�blico) y deja la ruta p�blica del archivo original intacta: cero cambios en los callers.
- La paleta compartida evita duplicar constantes privadas por archivo; al mover widgets, las constantes de estilo deben viajar a un archivo estilo (`ChatStyle`) o cada widget re-declara las suyas.
- Verificar con `flutter analyze` + suite completa despu�s del refactor: 212 tests verdes, sin cambios de comportamiento.
**Impacto**: `chat/chat_style.dart` (nuevo), `chat/widgets/*` (5 nuevos), `chat_screen.dart`. Suite 212 verdes, analyze baseline.
**Relacionado con**: Fase 0 del roadmap, convenciones (widgets separados, UIN).

## [2026-08-26] - FEATURE - Puntos y Recompensas de pareja ?? (cajita de deseos)
**Resumen**: �ltima pieza de la capa de juego. El �lbum de Logros ahora da acceso a una "cajita de deseos": recompensas f�sicas que cuestan puntos y se marcan como cumplidas, con un libro de puntos (libro mayor, deltas positivos/negativos) y balances por usuario. Los avisos del bot ganan 2 categor�as nuevas: logro desbloqueado (a ambos) y resultado de la trivia del d�a.
**Cambios realizados**:
- `lib/models/rewards.dart` (nuevo): `CoupleReward` (id, title, emoji, cost, fulfilled, createdBy) con fromMap/toMap/copyWith, `PointsEntry` (userId, reason, delta, createdAt), y `PointsStats` l�gica pura: `balanceOf`, `total`, `pointsEarned`.
- `lib/providers/rewards_provider.dart` (nuevo): CRUD de recompensas (`addReward`, `deleteReward`, `toggleFulfilled`) + `addPoints` (hook para automatizar ganancia de puntos en el futuro), balances (`myBalance`, `totalEarned`), pendientes/cumplidas. Realtime en ambas tablas. Registrado en `main.dart` (19� provider).
- `supabase/migration_rewards.sql` (nuevo): tablas `couple_rewards` y `couple_points` + �ndices + RLS full access + publicaci�n realtime + GRANTs. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: tablas #24c + �ndices + RLS + policies.
- `lib/screens/recompensas/rewards_screen.dart` (nuevo): balance (saldo/total/cumplidas), lista de recompensas (cumplidas se marcan en verde), dialog de alta, estados loading/empty/error/data, brutalista. Acceso desde el header de `LogrosScreen` (bot�n regalo ??).
- `lib/screens/logros/logros_screen.dart`: bot�n de acceso a Recompensas.
- `bot-furi/bot.js`: categor�a #21 logro desbloqueado (`couple_achievements.awarded_at` en la �ltima hora ? a AMBOS, con emoji/t�tulo v�a `descripcionLogro`) y categor�a #22 trivia (`question_answers` del d�a con los 2 miembros ? aviso "�qui�n conoce m�s?"). Tracking `logro-{code}`/`trivia-{date}`.
- Tests TDD: `test/models/rewards_test.dart` (7). Suite total 212 verdes (antes 205). `flutter analyze` sin issues nuevos (23 preexistentes). `node --check bot.js` OK.
**Lecciones**:
- El balance de puntos es l�gica pura (`PointsStats`) y la ganancia es un libro mayor (`PointsEntry` con deltas), as� el "gasto" de recompensas es solo un delta negativo; no hay que tocar el schema para gastar.
- La automatizaci�n de ganancia de puntos (sumar al hacer mood/entrenar/match) es un hook `addPoints` que el provider ya expone; por ahora la cajita funciona con recompensas y balances calculados en vivo.
**Pendiente**: automatizar la ganancia de puntos desde acciones reales (llamar `addPoints` desde providers de mood/workout/match).
**Impacto**: `rewards.dart` (nuevo), `rewards_provider.dart` (nuevo), `migration_rewards.sql` (nuevo), `supabase_schema.sql`, `rewards_screen.dart` (nuevo), `logros_screen.dart`, `main.dart`, `bot-furi/bot.js`, `rewards_test.dart` (nuevo), `bot-whatsapp.md`, `glosario.md`, docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot), logros (entrada previa), glosario.

## [2026-08-26] - FEATURE - Trivia de pareja ?? (pregunta del d�a: respond�s + predec�s)
**Resumen**: Juego diario de "cu�nto conoc�s a tu pareja". Cada d�a hay una pregunta con opciones; cada uno elige su respuesta y predice la de la otra. Cuando ambos responden, se revela el marcador acumulado de predicciones acertadas ("qui�n conoce m�s a qui�n"). Reusa las tablas `daily_questions`/`question_answers` que estaban vac�as. Entrada desde el bot�n del Home (`Icons.school`, antes sin funci�n).
**Cambios realizados**:
- `lib/models/trivia.dart` (nuevo): `TriviaQuestion` (id, question, options) con fromMap/toMap, `TriviaAnswer` (id, questionId, userId, answer, guess, date), `TriviaQuestionBank` (10 preguntas de pareja con 4 opciones), y `TriviaStats` l�gica pura: `scoreFor` (un punto por cada predicci�n que acierta la respuesta real de la pareja), `bothAnsweredFor`, `questionForDay` (selecci�n por �ndice seg�n d�a del a�o).
- `lib/providers/trivia_provider.dart` (nuevo): siembra el banco en `daily_questions` si est� vac�o, carga preguntas + todas las respuestas (puntaje acumulado), expone `todayQuestion`/`todayAnswers`/`myAnswerToday`/`bothAnsweredToday`/`myScore`/`partnerScore`/`scoreboard`, `submit()` con delete-then-insert (permite re-responder el d�a). Realtime en `question_answers`. Registrado en `main.dart` (18� provider).
- `supabase/migration_trivia.sql` (nuevo): `daily_questions.options JSONB`, `question_answers.guess TEXT`, �ndices y publicaci�n realtime de `question_answers`. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: columnas `options` y `guess` en el CREATE master.
- `lib/screens/trivia/trivia_screen.dart` (nuevo): pregunta del d�a, chips de opciones para "Tu respuesta" y "Predec� a tu pareja", bot�n confirmar (se habilita con ambas), estado despues de responder (permite actualizar), marcador cuando ambos contestaron, header con scoreboard, estados loading/error/empty/data, brutalista.
- `lib/main.dart`: registrado `TriviaProvider`. `lib/screens/home_screen.dart`: `_openEstudio` ahora abre `TriviaScreen(mode: _mode)` (el bot�n Icons.school antes no hac�a nada).
- Tests TDD: `test/models/trivia_test.dart` (12). Suite total 205 verdes (antes 193). `flutter analyze` sin issues nuevos (23 preexistentes).
**Lecciones**:
- El `date` de `question_answers` (DATE, default CURRENT_DATE) viene como ISO sin zona y en `fromMap` hay que guardarlo como String para comparar contra el d�a local (`_today()`) sin desfases.
- Filtrar "respuestas de hoy" por columna `date` (String dd-aa) es m�s simple que parsear `created_at`; el modelo debe persistir ese campo.
- `TapTile` compartido exige `onTap` no-null: para un bot�n deshabilitable hay que pasar `() {}` y deshabilitar solo visual/metodo, no `null`.
- Reusar tablas vac�as (`daily_questions`/`question_answers`) adem�s de respetar el esquema evita migraciones nuevas de tablas.
**Pendiente**: aviso del bot WhatsApp del resultado diario de trivia (o lectura del marcador).
**Impacto**: `trivia.dart` (nuevo), `trivia_provider.dart` (nuevo), `migration_trivia.sql` (nuevo), `supabase_schema.sql`, `trivia_screen.dart` (nuevo), `main.dart`, `home_screen.dart`, `trivia_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot PENDIENTE), glosario.

## [2026-08-26] - FEATURE - FURI del mes ?? (memoria del mazo)
**Resumen**: Los matches del mazo ("FURI!!") ahora dejan memoria: el mazo muestra el "FURI del mes" (el match m�s reciente con categor�a+preview+mes), el conteo de FURIs del mes y la fecha del primer FURI de la pareja. El historial del mazo gan� un banner conmemorativo.
**Cambios realizados**:
- `lib/models/deck_memory.dart` (nuevo): `DeckMemory.latestMatch` (match m�s reciente por updatedAt), `firstMatch` (el primero), `matchesInMonth` (conteo por mes), `summary` (descripci�n legible). L�gica pura testeable.
- `lib/screens/mazo/deck_history_sheet.dart`: nuevo banner "FURI del mes" arriba del historial (fondo degradado de la categor�a, emoji, resumen, "N este mes", "Primer FURI: fecha"); se oculta si no hay matches.
- Tests TDD: `test/models/deck_memory_test.dart` (6). Suite total 187 verdes. `flutter analyze` sin issues nuevos.
**Lecciones**:
- Reusar `DeckCard.isMatch` y `updatedAt` como timestamp del match (cuando se actualiz� la reacci�n) da la memoria sin tocar el schema.
- `DeckCard.updatedAt` no es const y `matchesInMonth` compara con `DateTime.now()` � hay que pasar el mes expl�cito para mantener el test determin�stico.
**Impacto**: `deck_memory.dart` (nuevo), `deck_history_sheet.dart`, `deck_memory_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), mazo (entrada previa), glosario.

## [2026-08-26] - FEATURE - Cartas con apertura programada ?? + entrega ceremonial por bot
**Resumen**: Las cartas de la pareja ahora pueden programar su apertura. Si se elige una fecha de apertura, la carta queda "sellada" (??) para el destinatario hasta ese d�a: se ve el t�tulo pero el contenido no se revela, ni en la lista ni en Nosotros. El bot de WhatsApp no spoilea las cartas selladas al crearse y, cuando llega el momento, las "entrega" con un mensaje ceremonial a quien deb�a recibirlas.
**Cambios realizados**:
- `lib/models/letter.dart`: nuevo `Letter.isSealed({scheduledOpen, isIncoming, now})` � l�gica pura: una carta est� sellada cuando tiene `scheduled_open` futuro y es carta recibida (el autor siempre lee la suya).
- `lib/screens/letters_screen.dart`: estado `_scheduledOpen` en el compositor + barra "Programar apertura" (picker de fecha, se guarda `scheduled_open` en el INSERT, se resetea al enviar/cancelar). `_isSealed`/`_showSealed`: cards selladas muestran candado + "se abre el dd/mm/yyyy" y abren un di�logo de sobre sellado (no el contenido). Cuerpo de la carta y barra de programaci�n ajustados para no superponerse.
- `lib/screens/nosotros_screen.dart`: `_loadPartnerLetter` ahora ignora cartas selladas (`scheduled_open` futuro) y no las marca como vistas.
- `bot-furi/bot.js`: categor�a #4 LETTERS ignora cartas futuras (no spoilear). Nueva categor�a 4b "entrega ceremonial": consulta cartas cuyo `scheduled_open` cay� en la �ltima hora (`.gte(haceUnaHora).lte(ahora)`) y avisa al destinatario con `?? ... tu carta "... " acaba de abrirse`. Tracking `letteropen-{id}-{fecha}`.
- Tests TDD: `test/models/letter_test.dart` (5). Suite total 187 verdes (antes 182). `flutter analyze` sin issues nuevos (23 preexistentes). `node --check bot.js` OK.
**Lecciones**:
- El modelo `Letter` ya ten�a `scheduled_open` pero nada lo usaba: faltaba el "puente" entre el campo, el compositor (no lo guardaba) y el gating (nadie lo validaba). El campo por s� solo no es la feature.
- El gating por "sellado" debe ser por ROL, no solo por fecha: si no, el autor no podr�a releer la carta que escribi�. `isIncoming` (�to_user = yo?) + fecha futura = sellada; una carta propia siempre se puede leer.
- Las fechas de apertura se guardan en UTC (`toUtc().toIso8601String()`) y el bot compara contra `ahora.toISOString()` (tambi�n UTC) � coherencia de zona evitada.
- El bot ya ten�a tracking anti-duplicado por `(tabla, registro_id)`: reus� el mismo patr�n para la entrega ceremonial con key distinta (`letteropen-`) para no colisionar con la de "nueva" (`letter-`).
**Impacto**: `letter.dart`, `letters_screen.dart`, `nosotros_screen.dart`, `bot-furi/bot.js`, `letter_test.dart` (nuevo), `bot-whatsapp.md`, `glosario.md`, docs.
**Relacionado con**: D-2 (Supabase), D-10 (bot), D-4 (skill_visual), errores-conocidos (sin nuevos), glosario (carta sellada).

## [2026-08-26] - FEATURE - Logros de pareja ?? (colecci�n de insignias desbloqueables)
**Resumen**: Segunda pieza de la capa de juego/unicidad. La pareja desbloquea logros (insignias) al cumplir hitos: registraron mood ambos, entrenaron ambos, primer FURI!! del mazo, rachas de pareja (3/7 d�as y mejor racha 14+), y cantidad de mensajes (100/1000). Se muestran en una pantalla "�lbum" a la que se accede tocando el chip ?? de racha del Home. Las reglas son datos y la evaluaci�n es l�gica pura testeable (mismo patr�n que `CoupleStats`).
**Cambios realizados**:
- `lib/models/couple_achievement.dart` (nuevo): `CoupleAchievement` (code, emoji, title, description), `AchievementSnapshot` (coupleStreak, bestCoupleStreak, bothLoggedMood, bothWorkedOut, hasDeckMatch, totalMessages) con `copyWith`, `EarnedAchievement` (fromMap/toMap), y `CoupleAchievements` con 8 definiciones + `byCode` + `earnedCodes(snapshot)` (l�gica pura).
- `lib/providers/couple_achievements_provider.dart` (nuevo): `load()` carga los ya otorgados, construye el snapshot (queries a `moods`, `workout_completions`, `messages.count()`, `deck_cards` reacciones), calcula los c�digos obtenidos, e inserta los nuevos (guard por UNIQUE + diferencia de sets). Expone `earnedCodes`, `collected`, `remaining`. Realtime en `couple_achievements` (el otro dispositivo ve los logros al instante). Sin cache local. Registrado en `main.dart` (17� provider).
- `supabase/migration_couple_achievements.sql` (nuevo): tabla `couple_achievements` (id, achievement_code UNIQUE, awarded_at, created_at) + �ndice + RLS full access + publicaci�n realtime + GRANTs. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: tabla `couple_achievements` (#24b) + �ndice + RLS + policy.
- `lib/screens/logros/logros_screen.dart` (nuevo): �lbum en grilla 2 columnas con contador "X de 8 desbloqueados"; logros desbloqueados a color del tema, pendientes desvanecidos con candado ??; estados loading/error/data; skill_visual (fondo=borde, redondo, sombra brutalista, sin negro puro); reutiliza `TapTile` compartido (animaci�n + sonido).
- `lib/screens/home_screen.dart`: el chip ?? de racha ahora es tappable (`coupleTile` con `onTap`) y abre `LogrosScreen(mode: _mode)`. Nuevo m�todo `_openLogros()`.
- Tests TDD: `test/models/couple_achievement_test.dart` (16). Suite total 182 verdes (antes 166). `flutter analyze` sin issues nuevos (los 23 preexistentes).
**Lecciones**:
- Persistir los logros otorgados en una tabla (`couple_achievements`) es mejor que evaluarlos en vivo cada vez: da historial, sync entre dispositivos y base para el bot. La evaluaci�n (`earnedCodes(snapshot)`) sigue siendo l�gica pura testeable; el provider solo arma el snapshot.
- El `messages.count()` de postgrest devuelve `int` directo (`PostgrestFilterBuilder<int>`), no hace falta traer las filas � clave para contar mensajes sin peso.
- Guard de duplicados natural: la columna es UNIQUE y el provider inserta solo los c�digos que faltan (`earnedNow.difference(earnedCodes)`), as� repetir `load()` es idempotente.
- El match del mazo ya lo resuelve `DeckCard.isMatch` (=2 reacciones todas 'encanta'); reutilic� la regla en el provider en vez de reimplementarla.
**Pendiente**: aviso del bot WhatsApp de logro desbloqueado (categor�a nueva leyendo `couple_achievements.awarded_at` de la �ltima hora ? a ambos). Ver Fase 2.x del roadmap.
**Impacto**: `couple_achievement.dart` (nuevo), `couple_achievements_provider.dart` (nuevo), `migration_couple_achievements.sql` (nuevo), `supabase_schema.sql`, `logros_screen.dart` (nuevo), `main.dart`, `home_screen.dart`, `couple_achievement_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot PENDIENTE), racha de pareja (entrada previa 2026-08-26), glosario.

## [2026-08-26] - FEATURE - Racha de pareja ?? (d�as consecutivos en que ambos est�n activos)
**Resumen**: Se agreg� la "racha de pareja" como nueva capa de juego del Home: d�as consecutivos en que AMBOS miembros de la pareja estuvieron activos (registraron mood o completaron un entrenamiento). Es el primer entregable del roadmap de "capa de juego/unicidad" y usa el patr�n ya probado de `WorkoutStats` (l�gica pura testeable) + `WorkoutProvider` (Supabase + realtime sin cache local).
**Cambios realizados**:
- `lib/models/couple_stats.dart` (nuevo): `CoupleActivity` (userId + d�a, `fromMap` tolerante a `date`/`completed_on`/`created_at`) y `CoupleStats` con l�gica pura: `activeByDay` (agrupa por d�a ? set de usuarios activos), `bothActiveDays` (d�as donde TODOS los miembros est�n activos), `streakFor` (racha actual terminando hoy o ayer, mismo criterio que `WorkoutStats.streakFor`), `bestStreak` (racha m�s larga), `isBothActiveOn`.
- `lib/providers/couple_provider.dart` (nuevo): `CoupleProvider` carga `moods` + `workout_completions` (solo `user_id` + fecha), unifica en actividades, calcula `bothDays` = d�as con ambos (`members: {myId, partnerId}`), y expone `coupleStreak`, `bestCoupleStreak`, `todayActive`. Realtime en ambas tablas (recarga por evento). Registrado como provider global.
- `lib/main.dart`: import + `ChangeNotifierProvider(create: (_) => CoupleProvider())`.
- `lib/screens/home_screen.dart`: `_BrutalGridState.initState` carga `CoupleProvider` post-frame; nuevo widget `coupleTile` (chip ?? + n�mero con `GoogleFonts.bangers`, fondo=borde color del tema, sombra brutalista) posicionado en la esquina superior derecha con `Consumer<CoupleProvider>`, sin alterar la grilla.
- Tests TDD: `test/models/couple_stats_test.dart` (14 tests). Suite total 166 verdes (antes 152). `flutter analyze` sin issues nuevos (los 23 son preexistentes).
**Lecciones**:
- Espejar `WorkoutStats` es el camino correcto: agregar l�gica de "racha" requiere la misma estructura de d�as consecutivos terminando en hoy/ayer (el d�a en curso no cuenta hasta completarse).
- La "racha de pareja" NO puede calcularse con una tabla propia (habr�a que escribir cada d�a); se deriva de se�ales existentes con `user_id` + fecha. Moods es la se�al diaria m�s confiable (ambos la registran en Nosotros); workout_completions la refuerza.
- El Home es una grilla brutalista muy ajustada: un widget nuevo NO debe romper el layout; un chip flotante posicionado con `Consumer` en el Stack evita tocar las coordenadas de los bloques.
- Ojo al escribir providers por primera vez: `Identical`/`a == a` en un `removeWhere` es un bug silencioso (siempre true ? borra todo); revisar el c�digo resultante antes de correr.
**Pendiente**: aviso del bot WhatsApp de "racha de pareja rota" (requiere calcular ambos-miembros-activos en JS ? requerimiento no trivial, dejar para pr�xima iteraci�n).
**Impacto**: `couple_stats.dart` (nuevo), `couple_provider.dart` (nuevo), `main.dart`, `home_screen.dart`, `couple_stats_test.dart` (nuevo), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), patr�n WorkoutStats/WorkoutProvider, glosario (nuevo concepto racha de pareja).

## [2026-08-17] - FEATURE - Calendario completo: eventos por d�a, gesti�n de tipos y recordatorios programados (port desde Gastronomia-App)
**Resumen**: Se portaron a F.U.R.I las funciones de calendario/clases/eventos de Gastronomia-App que faltaban: pantalla de eventos por d�a con navegaci�n por fecha, gesti�n de tipos de clase y de evento (crear/editar/borrar con color e icono), campo Profesor en el formulario de evento, y recordatorios locales programados (eventos: 1h antes + al empezar; clases: semanal recurrente 1h antes). Se conectaron los accesos desde el calendario (botones Clases + D�a) y se rescat� `ClassBoardScreen`, que era c�digo muerto (nadie navegaba a �l).
**Cambios realizados**:
- `pubspec.yaml`: + `flutter_timezone: ^4.1.0` (nombre IANA de la zona del dispositivo para `zonedSchedule`).
- `lib/services/notification_service.dart`: nuevos `scheduleNotification()` (`zonedSchedule` con `AndroidScheduleMode.inexactAllowWhileIdle` + `_ensureTz()` con flutter_timezone y fallback por offset) y `cancel(id)`. Todo en try/catch: en desktop `zonedSchedule` no est� implementado ? no-op seguro.
- `lib/services/event_notification_service.dart` (nuevo): `specsForEvent()` l�gica pura (1h antes + al empezar; ids `100000+id` y `100000+id+1`), `rescheduleAll()` (cancela los vigentes y reprograma), `cancelForEvent()`.
- `lib/services/class_notification_service.dart` (nuevo): `nextOccurrence()` (pr�xima ocurrencia semanal, convenci�n Dart `weekday` 1=Lun..7=Dom), `specsForClass()` (1h antes con `matchDateTimeComponents: dayOfWeekAndTime`, id `200000+id`), `rescheduleAll()`.
- `lib/providers/schedule_provider.dart` y `class_schedule_provider.dart`: `_rescheduleNotifs()` despu�s de load/add/update/delete y de los eventos realtime. Decisi�n del usuario: recordatorios para TODOS los eventos y clases (calendario compartido � ambos dispositivos avisan todo).
- `lib/screens/calendar/daily_events_screen.dart` (nuevo): lista de eventos fechados + clases recurrentes del d�a; navegaci�n con chevrons + date picker; card de evento con icono/color del tipo, tap=editar, long-press=borrar con confirmaci�n; card de clase ? abre `ClassBoardScreen`; estados LOADING/EMPTY/ERROR/DATA; estilo brutalista (ConcretePainter, TapTile, cian #00D4FF).
- `lib/screens/calendar/calendar_home_screen.dart`: botones "D�a" y "Clases" en la barra de mes (abren `DailyEventsScreen` y `ClassBoardScreen`); limpieza de warnings preexistentes del archivo.
- `lib/screens/calendar/class_board_screen.dart`: bot�n gesti�n de tipos de clase (crear con color picker de 16 colores, editar nombre/color, borrar); di�logo de clase ampliado con hora fin y profesor; al editar se preservan `cloudId`/`userId`/`color` (antes se perd�an al reconstruir el objeto); bot�n settings dentro del di�logo.
- `lib/screens/calendar/schedule_form_screen.dart`: campo Profesor/Instructor; gesti�n de tipos de evento (crear con color + picker de 30 iconos, borrar); fecha y horas ahora muestran su valor (antes solo iconos); `_backBtn` conectado al Stack (el form no ten�a forma de cancelar en desktop).
- `lib/providers/class_type_provider.dart` + `lib/database/database_helper.dart`: defaults "Gastronom�a 1"/"Pasteler�a 1" ? "Clase" (cian) + "Pr�ctico" (verde lima). Solo aplica a instalaciones nuevas; las existentes se editan con la nueva UI de gesti�n.
- `lib/main.dart`: `initializeDateFormatting('es')` para `DateFormat` con locale es.
- Tests TDD: `test/services/event_notification_service_test.dart` (5) + `test/services/class_notification_service_test.dart` (8). Total 13 nuevos; suite completa 152 verdes. Build Windows release verificado (exe completo con `flutter_timezone_plugin.dll`).
**Lecciones**:
- flutter_local_notifications **18.0.1** usa API posicional: `zonedSchedule(id, title, body, scheduledDate, details, {...})` y `cancel(id)`; la API con named parameters es de v19+. "Too few positional arguments" al compilar delata la versi�n vieja.
- timezone 0.10.1: `Location(name, transitionAt, transitionZone, zones)` pide `List<int>` de transiciones e �ndices, y `TimeZone(offset, {isDst, abbreviation})`. Fallback por offset: `Location('device-local', [minTime], [0], [TimeZone(offset.inSeconds, isDst: false, abbreviation: 'loc')])` (mismo patr�n que `_UTC` del paquete).
- `tz.local` por defecto es UTC: sin setear la zona del dispositivo (flutter_timezone) los recordatorios quedan desfasados por el offset. El fallback por offset cubre Argentina (sin DST desde 2010).
- Los ids de notificaci�n de eventos y clases deben vivir en namespaces separados (SQLite autoincrement por tabla ? ids repetidos): eventos 100000+, clases 200000+.
- El exe en uso bloquea el linker (LNK1104) � cerrar la app antes de `flutter build windows --release`.
- TRK0005 (cl.exe no encontrado) vuelve a aparecer cuando un plugin nuevo fuerza rebuild CMake: activar `vcvarsall.bat amd64` antes del build.
- Un helper de test con `id ?? 3` no puede testear el caso "id null": el default enmascara el null. Recibir `int?` y dejar que el caso de prueba construya el objeto expl�cito.
**Impacto**: `pubspec.yaml`, `notification_service.dart`, 2 servicios nuevos, 2 providers, 4 screens de calendario, `class_type_provider.dart`, `database_helper.dart`, `main.dart`, 2 archivos de test, docs.
**Relacionado con**: D-3 (SQLite), D-2 (Supabase), D-4 (skill_visual), errores-conocidos (TRK0005/LNK1104), glosario (tipos de evento/clase).

## [2026-08-17] - FEATURE - Secci�n Ejercicios: bot�n pesa, plan semanal, retos y stats
**Resumen**: El bot�n del Home con icono de planta (Icons.spa, que solo lanzaba confeti) ahora es una pesa (Icons.fitness_center) en verde lima #39FF14 que abre la nueva pantalla "Ejercicios". Secci�n compartida con 4 pesta�as: Hoy (plan semanal por d�a con rutinas y marcas F/R), Ejercicios (registros con historial de pesos, reacciones y comentarios), Retos (aprobaci�n y completado conjuntos) y Stats (rachas individuales, sesiones por semana, grupos musculares). Sincronizada con Supabase + realtime; el bot de WhatsApp avisa ejercicios nuevos, sesiones completadas, retos y racha rota.
**Cambios realizados**:
- `lib/models/workout_social.dart` (nuevo): `WorkoutSocial` + `WorkoutComment` � reacciones (max 5 keys, 1 por usuario, se mueve entre keys como el chat) y comentarios (delete en cascada de replies) embebidos en `social` JSONB. `mergeReactions` (uni�n de user_ids por key) y `mergeComments` (uni�n por id) para el realtime � evita el race de reacciones concurrentes (lecci�n del pizarr�n BUG 2).
- `lib/models/workout_log.dart` (nuevo): registro de ejercicio (nombre obligatorio; series/reps/peso/descanso/grupo/notas opcionales), `loggedOn`, `summary` ("4x10 @ 60kg"), social embebido, copyWith con clears.
- `lib/models/workout_routine.dart` (nuevo): rutina con `dayOfWeek` (1-7) y `items` JSONB (`RoutineItem`).
- `lib/models/workout_completion.dart` (nuevo): marca "entren� este d�a" por persona.
- `lib/models/workout_challenge.dart` (nuevo): reto con `approvedBy`/`completedBy` (ambos deben aprobar/completar � 2 personas), toggle sin duplicados.
- `lib/models/workout_stats.dart` (nuevo): l�gica pura � `streakFor` (d�as consecutivos hasta hoy/ayer), `weightHistoryFor`, `lastWeightFor`, `sessionsThisWeek/LastWeek`, `distinctExerciseNames`, `muscleGroupCounts`.
- `lib/providers/workout_provider.dart` (nuevo): CRUD de las 4 tablas + realtime con merge social, `toggleCompletion` (marca/desmarca por user), `toggleChallengeApproval/Completion`, getters de dominio (streaks, stats). Registrado en `lib/main.dart` (15� provider).
- `lib/screens/ejercicios/ejercicios_screen.dart` (nuevo, ~1900 l�neas): 4 pesta�as con chips verde lima (#39FF14 sobre #0E3A0E), header + tabs + FAB contextual (rutina/ejercicio/reto). Hoy: semana completa (LUN-DOM) con rutina del d�a, items tap=registrar pre-rellenado, badges F/R de completado, racha en cabecera. Ejercicios: cards con autor, summary, reacciones; tap=detalle (evoluci�n de peso + comentarios), long-press=reacciones. Retos: estado de aprobaci�n/completado por persona, sheet de acciones. Stats: rachas, sesiones, grupos. Estados loading/empty/error/data; skill_visual (fondo=borde, redondo, sin negro puro, botones con iconos).
- `lib/screens/home_screen.dart`: `bottomBtn(const Color(0xFF39FF14), Icons.fitness_center, const Color(0xFF062B06), 5, _openEjercicios)` � reemplaza el bot�n spa/confeti; `_openEjercicios` sin confeti.
- `supabase/migration_workouts.sql` (nuevo): tablas `workout_logs`, `workout_routines`, `workout_completions` (UNIQUE user+date+routine), `workout_challenges` + �ndices + RLS full access + GRANTs + publicaci�n realtime. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: tablas #25-28 + �ndices + RLS + policies.
- `bot-furi/bot.js`: categor�as #16 workout_logs (nuevo ejercicio), #17 workout_completions (sesi�n completada), #18 workout_challenges (creado/aprobado/completado), #19 racha rota (streak >= 3 y no entren� hoy ni ayer; tracking `streak-{uuid}-{fecha}`). Helper `diasConsecutivos`.
- Tests TDD: `workout_log_test` (10), `workout_routine_test` (5), `workout_challenge_test` (7), `workout_social_test` (7), `workout_stats_test` (9). Total 38 nuevos; suite completa 152 verdes.
**Lecciones**:
- El comportamiento de reacciones del proyecto (chat) es 1 reacci�n ACTIVA por usuario: al reaccionar con otra key, la reacci�n se MUEVE. Los tests que asum�an "5 keys del mismo usuario" fallaron y se ajustaron al comportamiento real.
- `WorkoutSocial` era una clase sin constructor `const` pero los tests la usaban como `const WorkoutSocial(...)` ? error "Couldn't find constructor" que en realidad era import faltante en el test (la clase vive en workout_social.dart, no se re-exporta desde workout_challenge.dart).
- Lambdas pasadas a `Future<void> Function(String)` fallan si no reciben el par�metro; y `StateSetter` (de StatefulBuilder) no es asignable a `void Function()` � envolver con `() => setSheetState(() {})`.
- `'$series\x$reps'` en Dart es trampa: `\x` inicia un escape hex. Usar `'$series' 'x' '$reps'` (literales adyacentes) o `${series}x${reps}`.
- En la app los infos `use_build_context_synchronously` se silencian con `if (!mounted) return;` despu�s del await del dialog, patr�n ya usado en favoritos.
**Impacto**: 6 modelos nuevos, 1 provider nuevo, 1 pantalla nueva, `main.dart`, `home_screen.dart`, `supabase/migration_workouts.sql` (nuevo), `supabase_schema.sql`, `bot-furi/bot.js`, 5 archivos de test, docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot), errores-conocidos (race reacciones JSONB), skill-pantallas, glosario, bot-whatsapp.

## [2026-08-17] - FEATURE - Mazo: tarjetas swipe tipo Tinder (ideas, chistes, poemas, recetas, retos, random, sue�o, me pas�)
**Resumen**: Nueva secci�n "Mazo" con tarjetas creadas por Facu y Rocio que se deslizan en 4 direcciones: ?? me encanta, ?? no me gusta, ?? me gusta, ?? meh. Al entrar a la app, si hay tarjetas sin deslizar, aparece el overlay encima del Home (con X para cerrar). Hay MATCH cuando ambos dieron me encanta a la misma tarjeta ? pantalla especial "FURI!!" con confetti. Las tarjetas ya deslizadas se pueden re-deslizar desde el historial. El bot de WhatsApp avisa tarjeta nueva (a la pareja) y match (a ambos).
**Cambios realizados**:
- `supabase/migration_deck_cards.sql` (nuevo): tabla `deck_cards` (id, category, content, created_by, reactions JSONB `{"user_id": "encanta"|"me_gusta"|"meh"|"no_me_gusta"}`, created_at, updated_at) + �ndices + RLS full access + publicaci�n realtime. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: agregada tabla `deck_cards` (#24) con �ndice, RLS y policy.
- `lib/models/deck_card.dart` (nuevo): `DeckReaction` (4 valores), `DeckCategory` (8 categor�as), `DeckCard` con `toMap`/`fromMap` (reacciones JSONB tolerantes), `withReaction` (inmutable), `mergedReactions`/`mergedFromCloud` (merge anti-race: las reacciones locales pisan a las cloud del mismo user), `isMatch` (>=2 reacciones y todas encanta).
- `lib/providers/deck_provider.dart` (nuevo): `load()` (Supabase + realtime `deck_cards_changes`), `pendingFor`/`historyFor` (filtran por reacci�n del usuario activo), `matches`/`matchCount`, `add()`, `react()` (update optimista + JSONB), `delete()`, `applyCloudCards()` (l�gica pura: merge cloud+local y detecci�n de transici�n a match ? `pendingMatch`), `consumeMatch()`. Registrado en `lib/main.dart` (14� provider).
- `lib/screens/mazo/deck_style.dart` (nuevo): estilo por categor�a (emoji, label, **degradado 3 colores**) y por reacci�n (label, **degradado 3 colores**, icono, direcci�n).
- `lib/screens/mazo/deck_overlay.dart` (nuevo): overlay encima del Home con stack de 3 tarjetas (escala descendente), drag en 4 direcciones con sello de reacci�n, rotaci�n progresiva, snap-back y salida animada (160ms) ? `pv.react()`. **Solo bot�n X cerrar en header** (sin botones de acci�n abajo). **Tarjetas sin borde** (degradado puro, borderRadius 32), **más delgadas y altas** (75% ancho � 92% alto), fuente **Bangers** blanco tama�o 28. Etiquetas de reacci�n al deslizar **sin borde** (solo degradado + Bangers blanco). Categoría **POEMAS**: degradado rojo-rosa-rojo.
- `lib/screens/mazo/create_deck_card_modal.dart` (nuevo): dialog con chips de las 8 categor�as (fondo=borde, check en la seleccionada), TextField multilinea (max 1000), botón guardar con icono check que se habilita al escribir (listener del controller).
- `lib/screens/mazo/deck_history_sheet.dart` (nuevo): bottom sheet con las tarjetas ya deslizadas: mi reacci�n + reacciones de la pareja + botón re-deslizar (vuelve al overlay en modo re-swipe de esa tarjeta).
- `lib/screens/mazo/deck_match_overlay.dart` (nuevo): pantalla "FURI!!" gigante en color de la categor�a + tarjeta + confetti (flutter_confetti) + botón seguir. No dice "match" (pedido del usuario).
- `lib/screens/home_screen.dart`: `_initDeck()` en initState (post frame: load + abrir overlay si hay pendientes); `_openMazo()` en el bloque con iconos ?/???/? del Home (antes decorativo); Stack del Home ahora monta `DeckOverlay` (si `_showDeck`) y `DeckMatchOverlay` v�a `Consumer<DeckProvider>` cuando hay `pendingMatch` (encima de todo, incluso sin deck abierto).
- `bot-furi/bot.js`: categor�a #14 `deck_cards` (tarjeta nueva en �ltima hora ? avisa a la pareja del creador, con categor�a y preview de 90 chars) y categor�a #15 `deck match` (reactions con >=2 valores todos 'encanta' y updated_at en �ltima hora ? avisa a AMBOS con "?? *FURI!!*"). Tracking keys `deck-{id}` y `deckmatch-{id}`.
- Tests TDD: `test/models/deck_card_test.dart` (12 tests) + `test/providers/deck_provider_test.dart` (13 tests). Total 25 nuevos, todos verdes.
**Lecciones**:
- El JSONB de reacciones se env�a entero en cada update: dos reacciones simult�neas (Facu y Rocio) se pisan. El fix usado (como en el pizarr�n): merge en el callback realtime con las reacciones locales ganando para el mismo user (`mergedFromCloud`), porque mi UPDATE en vuelo a�n no est� en el server y un `load()` completo lo borrar�a de la vista.
- La detecci�n de match debe ser por TRANSICI�N (local no-match ? merged match), no por estado: si no, cada reload/realtime de una carta ya matcheada volver�a a disparar la pantalla "FURI!!".
- `pendingFor(null)` devuelve todas las cartas (sin identidad cargada no se puede filtrar) � �til para tests.
- Un `showDialog`/bottom sheet que se habilita seg�n el texto necesita `_ctrl.addListener(() => setState(() {}))`; evaluar `_ctrl.text` una sola vez en el build deja el bot�n congelado.
- **Degradados de 3 colores por categor�a**: IDEAS (rojo-amarillo-naranja), CHISTES (morado-amarillo-fucsia), POEMAS (rojo-rosa-rojo), RECETAS (verde-amarillo-verde), RETOS (rojo-naranja-fucsia), RANDOM (morado-amarillo-cian), SUE�O (azul-celeste-violeta), ME PAS� (rojo-amarillo-fucsia). Reacciones tambi�n con degradados de 3 colores.
- **Sin bordes en tarjetas ni sellos**: el degradado es el fondo y el borde se camufla eliminando `Border.all`.
- **Bangers + blanco**: fuente consistente con el resto de la app, tama�o grande para legibilidad.
**Impacto**: `supabase/migration_deck_cards.sql` (nuevo), `supabase_schema.sql`, `lib/models/deck_card.dart` (nuevo), `lib/providers/deck_provider.dart` (nuevo), `lib/screens/mazo/` (5 archivos nuevos), `lib/main.dart`, `lib/screens/home_screen.dart`, `bot-furi/bot.js`, tests (2 archivos nuevos), docs.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), D-10 (bot), errores-conocidos (race de reacciones JSONB), skill-pantallas, glosario, bot-whatsapp.

## [2026-08-14] - FEATURE+BUGFIX - Calendario compartido: ambos usuarios ven las fechas del otro
**Resumen**: El calendario no compart�a eventos entre Facu y Rocio. Cada dispositivo solo ve�a lo guardado en su SQLite local. Fix: sync bidireccional completo de `schedules` (eventos fechados) y `class_schedules` (clases recurrentes) con Supabase, merge por cloudId, realtime, y migraci�n SQL que arregla la causa ra�z del fallo silencioso de los INSERT.
**Cambios realizados**:
- `lib/models/schedule.dart`: nuevo campo `cloudId` (PK cloud vs id local), `toSupabaseMap()` (`user_id` snake_case, sin id local, fecha YYYY-MM-DD), `fromCloudRow()` (id del servidor ? cloudId), `fromMap` tolera `user_id`/`userId` y filas legacy.
- `lib/models/class_schedule.dart`: nuevo `fromCloudRow()`.
- `lib/providers/schedule_provider.dart`: reescrito � `loadSchedules()` hace push de filas locales sin cloudId, pull de TODAS las filas cloud, merge por cloudId (updatedAt decide conflictos; filas cloud ausentes en local se borran = delete de la pareja). `addSchedule`/`updateSchedule`/`deleteSchedule` sincronizan con Supabase (update/delete usan cloudId como PK cloud, no el id local). Realtime `schedules_sync` (INSERT/UPDATE/DELETE) con `ConflictAlgorithm.ignore` + �ndice �nico por cloudId para no duplicar filas en la carrera realtime vs. insert propio.
- `lib/providers/class_schedule_provider.dart`: `loadSchedules()` ahora tambi�n hace pull+merge del cloud (las clases de la pareja aparecen). `updateSchedule` resuelve el cloudId desde la BD local (antes hac�a INSERT duplicado cuando el objeto no tra�a cloudId). Realtime `class_schedules_sync`.
- `lib/providers/schedule_sync.dart` (nuevo): `buildScheduleSyncPlan()` � l�gica pura del merge (testeable).
- `lib/database/database_helper.dart`: SQLite v8 � columna `cloudId` en `schedules` + �ndices �nicos `idx_schedules_cloudId`/`idx_class_schedules_cloudId` (WHERE cloudId IS NOT NULL). `insert()` acepta `conflictAlgorithm`.
- `lib/screens/calendar/schedule_form_screen.dart`: al guardar setea `userId: AppState.identity` (colores F/R por celda).
- `supabase/migration_schedules_sync.sql` (nuevo): `user_id` en `schedules`, `color` ? BIGINT, y agrega `schedules` + `class_schedules` a la publicaci�n realtime. **PENDIENTE ejecutar en SQL Editor**.
- `supabase_schema.sql`: `schedules` actualizado (`user_id`, `color BIGINT DEFAULT 4286262670`).
- Bugfix colateral: `lib/screens/pizarra_v2/pizarra_screen_v2.dart` ten�a un error de sintaxis preexistente (declaraci�n `final world` dentro de un collection-if) que romp�a la compilaci�n de TODA la app; se hoiste� el c�lculo al builder del Consumer.
- Tests: `test/models/schedule_test.dart` (5) + `test/providers/schedule_sync_test.dart` (5). Total 77 verdes.
**Lecciones**:
- El INSERT a Supabase fallaba en silencio desde siempre: `color` mandaba un ARGB de Flutter (4286262670) que excede el `INTEGER` de Postgres ? error 22003 tragado por el try/catch ? los eventos nunca llegaban a la nube. Mismo bug ya resuelto en `class_schedules`.
- El id local de SQLite (autoincrement) nunca coincide con el BIGSERIAL de Supabase: hay que persistir un `cloudId` aparte y usarlo como PK cloud en update/delete.
- Merge por cloudId con `updatedAt` como �rbitro cubre el caso "la pareja borr� algo": fila local con cloudId ausente en cloud = delete remoto.
- En la carrera "realtime INSERT propio vs insert local", un �ndice �nico sobre cloudId + `ConflictAlgorithm.ignore` evita duplicados.
**Impacto**: `schedule.dart`, `class_schedule.dart`, `schedule_provider.dart`, `class_schedule_provider.dart`, `schedule_sync.dart` (nuevo), `database_helper.dart`, `schedule_form_screen.dart`, `migration_schedules_sync.sql` (nuevo), `supabase_schema.sql`, `pizarra_screen_v2.dart`, tests.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), errores-conocidos (calendar sync), glosario (Schedule).

## [2026-08-12] - BUGFIX - Fixes de auditor�a del pizarr�n v2 (10 bugs: 3 cr�ticos + 4 altos + 3 medios)
**Resumen**: Tras la auditor�a completa del pizarr�n v2 (19 bugs encontrados en `documentacion/auditoria-pizarron-v2.md`), se aplicaron los fixes por prioridad: BUG 1 (offline sync), BUG 2 (reacciones race), BUG 3 (conectores hu�rfanos), BUG 4 (drag jitter), BUG 5 (isLocked), BUG 6 (reacci�n sin feedback), BUG 7 (comentario hu�rfano), BUG 8 (b�squeda cross-board), BUG 9 (retry cloud writes), BUG 12 (comment length). 67 tests verdes, `flutter analyze` sin errores nuevos.
**Cambios realizados**:
- `lib/providers/board_provider_v2.dart`:
  - **BUG 1+9 (CR�TICO+ALTO)**: `_saveToLocal` ahora acepta `syncedFlag` para marcar elementos como no sincronizados. Nuevo `_markUnsynced(id)` que setea `synced=0` en SQLite. `moveLocal()` y `update()` marcan `synced=0` cuando est�n offline o cuando el cloud write del debounce timer falla. Tras un cloud write exitoso, marcan `synced=1`. `_pushUnsyncedToCloud()` ahora diferencia entre elementos sin id cloud (INSERT) y elementos con id cloud pero modificados offline (UPDATE). Import de `board_element_data.dart` para `ConnectorData`.
  - **BUG 5 (ALTO)**: `update()` y `moveLocal()` ahora chequean `isLocked` y retornan early si el elemento est� bloqueado.
  - **BUG 2 (CR�TICO)**: El callback de realtime ahora mergeea las reacciones del cloud con las locales (union de user_ids por key) en vez de reemplazar el data completo. Nuevo helper `_reactionsOf(data)`.
  - **BUG 3 (CR�TICO)**: `delete()` ahora busca y elimina en cascada los conectores cuyo `fromId` o `toId` apuntan al elemento borrado (memoria + SQLite + cloud).
  - **BUG 8**: Nuevo `loadSearchPool()` que carga TODOS los elementos no archivados de SQLite sin filtro de `board_id`, para b�squeda cross-board.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`:
  - **BUG 4 (ALTO)**: `onPanUpdate` ahora usa `live.x`/`live.y` del elemento vivo en vez del snapshot del build. Previene jitter en drags r�pidos.
  - **BUG 8**: `BoardSearchPanel` ahora recibe `provider` (BoardProviderV2) en vez de `elements` (List). `_goToElement` ahora cambia al tablero del elemento si est� en otro board (`pv.setBoard(el.boardId)`).
- `lib/screens/pizarra_v2/widgets/board_search_panel.dart`:
  - **BUG 8**: Convertido de StatelessWidget a StatefulWidget. Carga el pool cross-board en `initState` con `provider.loadSearchPool()` (async). Hint cambiado a "Buscar en todos los tableros...". Estado de loading con spinner verde.
- `lib/screens/pizarra_v2/widgets/board_element_options.dart`:
  - **BUG 6 (ALTO)**: `react()` ahora detecta si `withToggledReaction` devuelve la misma referencia (`identical()`) � indica l�mite de 5 reacciones alcanzado. Muestra SnackBar "M�ximo 5 reacciones por elemento" + haptic feedback. Tambi�n relee el elemento vivo (`pv.findById`) para usar data fresca.
  - **BUG 7 (ALTO)**: `withCommentRemoved()` ahora hace cascade-delete: borra el comentario Y todas sus respuestas (donde `replyToId == commentId`). Previere respuestas hu�rfanas sin contexto.
  - **BUG 12 (MEDIO)**: TextField de comentarios ahora tiene `maxLength: 1000`.
**Lecciones**:
- `withToggledReaction` devuelve la misma referencia `data` cuando alcanza el l�mite de 5 reacciones � `identical(newData, live.data)` detecta este caso sin cambiar el return type.
- Un elemento modificado offline ya tiene un id cloud pero `synced=1` del sync inicial. Hay que marcarlo `synced=0` expl�citamente al guardar local offline, y que `_pushUnsyncedToCloud` haga UPDATE (no INSERT) para los que ya tienen id.
- El merge de reacciones en realtime es necesario porque el `data` JSONB se env�a entero en cada update � dos updates concurrentes pisan el campo completo. El merge union los user_ids por key preserva ambas reacciones.
- Los conectores referencian elementos por `fromId`/`toId` en `data` JSONB � borrar un elemento sin limpiar sus conectores deja conectores fantasma en la BD.
- El drag jitter ocurr�a porque `onPanUpdate` usaba `el.x` (snapshot del build) + delta del frame actual. Si entre pan events no llegaba un rebuild, todos los events acumulaban delta sobre la posici�n vieja. Usar `_liveElement(pv, el).x` resuelve el problema.
- `isLocked` se persist�a pero nunca se validaba � agregar el check en `update()` y `moveLocal()` es suficiente (el delete se mantiene con confirmaci�n UI).
**Impacto**: `board_provider_v2.dart`, `pizarra_screen_v2.dart`, `board_search_panel.dart`, `board_element_options.dart`. 67 tests verdes, `flutter analyze` 0 errores nuevos.
**Relacionado con**: `documentacion/auditoria-pizarron-v2.md`, D-2 (Supabase), D-3 (SQLite), errores-conocidos

## [2026-08-12] - DECISION - Etapa 5 del pizarr�n cancelada (undo/redo global, doble tap, atajos, exportar)
**Resumen**: El usuario cancel� la Etapa 5 (undo/redo global Ctrl+Z/Y, doble tap en espacio vac�o para crear nota, atajos desktop, exportar PNG/PDF). No hab�a c�digo implementado de esa etapa � solo referencias en la spec.
**Cambios realizados**:
- `skill-pantallas.md`: eliminados de la spec del pizarr�n "Doble tap vac�o: Crear nota nueva", "Undo/Redo: Ctrl+Z/Ctrl+Y + bot�n en mobile", "Atajos desktop", "Exportar: PNG + PDF". Agregados a la secci�n "NO incluido".
**Nota**: El bot�n undo del editor de dibujo (`board_drawing_editor.dart`) se mantiene � es deshacer el �ltimo stroke del dibujo (feature del editor desde la Etapa 2b), no el undo/redo global del tablero que era parte de la Etapa 5.
**Impacto**: `skill-pantallas.md`
**Relacionado con**: plan de etapas del pizarr�n

## [2026-08-12] - FEATURE - Pizarr�n v2: Etapa 4 (sub-tableros + separadores + migraci�n board_v2)
**Resumen**: Se agregaron sub-tableros (tableros anidados que se abren con tap y tienen bot�n Volver), separadores manuales horizontales/verticales, y la migraci�n SQL que crea `board_elements_v2` + `boards` en Supabase (el sync cloud de la pizarra v2 nunca funcion� porque la tabla no exist�a en prod).
**Cambios realizados**:
- `supabase/migration_board_v2.sql` (nuevo): crea `board_elements_v2` (espejo del schema SQLite local: type, title, content, x/y, width/height, rotation, color, text_color, font_family, font_size, text_align, is_bold/italic/underline, emoji_header, tags JSONB, priority, assigned_to, user_id, status, is_collapsed/locked/archived/new, board_id, z, data JSONB, timestamps), `boards` (id BIGSERIAL, name, parent_id, created_at) con ra�z id=1 "Pizarra", RLS full access, GRANTs, e `ALTER PUBLICATION supabase_realtime ADD TABLE board_elements_v2` para el realtime. Idempotente. **PENDIENTE ejecutar en SQL Editor de Supabase** � sin esto el sync cloud sigue fallando en silencio.
- `lib/providers/board_provider_v2.dart`: `_boards` + getters `boards`/`boardName`/`parentBoardId`; `loadBoards()` (cargado en `load()`); `createBoard(name, parentId)` (insert + reload); `goBackBoard()` (setBoard al padre).
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: 2 herramientas nuevas � Sub-tablero (folder, morado) y Separador (remove, violeta).
- `lib/screens/pizarra_v2/widgets/board_header.dart`: en modo canvas el t�tulo muestra `provider.boardName` (breadcrumb del tablero actual) en vez de "Pizarra".
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: `_createSubBoard()` (dialog de nombre ? `createBoard` ? agrega elemento `subBoard` con `SubBoardData{boardId}`), `_openSubBoard()` (tap ? `setBoard` + centra el canvas), `_createSeparator()`, `_toggleSeparator()` (tap cambia orientaci�n horizontal/vertical), bot�n "Volver" arriba-izquierda cuando `parentBoardId != null`, renders `_subBoardBody` (folder + nombre + chevron) y `_separatorBody` (l�nea de color). Quitado el `BoardZoomSlider` (pedido del usuario).
**Lecciones**:
- El sync cloud de la pizarra v2 nunca hab�a funcionado: `board_elements_v2` solo exist�a en SQLite local. Cualquier feature "realtime" del pizarr�n depende de ejecutar la migraci�n en prod.
- Los sub-tableros reutilizan el `board_id` que ya estaba en el modelo y en el provider (`setBoard` + `load()` filtran por tablero); solo faltaba la tabla `boards` y el flujo de creaci�n.
- El separador guarda su orientaci�n en `data['orientation']` y el tap lo rota intercambiando width/height.
**Impacto**: `migration_board_v2.sql` (nuevo), `board_provider_v2.dart`, `board_tools_menu.dart`, `board_header.dart`, `pizarra_screen_v2.dart`
**Relacionado con**: skill-pantallas.md (spec pizarr�n � sub-tableros, breadcrumb, separadores), D-2 (Supabase), Etapa 4 del plan

## [2026-08-12] - FEATURE - Pizarr�n v2: Etapa 3 (reacciones + comentarios + badges F/R + badge NUEVO)
**Resumen**: Cada elemento del pizarr�n ahora tiene reacciones por long-press (mismo formato que el chat), comentarios con respuestas, badge de autor (F=azul, R=morado) y badge NUEVO que desaparece al ver el elemento.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_element_options.dart` (nuevo): `BoardSocialData` con l�gica pura de reacciones (`{key: [userIds]}`, max 5 keys, 1 por usuario por key � espejo de `Message.toggleReaction`) y comentarios (`{id, userId, text, createdAt, replyToId}`) embebidos en `el.data` (se sincronizan v�a `update()` + realtime). `showElementOptionsSheet()`: bottom sheet con barra de reacciones (6 emojis default + custom v�a dialog + chips de keys custom existentes), y 4 acciones: Comentarios (con contador), Duplicar (copia con offset +30 y id nuevo), Archivar, Eliminar (con confirmaci�n). `showCommentsSheet()`: lista de comentarios con badge de autor, tiempo relativo, responder (hilo con preview "?"), borrar solo si es m�o, input con keyboard insets.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: `_buildElementCard` ahora envuelve el elemento en `Stack(clipBehavior: Clip.none)` con: reacciones inline debajo del card (chips con key + contador), badge NUEVO verde arriba-izquierda, badge de autor (inicial F/R con color azul/morado) arriba-derecha. Long-press abre `showElementOptionsSheet` (reemplaza el viejo di�logo de borrado). Tap marca el elemento como visto (`markAsSeen`) si `isNew`.
- `lib/providers/board_provider_v2.dart`: nuevo `findById(int?)` para resolver el elemento vivo desde sheets/dialogs.
- `lib/models/board_element_v2.dart`: `copyWith` ahora acepta `createdAt` (necesario para duplicar con timestamp nuevo y no colisionar los lookups por `createdAt`).
- Eliminado c�digo muerto: `board_element_panel.dart`, `board_canvas.dart`, `board_note_renderer.dart`, `board_element_renderer.dart` (no se importaban desde el reset del 11/8; los renderers vivos ya se llaman directo desde la pantalla).
**Lecciones**:
- Las reacciones/comentarios embebidos en `el.data` no necesitan tablas nuevas: `update()` + Realtime hacen el sync entre dispositivos. El formato de reacciones espeja el del chat para consistencia.
- Los sheets que mutan datos del provider deben leer el elemento VIVO (`pv.findById`) en cada acci�n, no el snapshot con el que se abrieron, y hacer `setSheetState`/`ListenableBuilder` para refrescar el contador.
- `copyWith(clearId: true)` mantiene el `createdAt` original; al duplicar hay que pasar `createdAt: DateTime.now()` expl�cito o el nuevo elemento colisiona en los lookups por timestamp.
**Impacto**: `board_element_options.dart` (nuevo), `pizarra_screen_v2.dart`, `board_provider_v2.dart`, `board_element_v2.dart`, 4 archivos muertos eliminados
**Relacionado con**: skill-pantallas.md (reglas 6/7/8 � comentable/reaccionable/interactuable, badge NUEVO), D-2 (Supabase realtime), Etapa 3 del plan

## [2026-08-12] - FEATURE - Pizarr�n v2: Etapa 2 (header + vistas + b�squeda + zoom + actividad + tags)
**Resumen**: Se integraron al canvas los widgets de organizaci�n que quedaron muertos tras el reset del 11/8: header con cambio de vista, vistas Lista/Timeline/Archivados, buscador, panel de actividad, gestor de tags y slider de zoom.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: nuevo estado `_viewMode` (canvas/list/timeline/archived) + `_searchOpen`/`_searchText`/`_activityOpen`/`_tagManagerOpen`. El `InteractiveViewer` ahora solo se monta en modo canvas; las vistas lista/timeline/archivados reemplazan el canvas con `Positioned.fill`. `BoardHeader` siempre visible arriba (nombre de vista clickeable cicla canvas?lista?timeline?archivados?canvas, botones tags/actividad/b�squeda, indicador online). `BoardZoomSlider` abajo a la derecha (solo canvas). `BoardSearchPanel` busca por t�tulo/contenido/tags y navega al elemento. `BoardActivityPanel` carga con `pv.loadActivity()`. `BoardTagManager` crea tags. Nuevos `_goToElement(el)` (cambia a canvas y centra la transformaci�n en el elemento), `_toggleActivity()`, `_restoreElement(el)` (toggleArchive).
- Limpieza de imports muertos en widgets activados: `board_list_view.dart`, `board_timeline_view.dart`, `board_archived_view.dart` (app_state sin uso), `board_drawing_editor.dart`, `board_audio_editor.dart` (app_state/services/dart:io sin uso), `board_checklist_renderer.dart` (services innecesario).
**Lecciones**:
- Los widgets viejos (`BoardHeader`, `BoardListView`, etc.) son todos `Positioned` � deben ser hijos directos del `Stack` de la pantalla; las vistas completas (lista/timeline) se envuelven en `Positioned.fill` con padding top para no quedar debajo del header.
- `_goToElement` centra por traducci�n pura (sin escala): `translation = screenCenter - elementCenter`. Simple y suficiente para navegar a un resultado de b�squeda.
- Al cambiar de vista hay que cancelar el modo conector y cerrar el buscador, si no quedan banners colgados sobre la vista nueva.
**Impacto**: `pizarra_screen_v2.dart`, `board_list_view.dart`, `board_timeline_view.dart`, `board_archived_view.dart`, `board_drawing_editor.dart`, `board_audio_editor.dart`, `board_checklist_renderer.dart`
**Relacionado con**: skill-pantallas.md (spec pizarr�n � Organizaci�n: b�squeda, vistas, breadcrumb), Etapa 2 del plan

## [2026-08-12] - FEATURE - Pizarr�n v2: men� radial + tipos nuevos (checklist, dibujo, video, audio, conectores)
**Resumen**: Se complet� la Etapa 1 del pizarr�n: men� radial con 6 herramientas, creaci�n y renderizado de todos los tipos de elemento en el canvas, y modo conector para unir elementos con flechas. Los elementos nuevos se crean en el centro del viewport actual.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: reescrito. Reemplazado el FAB verde por `BoardToolsMenu` (men� radial con Nota, Checklist, Dibujo, Video, Audio, Conector). El canvas ahora renderiza todos los tipos: notas (estilo completo), checklists (`BoardChecklistRenderer` con edici�n inline), dibujos (`BoardDrawingRenderer`), videos (`BoardVideoRenderer`, tap abre URL en navegador con `url_launcher`), audios (`BoardAudioRenderer` con waveform + play). Conectores pintados en capa `CustomPaint` de 10000x10000 con `MultiConnectorPainter` (bezier + flecha). Wrapper com�n de gestos (`HitTestBehavior.opaque`): tap ? acci�n por tipo, long-press ? confirmaci�n de borrado, pan ? mover. Modo conector: banner cian arriba ("ORIGEN"/"DESTINO") + highlight del elemento; cancelar con bot�n. Banner de error rojo con reintentar. `_screenCenterToWorld()` para spawnear en el centro del viewport (inversa de la matriz del InteractiveViewer).
- `lib/providers/board_provider_v2.dart`: `update()` ahora soporta elementos sin id cloud (busca por `identical` ? `id` ? `createdAt`, actualiza local, debounce cloud solo si hay id). `_saveToLocal()` para elementos sin id actualiza la fila local por `created_at` en vez de insertar (evita duplicados en SQLite durante ediciones offline).
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: corregidas violaciones de skill_visual (fondo semitransparente `withValues(alpha: 0.2)` ? s�lido, fondo=borde mismo color, icono oscuro).
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart`: nuevo param `targetId` para editar un dibujo espec�fico (tap en el canvas), no solo el �ltimo creado.
- `lib/screens/pizarra_v2/editors/board_audio_editor.dart`: nuevo param `targetId`; busca el audio por id con fallback al �ltimo.
- `lib/screens/pizarra_v2/editors/board_video_search.dart`: nuevos params `spawnX`/`spawnY` (el video se crea en el centro del viewport).
- `lib/screens/pizarra_v2/note/note_card_modal.dart`: nuevos params `initialX`/`initialY` (notas nuevas spawnean en el centro del viewport, antes x:200 y:200 fijo).
- `lib/screens/pizarra_v2/renderers/board_checklist_renderer.dart`: `didUpdateWidget` que refresca los datos internos cuando el elemento cambia desde afuera (realtime de la pareja).
**Lecciones**:
- Los editores de dibujo/audio guardan al "�ltimo elemento del tipo": para editar uno espec�fico desde el canvas hay que pasar `targetId` (con fallback al �ltimo, que cubre el flujo de creaci�n).
- Un elemento creado optimista (sin id cloud) no puede usarse en `update()` con `eq('id')`; hay que resolverlo por `identical`/`createdAt` y persistir local por `created_at` para no duplicar filas en SQLite.
- Los conectores no deben ser hijos `Positioned`: se pintan en una capa `CustomPaint` del tama�o del mundo, que calcula los centros desde los elementos referenciados (se actualizan solos al moverlos).
- El renderer de checklist es un StatefulWidget con copia interna de `data`: sin `didUpdateWidget` los cambios de la pareja por realtime no se reflejaban.
**Impacto**: `pizarra_screen_v2.dart`, `board_provider_v2.dart`, `board_tools_menu.dart`, `board_drawing_editor.dart`, `board_audio_editor.dart`, `board_video_search.dart`, `note_card_modal.dart`, `board_checklist_renderer.dart`
**Relacionado con**: skill-pantallas.md (spec pizarr�n), D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual), Etapa 1 del plan

## [2026-08-12] - BUGFIX - ClassSetupWizard ahora solo aparece al entrar al calendario
**Resumen**: El wizard de "Cuantas clases tienes a la semana?" se mostraba al abrir la app (HomeScreen). Ahora solo aparece al entrar a la pantalla del calendario (CalendarHomeScreen).
**Cambios realizados**:
- `lib/screens/home_screen.dart`: eliminado `_checkClassSetup()` y su llamado en `initState`. Limpiados imports hu�rfanos (`provider`, `DatabaseHelper`, `ClassScheduleProvider`, `class_setup_wizard`, `pizarra_screen`).
- `lib/screens/calendar/calendar_home_screen.dart`: agregado `_checkClassSetup()` que revisa si hay clases configuradas en SQLite local; si no hay, abre el `ClassSetupWizard`. Se llama en `initState` antes de `_loadData()`. Agregados imports necesarios (`DatabaseHelper`, `class_setup_wizard`).
**Lecciones**:
- La verificaci�n de setup inicial no debe bloquear la experiencia de toda la app; es mejor ubicarla en el contexto donde se necesita (calendario).
**Impacto**: `home_screen.dart`, `calendar_home_screen.dart`

## [2026-08-12] - FEATURE+BUGFIX - Notas funcionales en canvas + polish completo del editor
**Resumen**: Las notas ahora se renderizan en el canvas del pizarr�n con su estilo real (forma, color, gradiente, borde). Se pueden arrastrar, editar (tap) y eliminar (long press). Adem�s se pulieron bugs cr�ticos de los editores y se agregaron opciones faltantes.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: integrado `BoardProviderV2` + `Consumer` para cargar y renderizar notas en el canvas. Cada nota se muestra con su color, shape (ClipPath), gradiente y borde real. Soporte drag-to-move (desactiva canvas pan durante el drag), tap para editar, long-press para eliminar con confirmaci�n. `_MiniShapeClipper` para formas igual que en el modal. Canvas reducido a 10000x10000 con `boundaryMargin: 5000` (antes `double.infinity` causaba bugs).
- `lib/screens/pizarra_v2/note/note_card_modal.dart`: soporte para `noteId` � carga datos existentes al editar, guarda con `provider.update()` si es edici�n o `provider.add()` si es nueva. Color default cambiado a violeta (`#5C2D91`) para visibilidad. Gradiente por defecto con colores violeta/azul/cian. Patrones solo se muestran si `patternEnabled: true` (toggle en Capa 2). `_PatternPainter` con 12 patrones (agregados Diagonales, C�rculos, Tri�ngulos, Panal). `_CardBorderPainter` con renderizado real: punteado dibuja c�rculos, dashed pinta segmentos, doble usa 2 l�neas, ondulado usa sinusoide, relieve doble stroke.
- `lib/screens/pizarra_v2/note/note_background_editor.dart`: `TextEditingController` con `dispose()` (fix memory leak). `didUpdateWidget` completo para todos los campos. Slider de saturaci�n agregado. Labels de sliders ampliados a 72px. Capa 1 (Color) eliminada � solo Capa 1 Degradado + Capa 2 Patr�n con toggle on/off. Color picker de gradiente usa `GradientColorPicker` (StatefulWidget propio, evita bug de `StatefulBuilder`).
- `lib/screens/pizarra_v2/note/note_border_editor.dart`: agregado slider de espaciado (1-20px). `didUpdateWidget` completo incluyendo spacing.
- `lib/screens/pizarra_v2/note/note_font_editor.dart`: Google Fonts cargadas con `GoogleFonts.getFont()`. Nombres de fuente corregidos (Open Sans, Dancing Script, etc.). Color dot negro reemplazado por `#444444`.
- `lib/screens/pizarra_v2/note/note_audio_recorder.dart`: cleanup de archivos temporales en `dispose()`. `_recorder.stop()` autom�tico al cerrar. Manejo de `null` en `stop()`.
- `lib/screens/pizarra_v2/note/note_toolbar.dart`: haptic feedback en los 5 botones. Barreras semitransparentes (`barrierColor: Colors.black26`) en todos los bottom sheets. Editor de fondo limitado a 55% de altura.
- `lib/screens/pizarra_v2/note/note_shape_editor.dart`: borde=fondo en estado no seleccionado (regla brutalista).
- `lib/screens/pizarra_v2/note/note_color_editor.dart`: glow en color seleccionado.
- `lib/screens/pizarra_v2/note/note_gradient_color_picker.dart` (nuevo): dialog de picker de color para gradientes, StatefulWidget propio.
- `lib/screens/pizarra_v2/note/note_common_color_wheel.dart` (nuevo): `SimpleColorWheel` compartido entre font editor y border editor (elimina 2 copias duplicadas del color wheel).
- `lib/services/notification_service.dart`: `LateInitializationError` fix � `_showLocalNotification` envuelta en try-catch + guard `_initialized`.
**Lecciones**:
- `StatefulBuilder` resetea variables locales en cada rebuild del builder � para di�logos de color, usar un `StatefulWidget` propio que mantenga el estado.
- Los `CustomPainter` necesitan `HitTestBehavior.opaque` si el child no es hittable.
- `BoxDecoration.border` es final � no se puede mutar; crear una nueva decoraci�n para cada estado de borde.
- El `InteractiveViewer` gana la guerra de gestos contra `GestureDetector` anidados � desactivar `panEnabled` durante drags de notas.
- Los archivos de audio temporal deben limpiarse en `dispose()` o quedan hu�rfanos en el filesystem.
**Impacto**: `pizarra_screen_v2.dart`, `note_card_modal.dart`, `note_background_editor.dart`, `note_border_editor.dart`, `note_font_editor.dart`, `note_toolbar.dart`, `note_shape_editor.dart`, `note_color_editor.dart`, `note_audio_recorder.dart`, `note_gradient_color_picker.dart` (nuevo), `note_common_color_wheel.dart` (nuevo), `notification_service.dart`
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual), errores-conocidos

## [2026-08-11] - FEATURE - Pizarr�n v2: editores de fondo por capas, fuente y borde (Etapa 2)
**Resumen**: Se complet� la toolbar derecha del modal de nota con los 3 botones restantes: Fondo (violeta), Fuente (fucsia) y Borde (naranja). Cada uno abre un bottom sheet con editor completo.
**Cambios realizados**:
- `lib/screens/pizarra_v2/note/note_background_editor.dart` (nuevo): sistema de 3 capas con tabs � Capa 1 Color (muestra el color base), Capa 2 Tipo (Liso/Lineal/Radial + selector de 3 colores del gradiente), Capa 3 Patr�n (8 patrones: puntos, l�neas H/V, cuadr�cula, zigzag, diamantes, ondas, rayas + patr�n personalizado con texto/emoji). Sliders para grosor, �ngulo, tama�o, opacidad y espaciado del patr�n.
- `lib/screens/pizarra_v2/note/note_font_editor.dart` (nuevo): 12 Google Fonts (Roboto, Open Sans, Lato, Montserrat, Oswald, Raleway, Poppins, Dancing Script, Pacifico, Permanent Marker, Caveat, Indie Flower), 5 colores base + "+" para custom, slider de tama�o 8-48px con botones +/-.
- `lib/screens/pizarra_v2/note/note_border_editor.dart` (nuevo): toggle on/off, color, 6 tipos de borde (S�lido, Punteado, Dashed, Doble, Ondulado, Relieve), slider de grosor 1-10px.
- `lib/screens/pizarra_v2/note/note_toolbar.dart`: reescrito con todos los botones funcionales, fondos violeta/fucsia/naranja, cada uno abre su bottom sheet con los editores completos.
- `lib/screens/pizarra_v2/note/note_card_modal.dart`: agregado estado `_bgState`, `_fontState`, `_borderState` con handles, y helper `_toSerializable` para persistir Colors en el Map de datos.
**Lecciones**:
- Los Maps con valores mixtos (Color + primitives) necesitan serializaci�n expl�cita antes de pasarlos a `data` del BoardElementV2 (que espera `Map<String,dynamic>` sin Colors).
- `.clamp()` en `num` devuelve `num` no `double`; usar `.toDouble()` al pasarlo a un par�metro `double`.
- Los bottom sheets con sliders necesitan `isScrollControlled: true` + `viewInsets` para que el teclado no tape el contenido.
**Impacto**: 3 archivos nuevos en `lib/screens/pizarra_v2/note/`, 2 modificados. `flutter analyze` 0 issues. Exe compilado OK.
**Relacionado con**: skill_visual.md, D-4, Etapa 1 del modal de nota

## [2026-08-11] - FEATURE - Pizarr�n v2: modal de nota con toolbar de edici�n (Etapa 1)
**Resumen**: Se cre� el modal de nota desde cero. Al apretar el bot�n verde flotante aparece un modal centrado con: t�tulo, cuerpo de texto, grabadora de audio funcional, selector de imagen de galer�a con picker de posici�n (arriba/medio/abajo), y toolbar derecha con 5 botones (Forma, Color, Fondo - placeholder, Fuente - placeholder, Borde - placeholder). Forma tiene 6 opciones (rect�ngulo, cuadrado, c�rculo, �valo, diamante, hex�gono). Color tiene 5 colores brutalistas base + rueda de color custom con slider de tono y cuadrado saturaci�n/brillo + �ltimos 5 colores custom. Nota se persiste en Supabase + SQLite v�a BoardProviderV2.
**Cambios realizados**:
- `lib/screens/pizarra_v2/note/note_card_modal.dart` (nuevo): modal principal con TextField para t�tulo y cuerpo, picker de imagen (`image_picker`) con selector de posici�n (top/middle/bottom) v�a bottom sheet, integraci�n con NoteAudioRecorder y NoteToolbar, bot�n de guardar que llama a `BoardProviderV2.add()`.
- `lib/screens/pizarra_v2/note/note_toolbar.dart` (nuevo): barra vertical con 5 botones (Forma cian, Color naranja, Fondo/A/B gris placeholder). Modo shape y color abren bottom sheets.
- `lib/screens/pizarra_v2/note/note_shape_editor.dart` (nuevo): grid de 6 formas con iconos (rect�ngulo, cuadrado, c�rculo, �valo, diamante, hex�gono), selecci�n con highlight verde.
- `lib/screens/pizarra_v2/note/note_color_editor.dart` (nuevo): 5 colores brutalistas (#FF6B00, #FF00FF, #00D4FF, #39FF14, #9D00FF) + bot�n "+" que abre color wheel. Secci�n de colores recientes (�ltimos 5 custom).
- `lib/screens/pizarra_v2/note/note_color_wheel.dart` (nuevo): barra de tono (hue) horizontal + cuadrado saturaci�n/brillo con gradientes, ambos con GestureDetector para pan. Preview con hex code en tiempo real.
- `lib/screens/pizarra_v2/note/note_audio_recorder.dart` (nuevo): grabador de audio funcional con `record` package (mic/stop), contador de tiempo, confirmacion visual (check verde) y bot�n de borrar.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: agregado estado `_showNote`, el bot�n verde ahora abre el modal en vez de hacer nada, y el NoteCardModal se superpone en el Stack cuando est� activo.
**Lecciones**:
- `Color.value` est� deprecated en Flutter 3.27+; usar `toARGB32()` para el int argb y `.r`/`.g`/`.b` (0-1 doubles) para canales individuales.
- `image_picker: ^1.2.3` devuelve `XFile` (no `File`); se usa `.path` directamente con `Image.file()`.
- El NoteCardModal usa `context.read<BoardProviderV2>()` v�a Provider (registrado en main.dart), sin necesidad de declarar imports en el screen padre.
- La toolbar derecha se posiciona como parte del mismo `Row` que la card en el modal, no como `Positioned` separado.
**Impacto**: 6 archivos nuevos en `lib/screens/pizarra_v2/note/`, 1 modificado (`pizarra_screen_v2.dart`). `flutter analyze` 0 issues.
**Relacionado con**: skill_visual.md (fondo=borde, sin sombras, redondo, sin negro puro), D-2 (Supabase), D-3 (SQLite)

## [2026-08-11] - REFACTOR - Pizarr�n v2: redise�o desde cero, solo lienzo con grid
**Resumen**: Se borr� toda la funcionalidad del pizarr�n v2 (elementos, herramientas, header, paneles, editores, vistas alternativas) y se dej� �nicamente el lienzo infinito con grid de puntitos y pan/zoom. Es el punto de partida para un redise�o completo desde cero.
**Cambios realizados**:
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: reescrito de 387 a 100 l�neas. Solo contiene `Scaffold` con fondo `#0A0A0A`, grid de puntitos `#333333` cada 30px (`_GridPainter` inline), e `InteractiveViewer` con pan/zoom (0.1x-5x). Se conserva el enum `BoardViewMode` para que los widgets viejos no rompan el an�lisis.
- Eliminadas todas las dependencias del provider, modelos, editores, renderers y widgets del pizarr�n.
- La navegaci�n desde `home_screen.dart` sigue funcionando (`const PizarraScreenV2()`).
**Lecciones**:
- El grid de puntitos se pinta en espacio de pantalla (Stack externo al InteractiveViewer) transformado por la matriz del `TransformationController`, as� no necesita `boundaryMargin` limitado.
- Los widgets viejos (header, timeline, etc.) quedan como c�digo muerto en disco pero no se importan; el `flutter analyze` los sigue chequeando, por eso se conserv� `BoardViewMode`.
**Impacto**: `lib/screens/pizarra_v2/pizarra_screen_v2.dart`
**Relacionado con**: skill-pantallas.md (especificaci�n del pizarr�n obsoleta para esta iteraci�n), D-4 (skill_visual)

## [2026-08-11] - BUGFIX - Bot WhatsApp: migraci�n a LID de WhatsApp (resoluci�n + cache + conexi�n descartable)
**Resumen**: El bot dej� de entregar mensajes el ~2026-08-10. WhatsApp migr� el enrutamiento de contactos a IDs de dispositivo vinculado (`@lid`): enviar al JID con n�mero normal resuelve sin error pero el servidor NO entrega (p�rdida silenciosa). Fix: resolver LIDs con `onWhatsApp()` en conexi�n descartable, cachear en `lids.json`, y enviar al JID LID. Verificado end-to-end con ACK `status=4` (le�do).
**Cambios realizados**:
- `bot-furi/bot.js`: nueva secci�n de resoluci�n de LIDs � `lidCache` + `cargarLidsCache()` + `guardarLidCache(phone, lid)` + `lidJid(sock, phone)` + `resolverLidsSolo()`. `main()` ahora resuelve LIDs en conexi�n descartable si faltan en cache. `enviarMensaje()` usa SOLO cache (nunca llama `onWhatsApp` en la conexi�n principal). `esperarAck()` agrega flush peri�dico (`sock.ev.flush()`) cada 2s para liberar ACKs retenidos por `AwaitingInitialSync`.
- `bot-furi/lids.json` (nuevo, gitignored): cache de LIDs persistido.
- `bot-furi/.gitignore`: agregados `lids.json` y `*.txt`.
- Quitado `console.log([DEBUG-ACK])` temporal de `esperarAck`.
- Verificaci�n: mood-120 de prueba ? enviado a `83189842346022@lid` (Facu) ? ACK status=4 ? marcado en `bot_notificaciones` ? limpieza del test row.
- `docs/contexto/bot-whatsapp.md`: secci�n de LID reescrita con fix real (no "re-vincular QR").
- `docs/contexto/errores-conocidos.md`: entrada LID marcada RESUELTO 2026-08-11 con fix real.
**Lecciones**:
- `onWhatsApp()` devuelve `lid` YA con sufijo `@lid`; si se concatena otro `@lid` queda `xxx@lid@lid`.
- `onWhatsApp()` puede romper el stream con `xml-not-well-formed` (2 de 3 corridas); la conexi�n descartable lo a�sla.
- El event buffer de Baileys (`AwaitingInitialSync`) retiene `messages.update`; el flush peri�dico los libera.
- Re-vincular WhatsApp (borrar `auth/` + QR nuevo) NO serv�a: el bloqueo era del JID destino (LID), no de las claves de cifrado. La sesi�n ya ten�a las claves LID de los contactos.
- Los LIDs de contactos NO est�n en la sesi�n del bot: se obtienen con una query a WhatsApp (`onWhatsApp`) y se cachean.
**Impacto**: `bot-furi/bot.js`, `bot-furi/.gitignore`, `bot-furi/lids.json` (nuevo), `docs/contexto/bot-whatsapp.md`, `docs/contexto/errores-conocidos.md`, `docs/contexto/historial.md`
**Relacionado con**: D-10 (bot WhatsApp), errores-conocidos (mensajes en cola LID), bot-whatsapp.md

## [2026-08-10] - BUGFIX+BUILD - Keystore eliminado + APK release firmado con firma debug (se instala sobre versiones previas)
**Resumen**: La app no funcionaba en el Realme C11 de Rocio (sin acceso USB). El usuario pidi� eliminar la keystore (que "no hace falta") y que el APK se instale s� o s� en todos los dispositivos. Se elimin� la firma custom (CN=Furi) y se volvi� a la **firma debug est�ndar de Flutter** � la misma que usaban los APK que s� instalaban antes del 6/8 � que se instala sobre cualquier instalaci�n debug previa sin desinstalar.
**Cambios realizados**:
- `android/app/build.gradle.kts`: eliminado el bloque `signingConfigs { create("release") }` con key.properties y el `signingConfig = signingConfigs.getByName("release")`. Ahora `release { signingConfig = signingConfigs.getByName("debug") }`.
- Borrados `android/key.properties` y `android/app/upload-keystore.jks`.
- **Hallazgo cr�tico**: tras quitar el signingConfig del release, el primer build gener� un APK **COMPLETAMENTE SIN FIRMAR** (`apksigner verify` ? `DOES NOT VERIFY: Missing META-INF/MANIFEST.MF`; sin bloque de firma v2 en el ZIP; META-INF sin MANIFEST.MF/CERT.RSA). AGP **NO** asigna autom�ticamente la firma debug en este proyecto cuando el buildType release queda sin signingConfig. Fix: `signingConfig = signingConfigs.getByName("debug")` expl�cito ? `Verifies (v2 scheme: true)` con `CN=Android Debug`.
- Build universal `app-release.apk` (64.6 MB, todas las ABIs: arm64-v8a + armeabi-v7a + x86_64, minSdk 24, targetSdk 36) verificado con apksigner 37.0.0.
- Release GitHub `v1.0.2-debug-firma` creado (el link `releases/latest` apunta al nuevo). Subida por API REST (`uploads.github.com`) porque `gh release upload` colgaba; la velocidad de subida var�a de ~3 KB/s a ~370 KB/s.
**Lecciones**:
- **Sin signingConfig expl�cito en release, AGP puede NO firmar el APK** (no siempre hace el fallback al debug config): el APK compila "v Built" pero Android lo rechaza al instalar. SIEMPRE verificar `apksigner verify` despu�s de tocar la firma � y antes de mandar un APK a otro celular.
- La firma debug de Flutter (`~/.android/debug.keystore`) es la misma en todos los builds del mismo dev machine y es la m�s compatible para instalaci�n manual: cualquier dispositivo que alguna vez acept� un APK debug acepta el nuevo sin desinstalar.
- La firma CN=Furi (keystore del 6/8) queda **hu�rfana**: los APK v1.0.1 instalados en el Realme C11 requieren desinstalaci�n previa para aceptar la v1.0.2. Documentado en la gu�a de instalaci�n.
- El keystore propio era innecesario para instalaci�n manual en 2 celulares; aportaba solo fricci�n (incompatibilidad de firma con los APK debug previos).
**Impacto**: `android/app/build.gradle.kts`, `android/key.properties` (borrado), `android/app/upload-keystore.jks` (borrado), `build/app/outputs/flutter-apk/app-release.apk`, GitHub release `v1.0.2-debug-firma`, `docs/contexto/historial.md`, `docs/contexto/flujo-de-trabajo.md`, `documentacion/GUIA_INSTALACION_APK.md`, `docs/contexto/errores-conocidos.md`
**Relacionado con**: errores-conocidos (firma release/APK no instalado), flujo-de-trabajo (build APK, firma), entrada keystore 2026-08-06

## [2026-08-08] - BUGFIX - Bot WhatsApp: API key invalidada hac�a parecer "sesi�n cerrada" (todo el d�a sin notificar)
**Resumen**: El bot dec�a "No hay sesion guardada en Supabase" en cada corrida de CI y mostraba QR sin poder conectarse. La sesi�n de WhatsApp estaba **intacta** en `bot_sessions` (104 claves, `creds.json` presente, `updated_at` 10:24 UTC); el problema era que la `SUPABASE_KEY` en `bot-furi/.env` y el secret `SUPABASE_KEY` de GitHub (creado el 2026-08-05) eran la service role key vieja invalidada por Supabase ? toda query respond�a `Unregistered API key`/`Invalid API key` ? `loadSessionFromSupabase()` encontraba error y trataba la sesi�n como inexistente ? ped�a QR y mor�a por timeout ("Sesi�n cerrada" aparente).
**Cambios realizados**:
- Verificaci�n: query con la key vieja ? `Unregistered API key`; con la key publicable de la app ? lee/escribe todas las tablas del bot (16 tablas verificadas una por una, incluidas `bot_sessions` y `bot_notificaciones`).
- `bot-furi/.env`: `SUPABASE_KEY` cambiada de service role key vieja a la **service role key nueva** (provista por el usuario).
- GitHub secret `SUPABASE_KEY`: actualizado en gh (secret list + `gh secret set`).
- Verificaci�n local + CI (key nueva): `node bot.js` ? "Sesion cargada desde Supabase" ? "Conectado a WhatsApp" ? "Sin novedades para notificar". **Sin reescanear QR** (la sesi�n no se perdi�).
- Verificaci�n CI: `gh workflow run` ? log: "Sesion cargada desde Supabase", "Conectado a WhatsApp", "Bot finalizado" � restaurado.
**Lecciones**:
- Un "Sesion cerrada / No hay sesion guardada" del bot NO siempre significa sesi�n de WhatsApp vencida: la primera autopsia es probar una query a `bot_sessions` con la key del `.env`. Si da `Invalid API key`/`Unregistered API key`, es la key, no el QR.
- La service role key vieja del proyecto fue invalidada por Supabase; las key nuevas que funcionan son las publishable. El bot puede operar con la publishable porque las tablas `bot_sessions`/`bot_notificaciones` tienen policies `FOR ALL USING (true)`.
- `cargarUsuarios()`/verificaciones usan la misma key: si la lectura falla, todo "no funciona" parec�a desconexi�n.
**Impacto**: `bot-furi/.env`, GitHub secret `SUPABASE_KEY`, `docs/contexto/bot-whatsapp.md`, `docs/contexto/historial.md`
**Relacionado con**: D-10 (bot), errores-conocidos (sesi�n LID � no re-relacionar, este ES distinto: key rota)

## [2026-08-08] - BUGFIX - Clases del wizard nunca se sub�an a Supabase (color ARGB fuera de rango en columna INTEGER)
**Resumen**: Las clases/materias configuradas en el wizard se guardaban solo en SQLite local y la tabla cloud `class_schedules` quedaba en `count = 0`. Causa ra�z: la columna `color` en la BD cloud se cre� como `INTEGER` (m�x 2147483647) pero el modelo manda `0xFF7B2D8E` = **4286262670**, fuera de rango ? Supabase respond�a `22003: value "4286262670" is out of range for type integer` y `_pushToSupabase()` (try/catch) lo tragaba silenciosamente ? `cloudId` nunca se asignaba ? el wizard volv�a a aparecer en cada apertura.
**Cambios realizados**:
- `supabase/migration_class_schedules.sql`: `color BIGINT DEFAULT 4286262670` en el CREATE + `ALTER TABLE class_schedules ALTER COLUMN color TYPE BIGINT USING color::bigint;` idempotente para tablas ya creadas.
- `supabase_schema.sql`: `color BIGINT DEFAULT 4286262670` en el CREATE TABLE master.
- Verificado en vivo contra la API REST (anon key): SELECT devuelve 200 con `count 0` (tabla exist�a, vac�a); INSERT directo reproduce el error 22003 exacto; `profiles` responde OK (proyecto y anon key v�lidos).
**Lecciones**:
- Un color ARGB de Flutter (`0xFFRRGGBB`) como int siempre excede el rango del `INTEGER` de Postgres (m�x 2147483647). Cualquier columna cloud que persista colores ARGB debe ser `BIGINT`.
- El try/catch de `_pushToSupabase` convierte el fallo de migraci�n de tipo en un "sync roto en silencio": la clase queda local, el cloudId nunca se setea y el wizard aparece de nuevo. Vale la pena revisar los logs `developer.log` ante "se guarda local pero no en la nube".
- El sync autom�tico de clases existentes ya existe (`_syncUnsyncedToSupabase` dentro de `loadSchedules`): basta abrir la app una vez tras ejecutar la migraci�n para que las clases locales suban solas.
**Impacto**: `supabase/migration_class_schedules.sql`, `supabase_schema.sql`, `docs/contexto/errores-conocidos.md`, `docs/contexto/historial.md`. **Pendiente de acci�n manual**: ejecutar `migration_class_schedules.sql` en el SQL Editor de Supabase para que la columna pase a BIGINT.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), errores-conocidos (ClassSetupWizard color fuera de rango)

## [2026-08-08] - BUILD+BUGFIX - APK no se instalaba en el Realme C11 de Rocio ? Release en GitHub + fix compilaci�n pizarra v2
**Resumen**: La app dej� de instalarse en el Realme C11 (Rocio, en otra provincia, sin acceso ADB). Los APK viejos s� instalaban, los nuevos daban "aplicaci�n no instalada". Investigaci�n: (1) los APK nuevos cambiaron de firma (debug ? keystore CN=Furi el 6/8), por lo que una versi�n vieja instalada en el celular hace que Android rechace el update con `INSTALL_FAILED_UPDATE_INCOMPATIBLE`; (2) WhatsApp/Drive renombran el archivo a `.apk.1` ? "aplicaci�n no instalada". Soluci�n: subir el APK universal actual a GitHub Releases (descarga por Chrome mantiene el nombre `.apk`), indicarle a Rocio desinstalar la versi�n vieja primero.
**Cambios realizados**:
- Fix de compilaci�n: `lib/screens/pizarra_v2/widgets/board_canvas.dart:153` pasaba 2 argumentos a `_liveElement()` (que acepta 1) ? `release` no compilaba (`Target kernel_snapshot_program failed`).
- Rebuild `flutter build apk --release` ? `app-release.apk` (64.6 MB, minSdk 24, targetSdk 36, ABIs arm64-v8a+armeabi-v7a+x86_64, firma CN=Furi).
- Publicado release en GitHub: `v1.0.1-apk-instalable` con el APK adjunto ? https://github.com/mrtuco748-cmyk/furiiiiiiiiiii/releases/tag/v1.0.1-apk-instalable
  (El primer intento cre� un Draft; se complet� con `gh release upload --clobber` + `gh release edit --draft=false`).
- `documentacion/GUIA_INSTALACION_APK.md`: m�todo A con link de GitHub + Chrome (no renombra). Tabla de errores ampliada con "bloqueada por seguridad ? desactivar escaneo de Play Protect".
**Lecciones**:
- Un APK release que compila en dev (debug) puede fallar en release por errores de lint que solo aparecen en la compilaci�n de AOT/`kernel_snapshot` (board_canvas.dart:153 `_liveElement(el, d)`). Correr al menos una vez `flutter build apk --release` tras cada milestone.
- Los APK con firma nueva NO se pueden instalar sobre una versi�n vieja con otra firma: hay que desinstalar primero ("aplicaci�n no instalada"). Se document� el paso 0 en la gu�a.
- WhatsApp/Drive renombran/cortan APKs grandes: el m�todo confiable es descarga con Chrome desde GitHub Releases (link `releases/latest`).
- Si el update sin ADB: GitHub Actions ya est� configurado; el Release se puede re-subir con un solo comando `gh release create` (o `gh release upload --clobber` + `--draft=false`).
**Impacto**: `app-release.apk` (nuevo), `github.com/mrtuco748-cmyk/furiiiiiiiiiii` releases, `documentacion/GUIA_INSTALACION_APK.md`, `lib/screens/pizarra_v2/widgets/board_canvas.dart`, `docs/contexto/historial.md`.
**Relacionado con**: errores-conocidos (firma release/APK), flujo-de-trabajo (build APK), D-4, pizarra v2

## [2026-08-08] - BUGFIX - Limpieza de 228 notas espurias de la pizarra v2 (DB local del exe)
**Resumen**: Las notas espurias creadas por el bug del doble tap (ver entrada anterior) quedaron persistidas en la BD SQLite local del exe: 228 elementos `note` con t�tulo "Nueva nota", contenido vac�o y `created_at` id�ntico (2026-08-08T06:44:17.281814). Se borraron de la BD local. Adem�s se descubri� que la tabla `board_elements_v2` NO existe en Supabase (error "No se pudo encontrar la tabla en schema cache" con supabase-js), as� que el sync de la pizarra v2 falla en silencio y los datos viven solo en SQLite local.
**Cambios realizados**:
- Backup de la BD: `build\windows\x64\runner\Release\.dart_tool\sqflite_common_ffi\databases\furi_calendar.db.backup_20260808` (106 KB).
- Script temporal `tool/board_cleanup.dart` (usando `package:sqlite3` del proyecto; SQLITE3 CLI no disponible, `better-sqlite3` no compila con gyp) que lista y borra las notas vac�as con `DELETE ... WHERE type='note' AND (content IS NULL OR content='') AND title='Nueva nota'`. Eliminado tras usarlo (no se deja c�digo muerto).
- Resultado: 230 ? 2 elementos. Quedan el dibujo (id 26, "Nuevo dibujo") y el video (id 149, "YouTube Video") que el usuario cre� a prop�sito.
**Lecciones**:
- En Windows no hay CLI de sqlite3 disponible y `better-sqlite3` falla a compilar (node-gyp). Lo m�s simple para operar la BD local es un script Dart con `package:sqlite3` (ya transitivo del proyecto) y `dart run`.
- La API de Supabase (service key) bloqueada para REST directo: "Forbidden use of secret API key in browser outside". Solo usar supabase-js con `ws` como transport en Node 20.
- La pizarra v2 NO est� sincronizada con la nube (tabla ausente en Supabase) ? borrar datos locales de la pizarra es suficiente; no hay soporte cloud para la v2 todav�a.
**Impacto**: `build\windows\x64\runner\Release\.dart_tool\sqflite_common_ffi\databases\furi_calendar.db` (+ backup), `docs/contexto/historial.md`
**Relacionado con**: entrada doble tap espurias (2026-08-08), D-3 (SQLite)

## [2026-08-08] - BUGFIX - Pizarra v2: dibujos/videos no se mov�an + notas espurias por doble tap
**Resumen**: Tras testear con el exe, ning�n tipo de tarjeta respond�a (arrastrar/mover/interactuar) y se creaban notas no deseadas. Tres causas combinadas: (1) el `GestureDetector` de cada elemento usaba `HitTestBehavior.deferToChild`, que delega el hit test al child � un `CustomPaint` (dibujos) no es hit-testable, as� que los gestos no llegaban al elemento; (2) `BoardVideoRenderer` ten�a su propio `GestureDetector` con `onTap` que robaba el tap del elemento y abr�a el navegador en vez de seleccionar (nunca se seleccionaba ? `panEnabled` segu�a `true` ? el InteractiveViewer robaba el drag); (3) el `onDoubleTap` del elemento solo exist�a para notas, as� que el doble tap sobre dibujos/videos ca�a al fondo y ejecutaba `onDoubleTapEmpty` ? creadas notas espurias en cada doble click.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: `behavior: HitTestBehavior.opaque` en el GestureDetector de elemento (captura gestos en toda el �rea, aunque el child no pinte en ese pixel); `onTap` ahora si el elemento es video y ya est� seleccionado abre el video (segundo tap), sino selecciona; `onDoubleTap` para todo tipo absorbe el gesto (notas alternan edici�n; resto solo selecciona � evita que caiga al fondo y cree notas); nuevo helper `_liveElement(el)` que busca por id con fallback `createdAt % 1000000` (mismo id que el usado en el build) para mover/actualizar la copia viva; nuevo `_openVideo(el)` con `url_launcher` (imports `board_element_data.dart` y `url_launcher`).
- `lib/screens/pizarra_v2/renderers/board_video_renderer.dart`: eliminado el `GestureDetector` interno con `onTap` y `_openVideo`; ahora es puramente visual (thumbnail + play button + t�tulo). La apertura la maneja el canvas al tocar el video seleccionado.
**Lecciones**:
- `HitTestBehavior.deferToChild` en el GestureDetector de un elemento NO funciona si el child no participa del hit test en ese punto: un `CustomPaint` sin `hitTest` propio (o `Image.network` en errorBuilder) no captura eventos ? el elemento queda "muerto" para gestos. `opaque` garantiza que el �rea completa del widget responda; los hijos internos (TextField) siguen recibiendo sus propios gestos porque est�n m�s profundo que en el �rbol.
- Doble GestureDetector anidado (renderer + elemento) roba la selecci�n: el renderer interno con `onTap` siempre gana y el elemento nunca se selecciona. La interacci�n de tipo "abrir video" debe hacerla el canvas (con elemento seleccionado) o el panel, no el renderer.
- Si el `onDoubleTap` del fondo (crear nota) es configurable y los elementos no lo absorben, el doble click sobre cualquier tipo de card sin `onDoubleTap` propio genera notas espurias: hay que absorber el gesto arriba en todos los tipos.
**Impacto**: `lib/screens/pizarra_v2/widgets/board_canvas.dart`, `lib/screens/pizarra_v2/renderers/board_video_renderer.dart`. 67 tests verdes, `flutter analyze` 0 errores.
**Relacionado con**: entrada regresi�n panEnabled (2026-08-08), skill_visual (sin cambios), D-2 (Supabase), D-3 (SQLite)

## [2026-08-08] - BUGFIX - Pizarra v2: notas no se mov�an ni editaban (regresi�n panEnabled) + build Windows completo
**Resumen**: Tras la ronda 2 de bugs, al testear el usuario descubri� que las notas no se pod�an mover ni escribir. Causa: el fix de la ronda 2 cambi� `panEnabled` a `!_isEditingText` (pan siempre habilitado salvo edici�n), y el InteractiveViewer robaba los gestos del GestureDetector interno de cada nota ? el drag no llegaba y el doble tap para editar tampoco. Se revirti� el comportamiento y se agreg� soporte de move para elementos reci�n creados (sin id cloud). Adem�s se complet� la compilaci�n del exe de Windows, que quedaba sin DLLs por un fallo intermedio de NuGet.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: `panEnabled` vuelve a `widget.selectedId == null && !widget.connectorMode`; eliminado el getter `_isEditingText` (innecesario). El `onPanUpdate` ahora usa `widget.provider.moveLocal(liveEl, ...)` (mueve aunque el elemento no tenga id cloud) y el renderer recibe `onRequestEdit` para entrar a edici�n con doble tap sobre el texto.
- `lib/providers/board_provider_v2.dart`: nuevo `moveLocal(BoardElementV2 el, double x, double y)` � actualiza la copia local (busca por `identical` ? `id` ? `createdAt`), `notifyListeners()`, guarda en SQLite y sincroniza a cloud con debounce de 300ms solo si hay id cloud (si no, queda solo local hasta que el id llegue del realtime).
- `lib/screens/pizarra_v2/renderers/board_note_renderer.dart`: nuevo callback `onRequestEdit` (VoidCallback?) � el doble tap sobre el texto ahora llama a `onRequestEdit` para que el canvas active el modo edici�n (antes re-emit�a el contenido sin entrar en edici�n).
- `lib/screens/pizarra_v2/renderers/board_element_renderer.dart`: nuevo param `onRequestEdit` que se propaga al renderer interno.
- Build Windows: el build `flutter build windows --release` previo fallaba con "ZIP decompression failed (-5)" al descargar un paquete NuGet de `audioplayers_windows` (red schannel intermitente) y dejaba el `runner\Release\` SOLO con `furi_app.exe` (sin DLLs ni `data/`). Se copi� el contenido de `build\windows\x64\install\` (todas las DLLs, `flutter_windows.dll`, `app.so`, `icudtl.dat`, `data/flutter_assets`) a `build\windows\x64\runner\Release\`.
**Lecciones**:
- El conflicto pan vs. gestos de notas es a dos bandas: con `panEnabled` siempre true el InteractiveViewer roba el drag de las notas; con pan siempre false no se puede panear con un elemento seleccionado. La soluci�n usada: pan deshabilitado solo cuando hay selecci�n activa (`selectedId != null`), porque el elemento seleccionado se mueve con su propio GestureDetector (no necesita el pan del fondo) y el doble tap para editar tambi�n llega.
- Un build de Flutter Windows "v Built" puede quedar incompleto si el paso de NuGet/CIFall� silenciosamente: no basta con que exista `furi_app.exe`; hay que verificar que el folder de release tenga `flutter_windows.dll` y `data/`.
- Al borrar `build\windows` hay que activar el entorno MSVC (`D:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat amd64`) o CMake no encuentra `cl.exe` (TRK0005).
**Impacto**: `lib/screens/pizarra_v2/widgets/board_canvas.dart`, `lib/providers/board_provider_v2.dart`, `lib/screens/pizarra_v2/renderers/board_note_renderer.dart`, `lib/screens/pizarra_v2/renderers/board_element_renderer.dart`, `build\windows\x64\runner\Release\` (exe completo), `docs/contexto/historial.md`. Exe recompilado 2026-08-08 06:35, 1.4 MB.
**Relacionado con**: entrada ronda 2 (2026-08-08), skill_visual (sin cambios), D-2 (Supabase), D-3 (SQLite)

## [2026-08-08] - BUGFIX - Pizarra v2: 18 bugs de UX/funcionalidad (ronda 2)
**Resumen**: Tras la primera ronda de 24 bugs, se corrigieron 18 bugs adicionales de la pizarra v2: notas que no guardaban texto, columna is_archived faltante en instalaciones nuevas, Tag Manager que cerraba la pantalla, conectores sin UI de origen/destino, checklist sin edici�n de texto, comentarios que no aparec�an al agregar, editor de dibujo sin carga de strokes existentes, audio sin reproducci�n, reacciones sin mostrar inline, c�digo muerto eliminado, zoom slider est�tico, renderers faltantes para subBoard/separator, markAsSeen sin await en cloud, pan deshabilitado al seleccionar, vistas alternativas sin estados, drawing imagePath con icono gen�rico, video con dialog muerto, y _pushUnsyncedToCloud sin asignar id cloud.
**Cambios realizados**:
- `lib/screens/pizarra_v2/renderers/board_element_renderer.dart`: el `onContentChanged` de la nota ahora emite `{'_content': content}` (antes `quillDelta` inexistente) y `board_canvas` lo traduce a `copyWith(content:)`; se agregan renderers para `subBoard` (card con icono dashboard + t�tulo) y `separator` (l�nea horizontal/vertical seg�n data).
- `lib/database/database_helper.dart`: `is_archived INTEGER NOT NULL DEFAULT 0` agregado al CREATE TABLE de `board_elements_v2` en instalaciones nuevas (el upgrade v7 ya lo ten�a).
- `lib/screens/pizarra_v2/widgets/board_tag_manager.dart`: nuevo param `onClose`; el bot�n X llama `widget.onClose` en vez de `Navigator.pop(context)` que cerraba toda la pantalla.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: modo conector completo � `_connectorMode`/`_connectorFromId`, `_createAndEdit('connector')` entra a modo selecci�n, `_handleConnectorSelect` crea el elemento con `ConnectorData(fromId, toId)`, banner inferior con instrucciones y bot�n "Cancelar", panel de opciones oculto en modo conector; pasa `transformController` al zoom slider.
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: params `connectorMode`/`connectorFromId`, `panEnabled` queda en `widget.selectedId == null && !widget.connectorMode` (se desactiva con selecci�n � revertido en la sesi�n siguiente porque `_isEditingText` romp�a mover/editar notas); highlight cian del origen del conector; reacciones inline (chips con emojis de `data['reactions']`).
- `lib/screens/pizarra_v2/renderers/board_checklist_renderer.dart`: di�logo de edici�n ahora hace `Navigator.pop` con el texto en las acciones Cancelar/Guardar (antes `setState` local nunca devolv�a); llave `}` faltante agregada.
- `lib/screens/pizarra_v2/widgets/board_element_panel.dart`: `_showComments` usa `_liveComments()` (relee del provider por id) para que el comentario nuevo aparezca de inmediato.
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart`: `initState` carga strokes del �ltimo dibujo existente y guarda en ese elemento (`_targetId`), no en uno nuevo.
- `lib/screens/pizarra_v2/renderers/board_audio_renderer.dart`: reescrito como StatefulWidget con `Audioplayers` � reproduce `DeviceFileSource(localPath)` o `UrlSource(storagePath)`, waveform con progreso, formato de duraci�n mm:ss.
- `lib/screens/pizarra_v2/widgets/board_element_card.dart`: eliminado (c�digo muerto).
- `lib/screens/pizarra_v2/widgets/board_zoom_slider.dart`: reescrito con `TransformationController` de verdad � bot�n -/+, Slider vinculado al scale (0.1-5.0), escala preservando el centro.
- `lib/providers/board_provider_v2.dart`: `markAsSeen` ahora hace `await` del update cloud con try/catch; `_pushUnsyncedToCloud` inserta con `clearId: true` (no env�a el id local de SQLite al cloud), guarda el id cloud en memoria y reconcilia la fila local (delete del id local + re-save con el id cloud + synced=1). Preven�a colisiones y updates que apuntaban a filas inexistentes.
- `lib/screens/pizarra_v2/widgets/board_list_view.dart` / `board_timeline_view.dart` / `board_archived_view.dart`: estados LOADING (spinner) y ERROR (mensaje + retry) adem�s del vac�o.
- `lib/screens/pizarra_v2/renderers/board_drawing_renderer.dart`: `Image.file` si `imagePath != null` (antes icono gen�rico).
- `lib/screens/pizarra_v2/renderers/board_video_renderer.dart`: al tocar abre el video en navegador externo con `url_launcher` (agregada a pubspec) en vez de un dialog con solo la URL.
- `pubspec.yaml`: agregada `url_launcher: ^6.3.1`.
**Lecciones**:
- `panEnabled` con `!editingText` (siempre true salvo edici�n) hac�a que el InteractiveViewer robara los gestos de las notas: con GestureDetector interno del elemento, el pan del fondo y el drag/elemento pelean. Se revierte a desactivar el pan con selecci�n activa (`selectedId == null`) � el elemento seleccionado se mueve con su propio GestureDetector, sin conflicto.
- Los widgets con botones que cierran (Tag Manager) no deben usar `Navigator.pop` si est�n embebidos en un Stack con otro Scaffold debajo: cierran toda la app.
- El id local de SQLite (`INTEGER PRIMARY KEY` autoincrement) NO es el id cloud (BIGSERIAL): al subir hay que `clearId: true`, tomar `res['id']` y reconciliar la fila local (borrar la fila con el id viejo y reinsertar con el cloud id).
- Un audio embebido en un renderer debe ser StatefulWidget con dispose del player, o el stream queda escuchando y el audio sigue reproduciendo tras cerrar la pizarra.
- url_launcher ya estaba en pubspec.lock (transitiva) � declararla en pubspec directo no cambia la versi�n resuelta.
**Impacto**: 13 archivos modificados + 1 eliminado, 67 tests verdes, `flutter analyze` 0 errores.
**Relacionado con**: skill-pantallas.md (pizarr�n), D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual)

## [2026-08-07] - BUGFIX - Pizarra v2: 24 bugs cr�ticos de UX/funcionalidad
**Resumen**: Tras testear la pizarra como usuario se corrigieron 24 bugs que romp�an flujos reales: grid no visible, notas no editables, mover solo funciona una vez, panel de opciones con botones rotos, men� radial no funciona, dibujo/video/audio sacan del pizarr�n, conectores no crean, zoom/pan se buguea, notas del otro no interact�an, vista archivados no cambia, tags no crean, colores no cambian, tipos se ven iguales, reacciones no funcionan, comentarios no agregan, sub-tableros no crean, colapsar no funciona, bloquear no funciona, fuente/tama�o/alineaci�n no cambian, emoji header no agrega, performance lenta, no guarda offline, reiniciar no arregla.
**Cambios realizados**:
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: reescrito con GestureDetector separado del InteractiveViewer, grid siempre visible, panEnabled=false cuando hay selecci�n, hitTestBehavior.deferToChild para permitir TextField, live element lookup para moves, clipBehavior.none en Stack.
- `lib/screens/pizarra_v2/widgets/board_element_panel.dart`: reescrito como StatefulWidget con dialogs funcionales para editar, color picker, font picker, reacciones, comentarios. Cada bot�n ahora tiene implementaci�n real.
- `lib/screens/pizarra_v2/renderers/board_note_renderer.dart`: reescrito como StatefulWidget con TextEditingController + FocusNode, autoFocus en edici�n, save on every change, double tap para entrar en modo edici�n.
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: reescrito con callbacks individuales por tipo (onCreateNote, onCreateChecklist, etc.), crea elemento y abre editor correspondiente sin salir del pizarr�n.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: reescrito con estados separados para cada editor (_showDrawingEditor, _showAudioEditor), createAndEdit() que crea elemento y abre editor, callbacks individuales al menu.
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart`: reescrito sin referencia a elemento espec�fico, guarda al elemento de dibujo m�s reciente, onClose callback.
- `lib/screens/pizarra_v2/editors/board_audio_editor.dart`: reescrito sin referencia a elemento espec�fico, guarda al elemento de audio m�s reciente, onClose callback.
- `lib/screens/pizarra_v2/editors/board_video_search.dart`: reescrito con onClose callback, no sale del pizarr�n.
- `lib/screens/pizarra_v2/renderers/board_checklist_renderer.dart`: reescrito con edici�n de texto por item, asignaci�n toggle, progress bar, delete items.
- `lib/providers/board_provider_v2.dart`: reescrito con saveToLocal inmediato en add/update, bool?int conversion para SQLite, JSON encode/decode para tags/data, markAsSeen con sync local+cloud, toggleArchive, offline-first load.
**Lecciones**:
- InteractiveViewer + GestureDetector anidados causan conflicto de gestos. Separar el GestureDetector del InteractiveViewer y usar panEnabled=false cuando hay selecci�n resuelve el problema de "mover solo funciona una vez".
- hitTestBehavior.deferToChild permite que los hijos (TextField) reciban taps mientras el padre sigue recibiendo pan.
- TextField necesita FocusNode + autoFocus + addPostFrameCallback para funcionar dentro de un GestureDetector.
- Los editores (dibujo, audio, video) no deben recibir un elemento espec�fico; deben crear uno nuevo y guardarlo al elemento m�s reciente de ese tipo.
- SQLite necesita bools como ints (0/1) y maps como JSON strings.
- El provider debe guardar en SQLite inmediatamente en add/update, no solo en debounce.
**Impacto**: 10 archivos reescritos, 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 1/2/3 del pizarr�n, skill-pantallas.md, D-2 (Supabase), D-3 (SQLite)

## [2026-08-07] - FEATURE - Pizarr�n v2: Etapa 3 (Polish - Vistas m�ltiples + Archivados + Tags + B�squeda)
**Resumen**: Se agregaron vistas alternativas (lista, timeline, archivados), gesti�n de tags personalizados, campo isArchived, y navegaci�n entre vistas desde el header.
**Cambios realizados**:
- `lib/models/board_element_v2.dart`: agregado campo `isArchived` con copyWith, toMap, fromMap.
- `lib/providers/board_provider_v2.dart`: `elements` filtra archivados, nuevos getters `allElements`, `archivedElements`, m�todo `toggleArchive()`.
- `lib/database/database_helper.dart`: agregada columna `is_archived` a `board_elements_v2`.
- `lib/screens/pizarra_v2/widgets/board_list_view.dart` (nuevo): vista de lista con cards por elemento, tipo, autor, tags.
- `lib/screens/pizarra_v2/widgets/board_timeline_view.dart` (nuevo): vista timeline cronol�gico con l�nea vertical, dots por autor, tiempo relativo.
- `lib/screens/pizarra_v2/widgets/board_archived_view.dart` (nuevo): vista de archivados con bot�n restaurar.
- `lib/screens/pizarra_v2/widgets/board_tag_manager.dart` (nuevo): panel para crear/gestionar tags con colores, guardados en SQLite.
- `lib/screens/pizarra_v2/widgets/board_header.dart`: actualizado con selector de vista (tap en nombre cambia: Pizarra ? Lista ? Timeline ? Archivados), bot�n de tags.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: enum `BoardViewMode`, integraci�n de vistas, estado para tag manager.
**Lecciones**:
- Las vistas alternativas reusan los mismos datos del provider, solo cambian el renderer. Patr�n escalable: nueva vista = nuevo widget + caso en el switch del build.
- `isArchived` filtra por defecto en `elements`, pero `allElements` incluye todo. As� las vistas de canvas/lista/timeline no muestran archivados, pero la vista de archivados s�.
- Los tags se guardan en SQLite (`board_tags`) y se cargan al iniciar el provider. Escalable: se pueden sync con cloud en el futuro.
- El header cambia de vista con un tap simple (ciclo: canvas ? lista ? timeline ? archivados ? canvas). Simple pero efectivo.
**Impacto**: 4 archivos nuevos, 5 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 2 del pizarra, skill-pantallas.md, D-2 (Supabase), D-3 (SQLite)

## [2026-08-07] - FEATURE - Pizarr�n v2: Etapa 2b (Editores interactivos + Video Search + Audio Recording + Drawing Editor)
**Resumen**: Se agregaron editores interactivos para dibujo, audio y video. Drawing editor con herramientas (brush, eraser, line, rectangle, circle), colores y tama�o de pincel. Audio editor con grabaci�n de voz y waveform en tiempo real. Video search dialog para pegar URLs de YouTube/TikTok.
**Cambios realizados**:
- `lib/screens/pizarra_v2/editors/board_drawing_editor.dart` (nuevo): editor de dibujo con canvas, herramientas (brush, eraser, line, rectangle, circle), paleta de 8 colores, slider de tama�o, undo, clear.
- `lib/screens/pizarra_v2/editors/board_audio_editor.dart` (nuevo): grabador de audio con waveform en tiempo real, bot�n record/stop, duraci�n, guardado local.
- `lib/screens/pizarra_v2/editors/board_video_search.dart` (nuevo): dialog para pegar URLs de YouTube/TikTok, parseo autom�tico de thumbnail YouTube, validaci�n de URL.
- `lib/screens/pizarra_v2/pizarra_screen_v2.dart`: integrado con editores, estado para mostrar/ocultar editores.
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: callbacks para abrir editores espec�ficos por tipo.
- `lib/models/board_element_data.dart`: agregado `copyWith` a `DrawingStroke`.
**Lecciones**:
- Drawing strokes se guardan como JSON de puntos. Si crecen mucho, futuro: renderizar a imagen y guardar en Storage.
- Audio recording usa `record` package que ya estaba en pubspec. Waveform se genera en tiempo real simulando amplitud.
- YouTube thumbnails se obtienen gratis via `img.youtube.com/vi/{id}/hqdefault.jpg`.
- Los editores se abren como bottom sheets para mantener contexto del pizarr�n.
**Impacto**: 3 archivos nuevos, 3 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 2 del pizarr�n, D-2 (Supabase), skill-pantallas.md

## [2026-08-07] - FEATURE - Pizarr�n v2: Etapa 2 (Renderers por tipo + Checklist + Conectores + Drawing + Video + Audio)
**Resumen**: Se agregaron renderers espec�ficos por tipo de elemento, modelos de datos type-safe, y soporte para checklist, drawing, video, audio y conectores con curvas bezier.
**Cambios realizados**:
- `lib/models/board_element_data.dart` (nuevo): modelos type-safe por tipo (ChecklistData, ConnectorData, VideoData, AudioData, DrawingData, SeparatorData, SubBoardData). Cada modelo serializa/deserializa al campo `data` de BoardElementV2.
- `lib/screens/pizarra_v2/renderers/` (nueva carpeta):
  - `board_note_renderer.dart`: renderer de notas con texto simple (formato rico completo en etapa futura).
  - `board_checklist_renderer.dart`: checklist con items, estados (pending/in_progress/done), asignaci�n a Facu/Rocio, progress bar, reordenar.
  - `board_drawing_renderer.dart`: dibujo libre con strokes (brush, eraser, line, rectangle, circle). Renderiza con CustomPainter.
  - `board_video_renderer.dart`: video embed con thumbnail + play button. Soporta YouTube, TikTok, otros.
  - `board_audio_renderer.dart`: audio con waveform visual, bot�n play/pause, duraci�n.
  - `board_connector_renderer.dart`: conectores con curvas bezier, l�neas rectas, punteadas, etiquetas, flechas. Calcula posiciones en tiempo de renderizado desde elementos referenciados.
  - `board_element_renderer.dart`: widget unificado que delega al renderer espec�fico seg�n el tipo.
- `lib/screens/pizarra_v2/widgets/board_canvas.dart`: reescrito para usar renderers unificados, capa de conectores detr�s de elementos, soporte para edici�n inline.
- `lib/screens/pizarra_v2/widgets/board_tools_menu.dart`: actualizado con botones para checklist, dibujo, video, audio, conector.
- `pubspec.yaml`: eliminada dependencia flutter_quill (API incompatible), se usa TextField simple por ahora.
**Lecciones**:
- flutter_quill tiene API inestable entre versiones. Mejor usar TextField simple + formato b�sico por ahora, agregar formato rico completo despu�s.
- Los conectores no deben guardar posiciones, solo fromId/toId. Las posiciones se calculan al renderizar desde los elementos referenciados. As� se actualizan autom�ticamente cuando los elementos se mueven.
- Los renderers por tipo permiten escalabilidad: nuevo tipo = nuevo renderer + caso en el switch del renderer unificado.
- Drawing strokes como JSON pueden ser grandes. Futuro: renderizar a imagen y guardar en Storage, mantener solo path en `data`.
**Impacto**: 8 archivos nuevos, 3 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: Etapa 1 del pizarr�n, skill-pantallas.md (especificaci�n del pizarr�n), D-2 (Supabase)

## [2026-08-07] - FEATURE - Pizarr�n v2: Etapa 1 (Sync + Offline + Estructura nueva)
**Resumen**: Se comenz� el redise�o completo del pizarr�n basado en 100 preguntas respondidas. Etapa 1: nueva estructura de c�digo, modelo de datos completo, provider con sync realtime + offline, canvas b�sico con notas, panel de edici�n, badge NUEVO, historial de actividad.
**Cambios realizados**:
- `lib/models/board_element_v2.dart` (nuevo): modelo completo con t�tulo, contenido, formato de texto (B/I/U, tama�o, color, fuente, alineaci�n), color de fondo custom, emoji header, tags, prioridad, asignado, estado, colapsable, bloqueable, auto-size, badge NUEVO, autor�a.
- `lib/providers/board_provider_v2.dart` (nuevo): provider con offline-first (SQLite cache), sync con Supabase, realtime, debounce para moves/resizes, actividad, tags guardados, markAsSeen.
- `lib/database/database_helper.dart`: versi�n 7 con tablas `board_elements_v2`, `board_activity`, `board_tags`.
- `lib/screens/pizarra_v2/` (nueva carpeta): pantalla reescrita desde cero en widgets separados:
  - `pizarra_screen_v2.dart`: pantalla principal con Stack de widgets.
  - `widgets/board_canvas.dart`: InteractiveViewer + grid de puntos grises + skeleton loading.
  - `widgets/board_header.dart`: header minimalista con nombre del tablero + search + actividad + indicador online.
  - `widgets/board_tools_menu.dart`: men� radial con bot�n + que expande herramientas.
  - `widgets/board_element_card.dart`: card de elemento con badge de autor (iniciales color), badge NUEVO, tags, prioridad, colapsado, bloqueado, animaci�n scale bounce.
  - `widgets/board_element_panel.dart`: bottom sheet con opciones (editar, color, fuente, reacciones, comentarios, duplicar, bloquear, eliminar).
  - `widgets/board_search_panel.dart`: b�squeda con preview + filtros.
  - `widgets/board_activity_panel.dart`: panel lateral con historial de actividad.
  - `widgets/board_zoom_slider.dart`: indicador de zoom.
- `lib/main.dart`: registrado `BoardProviderV2`.
- `lib/screens/home_screen.dart`: navegaci�n actualizada a `PizarraScreenV2`.
- `skill-pantallas.md`: agregada especificaci�n completa del pizarr�n (100 respuestas).
**Lecciones**:
- Los imports en subcarpetas necesitan `../../../` para llegar a `lib/`.
- `ConflictAlgorithm` viene de `sqflite`, no de `supabase_flutter`.
- Text no tiene `fontSize` como par�metro directo � va dentro de `TextStyle`.
- El modelo v2 es inmutable (`copyWith`) � cada actualizaci�n crea una nueva instancia.
- Offline-first: cargar SQLite primero, luego sync con cloud. Los elementos no sincronizados tienen `synced = 0`.
**Impacto**: 12 archivos nuevos, 3 modificados. 67 tests verdes, `flutter analyze` sin errores.
**Relacionado con**: skill-pantallas.md (especificaci�n del pizarr�n), D-2 (Supabase), D-3 (SQLite offline)

## [2026-08-07] - FEATURE - Skill de Pantallas y Sincronizaci�n (skill-pantallas.md) v2
**Resumen**: Se cre� `skill-pantallas.md` en la ra�z como regla obligatoria que documenta las reglas de sincronizaci�n entre Facu y Rocio, estructura de cada pantalla, estados visuales, navegaci�n, colores por usuario y reglas de negocio por pantalla. **Versi�n 2**: se agregaron reglas de "todo comentable + todo reaccionable + todo interactuable".
**Cambios realizados**:
- `skill-pantallas.md` (nuevo, v2): Reglas generales de sync (todo en tiempo real, notificaciones solo por bot WhatsApp, colores por usuario, 4 estados por pantalla, mapa de navegaci�n), **regla 6 "todo comentable"** (excepto chat que ya tiene reply), **regla 7 "todo reaccionable"** (long-press ? emojis como WhatsApp, max 5 keys), **regla 8 "todo interactuable"** (no hay nada de solo lectura), fichas detalladas de 13 pantallas con filas de comentarios y reacciones, checklist de implementaci�n actualizado, pantallas excluidas.
- Cada ficha incluye: tabla, sync, permisos, colores, reacciones, comentarios, estados visuales.
- Se excluyeron LoginScreen, SettingsScreen, MapaScreen, NotificationsScreen (simples o sin sync compleja).
**Lecciones**:
- El skill se cre� iterativamente con 14 preguntas al usuario v�a tool `question`.
- Formato elegido: reglas generales + fichas por pantalla (no tablas comparativas ni secci�n por pantalla pura).
- Las reglas de permisos son "por pantalla" � se documentaron las que ya existen en el c�digo; las que no est�n confirmadas se pueden ajustar despu�s.
- "Todo comentable" excluye chat porque ya tiene reply/swipe-to-reply.
- "Todo reaccionable" usa mismo formato que chat: long-press ? ??????:v xD :0 + custom, max 5 keys, 1 por usuario por key.
**Impacto**: `skill-pantallas.md` (nuevo, v2), `docs/contexto/historial.md`
**Relacionado con**: AGENTS.md (regla de leer docs antes), skill_visual.md, FURI-Nosotros-Skill.md

## [2026-08-07] - BUGFIX - Pizarr�n: 12 bugs de UX/persistencia (dialogs, IDs, flechas, links, estados)
**Resumen**: Tras testear la pizarra como usuario se corrigieron bugs que romp�an flujos reales: botones Crear de dialogs siempre deshabilitados, elementos sin id cloud (duplicados + no se pod�an conectar/borrar bien), flecha del conector al rev�s, editar link borraba comentarios, sub-tablero en (20,20), comentarios con snapshot stale, sin UI de error y skill_visual en carpeta/search.
**Cambios realizados**:
- `lib/models/board_element.dart`: `copyWith` ahora acepta `id`/`clearId`/`color`/`userId`. `toMap` usa `userId ?? AppState.myId` (no pisa autor�a). `fromMap` acepta `data` como `Map` din�mico (no solo `Map<String,dynamic>`).
- `lib/providers/board_data_provider.dart`:
  - `add()` hace `.insert().select().single()` y fusiona el id cloud en la copia optimista (conserva x/y/data locales). Si falla, rollback del optimista.
  - Realtime: mergea optimista sin id (evita duplicados) y no pisa moves/resizes pendientes.
  - `delete()` limpia conectores hu�rfanos. Nuevo `deleteLocal` para elementos sin id. Getter `isEmpty`.
- `lib/screens/pizarra/pizarra_screen.dart`:
  - Dialogs con `StatefulBuilder` + `onChanged` (Crear se habilita al tipear). Helper `_promptText`.
  - Links: guarda URL normalizada en `content` + `data` sin borrar comments.
  - Sub-tablero spawnea en centro del viewport. Doble-tap board parsea `boardId` int/string. Back limpia selecci�n.
  - Conectores: flecha en el destino (`_drawArrowhead(b, a)`), evita dupes del mismo par.
  - Move/resize/comentarios usan `_liveElement` (copia actual del provider, no el snapshot del build).
  - Borrar resuelve por id o por temp-id local. Banner + pantalla de error con retry.
  - skill_visual: carpeta board y panel b�squeda con fondo=borde.
- Tests: 12 board_element + 8 board_data_provider = 20 verdes. `flutter analyze` sin issues.
**Lecciones**:
- `onPressed: ctrl.text.isNotEmpty ? fn : null` se eval�a UNA vez al build del dialog ? bot�n Crear queda null para siempre. Hay que `StatefulBuilder` + `onChanged`/`setState`.
- Insert sin `.select()` deja el elemento local sin id ? no se puede conectar/borrar por id, y el realtime agrega un segundo. Siempre `insert().select().single()` y mergear.
- `_drawArrowhead(canvas, a, b)` con tip=a dibuja la punta en el origen; la punta va en el destino.
- `updateDataLocal(el, {url, title})` pisa el map entero y borra `comments`. Hay que `{...el.data, ...}`.
- En pan/resize el `el` del build queda stale tras el primer frame; hay que releer del provider (`_liveElement`).
**Impacto**: `lib/models/board_element.dart`, `lib/providers/board_data_provider.dart`, `lib/screens/pizarra/pizarra_screen.dart`, tests.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), historial pizarr�n etapa 1/2.

## [2026-08-07] - FEATURE - Pizarr�n: lienzo infinito + centrado + alta en el centro del visible + tipos limpiados
**Resumen**: El pizarr�n ten�a un l�mite de 20000px (`boundaryMargin` del InteractiveViewer) que cortaba el arrastre/zoom y se mostraba desde la esquina. Ahora el lienzo es infinito, arranca centrado en el origen, los elementos nuevos se colocan en el centro del viewport actual y se eliminaron los tipos `postit` y `arrow`.
**Cambios realizados**:
- `lib/screens/pizarra/pizarra_screen.dart`:
  - **Lienzo infinito**: grid movido a un `CustomPaint` en el Stack externo (espacio de pantalla) que repinta seg�n la transformento actual, en vez de pintarlo dentro del InteractiveViewer limitado por el SizedBox. `boundaryMargin` de `EdgeInsets.all(_boardSize)` ? `EdgeInsets.all(double.infinity)` y los `Stack` internos con `clipBehavior: Clip.none`, as� los elementos pueden ubicarse y verse en cualquier parte sin recortarse.
  - **Centrado al iniciar**: `_goToCenter()` ahora centra el mundo en la pantalla usando `MediaQuery.size` (antes pon�a `(-500, -400)`).
  - **Agregar al centro del viewport**: nuevo `_screenCenterToWorld()` (invierte `_transformController.value` y transforma el punto central de la pantalla a coordenadas mundo) usado en `_spawnAdd()` para ubicar el elemento centrado en el punto actual de la vista. Reemplazado `_randPos()` aleatorio.
  - **Tipos eliminados**: se quit� `postit` y `arrow` de las herramientas flotantes, del renderizado (`_buildElementBody`), del `_typeIcon`, del `onDoubleTap` para editar y de la referencia en el contenido por defecto.
**Lecciones**:
- Un lienzo "infinito" con InteractiveViewer se logra pintando el fondo en espacio de pantalla (superpuesto externo transformado por la matriz) en vez de dentro del hijo escalado; as� dejas `boundaryMargin` infinito y no necesit�s un SizedBox enorme ni l�mite.
- Para que los elementos aparezcan donde el usuario est� viendo hay que traducir el centro de la pantalla al espacio mundo con la inversa de la transformaci�n actual (`MatrixUtils.transformPoint(inverse, center)`), no usar coordenadas aleatorias.
- `_randPos()` depend�a de la traslaci�n actual + ruido; era la causa de que las notas aparecieran "en otro lado". El centrado por transform es m�s predecible.
**Impacto**: `lib/screens/pizarra/pizarra_screen.dart`
**Relacionado con**: D-4 (skill_visual � la grid/selecci�n siguen usando fondo=borde), historial pizarr�n etapa 1/2

## [2026-08-07] - BUGFIX - Crash de Firebase Messaging en Windows (MissingPluginException)
**Resumen**: Al abrir la app en desktop (Windows) tras el login, explotaba `MissingPluginException: No implementation found for method Messaging#getToken`. `NotificationService.initialize()` seteaba `_firebaseAvailable = true` (el singleton `FirebaseMessaging.instance` se crea sin tocar la plataforma) pero `firebase_messaging` no tiene plugin nativo en Windows ? `registerTokenAfterLogin()` llamaba `getToken()` y lanzaba.
**Cambios realizados**:
- `lib/services/notification_service.dart`: nuevo getter `_supportsMessaging` (`!kIsWeb && (Platform.isAndroid || Platform.isIOS)`). En `initialize()` solo se instancia `_fcm` si la plataforma lo soporta; en desktop queda `null`. `registerTokenAfterLogin()` chequea `_supportsMessaging` y envuelve `getToken()`/`onTokenRefresh` en try/catch. Import de `foundation` para `kIsWeb`; removido import innecesario de `material`.
- Recompilados exe + APKs split-per-abi.
**Lecciones**:
- `FirebaseMessaging.instance` no lanza en plataformas sin plugin: devuelve un objeto. El crash aparece reci�n en el primer `MethodChannel` (`getToken`, `requestPermission`, `onMessage`). Hay que gatear por plataforma, no por �xito del singleton.
- Windows/Linux/macOS desktop no tienen `firebase_messaging` nativo; guardar con `kIsWeb` + `Platform.isAndroid/iOS`.
**Impacto**: `lib/services/notification_service.dart`
**Relacionado con**: D-7 (FCM), build exe Windows.

## [2026-08-07] - FEATURE - Pizarr�n: comentarios+menciones (I), b�squeda (J) y tableros anidados (K)
**Resumen**: Etapa 2 de acercar el pizarr�n a Milanote. Se agregaron comentarios por elemento con respuestas y highlight de menciones @, b�squeda integrada que zoom y selecciona el elemento, y tableros anidados (canvas por sub-tablero, breadcrumb, crear sub-tablero, elemento carpeta navegable).
**Cambios realizados**:
- **I. Comentarios**: m�todos `_commentsOf`, `_openComments`, `_showCommentsSheet` (bottom sheet con lista + input, responder a un comentario con `replyTo`, highlight de `@menciones`), `_addComment`, `_deleteComment`, `_commentRow` y badge de contador en el elemento. Persisten en `data['comments']` v�a `updateDataLocal`.
- **J. B�squeda**: bot�n lupa en header ? panel `_searchPanel`, `_searchResults` filtra por `content` y `data['title']` (excluyendo conectores), `_goToElement` transpone el transform al centro del resultado y lo selecciona.
- **K. Tableros anidados**: tabla `boards` (id, name, parent_id, created_at) con id=1 ra�z "Pizarra" + RLS `full_access_boards`. Columna `board_elements.board_id BIGINT NOT NULL DEFAULT 1` + �ndice. `BoardElement` gana `boardId`. `BoardDataProvider` gana `_boardId`, `boardName`, `loadBoards`, `createBoard`, `setBoard`; `load()` filtra por `board_id`, el realtime ignora cambios de otros tableros, `add()` inyecta el tablero actual en el elemento. Pantalla: stack `_boardStack`, `_openBoard` (doble tap en elemento carpeta), `_goBackBoard`, `_createSubBoard` (dialog ? crea board + agrega elemento tipo `board`), breadcrumb con nombre del tablero, body tipo `board` (carpeta + nombre + chevron).
- `supabase_schema.sql` y `supabase/migration_board_milanote.sql` actualizados con `boards`, `board_id`, `full_access_boards`. **PENDIENTE ejecutar migraci�n en SQL Editor.**
- Tests: 2 nuevos en `board_element_test` (boardId default/serializaci�n + copyWith). Total 59 verdes. `flutter analyze` sin issues en los 4 archivos tocados.
**Lecciones**:
- `firstOrNull` viene de `package:collection`; evitarlo con b�squeda manual para no sumar dependencia.
- Al agregar RLS hay que habilitarlo (`ENABLE ROW LEVEL SECURITY`) + policy `FOR ALL USING (true)` y `GRANT` sobre la secuencia (`boards_id_seq`), igual que `board_elements`.
- Un `showModalBottomSheet` con `StatefulBuilder` anidado en varios `Padding`/`SizedBox` es fr�gil de cerrar; reescribirlo plano (bloques indentados) reduce errores de par�ntesis.
- Los tableros anidados necesitan que `add()` inyecte el `boardId` actual v�a `copyWith`, no que el modelo conozca el tablero.
**Impacto**: `lib/models/board_element.dart`, `lib/providers/board_data_provider.dart`, `lib/screens/pizarra/pizarra_screen.dart`, `supabase_schema.sql`, `supabase/migration_board_milanote.sql`, `test/models/board_element_test.dart`.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual � tipo board usa fondo=borde, redondo, sin sombras), historial etapa 1 del pizarr�n.

## [2026-08-07] - BUGFIX - Bot WhatsApp: enviarMensaje reintentaba y duplicaba la entrega 3x
**Resumen**: Tras re-vincular la sesi�n (fix LID), el bot ya entregaba pero cada mensaje llegaba 3 veces. Causa: `enviarMensaje` ten�a bucle de reintentos (hasta 3) pensado para el escenario LID roto donde no se confirmaba la entrega. Una vez que la sesi�n qued� sana, el ACK tarda >8s en una sesi�n restaurada de Supabase, as� que el timeout de 8s venc�a antes del ACK y el bot volv�a a mandar el mismo texto ? duplicado 3x.
**Cambios realizados**:
- `bot-furi/bot.js`: `enviarMensaje` ya NO reintenta. Con la sesi�n sana, reenviar el mismo mensaje duplica la entrega: WhatsApp ya lo recibi� aunque el ACK tarde. Ahora manda una vez, espera ACK con ventana generosa (20s), y cuenta como entregado si `sendMessage` resolvi� aunque no llegue ACK oportuno. Devuelve `false` solo si `sendMessage` lanza.
**Lecciones**:
- La verificaci�n con datos reales (insertar reto + correr el bot) revel� que "el mensaje no se confirma" ? "el mensaje no se entreg�". Cuando el destinatario recibe pero el ACK se pierde, reintentar solo duplica.
- El reintento como parche de disponibilidad (para LID roto) es contraproducente una vez que la causa ra�z (claves LID) se resuelve. Hay que quitar el reintento cuando la entrega ya funciona, o condicionarlo.
- El ACK en sesi�n restaurada de Supabase tarda m�s de 8s; usa una ventana de espera generosa (20s) para no mandar copias extra.
**Impacto**: `bot-furi/bot.js`
**Relacionado con**: D-10 (bot WhatsApp), fix sesi�n LID previo (mismo d�a)

## [2026-08-07] - BUGFIX - Bot WhatsApp: mensajes se quedaban "en cola" sin entregarse y se marcaban como notificados igual
**Resumen**: El bot "enviaba" mensajes que nadie recib�a. Investigaci�n end-to-end (inserci�n real de datos + ejecuci�n del bot + seguimiento de ACK de entrega) revel� dos problemas:
1. **Entrega no confirmada**: `sendMessage` de Baileys resuelve apenas escribe al socket, NO cuando WhatsApp entrega. El bot cerraba la conexi�n ~1s despu�s sin esperar el ACK, as� que en CI (sesi�n ef�mera restaurada de Supabase) el mensaje quedaba encolado y se perd�a.
2. **Marcado prematuro**: el bot marcaba el registro como "notificado" en `bot_notificaciones` ANTES de confirmar la entrega, por lo que nunca reintentaba � de ah� "el bot dice que las envi� pero no llegaron".
3. **Causa ra�z de la no-entrega**: la sesi�n guardada en Supabase est� desincronizada con los nuevos IDs de dispositivo vinculado (LID) de WhatsApp. La sesi�n tiene `me.lid` (`36130036682897:2@lid`) y claves de cifrado (`session-*.json`) solo para los n�meros normales, pero WhatsApp ahora enruta los contactos a `@lid` (ej. `83189842346022@lid`) para los que NO hay `session record` ? `SessionError: No session record` ? no se cifra ? no se entrega ? sin ACK. Las emociones s� llegaban porque matcheaban claves viejas; el resto (notas, metas, cartas, etc.) no.
**Cambios realizados**:
- `bot-furi/bot.js`: `enviarMensaje` ahora espera la confirmaci�n del servidor (`esperarAck` escuchando `messages.update` con status >= SERVER_ACK, timeout 8s) con hasta 2 reintentos, y devuelve `true` solo si se confirma.
- `bot-furi/bot.js`: `marcarNotificado` ahora acumula en memoria (`marksPendientes`) en vez de escribir en la BD. Se persiste solo tras env�o confirmado v�a `flushMarksPendientes(num)`. Si el env�o falla, el registro NO se marca y se reintenta en la pr�xima corrida (no se pierde).
**Lecciones**:
- `sendMessage` NO garantiza entrega: resuelve al escribir en el socket. Para CI ef�mero hay que esperar el ACK (`messages.update` status 1/2/3) y reintentar.
- Nunca marcar un registro como "notificado" antes de confirmar la entrega: causa p�rdida silenciosa e irreversible.
- WhatsApp migr� de enrutar por n�mero (`@s.whatsapp.net`) a IDs de dispositivo vinculado (`@lid`). Si la sesi�n guardada no tiene claves de cifrado para los `@lid` de los contactos, los mensajes se encolan pero jam�s se cifran/entregan. **Fix permanente**: re-vincular el n�mero del bot escaneando QR de nuevo (borrar `auth/` + re-escanear) para regenerar claves LID v�lidas, y luego subir la sesi�n nueva a Supabase.
**Impacto**: `bot-furi/bot.js`
**Pendiente**: re-vincular WhatsApp del bot (escaneo QR) para regenerar claves LID; sin eso, el c�digo mejora el comportamiento pero WhatsApp seguir� sin poder cifrar a los contactos migrados a LID.
**Relacionado con**: D-10 (bot WhatsApp), bot-whatsapp.md

## [2026-08-07] - FEATURE - Pizarr�n Milanote-style: selecci�n+resize, im�genes, links y conectores
**Resumen**: Primera etapa de acercar el pizarr�n a Milanote. Se extendi� el modelo de elementos para soportar capas (z), metadatos flexibles (data JSONB) y 3 tipos nuevos: imagen, link y conector. Se agreg� selecci�n con borde, 8 handles de resize, traer al frente, subida de im�genes a Supabase Storage, cards de link con favicon y l�neas/flechas que siguen a los elementos.
**Cambios realizados**:
- `lib/models/board_element.dart` (nuevo): modelo extra�do del provider. Campos nuevos `z` (int, capas) y `data` (Map JSONB). Tipos `image`, `link`, `connector`. `copyWith` ampliado (width/height/data/z), getter `center`. Test en `test/models/board_element_test.dart`.
- `lib/providers/board_data_provider.dart`: importa el modelo. Nuevos `resizeLocal`/`resize`, `bringToFront` (z=max+1 persistido), `updateDataLocal`/`_updateData`. `move`/`resize` con throttle unificado en `_flushPending` (moves + resizes). Realtime reescrito: maneja delete v�a `oldRecord['id']` y evita el null-check de `newRecord`. Getter `zOrdered`. Test en `test/providers/board_data_provider_test.dart`.
- `lib/services/board_media_service.dart` (nuevo): bucket privado `board-media`, `uploadImage` (XFile?File), `downloadImage` con cache en memoria, `deleteImage`.
- `supabase/migration_board_milanote.sql` (nuevo): `ALTER board_elements ADD z INTEGER`, `ADD data JSONB`, crea bucket `board-media` privado + policies. **PENDIENTE ejecutar en SQL Editor**. `supabase_schema.sql` actualizado.
- `lib/screens/pizarra/pizarra_screen.dart`: reescrito. Selecci�n con borde, 8 handles de resize (esquinas + bordes, m�nimo 40px), traer al frente, render de imagen (bytes con cache), card de link con favicon (google s2) y host, conectores dibujados en capa `CustomPaint` que se autoposicionan entre los centros de los elementos y siguen al moverlos (flecha, opcional punteada). Modo conector: elegir origen ? icono timeline ? elegir destino.
**Lecciones**:
- Un modelo `const` no puede inicializar `createdAt` con `DateTime.now()` en el initializer; hay que sacar el `const` del constructor o recibir el valor.
- La pantalla qued� dos veces "casi lista" con c�digo muerto y m�todos sin definir (`_deleteDot`, extensiones `moveElement` que no exist�an en el provider). Lecci�n: verificar cada s�mbolo referenciado contra el provider/API real antes de asumir que compila, y no encolar archivos con clases placeholder.
- Supabase Storage `.upload` espera `File` (dart:io), no `XFile` de image_picker; hay que convertir con `File(file.path)`.
- El callback de realtime: en eventos DELETE `newRecord` puede venir vac�o/no-null; usar `oldRecord['id']` para resolver el id borrado.
**Impacto**: 4 archivos nuevos/modificados en `lib/`, `supabase_schema.sql`, `supabase/migration_board_milanote.sql`, 2 archivos de test.
**Relacionado con**: D-2 (Supabase), D-4 (skill_visual), errores-conocidos (sin nuevos)
**Pendiente**: ejecutar `migration_board_milanote.sql` en prod; en la etapa 2 (B/D/G/H) quedan notas con formato rico, tareas/checkbox, tableros anidados, cursor de la pareja y menciones.

## [2026-08-06] - BUILD - Firma de release propia (keystore) para APK instalable en otro celular
**Resumen**: El APK release usaba la firma `debug` (el default de Flutter), lo que imped�a reinstalar sobre versiones previas y era marcada como no fiable por Realme. Se configur� un keystore de release propio y la firma autom�tica del build release.
**Cambios realizados**:
- Generado `android/app/upload-keystore.jks` (SHA256withRSA 2048, validez 10000 d�as, alias `upload`) v�a `keytool` de JDK en `D:\jdk17\jdk17`.
- Creado `android/key.properties` con storePassword/keyPassword/keyAlias/storeFile.
- `android/build.gradle.kts`: carga `key.properties`, agrega `signingConfigs { create("release") }` y lo usa como `signingConfig` del `buildTypes.release` (en vez de `debug`).
- `.gitignore`: excluye `android/key.properties` y `android/app/*.jks`/`*.keystore`.
- `documentacion/GUIA_INSTALACION_APK.md`: gu�a de instalaci�n para el Realme C11 (permiso apps desconocidas, desinstalar versi�n vieja). `docs/contexto/flujo-de-trabajo.md`: secci�n de firma de release.
- Compilado `app-release.apk` (63.5 MB) y verificado con `apksigner` que el certificado es `CN=Furi, ..., C=AR` (no el debug).
**Lecciones**:
- Flutter firma el release con `debug` por defecto; para entregar un APK re-instalable hay que definir un `signingConfig` de release con keystore propio. Sin `key.properties`, el release compila pero con firma vac�a ? Android no lo instala.
- Realme/Android piden permisos de "instalar apps desconocidas" por-app y no permiten reemplazar otra firma sin desinstalar. Son dos causas distintas a comunicarle a quien instala.
- El `jarsigner -verify` no reporta el CN en entradas de ZIP de v2 signing; usar `apksigner arbitrio --print-certs` del build-tools para confirmar.
**Impacto**: `android/app/upload-keystore.jks` (nuevo, no commiteado), `android/key.properties` (nuevo, no commiteado), `android/app/build.gradle.kts`, `.gitignore`, `documentacion/GUIA_INSTALACION_APK.md`, `docs/contexto/flujo-de-trabajo.md`
**Relacionado con**: flujo-de-trabajo (build APK), errores-conocidos (pantalla negra), instalaci�n en otro celular

## [2026-08-06] - FEATURE+BUGFIX - Bot segmentado por usuario, sync de clases viejo, errores y schema
**Resumen**: Sesi�n de cierre de pendientes: el bot de WhatsApp ahora enruta cada notificaci�n solo a la persona que NO la gener� (cada uno ve solo lo que agrega la otra), sincronizaci�n autom�tica de las clases existentes de SQLite que jam�s se subieron a Supabase, logging para catches silenciosos, y schema SQL maestro completo.
**Cambios realizados**:
1. **Bot segmentado por destinatario** (`bot-furi/bot.js`):
   - Nuevo `cargarUsuarios()` que mapea `profiles.id` ? identidad (facu/rocio).
   - Nuevo `destinosPara(usuarios, creatorId)`: si el creador del registro es Facu vai a ROCIO_NUMERO y viceversa; si no se identifica el creador, va a ambos (default).
   - `yaNotificado()` ahora filtra por `phone` adem�s de `(tabla, registro_id)` para permitir tracking por destinatario.
   - `verificarYNotificar()` acumula en `mensajesPorNum` (map phone ? textos) en vez de un array �nico, y env�a a cada destinatario solo su difusi�n.
   - Aniversarios seguien compartidos (van a ambos, son fechas de pareja).
   - Mapeo por columna de creador por tabla: schedules?`user_id`, class_schedules?`user_id`, moods?`user_id`, letters?`from_user`, challenges?`couple_id`, goals?`couple_id`, tasks?`created_by`, transactions/gallery/notes/timeline?`user_id`, custom_questions?`from_user`.
2. **Sync autom�tico de clases viejas**:
   - SQLite sube a versi�n 6 (`cloudId INTEGER` en `class_schedules`).
   - `ClassSchedule` gana `cloudId`.
   - `ClassScheduleProvider._syncUnsyncedToSupabase()` corre dentro de `loadSchedules()`: sube a Supabase toda clase con `cloudId == null` y guarda el id cloud devuelto.
   - `_pushToSupabase()` ahora usa `cloudId` como PK cloud para update/delete (antes usaba el id local de SQLite, que NO coincide con el BIGSERIAL de Supabase ? update/delete apuntaban a fila equivocada).
   - `addSchedule()` persiste `cloudId`; `deleteSchedule()` borra por id cloud.
3. **Errores silenciosos con logging** (`lib/`):
   - `catch (_) {}` reemplazados por `developer.log` con contexto en: `chat_provider.dart` (marks), `chat_media_service.dart` (delete cloud), `chat_screen.dart` (sendText/sendMedia), `home_screen.dart` (checkClassSetup), `calendar_home_screen.dart`, `metas_screen.dart`, `retos_screen.dart`.
   - Excepci�n: `sound_service.dart` y pizarra (parse de color) se dejan silenciosos (fallo intencional/no-Supabase).
4. **Schema master completo** (`supabase_schema.sql`):
   - Aclaraba `class_schedules` (tabla nueva) + �ndice `day_of_week`.
   - `gallery_comments` (tabla) + �ndice.
   - Columnas nuevas consolidadas en el CREATE: `gallery.description`, `gallery.reactions`, `goals.completed_by`, `letters.seen_by`, `challenges.seen_by`.
   - RLS + policies para `gallery_comments` y `class_schedules`.
   - Pendiente: ejecutar las migraciones en prod (class_schedules, gallery_comments, seen_by, etc.) para DBs ya existentes.
**Lecciones**:
- El problema del sync de clases era doble: (a) las clases viejas se quedaron solo en SQLite porque el sync se agreg� despu�s; (b) el update/delete en c�digo usaba `eq('id', idLocalDeSQLite)` pero Supabase asigna su propio BIGSERIAL ? update/delete apuntaban a filas que no existen (o a otras). La soluci�n correcta es guardar expl�citamente el `cloudId` devuelto por el insert y usarlo como PK cloud.
- Para enrutar notificaciones por usuario, el bot necesit� conocer el mapeo `user_id` (UUID) ? identidad, que vive en `profiles`. No basta comparar strings de identidad (algunas tablas guardan `profile.id`, otras guardan `text`).
- La tabla `bot_notificaciones` no estaba dise�ada para enviar distinto a cada destinatario: hab�a que agregar el filtro por `phone` en el `yaNotificado`, de lo contrario la primera verificaci�n marcaria el key y bloquear�a el env�o al segundo destino.
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
- `bot-furi/bot.js`: nueva categoria #14 `CLASS_SCHEDULES`. Consulta `class_schedules`, filtra las de hoy (`day_of_week === hoy`), y avisa las que empiecen en las proximas 2h con `?? *Clase: titulo*` + horario (inicio o inicio-fin) + "En X minutos". Tracking key `class-{id}-{date}-{start_time}`.
- `docs/contexto/bot-whatsapp.md`: tabla ahora lista 14 categorias (arreglado: antes decia 14 pero el titulo era "12"). `docs/contexto/glosario.md`: `class_schedules` ahora SQLite + Supabase.
**Lecciones**:
- No hay RPC `pg_sql` disponible en el proyecto; para DDL hay que ejecutar la migracion en el SQL Editor de Supabase (manual, como las demas).
- La conversel de dia es trampa: Dart `DateTime.weekday` es 1=lunes..7=domingo, pero JS `Date.getDay()` es 0=domingo..6=sabado. Hay que convertir `jsDia === 0 ? 7 : jsDia` antes de comparar con `day_of_week`.
- El bot avisa clases a TODOS los destinatarios (no separa por `user_id`); el `user_id` de la clase se usa para saber de quien es, pero el aviso se manda a FACU y ROCIO por igual (la app es de pareja compartida).
**Impacto**: `supabase/migration_class_schedules.sql`, `lib/models/class_schedule.dart`, `lib/providers/class_schedule_provider.dart`, `bot-furi/bot.js`, docs.
**Relacionado con**: D-3 (SQLite), D-10 (bot), bot-whatsapp.md

## [2026-08-06] - FEATURE - Bot WhatsApp: categoria #13 de preguntas del boton ?
**Resumen**: El bot no avisaba cuando alguien creaba/respondia una pregunta en la seccion "Nosotros" (boton ?). La causa: esa pantalla guarda las preguntas en la tabla `custom_questions` (no en `daily_questions`/`question_answers`, que estaban vacias), y el bot no tenia categoria para esa tabla. El usuario creo carta, reto, pregunta y favorito, corrio el bot manualmente en GitHub Actions y no le llego nada por WhatsApp.
**Cambios realizados**:
- `bot-furi/bot.js`: nueva categoria #13 `CUSTOM_QUESTIONS`. Consulta `custom_questions` de la ultima hora, une `from_user:profiles!from_user(name)`, y avisa con `? *<nombre>* te hizo una pregunta nueva` (si `answer` es null) o `? *<nombre>* respondio una pregunta` (si tiene `answer`/`answered_at`). Tracking key `question-{id}`, tabla `custom_questions` en `bot_notificaciones`.
- `docs/contexto/bot-whatsapp.md`: tabla de categorias ahora lista 13 (custom_questions) y flujo "Itera las 13 categorias".
- Verificado end-to-end de forma real: el envio de WhatsApp funciona (test directo a FACU y ROCIO), el bot detecto y registro 3 preguntas en `bot_notificaciones` (incluidas `question-17` y `question-18` que el usuario habia creado y nunca se habian avisado), y envio el WhatsApp. Se inserto y luego elimino una pregunta de prueba (id 19) y su notificacion para no polucionar datos.
**Lecciones**:
- El bot funciona (detecta y envia). El problema era de cobertura de tablas: una funcionalidad de la app (preguntas de Nosotros) escribia en `custom_questions`, que no estaba en lista del bot. Ante "el bot no avisa", lo primero es mapear en que tabla escribe cada pantalla y comparar contra las categorias del bot.
- El envio a WhatsApp se confirmo de forma aislada (script `_test_send.mjs` con `sock.sendMessage` OK a ambos numeros), separando "deteccion" de "envio". El bot envia DESDE el numero del bot (`MI_NUMERO`), no desde el usuario.
- Nota: el cliente `@supabase/supabase-js` de Node 20 necesita `realtime: { transport: WebSocket }` o falla con "Node.js 20 detected without native WebSocket support"; para scripts de diagnostico sin realtime se puede usar REST fetch directo.
**Impacto**: `bot-furi/bot.js`, `docs/contexto/bot-whatsapp.md`, `docs/contexto/historial.md`
**Relacionado con**: D-10 (bot WhatsApp), bot-whatsapp.md

## [2026-08-06] - FEATURE - Ticks de chat en 3 estados (enviado/entregado/le�do)
**Resumen**: El chat ahora distingue 1 palomita (enviado), 2 palomitas (entregado) y 2 palomitas azules (le�do), tipo WhatsApp. Antes solo hab�a enviado (?) y le�do (??).
**Cambios realizados**:
- `lib/models/message.dart`: nuevo enum `MessageTick { sent, delivered, read }` y getter `tickState` que prioriza `readAt` > `deliveredAt` > `sent`. El modelo ya ten�a `deliveredAt`/`readAt`.
- `lib/providers/chat_provider.dart`: nuevo `markIncomingDelivered()` que escribe `delivered_at` en los mensajes recibidos por realtime sin marcarlos como le�dos. El callback de realtime insert ahora llama a `markIncomingDelivered()` en vez de `markIncomingRead()`. `markIncomingRead()` se mantiene para cuando se abre el chat (escribe `read` + `read_at`).
- `lib/screens/chat_screen.dart`: el tick renderiza seg�n `message.tickState` � sent ? `Icons.done`, delivered ? `Icons.done_all`, read ? `Icons.done_all` en azul `#4FC3FF`.
- `test/models/message_test.dart`: 3 tests nuevos para `tickState`. Total 45 tests verdes, analyze sin errores.
**Lecciones**:
- "Entregado" en una arquitectura servidor-local sin push de entrega confiado se define como "el dispositivo de la pareja recibi� el mensaje por realtime sin abrirlo". "Le�do" = abrir el chat. No hay confirmaci�n de servidor de "entregado" como en WhatsApp; es una aproximaci�n.
- El `copyWith` del modelo ya soportaba `deliveredAt`/`readAt`, solo faltaba propagarlos y renderizarlos.
- Separar el mark de realtime (entregado) del de apertura (le�do) evita que el mensaje salte directo a azul antes de que la pareja abra el chat.
**Impacto**: `lib/models/message.dart`, `lib/providers/chat_provider.dart`, `lib/screens/chat_screen.dart`, `test/models/message_test.dart`
**Relacionado con**: feature chat media/reacciones previo, errores-conocidos (ticks de chat)

## [2026-08-06] - BUGFIX - Pizarr�n abr�a en la esquina, ahora aparece centrada
**Resumen**: Al abrir la pizarra, el lienzo quedaba en la esquina superior izquierda (posici�n identidad). Ahora se centra autom�ticamente al primer frame.
**Cambios realizados**:
- `lib/screens/pizarra/pizarra_screen.dart`: `initState` agrega `WidgetsBinding.instance.addPostFrameCallback((_) => _goToCenter())` para centrar la transformaci�n tras el primer frame, reusando `_goToCenter()` existente (`translate(-500, -400)`).
**Lecciones**:
- `TransformationController` arranca en identidad; para mostrar un lienzo infinito centrado hay que setear la transformaci�n despu�s del primer frame con `addPostFrameCallback`.
**Impacto**: `lib/screens/pizarra/pizarra_screen.dart`
**Relacionado con**: D-4 (skill_visual � sin cambio de estilo)

## [2026-08-06] - BUGFIX - Chat: barra de escribir saltaba arriba con el teclado
**Resumen**: Al tocar el campo de escribir aparec�a el teclado y la barra de input se iba super arriba. Causa: doble-conteo de insets. `Scaffold` ten�a `resizeToAvoidBottomInset: true` (default), as� que el body ya se encog�a con el teclado; adem�s `_inputArea` y `_replyBanner` sumaban `MediaQuery.of(context).viewInsets.bottom`, volviendo a reservar el alto del teclado ? el input flotaba ~`keyboard` px por arriba.
**Cambios realizados**:
- `lib/screens/chat_screen.dart`: `Scaffold` ahora con `resizeToAvoidBottomInset: false` (el layout se posiciona manualmente).
- `_msgArea` dej� de usar `height: areaH = h * 0.76` fija y ahora usa `bottom: keyboard + 8 + h * 0.09 + 4`, as� la lista se acorta contra el input cuando el teclado aparece (la �ltima l�nea queda visible sobre la barra).
- `_inputArea`/`_replyBanner` ya usaban `viewInsets` � ahora sin doble-conteo son correctos.
- Tests 42 verdes, `flutter analyze` sin issues.
**Lecciones**:
- Con `resizeToAvoidBottomInset: true` (default) el Scaffold ya completa el teclado; sumar `viewInsets.bottom` en los `Positioned` del Stack produce doble reserva. Hay que elegir un solo mecanismo: o dejar que el Scaffold encoga el body y NO usar `viewInsets`, o poner `resizeToAvoidBottomInset: false` y posicionar con `viewInsets` expl�cito.
- Un `Positioned` en un `Stack` con `bottom: keyboard + X` es la forma de subir el input con el teclado cuando el body no se encoge.
**Impacto**: `lib/screens/chat_screen.dart`
**Relacionado con**: D-4 (skill_visual � sin cambio de estilo, solo layout), errores-conocidos (sin nuevo)

## [2026-08-06] - BUGFIX - Migraci�n favorites: columna subtitle inexistente
**Resumen**: La migraci�n `migration_favorites_dual_rating.sql` fallaba con `ERROR 42703: column "subtitle" does not exist`. En la BD la columna legacy era `title` (no `subtitle`). PostgreSQL compila el `UPDATE ... SET critica = subtitle` al vuelo y falla aunque despu�s haya un `DROP COLUMN IF EXISTS`, porque el parseo del statement __ completo antes de ejecutarse.
**Cambios realizados**:
- `supabase/migration_favorites_dual_rating.sql`: reescrita con bloque `DO $$ ... $$` PL/pgSQL que consulta `information_schema.columns` para saber si `subtitle`/`rating` existen antes de referenciarlas, usando `EXECUTE` din�mico solo cuando la columna est� presente.
- Sigue siendo idempotente: `ADD COLUMN IF NOT EXISTS` + chequeos condicionales.
**Lecciones**:
- PostgreSQL valida la existencia de columnas al compilar el statement completo, NO l�nea por l�nea. Un `UPDATE` que referencia una columna inexistente falla con 42703 en runtime aunque venga un `DROP COLUMN` despu�s.
- Para migraciones que tocan columnas legacy opcionales, hay que chequear `information_schema.columns` dentro de un bloque `DO` y usar `EXECUTE` con SQL din�mico.
**Impacto**: `supabase/migration_favorites_dual_rating.sql`
**Relacionado con**: D-2 (Supabase), errores-conocidos (migraci�n favorites)

## [2026-08-06] - BUGFIX - Bot WhatsApp fallaba en GitHub Actions (validaci�n de sesi�n rota)
**Resumen**: El bot en GitHub Actions dej� de funcionar: timeout de 60s porque nunca lograba restaurar la sesi�n. La causa era una validaci�n JS rota y un fix previo que la agrav�.
**Cambios realizados**:
- `bot-furi/bot.js`: la validaci�n de sesi�n ahora lee el contenido de `creds.json` (`me.id`) y compara con `MI_NUMERO`, usando **�ndice `[0]`** en vez de `.first`.
  - Primera reescritura us� `creds.json.me.id` pero con `.first` (propiedad inexistente en arrays de JS ? `undefined`) ? la validaci�n fallaba siempre.
  - El n�mero en `me.id` viene con sufijo de dispositivo: `5493786499129:1@s.whatsapp.net`. Se quita `@s.whatsapp.net` y se toma `split(':')[0]` para aislar el n�mero puro `5493786499129`.
- Diagn�stico: `bot_sessions.session_data` en Supabase confirm� que `creds.json.me.id` = `5493786499129:1@s.whatsapp.net` y `MI_NUMERO` = `5493786499129` (coincid�an).
- Local: build-show del bot conecta, verifica 12 categor�as y termina limpio. Los errores "failed to decrypt message" en log son inofensivos (mensajes de estado).
**Lecciones**:
- Los arrays de JS NO tienen `.first` (propiedad de Dart). En JS hay que usar `[0]`. El `node --check` no lo detecta (es error en runtime).
- En CI no existe la carpeta `auth/` local (est� en .gitignore): si la validaci�n contra Supabase falla, el bot pide QR y muere por timeout. La restauraci�n de sesi�n desde Supabase es cr�tica para CI.
- La vieja validaci�n chequaba el n�mero en los NOMBRES de archivo; la correcta es leer `creds.json.me.id`.
**Impacto**: `bot-furi/bot.js`, `docs/contexto/bot-whatsapp.md`
**Relacionado con**: D-10 (bot WhatsApp), errores-conocidos (sesi�n no coincide)

## [2026-08-06] - FEATURE - Reacciones, galer�a social, ticks de chat, quien valida metas y "visto" tipo WhatsApp
**Resumen**: Implementadas 8 mejoras de interacci�n de pareja. Se agreg� la reacci�n `:0`, descripci�n+reacciones+comentarios por foto en galer�a, correcci�n del sistema de ticks de chat (faltaban columnas `delivered_at`/`read_at`), indicaci�n de qui�n complet� cada meta, y sistema de "visto" en Supabase para retos/cartas que solo swapean no-cumplidos y no-le�das. Tambi�n se corrigi� el contraste del popup de finanzas y el bot�n OK de edici�n en el pizarr�n.
**Cambios realizados**:
- `lib/models/message.dart`: agregado `:0` a `defaultReactionEmojis` (ahora 6).
- `test/models/message_test.dart`: test actualizado a 6 reacciones.
- `lib/screens/finanzas/finanzas_screen.dart`: bot�n `INGRESO` del popup usa `_cIncome` (verde oscuro) en vez de `_c` (= fondo del dialog, invisible). Texto de bot�n activo en blanco para contraste.
- `lib/screens/pizarra/pizarra_screen.dart`: `_buildElement` recibe `id` consistente con el mapa de edici�n (antes el nuevo elemento sin ID usaba 0 y el OK fallaba); `_finishEditing` resuelve el elemento por `id` o `createdAt` y llama `updateContentLocal`. Notas ahora cumplen skill_visual: fondo s�lido, borde = fondo, sin boxShadow, texto oscuro `#111111`, bot�n de confirmaci�n como icono `Icons.check` (no texto "OK").
- `lib/providers/board_data_provider.dart`: nuevo `updateContentLocal(BoardElement el, String content)` para persistir/actualizar contenido en elementos reci�n creados (sin ID de BD a�n); si tiene ID delega a `updateContent()`.
- `lib/providers/gallery_provider.dart`: `GalleryItem` con `description` y `reactions` (JSONB, mismo formato que messages); nuevo modelo `GalleryComment`; provider con `comments`, `updateDescription`, `toggleReaction`, `addComment`, `deleteComment`, `loadComments`.
- `lib/screens/galeria/galeria_screen.dart`: pantalla full-screen redise�ada con panel de detalle (descripci�n editable con dialog, reacciones al texto con tap, lista de comentarios con input y borrado). Se cargan comentarios al abrir la foto.
- `lib/screens/metas_screen.dart`: `_toggle` guarda `completed_by: AppState.myId` al completar (y null al desmarcar); la card muestra una insignia F/R de qui�n complet� la meta.
- `lib/screens/nosotros_screen.dart`: `_loadPartnerLetter` solo presenta cartas no le�das por `myId` y las marca como vistas v�a `seen_by`; `_partnerRetos` filtra solo no-cumplidos; `_markSeen` (agrega `myId` al array JSONB `seen_by`). `_buildCartasIcon` usa `seen_by` en vez de `is_opened`.
- `lib/providers/chat_provider.dart`: `markIncomingRead` ya escribe `delivered_at`/`read_at` (ver migraci�n).
- Migraciones SQL nuevas en `supabase/`: `migration_gallery_comments.sql`, `migration_goals_completed_by.sql`, `migration_seen_system.sql`; ampliada `migration_chat_media_reactions.sql` con `delivered_at` y `read_at` (TIMESTAMPTZ).
- `bot-furi/bot.js`: validaci�n de sesi�n reescrita � en vez chequear el n�mero en los nombres de archivo, se lee el contenido de `creds.json` (`me.id` ? `<pais><numero>:<dev>@s.whatsapp.net`) y se compara con `MI_NUMERO`.
- Tests 42 verdes, `flutter analyze` 0 errores.
**Lecciones**:
- Los ticks de "visto" del chat depend�an de columnas que el modelo insertaba pero la BD no ten�a (`delivered_at`/`read_at`): el update fallaba con PGRST204 y se tragaba con `catch (_) {}` ? nunca sal�a el doble visto. Cualquier columna referenciada en `toMap`/update debe existir en la BD cloud.
- El "visto" entre personas debe vivir en Supabase (columna `seen_by` JSONB con array de user_id) para que la otra identidad sepa que ya fue le�do; `letters.is_opened` ya no alcanza para diferenciar qui�n lo ley�.
- En un provider optimista, editar un elemento "reci�n creado" sin ID de BD requiere actualizar por referencia de objeto (`identical`/atributos �nicos), no por `eq('id')`.
- La validaci�n de sesi�n por nombre de archivo es fr�gil; la correcta es leer `creds.me.id`.
**Impacto**: 8 archivos en `lib/`, 4 migraciones SQL, `bot-furi/bot.js`, test.
**Relacionado con**: D-2 (Supabase), D-3 (SQLite), D-4 (skill_visual), errores-conocidos (ticks de chat resuelto)

---

## [2026-08-06] - BUGFIX - APK muestra pantalla negra en Android (sqflite FFI de desktop en m�vil)
**Resumen**: Los APK compilados abr�an pero quedaban en pantalla negra en el celular (mirado con ADB: proceso vivo pero sin frames). El `main.dart` forzaba `sqfliteFfiInit()` + `databaseFactoryFfiNoIsolate` en TODAS las plataformas. Estas llamadas son para desktop (cargan libsqlite3 por FFI); en Android esa librer�a la provee `sqlite3_flutter_libs`, que NO estaba en pubspec.yaml, por lo que `sqfliteFfiInit()`/`DatabaseHelper().database` lanzaban una excepci�n antes de `runApp` ? pantalla negra silenciosa. Adem�s, el APK instalado se hab�a compilado con el `main.dart` viejo (commit `61ca588`, sin el manejo de errores con pantalla roja, agregado despu�s a las 21:04) ? el error no era visible.
**Cambios realizados**:
- `lib/main.dart`: el bloque `sqfliteFfiInit()`/`databaseFactoryFfiNoIsolate` ahora se ejecuta solo si `isDesktop` (`!kIsWeb && (windows || linux || macOS)`). En Android/iOS se deja el factory nativo de `sqflite` (default del plugin) sin override.
- Compilado APK release (63.4 MB, 74s), instalado via `adb install -r` en Xiaomi Redmi Note 10 (`vgbqzhbux8amkn5x`).
- Verificaci�n: `adb logcat` sin errores `FATAL`/`sqlite`, proceso comp.furiapp.furi_app vivo, `BufferQueueProducer` reporta renderizado a ~60 fps, screencap con p�xeles de color (pantalla ya no est� negra).
- Tests 42 verdes, `flutter analyze` 0 errores (29 infos preexistentes).
**Lecciones**:
- `sqflite_common_ffi` es SOLO desktop (`sqlite3_flutter_libs` no viaja en Android iOS). Forzarlo en m�vil rompe la app ANTES de `runApp` con pantalla negra, sin log si no se usa `runZonedGuarded`.
- Cuando un APK falla "en negro", el proceso puede estar vivo pero no renderizando; `BufferQueueProducer queueBuffer fps` en logcat y un screencap con an�lisis de p�xeles confirman si dibuja.
- El manejo de errores de `main()` (pantalla roja con mensaje) es condici�n para diagnosticar estos casos; el APK compilado a las 20:04 NO lo ten�a (se agreg� a las 21:04), por eso el bug se vio como pantalla negra en lugar de pantalla roja con el error.
- El an�lisis de p�xeles con System.Drawing (firmar samples de color) permite detectar "pantalla negra" sin ver la imagen (el modelo no puede leer im�genes, pero la app puede probar con ADB).
- Conveniencia: `pwsh` no est� en PATH en esta m�quina; correr `.\scripts\build-apk.ps1` directo desde la shell.
**Impacto**: `lib/main.dart`
**Relacionado con**: D-3 (SQLite local), errores-conocidos (pantalla negra APK resuelto), flujo-de-trabajo (build APK + adb install)

---

## [2026-08-05] - BUGFIX - Pizarra: nota nueva no se mueve hasta reabrir
**Resumen**: Al agregar una nota/foto/postit en la pizarra, no se podia arrastrar hasta salir y reabrir la pantalla. Era porque el `onPanUpdate` hacia `if (el.id != null) move(...)` y el ID llegaba recien cuando Supabase respondia el insert (delay de red). Mientras tanto, el movimiento se descartaba silenciosamente.
**Cambios realizados**:
- `board_data_provider.dart`: nuevo `moveLocal(BoardElement el, double x, double y)`. Si el elemento tiene ID, delega a `move()` (persiste, con throttle 300ms). Si no tiene ID (reci�n creado, esperando respuesta de BD), solo actualiza la copia local con `copyWith` + `notifyListeners()`. Identifica el elemento por `identical(e, el)` (referencia de objeto, no por ID).
- `pizarra_screen.dart`: `onPanUpdate` ahora llama `moveLocal(el, ...)` sin chequear `el.id`. El elemento arranca moviendose inmediatamente, sin esperar al ID de la BD.
- Tests 42 verdes, analyze 0 errores. Recompilados Windows + APK.
**Lecciones**:
- En apps optimistas (insert local primero, despues Supabase), el ID llega asincronamente. Hay que soportar drag/edicion sobre elementos "sin ID todavia" via referencias de objeto, no asumir que todo elemento trackeable ya tiene ID.
- `BoardDataProvider.move()` exige ID (usa `eq('id', id)` en la query Supabase). No se puede llamar con `id == null`. El `if (id == 0) return` es otra salvaguarda (ID provisional cuando fallback a timestamp). Encontrar el elemento por `identical()` es mas seguro que comparar por ID cuando puede ser null.
- El throttle de 300ms en `move()` no cumple para `moveLocal()` sin ID: los moves solo locales no persisten, no hay throttle. Cuando llega el ID desde la BD (realtime o `load()`), la copia local con x/y actualizada se reemplaza por la de la BD si la BD tiene la posicion vieja. Hay un edge case muy sutil: si moves una nota nueva antes de que el ID llegue y luego el realtime trae la posicion vieja, pisas el move optimista. Por ahora aceptamos esa race; en el futuro se podria mergear???? el pending move para reaplicar tras el realtime.
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
- Compartir un `Column` entre un banner y un input hace que se vean como un solo bloque del mismo color ? el usuario no distingue donde tapar para escribir. Separar en `Positioned` distintos con gap visual resuelve ambiguedad.
- `AnimationController.reverse()` con un listener que actualiza el estado es la forma idomatica de animar snap-back en swipe gestures. Setear `_ctrl.value = from/_max` antes de `reverse()` hace que arranque desde la posicion actual del drag (no de 0).
- `onHorizontalDragCancel` se llama cuando el gesture recognizer pierde el gesto (e.g. otra gesture gana). Implementarlo con `_snapBack()` (no reseteo brusco) mantiene consistencia visual.
**Impacto**: `lib/screens/chat_screen.dart` (build + `_inputArea` + `_replyBanner` nuevo + `_SwipeToReply`)
**Relacionado con**: D-4 (skill_visual � sin cambios, mismo naranja/bordes), errores-conocidos (sin nuevos errores)

---

## [2026-08-05] - BUILD - Fix compileSdk + scripts de build para Windows y APK
**Resumen**: El APK release dejo de compilar tras agregar el feature chat media (deps nuevas: file_picker, video_player, record, open_filex, permission_handler). Se agrego un override de compileSdk 36 en subprojects y se crearon scripts de build para un solo comando. Daemon de Gradle deshabilitado para evitar hang en builds largos.
**Cambios realizados**:
- `android/build.gradle.kts`: nuevo bloque `subprojects { afterEvaluate { ... compileSdkVersion = "android-36" } }` que overridea el compileSdk de plugins legacy (file_picker 8.3.7 trae 34 hardcodeado, flutter_plugin_android_lifecycle exige >=36). Combinado con `evaluationDependsOn(":app")` en el mismo bloque para que el hook se registre antes de la evaluacion.
- `android/gradle.properties`: agregado `org.gradle.daemon=false` y bajado heap a `-Xmx6G -XX:MaxMetaspaceSize=2G`. Antes heap era 8G y daemon se colgaba en builds largos (timeout de Gradle daemon despues de ~13min).
- Nuevo `scripts/build-windows.ps1`: corre `flutter build windows --release`, verifica Flutter en PATH, reporta exe final y tama�o.
- Nuevo `scripts/build-apk.ps1`: corre `flutter build apk --release`, verifica Flutter y JAVA_HOME, reporta apk final y tama�o. No necesita `$env:GRADLE_OPTS` porque daemon=false ya esta en gradle.properties.
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
**Resumen**: Chat reescrito con swipe-to-reply funcional en cualquier mensaje, reacciones por long-press (?????? :v xD + custom, max 5), envio de imagen/video/audio/gif/archivo via Supabase Storage, y borrado del cloud al descargar (queda solo local en el dispositivo).
**Cambios realizados**:
- Bugfix swipe: usaba `d.delta.dx` (frame a frame ~1-5px) en vez de acumular offset; ademas solo permitia swipe en mensajes ajenos. Nuevo `_SwipeToReply` acumula drag, umbral 42px, icono reply detras, funciona en todos los mensajes.
- Modelo `Message` tipado completo: `replyToId` ahora `int?`, reacciones con `toggleReaction` (1 reaccion por usuario, max 5 keys), campos media (`attachmentName/Mime/Size`, `cloudDeleted`, `localPath`), helpers `previewText`/`needsCloudDownload`/`isMedia`.
- Nuevo `ChatProvider`: carga, realtime, send text/media, reacciones, mark read, download+delete cloud.
- Nuevo `ChatMediaService`: upload bucket `chat-media`, download a app docs, bind path local SQLite, delete storage.
- SQLite v5: tabla `chat_media_local` (message_id ? local_path) para persistir media en dispositivo.
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
- Screen `favoritos_screen.dart`: reescrito completo. Paleta nueva: `_bg #0A0A0A` (no puro negro), `_panel #1A0830` violeta oscuro, `_vc #9D00FF` primario, `_light #D4A8FF` lila, `_fav #FFD700` dorado para guardados, `_facuT` naranja, `_rocioT` rosa (iniciales F/R). Todos los elementos con `BoxDecoration` cumplen fondo=borde mismo color. Botones del modal reemplazados por iconos (`Icons.close`, `Icons.check`, `Icons.add`, etc.) � se elimino el texto decorativo "X" "OK" "+". Toggle "favorited" ahora usa `Icons.bookmark`/`bookmark_border` (consistente con bloque "GUARDADOS") en dorado.
- UI de card: muestra dos mini filas de rating (F + R con estrellas cada una), promedio si ambos calificaron, critica en preview de 1 linea.
- Nuevo modal de detalle al tap en la card: muestra critica editable multilinea, editores de rating para F y para R (cualquiera puede calificar), promedio, y botones para toggle favorited / eliminar / guardar.
- Modal de alta/edicion ahora incluye `Wrap` selector de categoria (permite cambiarla al editar). Botones de accion cerrados con icono en contenedor brutalist.
- Confirmacion de eliminacion via dialog con iconos `Icons.close`/`Icons.delete_outline`.
- Banner de error rojo (`_errorBanner`) muestra `pv.error` con boton cerrar; antes no habia feedback visual de errores.
- `initState` migrado de `Future.microtask` a `WidgetsBinding.instance.addPostFrameCallback` con guard `mounted` (silencia warning `use_build_context_synchronously`).
- Tests TDD: `test/models/favorite_item_test.dart` (10 tests) cubren serializacion, migracion legacy, copyWith por usuario, averageRating, ratingFor, hasRating. `test/providers/favorites_provider_test.dart` (7 tests) cubren byCategory, categories, wishlistCount, allFavorited, averageRatingFor. Total 17 tests nuevos, todos verdes.
**Lecciones**:
- La regla NO-NEGOCIABLE "fondo=borde mismo color" + "prohibido negro puro" obliga a usar tonos del mismo color base (violeta oscuro/claro) en vez de negro para los tiles � el contraste surge de tonos claros vs oscuros, no de bordes distintos.
- TDD encontro un bug real sutil: el `toMap()` que pisaba el `userId` en `update()`. El test que parecia solo de serializacion revelo el problema de preservacion de autoria.
- Para testear providers que dependen de Supabase, lo practico es exponer un setter `@visibleForTesting` y testear solo la logica sincrona pura (getters filtros/avg), sin mockear el cliente.
- `addPostFrameCallback` es mas idomatico que `Future.microtask` para lecturas de Provider en `initState` y silencia el linter de async gaps.
**Impacto**: `lib/providers/favorites_provider.dart`, `lib/screens/favoritos/favoritos_screen.dart`, `supabase_schema.sql`, `supabase/migration_favorites_dual_rating.sql` (nuevo), `test/models/favorite_item_test.dart` (nuevo), `test/providers/favorites_provider_test.dart` (nuevo)
**Relacionado con**: D-4 (estilo brutalista), nueva decision D-11 (rating dual por usuario), skill_visual.md (cumplimiento), errores-conocidos.md (negro puro remediado en esta screen)

---

## [2026-08-05] - FEATURE - Clases recurrentes por semana en vez de fechas fijas
**Resumen**: Las clases configuradas en el wizard ahora se guardan como horarios recurrentes por d�a de la semana y aparecen en todas las semanas del calendario
**Cambios realizados**:
- Texto del wizard cambiado de `Cuantas materias tienes esta semana?` a `Cuantas clases tienes a la semana?`
- `ClassSchedule` extendido con `endTime`, `professor`, `userId` y `color` para soportar toda la info del wizard
- `DatabaseHelper` migrado a v4: tabla `class_schedules` ahora tiene las columnas nuevas
- `ClassSetupWizard` guarda en `ClassScheduleProvider` (tabla `class_schedules`) en lugar de crear `Schedule` con fechas fijas de la semana actual
- `CalendarHomeScreen` carga `ClassScheduleProvider` y genera eventos "sint�ticos" de tipo `Clase` para cada d�a de la semana, mostr�ndolos en cualquier semana del calendario
- `home_screen._checkClassSetup()` ahora verifica la tabla local `class_schedules` en vez de consultar Supabase, y recarga `ClassScheduleProvider` tras cerrar el wizard
- Agregado test `test/models/class_schedule_test.dart` para validar serializaci�n y valores por defecto
**Lecciones**:
- El sistema anterior ten�a dos modelos desconectados: `Schedule` (fecha fija) y `ClassSchedule` (recurrente). El wizard usaba el primero, lo que hac�a que las clases desaparecieran al cambiar de semana
- Es m�s limpio que el wizard use directamente el modelo recurrente (`ClassSchedule`) y que el calendario "proyecte" esos horarios en cada semana
- `ClassSchedule` no se sincroniza con Supabase por ahora: vive solo en SQLite local
**Impacto**: `lib/models/class_schedule.dart`, `lib/database/database_helper.dart`, `lib/screens/calendar/class_setup_wizard.dart`, `lib/screens/calendar/calendar_home_screen.dart`, `lib/screens/home_screen.dart`, `test/models/class_schedule_test.dart`
**Relacionado con**: D-3 (SQLite local), D-4 (estilo brutalista � sin cambios visuales, solo texto), `skill_visual.md`

---

## [2026-08-05] - BUGFIX - ClassSetupWizard reaparec�a siempre al iniciar la app
**Resumen**: El wizard de configuraci�n de clases aparec�a cada vez que se abr�a HomeScreen, incluso despu�s de completarlo
**Cambios realizados**:
- `ScheduleProvider.addSchedule()` ahora sube schedules a Supabase adem�s de SQLite local
- Antes: solo guardaba en SQLite local, pero `_checkClassSetup()` consultaba Supabase ? nunca encontraba clases ? wizard siempre aparec�a
- El `date` se trunca a `YYYY-MM-DD` para coincidir con el formato esperado por Supabase
**Lecciones**:
- La persistencia dual (SQLite + Supabase) requiere sincronizaci�n bidireccional expl�cita
- Los schedules de tipo `'Clase'` nunca eran sincronizados por `SyncProvider` (solo manejaba `Fecha especial` y `Examen`)
**Impacto**: `lib/providers/schedule_provider.dart`
**Relacionado con**: D-3 (SQLite local), D-9 (SyncProvider)

---

## [2026-08-05] - FEATURE - Bot de WhatsApp para notificaciones proactivas
**Resumen**: Creaci�n de bot que notifica por WhatsApp sobre actividad en todas las secciones de la app
**Cambios realizados**:
- Creado `bot-furi/` con Node.js + Baileys + Supabase
- Creadas tablas `bot_sessions` (persistencia sesion WhatsApp) y `bot_notificaciones` (tracking anti-duplicados)
- Bot notifica 12 categor�as: schedules, anniversaries, moods, letters, challenges, goals, tasks, transactions, favorites, notes, gallery, timeline_events
- GitHub Actions workflow corre cada 30 min (`.github/workflows/bot-whatsapp.yml`)
- Sesion WhatsApp persiste en Supabase para sobrevivir entre ejecuciones CI
- Inicializado repositorio git y pusheado a GitHub
- **No notifica mensajes del chat** (ya tienen push via FCM)
**Lecciones**:
- Baileys v6+ es ESM-only, requiere `"type": "module"` en package.json
- Supabase Realtime en Node.js 20 requiere paquete `ws` como transport
- La sesi�n WhatsApp se guarda/restaura desde Supabase para CI ef�mero
**Impacto**: `bot-furi/`, `.github/workflows/bot-whatsapp.yml`, docs actualizados
**Relacionado con**: decision D-10, bot-whatsapp.md

---

## [2026-07-29] - DISCOVERY - Inicializaci�n del Proyecto
**Resumen**: Configuraci�n inicial de opencode y an�lisis del c�digo base
**Cambios realizados**:
- Cuestionario de descubrimiento completado
- An�lisis autom�tico del repositorio
- Generaci�n de 8 documentos de contexto + AGENTS.md + opencode.json
**Lecciones**:
- El proyecto tiene c�digo funcional pero bugueado
- Solo la pantalla principal funciona correctamente
- Hay mucho c�digo muerto (8 providers sin registrar, tablas faltantes)
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
- Los 6 providers eliminados ten�an imports a modelos que nunca existieron
- BoardProvider duplicaba funcionalidad de BoardDataProvider
- El c�digo muerto ocultaba bugs (m�todos que no existen en DatabaseHelper)
- SharedPreferences necesita `setMockInitialValues({})` en tests
**Impacto**: app_state.dart, main.dart, database_helper.dart, menu_provider.dart
**Relacionado con**: errores-conocidos.md, convenciones.md

---

## [2026-07-29] - REFACTOR - Transformaci�n brutalista de todas las pantallas
**Resumen**: Se aplic� la gu�a de estilo brutalista a 18 screens (excepto HomeScreen)
**Cambios realizados**:
- Fondo unificado a `#0A0A0A` en todas las screens
- Eliminados todos los `BorderRadius.circular()` ? bordes rectos 90�
- Eliminadas todas las `BoxShadow` ? reemplazadas por bordes s�lidos
- Eliminado `BoxShape.circle` ? formas cuadradas
- 3 screens del calendario: eliminado estilo clay/neumorphism ? brutalist
  - daily_events_screen: AppBar Material ? brutalist, Card?Container, FAB?bot�n con borde
  - schedule_form_screen: clayCard ? BoxDecoration brutalist, ElevatedButton?GestureDetector
  - class_board_screen: clayCard ? BoxDecoration brutalist
- Eliminados imports muertos de `app_theme.dart` en screens que no lo usaban
- Reemplazado `context.textColor` ? `Colors.white`, `context.secondaryColor` ? `#00D4FF`
**Lecciones**:
- clayCard() y ThemeColors extension de app_theme.dart eran usados solo por 2 screens
- La transformaci�n masiva con reemplazos globales es viable si se mantiene la l�gica intacta
- ClipRRect necesita reemplazo manual por Container
**Impacto**: 18 archivos en lib/screens/
**Relacionado con**: convenciones.md, FURI_GUIA_ESTILO_BRUTALISTA.txt

---
## [2026-08-28] - FEATURE - M�sica de fondo a 50%
**Resumen**: Se ajust� el volumen de la m�sica de fondo de 0.4 a 0.5 seg�n requerimiento.
**Cambios realizados**:
- lib/services/sound_service.dart: modificado _bgVolume a 0.5.
**Lecciones**: El volumen se puede parametrizar a futuro desde los ajustes.
**Impacto**: lib/services/sound_service.dart








