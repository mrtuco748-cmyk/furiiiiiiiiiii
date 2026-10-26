# Arquitectura de F.U.R.I

## Stack Tecnológico

| Componente | Tecnología | Versión |
|-----------|-----------|---------|
| Lenguaje | Dart | ^3.12.2 |
| Framework UI | Flutter | SDK estable |
| State Management | Provider (ChangeNotifier) | ^6.1.2 |
| Backend/BaaS | Supabase | ^2.16.0 |
| Base de datos cloud | PostgreSQL (Supabase) | - |
| Base de datos local | SQLite (sqflite) | ^2.4.1 |
| Push notifications | Firebase Cloud Messaging | firebase_messaging: ^15.2.0 |
| Notificaciones locales | flutter_local_notifications | ^18.0.1 |
| Zona horaria (recordatorios) | flutter_timezone | ^4.1.0 |
| Bot WhatsApp | Node.js + Baileys | v20.18.0 / ^6.7.0 |
| Automatización | GitHub Actions | schedule cron |
| IA Generativa | Google Generative AI (Gemini 1.5 Flash) | ^0.4.6 |
| Calendario | table_calendar | ^3.2.0 |
| Iconos | font_awesome_flutter, phosphor_flutter, material_design_icons | varias |
| Fuentes | google_fonts | ^8.2.0 |
| Almacenamiento local | shared_preferences | ^2.5.0 |
| Navegación | GoRouter (route table centralizado, `MaterialApp.router`) | ^17.5.0 |
| Reproducción de audio | audioplayers | ^6.8.1 |
| Extracción YouTube | youtube_explode_dart | ^3.1.0 |
| Mapa interactivo | flutter_map + latlong2 | ^8.3.2 / ^0.9.1 |

## Mapa de Carpetas

```
lib/
├── main.dart                    # Punto de entrada, inits, MultiProvider, MaterialApp
├── app_state.dart               # Sesión (identidad, IDs) en SharedPreferences
├── supabase_config.dart         # Cliente Supabase singleton
├── firebase_options.dart        # Config Firebase
├── database/
│   └── database_helper.dart     # SQLite singleton (calendario, clases, pizarrón)
├── theme/
│   └── app_theme.dart           # 5 modos de color + clay theme
├── models/                      # 21 modelos Dart (message, mood, letter, deck_card, workout_log, etc.)
├── providers/                   # 20 providers registrados
├── screens/                     # 19 pantallas + subcarpetas
│   ├── calendar/               # Calendario unificado estilo Nosotros
│   │   ├── calendar_screen.dart     # Vista mensual + agenda del día integrado
│   │   ├── event_sheet.dart         # Modal único (alta/edición con selector de repetición)
│   │   └── day_agenda.dart          # Lógica pura de mezcla y orden de eventos
│   ├── mazo/                    # Mazo de tarjetas swipe tipo Tinder
│   │   ├── deck_overlay.dart           # Overlay encima del Home (swipe 4 direcciones)
│   │   ├── deck_style.dart             # Estilos por categoria y reaccion
│   │   ├── create_deck_card_modal.dart # Modal de creacion (8 categorias)
│   │   ├── deck_history_sheet.dart     # Historial + re-deslizar
│   │   └── deck_match_overlay.dart     # Pantalla "FURI!!" (match con confetti)
│   ├── ejercicios/              # Seccion Ejercicios (boton pesa del Home)
│   │   └── ejercicios_screen.dart      # 4 pestañas: Hoy, Ejercicios, Retos, Stats
│   ├── herramientas/            # Sección Herramientas (Taller de Dibujo multicapa + Taller de Cómic & Manga)
│   │   ├── herramientas_screen.dart    # Menú de herramientas creativas
│   │   ├── dibujo/                     # Motor y pantalla de dibujo profesional multicapa
│   │   └── comic/                      # Taller de cómic y manga multipágina con viñetas y modo lector
│   ├── pizarra/                 # Pizarrón Infinito colaborativo (drag fluido, notas, checklists, dibujos)
│   │   └── pizarra_screen.dart         # Canvas 2D con Pan/Zoom, grid punteado y sync realtime
│   └── music/                   # Reproductor de Música compartida
│       └── music_screen.dart           # Biblioteca compartida, búsqueda YouTube y reproductor
├── services/                    # 8 servicios (notifications, ai, sound, music_download, etc.)
└── widgets/                     # Widgets compartidos
    ├── furi_global_overlay.dart # Overlay global (notificaciones flotantes estilo WhatsApp + mini reproductor música)
    ├── brutal_style.dart        # Estilo Nosotros compartido (bg, block, card, fillIcon, iconAction)
    ├── loca_arranger.dart       # Mosaico "loca" determinístico (dividir lienzo en N bloques)
    ├── loca_screen.dart         # LocaScreen: pantalla icono+swink estilo Nosotros (LocaEntry, panels, swap)
    ├── swap_widget.dart         # Swap automático icono↔contenido + LineScrollText/PhraseScrollText
    ├── tap_tile.dart            # Botón tappable con animación de escala + sonido
    └── ...

Assets/
└── icons/                       # SVGs para botones, paneles, boards

bot-furi/                        # Bot de WhatsApp (Node.js)
├── bot.js                       # Lógica principal del bot
├── package.json                 # Dependencias npm
├── supabase_migration.sql       # Tablas bot_sessions + bot_notificaciones
├── .env                         # Config local (SUPABASE_URL, KEY, MI_NUMERO)
└── .gitignore                   # Ignora node_modules, auth/, .env

.github/
└── workflows/
    └── bot-whatsapp.yml         # GitHub Actions: corre cada 30 min

supabase/
├── functions/send-push/        # Edge Function para FCM push
├── schema.sql                  # Definición de tablas (incompleta vs código)
└── migration.sql               # Migración para tablas del bot

documentacion/                  # Documentación del proyecto
├── FURI_GUIA_ESTILO_BRUTALISTA.txt
├── PLAN_REDISENO.md
└── estructura_del_proyecto.txt
```

## Flujo de Datos

### Login + Class Setup
```
App inicia → loadSession() (SharedPreferences)
  ├── Sesión guardada → HomeScreen directo
  └── Sin sesión → LoginScreen
        → Seleccionar identidad (Facu/Rocio)
        → Supabase: upsert profiles
        → saveSession() → HomeScreen

HomeScreen.initState():
  → _checkClassSetup()
    → Consulta SQLite local: tabla `class_schedules`
    ├── Vacío → ClassSetupWizard (modal)
    │     → Guarda `ClassSchedule` recurrentes por día de la semana en SQLite local
    │     → Cierra wizard → loadSchedules() de ClassScheduleProvider
    └── Con datos → No muestra wizard

CalendarScreen:
  → Carga `ScheduleProvider` (eventos fechados y recurrentes) + `ClassScheduleProvider` (clases)
  → Vista mes arriba + agenda del día abajo con mezcla de únicos y recurrentes
  → Formulario único `EventSheet` (único, semanal, cada N días, mensual, anual)
  → Sin wizard intrusivo al inicio ni mosaico intermedio
```

### Recordatorios programados (eventos y clases)
```
Eventos (schedules):
  → ScheduleProvider._rescheduleNotifs() tras load/add/update/delete y realtime
  → EventNotificationService.specsForEvent() → zonedSchedule: 1h antes + al empezar
  → Ids de notificación 100000+id y 100000+id+1 (namespace de eventos)
Clases (class_schedules):
  → ClassScheduleProvider._rescheduleNotifs() tras load/add/update/delete y realtime
  → ClassNotificationService.specsForClass() → zonedSchedule semanal recurrente 1h antes
    (matchDateTimeComponents: dayOfWeekAndTime, id 200000+id)
Zona horaria: NotificationService._ensureTz() — flutter_timezone (nombre IANA) con fallback por offset
Desktop (Windows): zonedSchedule no implementado → try/catch → no-op (sin recordatorios)
```

### Chat (tiempo real + media)
```
ChatScreen abre
  → ChatProvider.init()
  → carga paths locales SQLite chat_media_local
  → loadMessages() (Supabase messages, ultimos 100)
  → RealtimeChannel suscribe a messages
  → Nuevo mensaje texto:
     1. Insert en Supabase messages (1 check gris: sent)
     2. Render 24/7 (bot-furi/server.js) + app despachan push FCM v1 de alta prioridad
     3. Receptor recibe push (background/foreground) o realtime → markMessageDelivered() → delivered_at = NOW() (2 checks grises: delivered)
     4. Receptor abre chat o ya está dentro → markIncomingRead() → read = true, read_at = NOW() (2 checks azules: read)
     5. RealtimeChannel propaga UPDATE → UI actualiza en vivo
  → Nuevo mensaje media:
     1. Copia local + upload bucket chat-media
     2. Insert messages (attachment_url, message_type, ...)
     3. Receptor toca descargar → download a app docs
     4. Guarda path en chat_media_local
     5. Borra objeto Storage + update cloud_deleted/attachment_url null
  → Reply: swipe horizontal cualquier mensaje (dock WhatsApp sobre input bar)
  → Reacciones: long-press → 🥰😘😍 :v xD :0 + custom (max 5 keys)
  → Emojis y Stickers (WhatsApp Style):
     - Botón emoji en barra de entrada → ChatEmojiStickerSheet con 2 tabs: EMOJIS (categorizados) y STICKERS (cuadrícula).
     - Botón "Exportar desde WhatsApp" → StickerService escanea rutas de WhatsApp en Android (`/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Stickers`) y las copia a `furi_stickers/` local (con fallback a FilePicker).
     - Al tocar un sticker se envía al chat como `message_type: 'sticker'` con renderizado transparente y microcápsula de hora/vistos.
  → Ticks de visto:
     - 1 check gris: enviado a Supabase
     - 2 checks grises: recibido en el celular (notificación push / realtime)
     - 2 checks azules: leído en chat abierto
```

### Pizarra v2 (Notas colaborativas)
```
PizarraScreenV2 abre
  → BoardProviderV2.load()
    → SQLite local (offline-first)
    → Supabase sync + RealtimeChannel suscribe a board_elements_v2
  → Canvas infinito con grid de puntos + InteractiveViewer (pan/zoom)
  → Notas renderizadas como cards con estilo real (forma, color, gradiente, borde)
  → Tap en nota → NoteCardModal (edición)
  → Drag → moveLocal() desactiva canvas pan
  → Long press → diálogo eliminar → provider.delete()
  → Botón verde flotante → NoteCardModal (nueva nota)

NoteCardModal:
  → Título + cuerpo + grabadora audio + imagen de galería (posicionable)
  → Toolbar derecha: Forma (6), Color (5 + custom), Fondo (2 capas), Fuente (12), Borde (6)
  → Capa Fondo: Degradado (Liso/Lineal/Radial + 3 colores) + Patrón (12 opciones + custom texto/emoji)
  → Sliders: grosor, ángulo, tamaño, opacidad, espaciado, saturación
  → Patrones solo visibles si toggle activado (patternEnabled)
  → Guardar → provider.add() o provider.update() → persiste SQLite + Supabase
```

### Mazo (tarjetas swipe tipo Tinder)
```
App inicia → HomeScreen.initState()
  → _initDeck() (post frame): DeckProvider.load() (Supabase deck_cards)
  → Si hay tarjetas sin reaccion mia → DeckOverlay encima del Home
  → Swipe: ➡️ me encanta | ⬅️ no me gusta | ⬇️ me gusta | ⬆️ meh
  → Salida animada (160ms) → DeckProvider.react() → update reactions JSONB
  → Realtime deck_cards_changes → applyCloudCards() (merge anti-race)
  → Si ambos "encanta" (transicion local no-match → match) → DeckMatchOverlay "FURI!!"
  → Historial (sheet) → re-deslizar una tarjeta (cambia la reaccion)
  → Bloque ▶/🖼️/▶ del Home → abre el mazo (crear con +)

Tarjetas: **sin bordes** (degradado puro, borderRadius 32), **mÃ¡s delgadas y altas** (75% ancho × 92% alto), fuente **Bangers blanco** tamaño 28. Etiquetas de reaccion al deslizar **sin borde** (solo degradado + Bangers blanco). Solo botÃ³n X cerrar en header (sin botones de accion abajo). CategorÃ­a POEMAS: degradado rojo-rosa-rojo.
```

### Ejercicios (boton pesa del Home)
```
Home → boton pesa (verde lima #39FF14, sin confeti) → EjerciciosScreen
  → WorkoutProvider.load() (4 tablas Supabase + RealtimeChannel workouts_realtime)
  → 4 pestañas:
     Hoy: semana LUN-DOM → routineForDay(dayOfWeek) → badges F/R de
          workout_completions (toggleCompletion marca/desmarca por persona)
          Tap en item de rutina → dialog nuevo log pre-rellenado
     Ejercicios: workout_logs (nombre obligatorio + opcionales) → tap =
          detalle (weightHistoryFor = evolución de peso) + comentarios;
          long-press = reacciones (social JSONB)
     Retos: workout_challenges (approved_by/completed_by, ambos deben
          aprobar/completar) → sheet de acciones
     Stats: WorkoutStats (streakFor individual, sessionsThisWeek,
          distinctExerciseNames, muscleGroupCounts)
  → `social` JSONB (reacciones `{key:[uid]}` + comentarios):
       Reacciones → RPC toggle_reaction (merge atómico, FOR UPDATE)
       Comentarios → RPC add_workout_comment / delete_workout_comment
          (merge atómico server-side, evita el race "último write gana");
          el provider hace optimistic + reconciliación con el `social`
          autoritativo que devuelve la RPC (workout_provider._commentViaRpc)
```

### Notas (sección "Notas" — antes pizarrón v2)
```
Sección "Notas" abre → NotesScreen → NotesProvider.load() (offline-first + Supabase)
  → SQLite local (tabla `notes`, v11: id, cloud_id, synced, user_id,
      title, content, color, created_at, updated_at) + tabla cloud `notes`
  → _pushUnsyncedToCloud() (insert notas sin cloudId + re-push dirty synced=0)
  → _pullFromCloud() (trae TODAS, merge por cloudId; borra locales sin fila cloud)
  → RealtimeChannel notes_sync → _debouncedReload()
  → add/update/delete escriben local + cloud (con dirty flag; re-push offline)
  → Las notas SE COMPARTEN entre Facu y Rocio (decisión D-15): cualquier
    dispositivo ve las notas de ambos. Autor por user_id (quién la creó).
```

### Racha de pareja 🔥 (días en que ambos están activos)
```
Home abre → HomeScreen.initState() (post frame) → CoupleProvider.load()
  → load moods (user_id, date) + workout_completions (user_id, completed_on)
  → CoupleStats.activeByDay() → Map<día, Set<usuarios activos>>
  → CoupleStats.bothActiveDays(members: {myId, partnerId}) → días con ambos
  → coupleStreak / bestCoupleStreak / todayActive
Realtime: moods + workout_completions → _reload() (recalcula racha)
UI: chip 🔥 con GoogleFonts.bangers en el Home (Consumer<CoupleProvider>),
    posicionado en esquina superior derecha sin tocar la grilla. (Tap → Logros)
Sin tabla propia: la racha se deriva de señales con user_id + fecha.
```

### Logros de pareja 🏅 (colección de insignias)
```
Home → tap chip 🔥 → LogrosScreen abierta → CoupleAchievementsProvider.load()
  → carga couple_achievements (los ya otorgados)
  → construye AchievementSnapshot: moods + workout_completions (ambos),
    messages.count(), deck_cards (algún match) → coupleStreak/bestStreak
  → CoupleAchievements.earnedCodes(snapshot) → códigos alcanzados
  → inserta los nuevos (UNIQUE + diferencia de sets) → idempotente
Realtime: couple_achievements → el otro dispositivo ve logros al instante
UI: álbum en grilla (desbloqueados a color, pendientes desvanecidos con 🔒)
Reglas = datos estáticos (CoupleAchievement), evaluación = lógica pura.
```

### Trivia de pareja 🎯 (pregunta del día: respondés + predecís)
```
Home → botón Icons.school → TriviaScreen (TriviaProvider.load())
  → siembra TriviaQuestionBank en daily_questions si está vacío (options JSONB)
  → TriviaStats.questionForDay(bank, hoy) → pregunta del día (índice por día del año)
  → Cada uno elige Tu respuesta + Predicción (chips) → submit() a question_answers
    (delete-then-insert del día propio: permite re-responder)
  → cuando ambos contestan → marcador: TriviaStats.scoreFor(userId) =
     un punto por cada predicción que acierta la respuesta real de la pareja
  → scoreboard "X - Y" en header + score view (quién conoce más a quién)
Realtime: question_answers → _reloadAnswers()
UI: pregunta en chip brutalista, opciones seleccionables, estados loading/empty/error/data
```

### Notificaciones Push
```
App cerrada:
  Trigger DB → Edge Function (send-push) → FCM → dispositivo

App abierta:
  Realtime global → NotificationService → notificación local
```

### Bot WhatsApp (notificaciones proactivas)
```
GitHub Actions (webhook en tiempo real + respaldo cada 30 min)
  → node bot.js
    → loadSessionFromSupabase()  (bot_sessions table)
    → makeWASocket() conecta WhatsApp
    → verificarYNotificar():
        1. schedules      → eventos en próximas 2h
        2. anniversaries   → hoy (8-10 AM) / mañana
        3. moods           → nuevas en última 1h
        4. letters         → nuevas en última 1h
        5. challenges      → creados/completados en última 1h
        6. goals           → creadas/completadas en última 1h
        7. tasks           → nuevas en última 1h
        8. transactions    → nuevos ingresos/gastos en última 1h
        9. favorites       → nuevos en última 1h
        10. notes          → nuevas en última 1h
        11. gallery        → nuevas fotos en última 1h
        12. timeline_events → nuevos eventos en última 1h
        13. custom_questions → nuevas/respondidas en última 1h
        14. class_schedules → clases de hoy en próximas 2h
        15. deck_cards      → tarjeta nueva (a la pareja del creador)
        16. deck match      → ambos "encanta" → FURI!! a ambos
        17. workout_logs    → nuevo ejercicio en última 1h
        18. workout_completions → sesión completada en última 1h
        19. workout_challenges → reto creado/aprobado/completado en última 1h
        20. racha rota     → streak >= 3 días y no entrenó hoy ni ayer
    → enviarMensaje() a MI_NUMERO
    → saveSessionToSupabase()
    → disconnect
```

Tracking de notificaciones (evita duplicados):
  - Tabla `bot_notificaciones` registra (tabla, registro_id, tipo, phone, mensaje)
  - Antes de notificar: chequea `yaNotificado(tabla, registroId)`
  - Después de notificar: `marcarNotificado(tabla, registroId, tipo, phone, mensaje)`

Persistencia de sesión WhatsApp:
  - Tabla `bot_sessions` (id=1, session_data JSONB)
  - `loadSessionFromSupabase()` escribe auth/*.json desde JSONB
  - `saveSessionToSupabase()` lee auth/*.json y sube a JSONB
  - En cada `creds.update` se guarda automáticamente

## Estados de Cada Pantalla (REQUISITO)
Toda pantalla debe manejar: **LOADING** | **EMPTY** | **ERROR** | **DATA**

## Lo que NO existe (features esperables faltantes)

- **Tests**: No hay tests unitarios ni de integración (solo 1 widget test)
- **Inyección de dependencias**: No hay DI (get_it, provider con factory)
- **Logging**: No hay sistema de logging (ni siquiera print statements)
- **Error handling global**: No hay error boundary, Zone, o handler global
- **Analytics**: No hay tracking de eventos
- **Autenticación real**: Solo selector de identidad local, no hay auth
- **Modo offline**: No hay sync offline robusto
- **Migraciones DB**: No hay sistema de migraciones (ni SQLite ni Supabase)
- **Diagramas de secuencia**: No existen

## Escalabilidad Actual

- **Provider** funciona para 2 usuarios, escalaría mal a más
- **Sin abstracción de datos**: providers llaman directo a Supabase/SQLite
- **Código muerto**: 8 providers sin registrar, 7+ tablas SQLite sin crear
- **Cuello de botella**: chat estaba en un solo archivo (1359 líneas) → separado en widgets (Fase 0, 2026-08-26): `chat_screen.dart` solo lógica+layout, `screens/chat/chat_style.dart` + `screens/chat/widgets/*` para los presentacionales.
- **Sin tests**: cualquier cambio puede romper sin que se sepa
