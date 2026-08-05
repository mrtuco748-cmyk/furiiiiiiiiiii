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
| Message | Mensaje del chat | `messages` |
| Mood | Estado de ánimo diario | `moods` |
| Letter | Carta programada | `letters` |
| Anniversary | Fecha importante | `anniversaries` |
| Goal | Meta compartida | `goals` |
| Challenge | Reto de pareja | `challenges` |
| DailyQuestion | Pregunta del día | `daily_questions` |
| QuestionAnswer | Respuesta a pregunta | `question_answers` |
| Notification | Notificación in-app | `notifications` |
| Note | Nota compartida | `notes` |
| DeviceToken | Token FCM | `device_tokens` |
| Schedule | Evento de calendario | SQLite `schedules` |
| Transaction | Transacción financiera | `transactions` |
| Task | Tarea kanban | `tasks` |
| Favorite | Favorito por categoría | `favorites` |

## Siglas y Acrónimos

| Sigla | Significado |
|-------|------------|
| FCM | Firebase Cloud Messaging |
| RLS | Row Level Security (Supabase) |
| FURI | Nombre de la aplicación |
| IA | Inteligencia Artificial (Gemini) |
| LOC | Lines of Code |
| TDD | Test-Driven Development |
