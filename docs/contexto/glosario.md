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
- **Pizarra**: Lienzo infinito colaborativo con notas, dibujos, posts.
- **Modo de color**: Uno de 5 temas visuales (flower, green, dark, blue, heart).

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
| Note | Nota compartida | `notes` |
| DeviceToken | Token FCM | `device_tokens` |
| Schedule | Evento de calendario | SQLite `schedules` + Supabase `schedules` |
| ClassSchedule | Clase recurrente por día de la semana; `cloudId` = id cloud (BIGSERIAL de Supabase) distinto del id local de SQLite | SQLite `class_schedules` + Supabase `class_schedules` |
| Transaction | Transacción financiera | `transactions` |
| Task | Tarea kanban | `tasks` |
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
