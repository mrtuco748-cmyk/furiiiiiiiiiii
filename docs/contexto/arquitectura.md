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

supabase/
├── functions/send-push/        # Edge Function para FCM push
└── schema.sql                  # Definición de tablas (incompleta vs código)

documentacion/                  # Documentación del proyecto
├── FURI_GUIA_ESTILO_BRUTALISTA.txt
├── PLAN_REDISENO.md
└── estructura_del_proyecto.txt
```

## Flujo de Datos

### Login
```
App inicia → loadSession() (SharedPreferences)
  ├── Sesión guardada → HomeScreen directo
  └── Sin sesión → LoginScreen
        → Seleccionar identidad (Facu/Rocio)
        → Supabase: upsert profiles
        → saveSession() → HomeScreen
```

### Chat (tiempo real)
```
ChatScreen abre
  → loadMessages() (Supabase messages table)
  → RealtimeChannel suscribe a messages
  → Nuevo mensaje:
     1. Insert en Supabase messages
     2. Trigger DB → Edge Function send-push → FCM
     3. RealtimeChannel recibe cambio → UI actualiza
     4. NotificationService.startListening() muestra local notif
```

### Notificaciones Push
```
App cerrada:
  Trigger DB → Edge Function (send-push) → FCM → dispositivo

App abierta:
  Realtime global → NotificationService → notificación local
```

## Estados de Cada Pantalla (REQUISITO)
Toda pantalla debe manejar: **LOADING** | **EMPTY** | **ERROR** | **DATA**

## Lo que NO existe (features esperables faltantes)

- **Tests**: No hay tests unitarios ni de integración (solo 1 widget test)
- **Router**: No hay sistema de rutas nombradas (GoRouter, Navigator 2.0)
- **Inyección de dependencias**: No hay DI (get_it, provider con factory)
- **Logging**: No hay sistema de logging (ni siquiera print statements)
- **Error handling global**: No hay error boundary, Zone, o handler global
- **Analytics**: No hay tracking de eventos
- **Git**: El proyecto nunca se subió a git
- **CI/CD**: No hay pipelines
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
