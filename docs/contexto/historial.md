# Historial de Cambios y Aprendizajes

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
