# Glosario de F.U.R.I

## Términos del Dominio

- **F.U.R.I**: Nombre de la app. Significado privado entre Facu y Rocio.
- **Identidad**: El usuario activo (Facu o Rocio). Se selecciona al iniciar sesión.
- **Pareja**: La otra persona. Se vincula por `couple_code` y `partner_id` en profiles.
- **Código de pareja**: Código único para vincular dos perfiles.
- **Mood**: Estado de ánimo diario. Se registra uno por día.
- **Carta**: Mensaje con apertura programada (puede tener fecha futura).
- **Reto/Challenge**: Desafío de pareja con duración en días.
- **Meta/Goal**: Objetivo compartido (completado no completado).
- **Pregunta diaria**: Pregunta del día para ambos (banco de preguntas).
- **Pizarra/Pizarrón**: Lienzo infinito colaborativo con notas personalizables. Las notas tienen forma, color, degradados, patrones, fuente y borde. Se arrastran, editan y eliminan en tiempo real.
- **Mazo/Tarjeta**: Tarjeta swipe tipo Tinder creada por Facu o Rocio (ideas, chistes, poemas, recetas, retos, random, sueño, me pasó). Se desliza en 4 direcciones: derecha=me encanta, izquierda=no me gusta, abajo=me gusta, arriba=meh. Hay **match** cuando ambos dan me encanta a la misma tarjeta (pantalla "FURI!!" con confetti). Las deslizadas se pueden re-deslizar desde el historial.
- **Ejercicio/WorkoutLog**: Registro de un ejercicio entrenado (nombre obligatorio; series, reps, peso, descanso, grupo muscular y notas opcionales). Sección Ejercicios (botón pesa del Home).
- **Rutina/WorkoutRoutine**: Conjunto de ejercicios (`items` JSONB); puede asignarse a un día de la semana (plan semanal 1=lunes..7=domingo).
- **Sesión completada/WorkoutCompletion**: Marca "entrené este día" por persona (badges F/R por día).
- **Reto de ejercicio/WorkoutChallenge**: Reto con `approved_by`/`completed_by` — ambos deben aprobar y ambos completar (2 personas).
- **Racha de entrenamiento**: Días consecutivos entrenados por persona; se calcula desde `workout_completions`. El bot avisa si se corta (>=3 días).
- **Modo de color**: Uno de 5 temas visuales (flower, green, dark, blue, heart).
- **Tipo de evento/Tipo de clase**: Categoría con nombre, color y (solo eventos) icono que se asigna a los eventos del calendario. Se gestionan desde el formulario de evento (`event_types`) y desde `ClassBoardScreen` (`class_types`). Solo existen en SQLite local.

## Entidades Principales

| Entidad | Descripción | Tabla Supabase |
|---------|------------|---------------|
| Profile | Perfil de usuario | `profiles` |
| Message | Mensaje del chat (texto/media, reply, reacciones max 5, delete-on-download, ticks `delivered_at`/`read_at`) | `messages` + SQLite `chat_media_local` |
| Reacción | Emoji/texto en un mensaje; max 5 keys; 1 por usuario | `messages.reactions` JSONB |
| Chat media | Adjunto (image/video/voice/gif/document); se borra de Storage al descargar | bucket `chat-media` |
| Mood | Estado de ánimo diario | `moods` |
| Letter | Carta programada; leída por quién vía `seen_by` (JSONB) | `letters` |
| Anniversary | Fecha importante | `anniversaries` |
| Goal | Meta compartida con `completed_by` (quién la hizo) | `goals` |
| GalleryComment | Comentario de una foto | `gallery_comments` |
| Challenge | Reto de pareja; `seen_by` (JSONB) | `challenges` |
| DailyQuestion | Pregunta del día | `daily_questions` |
| QuestionAnswer | Respuesta a pregunta | `question_answers` |
| Notification | Notificación in-app | `notifications` |
| Note | Nota del pizarrón v2 con forma, color, gradiente, patrón, fuente y borde personalizables; persiste en `board_elements_v2` | SQLite `board_elements_v2` + Supabase `board_elements_v2` |
| Pizarra v2 | Lienzo infinito colaborativo con grid de puntos, notas renderizadas con estilo real, drag-to-move, edit y delete | Provisto por `BoardProviderV2` |
| DeviceToken | Token FCM | `device_tokens` |
| Schedule | Evento de calendario; `cloudId` = id cloud (BIGSERIAL de Supabase) distinto del id local de SQLite; `user_id` en cloud = autor (colores F/R) | SQLite `schedules` + Supabase `schedules` |
| ClassSchedule | Clase recurrente por día de la semana; `cloudId` = id cloud (BIGSERIAL de Supabase) distinto del id local de SQLite | SQLite `class_schedules` + Supabase `class_schedules` |
| EventType | Tipo de evento del calendario (nombre, color, icono); gestión desde el formulario de evento | SQLite `event_types` |
| ClassType | Tipo de clase recurrente (nombre, color); gestión desde `ClassBoardScreen` | SQLite `class_types` |
| Transaction | Transacción financiera | `transactions` |
| Task | Tarea kanban | `tasks` |
| DeckCard | Tarjeta del mazo swipe (8 categorías) con reacciones por usuario en JSONB; match = ambos "encanta" | `deck_cards` |
| WorkoutLog | Ejercicio entrenado; `social` JSONB con reacciones + comentarios | `workout_logs` |
| WorkoutRoutine | Rutina con `day_of_week` e `items` JSONB | `workout_routines` |
| WorkoutCompletion | Día entrenado por persona (badges F/R) | `workout_completions` |
| WorkoutChallenge | Reto con aprobación/completado conjuntos | `workout_challenges` |
| Favorite | Favorito por categoría, con `rating_facu`/`rating_rocio` (rating dual por usuario) y `critica` texto compartido | `favorites` |

## Siglas y Acrónimos

| Sigla | Significado |
|-------|------------|
| FCM | Firebase Cloud Messaging |
| RLS | Row Level Security (Supabase) |
| FURI | Nombre de la aplicación |
| IA | Inteligencia Artificial (Gemini) |
| LOC | Lines of Code |
| TDD | Test-Driven Development |
| CI/CD | Continuous Integration / Continuous Deployment |
| ESM | ECMAScript Modules (sistema de módulos de Node.js) |
| QR | Quick Response code (escaneo para vincular WhatsApp) |
