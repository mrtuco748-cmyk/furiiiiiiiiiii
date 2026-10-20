# Mapa del Código y Arquitectura de F.U.R.I

> **GUÍA DE INGRESO RÁPIDO PARA AGENTES IA Y DESARROLLADORES**
> Este documento resume la estructura de todo el proyecto, la responsabilidad de cada carpeta y archivo, y las reglas arquitectónicas para que cualquier agente pueda navegar, comprender y modificar el código sin necesidad de cargar múltiples archivos ni saturar su contexto.

---

## 1. Principios Arquitectónicos Fundamentales

1. **Límite de Tamaño por Archivo (REGLA DE LAS 300 LÍNEAS)**:
   - Ningún archivo `.dart` debe exceder las **300 líneas de código**.
   - Si un archivo se acerca o supera las 300 líneas, debe subdividirse en la subcarpeta `widgets/`, `models/`, `services/` o `controllers/` de su feature correspondiente.
   - Tamaño óptimo por archivo: entre **50 y 150 líneas** con **Responsabilidad Única (SRP)**.

2. **Arquitectura Feature-First + Offline-First**:
   - Cada pantalla/módulo funcional vive en su propia subcarpeta dentro de `lib/screens/<feature>/`.
   - **Offline-First**: La interfaz consume y actualiza primero SQLite local (`DatabaseHelper`), y sincroniza en segundo plano de forma bidireccional con **Supabase** (`PostgreSQL + Realtime`).

3. **Estilo Visual (Brutalista Modificado - `skill_visual .md`)**:
   - **Sin bordes**: `border: null` o sin borde perimetral.
   - **Color sólido y uniforme**: Fondo y acento en bloques de color pleno, sin gradientes difusos ni negro puro (`#141414` o `#181818` para fondos oscuros).
   - **Esquinas redondeadas**: `BorderRadius.circular(10)` a `circular(18)`.

---

## 2. Mapa General de Carpetas (`lib/`)

```text
lib/
├── database/        # SQLite local, migraciones de esquema y helpers offline
├── models/          # Entidades de datos inmutables y mapeo JSON/SQLite/Supabase
├── providers/       # Gestores de estado reactivo (ChangeNotifier / Provider)
├── screens/         # Pantallas de la aplicación organizadas por feature
│   ├── calendar/    # Calendario compartido, eventos y horarios de clase
│   ├── chat/        # Chat en tiempo real, notas de voz, adjuntos y stickers
│   ├── ejercicios/  # Rutinas de gym, series, peso y estadísticas de entrenamiento
│   ├── favoritos/   # Lugares, series, películas y deseos compartidos con rating
│   ├── finanzas/    # Gastos compartidos, balances y divisiones de pago
│   ├── galeria/     # Galería estilo lienzo infinito y Pinterest integrado
│   ├── logros/      # Sistema de logros de pareja y estadísticas de racha
│   ├── mazo/        # Cartas de conexión, preguntas íntimas y matches
│   ├── milanote/    # Pizarrón interactivo infinito estilo Milanote
│   ├── music/       # Reproductor de música compartida, cola y playlists
│   └── trivia/      # Trivia diaria de pareja y preguntas de predicción
├── services/        # Servicios de infraestructura (audio, notificaciones, push, red)
└── widgets/         # Componentes transversales y overlays globales
```

---

## 3. Detalle de Módulos y Archivos

### 3.1. Núcleo de la Aplicación (`lib/`)
- [`main.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/main.dart): Punto de entrada, inicialización de Firebase, Supabase, SQLite, audio y `MultiProvider`.
- [`router.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/router.dart): Configuración de GoRouter con todas las rutas declaradas y tipadas.
- [`app_state.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/app_state.dart): Identidad activa (`Facu` o `Rocio`), `partnerId`, `myId` y estado global de sesión.
- [`supabase_config.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/supabase_config.dart): Credenciales y cliente singleton de Supabase.

---

### 3.2. Pantallas Principales (`lib/screens/`)

#### 🏠 Inicio (`lib/screens/home_screen.dart`)
- **Responsabilidad**: Vista de inicio tipo bento-grid con acceso a todas las secciones, clima, racha y accesos rápidos.
- **Subcarpetas/Widgets**: Barra superior de usuario, tarjetas de estado de ánimo, accesos rápidos.
- **Providers vinculados**: `CoupleAchievementsProvider`, `ChatProvider`, `WorkoutProvider`.

#### 🖼️ Galería & Pinterest (`lib/screens/galeria/`)
- [`galeria_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/galeria/galeria_screen.dart): Galería de fotos compartidas en grilla asimétrica infinita con visor de comentarios y reacciones.
- [`pinterest_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/galeria/pinterest_screen.dart): Pinterest webview embebido nativo con credenciales en 1-tap y protección anti-crash.
- **Subcarpeta `widgets/`**:
  - `galeria_top_bar.dart`: Encabezado con conteo de fotos y botón a Pinterest.
  - `galeria_photo_tile.dart`: Tarjeta de foto con proporciones variadas y badges.
  - `galeria_detail_modal.dart`: Hoja inferior de foto completa, reacciones y envío de comentarios.
  - `pinterest_top_bar.dart`: Barra de navegación nativa con botón atrás, reload y credenciales.
  - `pinterest_credentials_banner.dart`: Barra con chips de copia de correo y contraseña.

#### 🎵 Música Compartida (`lib/screens/music/`)
- [`music_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/music/music_screen.dart): Reproductor estilo Spotify/YouTube Music, búsqueda, playlists y visor de comentarios por canción.
- **Provider**: [`MusicPlayerProvider`](file:///d:/projetcs/proyectos/F.U.R.I/lib/providers/music_player_provider.dart).
- **Servicio Nativo Android**: [`FuriMusicService.kt`](file:///d:/projetcs/proyectos/F.U.R.I/android/app/src/main/kotlin/com/furiapp/furi_app/FuriMusicService.kt) (`MediaSession` con seek bar y controles en shade).

#### 💬 Chat (`lib/screens/chat/`)
- [`chat_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/chat_screen.dart): Chat en tiempo real, estados de entrega (ticks), respuestas a mensajes y grabadora de voz.
- **Subcarpeta `widgets/`**:
  - `chat_message_bubble.dart`: Burbujas de mensajes enviadas y recibidas.
  - `chat_media_body.dart`: Renderizado de imágenes, audios y adjuntos.
  - `chat_emoji_sticker_sheet.dart`: Selector flotante de stickers y emojis.
- **Provider**: [`ChatProvider`](file:///d:/projetcs/proyectos/F.U.R.I/lib/providers/chat_provider.dart).

#### 🏋️‍♂️ Ejercicios (`lib/screens/ejercicios/`)
- [`ejercicios_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/ejercicios/ejercicios_screen.dart): Registro de series, pesos, repeticiones y rutinas semanales compartidas.
- **Subcarpeta `widgets/`**:
  - `exercise_sheet.dart`: Hoja modal de registro rápido de ejercicio.
  - `routine_card.dart`: Tarjetas de rutina por día.
- **Provider**: [`WorkoutProvider`](file:///d:/projetcs/proyectos/F.U.R.I/lib/providers/workout_provider.dart).

#### 📝 Milanote / Pizarrón (`lib/screens/milanote/`)
- [`milanote_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/milanote/milanote_screen.dart): Lienzo bidimensional infinito con notas adhesivas, fotos, listas y conectores.
- **Subcarpetas**:
  - `models/note_style_config.dart`: Configuración de patrones, formas y gradientes.
  - `widgets/pizarron_note_widget.dart`: Renderizado visual de notas y tarjetas.
  - `widgets/pizarron_sidebar_overlay.dart`: Barra lateral de herramientas y creación.
  - `painters/note_card_painter.dart`: Dibujo vectorial de formas y siluetas.
- **Provider**: [`BoardDataProvider`](file:///d:/projetcs/proyectos/F.U.R.I/lib/providers/board_data_provider.dart).

#### 📅 Calendario & Horarios (`lib/screens/calendar/`)
- [`calendar_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/calendar/calendar_screen.dart): Vista mensual interactiva de eventos.
- [`calendar_home_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/calendar/calendar_home_screen.dart): Resumen de agenda del día y horarios.
- [`class_board_screen.dart`](file:///d:/projetcs/proyectos/F.U.R.I/lib/screens/calendar/class_board_screen.dart): Tablero de horarios de clase semanales.
- **Widgets**: `daily_events_screen.dart`, `event_sheet.dart`, `schedule_form_screen.dart`.
- **Providers**: `ScheduleProvider`, `ClassScheduleProvider`.

---

### 3.3. Proveedores de Estado (`lib/providers/`)
- `chat_provider.dart`: Mensajes, typing indicator, presencia ("en línea", "última vez").
- `music_player_provider.dart`: Audio streaming, cola de descargas, seek bar y sincronización con notificación nativa.
- `gallery_provider.dart`: Fotos, subida a storage, comentarios y reacciones.
- `workout_provider.dart`: Logs de gimnasio, estadísticas de peso y aprobación de retos.
- `board_data_provider.dart`: Elementos del lienzo de Milanote, posiciones X/Y y conectores.
- `couple_achievements_provider.dart`: Verificación automática y otorgamiento de logros de pareja.
- `favorites_provider.dart`: Lugares y elementos guardados con calificación independiente de Facu y Rocío.
- `trivia_provider.dart`: Preguntas diarias de trivia y cálculo de aciertos.
- `deck_provider.dart`: Mazo de cartas swipeable y coincidencia de matches íntimos.

---

### 3.4. Servicios Transversales (`lib/services/`)
- `notification_service.dart`: Canales de notificación locales, push FCM v1 y puente con `FuriMusicService`.
- `sound_service.dart`: Efectos de sonido de la interfaz y música ambiental.
- `music_download_service.dart`: Extracción de audio desde YouTube y subida a Supabase Storage.
- `local_cache.dart`: Almacenamiento rápido en SharedPreferences para flags y modo offline.
- `settings_service.dart`: Preferencias del usuario, paletas de tema y volúmenes.

---

## 4. Guía para Agentes IA: ¿Qué archivo modificar según la tarea?

| Necesidad del Usuario | Archivos Principales a Revisar |
|---|---|
| **Problemas o mejoras en Galería de fotos** | `lib/screens/galeria/` (`galeria_screen.dart`, `widgets/`), `lib/providers/gallery_provider.dart` |
| **Problemas o mejoras en Pinterest** | `lib/screens/galeria/pinterest_screen.dart`, `android/.../MainActivity.kt` |
| **Notificación o controles de Música en Android** | `android/.../FuriMusicService.kt`, `lib/services/notification_service.dart`, `lib/providers/music_player_provider.dart` |
| **Reproductor o búsqueda musical en la app** | `lib/screens/music/music_screen.dart`, `lib/providers/music_player_provider.dart` |
| **Chat, mensajes, fotos o audios en chat** | `lib/screens/chat_screen.dart`, `lib/screens/chat/widgets/`, `lib/providers/chat_provider.dart` |
| **Pizarrón / Milanote / Formas de notas** | `lib/screens/milanote/` (`milanote_screen.dart`, `models/`, `widgets/`, `painters/`) |
| **Entrenamiento, rutinas o ejercicios** | `lib/screens/ejercicios/`, `lib/providers/workout_provider.dart` |
| **Calendario, eventos o clases** | `lib/screens/calendar/`, `lib/providers/schedule_provider.dart` |
| **Estilos visuales o colores de la app** | `skill_visual .md`, `lib/widgets/theme_color_customizer_sheet.dart` |

---

## 5. Reglas al Refactorizar Archivos (> 300 Líneas)

1. Extraer widgets privados (`_buildSomething()`) a clases públicas en archivos separados dentro de `widgets/`.
2. Mantener la lógica de negocio en el `Provider` o pasar callbacks simples (`onTap`, `onChanged`).
3. Nunca alterar el estilo visual: bloques de color sólido, sin bordes, esquinas redondeadas.
4. Ejecutar siempre `flutter analyze` y `flutter test` tras cada modularización.
