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
| Bot WhatsApp | Node.js + Baileys | v20.18.0 / ^6.7.0 |
| Automatización | GitHub Actions | schedule cron |
| IA Generativa | Google Generative AI (Gemini 1.5 Flash) | ^0.4.6 |
| Calendario | table_calendar | ^3.2.0 |
| Iconos | font_awesome_flutter, phosphor_flutter, material_design_icons | varias |
| Fuentes | google_fonts | ^8.2.0 |
| Almacenamiento local | shared_preferences | ^2.5.0 |
| Navegación | Navigator nativo (push/pop) | - |

## Mapa de Carpetas

```
lib/
├── main.dart                    # Punto de entrada, inits, MultiProvider, MaterialApp
├── app_state.dart               # Sesión (identidad, IDs) en SharedPreferences
├── supabase_config.dart         # Cliente Supabase singleton
├── firebase_options.dart        # Config Firebase
├── database/
│   └── database_helper.dart     # SQLite singleton (calendario, clases)
├── theme/
│   └── app_theme.dart           # 5 modos de color + clay theme
├── models/                      # 14 modelos Dart (message, mood, letter, etc.)
├── providers/                   # 19 providers (11 registrados, 8 muertos)
├── screens/                     # 16 pantallas + subcarpetas
├── services/                    # 5 servicios (notifications, ai, settings, sound)
└── widgets/                     # 6 widgets compartidos

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

CalendarHomeScreen:
  → Carga `ScheduleProvider` (eventos fechados) + `ClassScheduleProvider` (clases recurrentes)
  → Por cada día mostrado, genera eventos sintéticos de tipo `Clase` a partir de `class_schedules.dayOfWeek`
```

### Chat (tiempo real + media)
```
ChatScreen abre
  → ChatProvider.init()
  → carga paths locales SQLite chat_media_local
  → loadMessages() (Supabase messages, ultimos 100)
  → RealtimeChannel suscribe a messages
  → Nuevo mensaje texto:
     1. Insert en Supabase messages
     2. Trigger DB → Edge Function send-push → FCM
     3. RealtimeChannel recibe cambio → UI actualiza
  → Nuevo mensaje media:
     1. Copia local + upload bucket chat-media
     2. Insert messages (attachment_url, message_type, ...)
     3. Receptor toca descargar → download a app docs
     4. Guarda path en chat_media_local
     5. Borra objeto Storage + update cloud_deleted/attachment_url null
  → Reply: swipe horizontal cualquier mensaje
  → Reacciones: long-press → 🥰😘😍 :v xD :0 + custom (max 5 keys)
  → Ticks de visto: markIncomingRead() → update messages read/delivered_at/read_at → doble tick
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
GitHub Actions (cada 30 min)
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
- **Router**: No hay sistema de rutas nombradas (GoRouter, Navigator 2.0)
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
- **Cuello de botella**: chat_screen.dart (699 líneas), sin separación de concerns
- **Sin tests**: cualquier cambio puede romper sin que se sepa
