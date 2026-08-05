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

## Imports

- Orden: 1) Flutter/Dart SDK, 2) Paquetes externos, 3) Internos
- Separar grupos con línea en blanco
- Usar imports relativos (`../providers/`) o package (`package:furi_app/...`) — inconsistente actualmente, preferir package

## Estilo Visual (BRUTALISTA — NO NEGOCIABLE)

```dart
// Referencia: FURI_GUIA_ESTILO_BRUTALISTA.txt

// Colores base
Color fondoBase = const Color(0xFF0A0A0A);
Color textoPrincipal = const Color(0xFFFFFFFF);
Color textoSecundario = const Color(0xFFE0E0E0);

// Bordes: 2-3px sólidos, ÁNGULOS RECTOS (sin border-radius)
// Animaciones: <150ms, linear o ease-in-out rápido
// Sin sombras ni gradientes suaves
// Sin fade-in/fade-out
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
