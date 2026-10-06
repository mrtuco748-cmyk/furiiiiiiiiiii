# F.U.R.I

Aplicación móvil **Flutter/Dart** para gestionar una pareja: calendario
compartido, chat con multimedia, finanzas, ejercicios, mazo de cartas, trivia,
galería, metas, notas, cartas y logros.

**Plataformas:** Android (APK), Windows y Web · **Backend:** Supabase + Firebase

---

## Qué hace

La app cubre las áreas de una vida en pareja compartida, cada una con su
pantalla y su propio provider de estado:

### Calendario y organización
- **Calendario** de eventos diarios y **agenda de clases** con asistente de
  configuración inicial
- **Tareas** y **menú semanal** planificado
- **Sincronización del calendario** (`schedule_sync.dart`)
- **Notificaciones** locales de clases y eventos, con manejo de zona horaria
  (`timezone`, `flutter_timezone`)

### Comunicación
- **Chat en tiempo real** con mensajes multimedia: **imágenes, audio grabado y
  video**
- **Reacciones** a mensajes y **swipe-to-reply**
- **Cartas** con historial
- **Notas**
- **Notificaciones push** vía Firebase Cloud Messaging

### Together
- **Finanzas**: registro de transacciones y balances
- **Ejercicios**: rutinas, logging de entrenamientos, challenges, estadísticas
  en el tiempo y bloque de mejoras con comentarios
- **Mazo de cartas**: creación de mazos, historial y juego de "¿qué carta
  tenemos?" (match de mazos)
- **Trivia**: banco de preguntas propio, mazos de trivia, historial y
  estadísticas
- **Galería** de fotos
- **Metas** y **logros** con recompensas (incluye `flutter_confetti`)
- **Mapa**: ubicaciones de la pareja (`geolocator`)
- **Aniversarios** y estadísticas de la pareja

### Personalización
- **TEMA brutalista** con `CustomPainter` propio (`concrete_painter.dart`,
  `brutal_style.dart`)
- **Sonido** con `audioplayers`
- **Favoritos** y **ajustes** persistentes
- Selección de íconos
- **Selector de modo/participantes** en varias pantallas

---

## Arquitectura

Flutter con **gestión de estado por Provider**, siguiendo la separación en
capas:

```
lib/
├── main.dart              Punto de entrada
├── app_state.dart         Estado raíz
├── router.dart            Navegación con go_router
├── supabase_config.dart   Configuración de Supabase
├── firebase_options.dart  Configuración de Firebase
│
├── models/                27 modelos de datos
├── providers/             19 providers (chat, finanzas, workouts, trivia…)
├── screens/               Pantallas agrupadas por feature
│   ├── calendar/          Calendario, clases, asistente de config
│   ├── chat/              Chat + widgets (media, reacciones, swipe-reply)
│   ├── ejercicios/        Ejercicios + stats/retos/hoy + comentarios
│   ├── mazo/              Mazo de cartas + overlays de juego
│   └── trivia/            Trivia + banco de preguntas + historial
├── services/              Servicios (IA, media, notificaciones, caché, audio)
├── widgets/               Widgets compartidos (bubbles, tiles, feedback)
└── theme/                 Tema y estilo visual
```

**Patrón de providers:** cada feature tiene su provider con `ChangeNotifier`,
que expone el estado y las acciones de su dominio. Las pantallas escuchan al
provider y no acceden a la base de datos directamente.

---

## Integraciones

### IA

`ai_service.dart` centraliza el uso de **Gemini 1.5 Flash** (Google Generative
AI) con manejo de cuelas de CUOTAS y timeout:

- Singleton con inicialización diferida
- **Rate limiting** con ventana de 5 s tras un error
- **Timeout de 15 s** en todas las llamadas
- Devuelve `null` en lugar de romper la UI si la IA no está disponible

Configuración por `flutter_dotenv`.

### Persistencia

- **Supabase** — backend principal: autenticación y datos compartidos en la
  nube
- **Firebase Cloud Messaging** — notificaciones push
- **Notificaciones locales** — `flutter_local_notifications` con zona horaria
  configurada
- **SQFLite** — caché local
- **SharedPreferences** — ajustes y preferencias

### Multimedia

`image_picker`, `file_picker`, `record` (audio), `video_player`,
`audioplayers`, `permission_handler` y `open_filex`.

---

## Compilación

Requiere **Flutter 3.x** con **Dart SDK ^3.12.2**.

```bash
flutter pub get

# Android
flutter build apk --release

# Otros targets
flutter build windows
flutter build web
```

### APK

Hay **3 APKs separados por arquitectura** (arm64-v8a, armeabi-v7a, x86_64) para
optimizar el tamaño de la descarga. La guía de instalación por arquitectura y
la solución al problema de firma que impide actualizar por encima de la v1.0.1
están documentadas en `documentacion/GUIA_INSTALACION_APK.md`.

---

## Stack

- **Flutter / Dart** — `sdk: ^3.12.2`
- **Estado:** Provider
- **Navegación:** go_router
- **Backend:** Supabase (auth + datos), Firebase Cloud Messaging (push)
- **IA:** Google Generative AI (Gemini 1.5 Flash)
- **UI:** `google_fonts`, `flutter_confetti`, `CustomPainter` propio
- **Persistencia local:** SQFLite, SharedPreferences
- **Plataformas:** Android, Windows, Web

---

## Documentación

El proyecto mantiene documentación de contexto en `docs/contexto/`:

| Archivo | Contenido |
|---|---|
| `arquitectura.md` | Estructura y decisiones de arquitectura |
| `convenciones.md` | Convenciones de código |
| `decisiones.md` | Registro de decisiones técnicas |
| `errores-conocidos.md` | Errores conocidos y workarounds |
| `flujo-de-trabajo.md` | Flujo de trabajo |
| `glosario.md` | Glosario de términos |
| `historial.md` | Historial de cambios |

Además, `documentacion/` incluye el diagnóstico técnico, la guía de estilo
brutalista, la guía de instalación del APK y los planes de rediseño.