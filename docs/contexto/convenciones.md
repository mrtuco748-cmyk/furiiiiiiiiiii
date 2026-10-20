# Convenciones de F.U.R.I

## Estilo de Código

| Regla | Convención |
|-------|-----------|
| Naming archivos | snake_case (`chat_screen.dart`) |
| Naming clases | PascalCase (`ChatScreen`) |
| Naming variables/funciones | lowerCamelCase (`loadMessages()`) |
| Naming constantes | lowerCamelCase (NO SCREAMING_SNAKE_CASE) |
| Naming privado | prefijo `_` (`_loading`, `_load()`) |
| Naming modelos | entidad en singular (`message.dart`, no `messages.dart`) |

## Formato

- Indentación: 2 espacios
- Límite de línea: 80 caracteres
- Punto y coma: obligatorio
- Usar `const` siempre que sea posible
- Preferir `final` sobre `var`
- Usar `withValues(alpha:)` de Flutter 3.27+ para colores

## Límite de Tamaño de Archivos y Modularización (OBLIGATORIO)

- **Límite máximo por archivo**: Ningún archivo .dart debe superar las **300 líneas de código**. Si un archivo supera 300 líneas, es **obligatorio** dividirlo en submódulos.
- **Tamaño ideal**: 50 a 150 líneas por archivo con Principio de Responsabilidad Única (SRP).
- **Estructura en subcarpetas por feature**:
  - widgets/: Componentes atómicos (cards, barras de acción, modales, dialogs).
  - models/: Entidades de datos y serialización.
  - services/: Operaciones de red, audio, cache, plugins nativos.
  - controllers/ o providers/: Gestión del estado reactivo.
- **Referencia de mapa**: Consultar docs/contexto/mapa-del-codigo.md para navegar rápidamente sin saturar el contexto del agente.

## Imports

- Orden: 1) Flutter/Dart SDK, 2) Paquetes externos, 3) Internos
- Separar grupos con línea en blanco
- Usar imports relativos (`../providers/`) o package (`package:furi_app/...`) — inconsistente actualmente, preferir package

## Estilo Visual (BRUTALISTA MODIFICADO — NO NEGOCIABLE)

> **REGLA FUNDAMENTAL**:
> **NO QUIERO BORDES EN NINGÚN LADO. CADA COSA DEBE TENER UN SOLO COLOR Y TONO. NADA DE RELLENOS Y BORDES DE DISTINTO COLOR. UN SOLO COLOR Y SIN BORDES: BLOQUES DE LITERALMENTE UN SOLO COLOR Y TONALIDAD CADA UNO, EXACTAMENTE COMO SE VE EN EL INICIO.**

```dart
// Referencia: docs/skill_visual.md
// Colores base
Color fondoBase = const Color(0xFF141414);
Color textoPrincipal = const Color(0xFFFFFFFF);
Color textoSecundario = const Color(0xFFE0E0E0);

// Bordes: NINGUNO (border: null o sin borde). Cero líneas perimetrales de distinto tono.
// Relleno: Un solo color y tono sólido por botón, card o bloque (como en el inicio).
// Esquinas: Redondeadas (BorderRadius.circular(10) a (18)).
// Sin sombras difusas ni gradientes.
```

### Colores por Sección

| Sección | Color Vibrante |
|---------|---------------|
| Mensajes/Chat | Naranja #FF6B00 |
| Tareas | Fucsia #FF00FF |
| Calendario/Tiempo | Cian #00D4FF |
| Eventos/Celebraciones | Verde #39FF14 |
| Notificaciones | Amarillo #FFFF00 |
| Perfil/Usuario | Rosa #FF1493 |
| Favoritos/Especial | Violeta #9D00FF |
| Errores/Crítico | Rojo #FF0000 |

## Patrones Usados

- **Provider + ChangeNotifier**: State management principal
- **Singleton**: DatabaseHelper, SupabaseConfig, NotificationService
- **CRUD Provider**: Cada provider sigue: `load()`, `add()`, `update()`, `delete()`
- **RealtimeChannel**: Para datos en tiempo real (chat, notas, notificaciones)
- **CustomPainter**: Para fondos (concrete_painter) y burbujas (message_bubble)
- **Event Bus**: SyncProvider como bus de eventos entre secciones

## Patrones Prohibidos

- NO usar setState para datos compartidos (usar Provider)
- NO usar GlobalKey a menos que sea estrictamente necesario
- NO hardcodear strings de UI repetidos (crear constantes)
- NO tragar excepciones silenciosamente (`catch (_) {}`)
- NO chamuyar navegación con push/pop sin ruteo

## Tests (TDD — OBLIGATORIO)

- Framework: `flutter_test`
- Ubicación: `test/` mirror de `lib/`
- Naming: `nombre_test.dart`
- Formato nombres de test: `descripción en español`
- TDD: escribir test antes de implementar
- Ejecutar: `flutter test` antes de cada commit

## Commits

- Formato: Conventional Commits
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `refactor:` refactorización
- `test:` tests
- `docs:` documentación
- `chore:` tareas de mantenimiento

## Excepciones/Irregularidades

- El estilo brutalista NO está implementado consistentemente en el código actual
- Los colores de FURI_GUIA_ESTILO no se usan en el código (se usan colores hardcodeados propios de cada screen)
- Algunos screens usan bordes redondeados (18px) que contradicen la guía brutalista
