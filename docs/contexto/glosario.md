# Glosario de F.U.R.I

## Términos del Dominio

- **F.U.R.I**: Nombre de la app. Significado privado entre Facu y Rocio.
- **Identidad**: El usuario activo (Facu o Rocio). Se selecciona al iniciar sesión.
- **Pareja**: La otra persona. Se vincula por `couple_code` y `partner_id` en profiles.
- **Código de pareja**: Código único para vincular dos perfiles.
- **Mood**: Estado de ánimo diario. Se registra uno por día.
- **Carta**: Mensaje con apertura programada (puede tener fecha futura). Si tiene `scheduled_open` futuro y es carta recibida, queda "sellada" (🔒): no se revela el contenido hasta esa fecha; el bot la "entrega" ceremonialmente cuando se abre.
- **Reto/Challenge**: Desafío de pareja con duración en días.
- **Meta/Goal**: Objetivo compartido (completado no completado).
- **Pregunta diaria**: Pregunta del día para ambos (banco de preguntas).
- **Pizarra/Pizarrón**: Lienzo infinito colaborativo con notas personalizables. Las notas tienen forma, color, degradados, patrones, fuente y borde. Se arrastran, editan y eliminan en tiempo real.
- **Mazo/Tarjeta**: Tarjeta swipe tipo Tinder creada por Facu o Rocio (ideas, chistes, poemas, recetas, retos, random, sueño, me pasó). Se desliza en 4 direcciones: derecha=me encanta, izquierda=no me gusta, abajo=me gusta, arriba=meh. Hay **match** cuando ambos dan me encanta a la misma tarjeta (pantalla "FURI!!" con confetti). Las deslizadas se pueden re-deslizar desde el historial. Tarjetas con **degradado de 3 colores por categoría**, **sin bordes**, **fuente Bangers blanco**, más **delgadas y altas** (75%×92%). Reacciones con degradado y sin borde.
- **Ejercicio/WorkoutLog**: Registro de un ejercicio entrenado (nombre obligatorio; series, reps, peso, descanso, grupo muscular y notas opcionales). Sección Ejercicios (botón pesa del Home).
- **Rutina/WorkoutRoutine**: Conjunto de ejercicios (`items` JSONB); puede asignarse a un día de la semana (plan semanal 1=lunes..7=domingo).
- **Sesión completada/WorkoutCompletion**: Marca "entrené este día" por persona (badges F/R por día).
- **Reto de ejercicio/WorkoutChallenge**: Reto con `approved_by`/`completed_by` — ambos deben aprobar y ambos completar (2 personas).
- **Racha de entrenamiento**: Días consecutivos entrenados por persona; se calcula desde `workout_completions`. El bot avisa si se corta (>=3 días).
- **Racha de pareja**: Días consecutivos en que AMBOS miembros estuvieron activos (registraron mood o completaron un entrenamiento). Se calcula desde `moods` + `workout_completions` (señales con `user_id` + fecha) con `CoupleStats`/`CoupleProvider`, sin tabla propia. Visible en el Home como chip 🔥.
- **Logro de pareja**: Insignia desbloqueable al cumplir un hito (ambos con mood, ambos entrenaron, primer FURI!!, rachas de 3/7/14 días, 100/1000 mensajes). Definido como datos estáticos (`CoupleAchievement`) y evaluado con lógica pura (`CoupleAchievements.earnedCodes`); los otorgados se persisten en `couple_achievements` y se muestran en el álbum de Logros (tocando el chip 🔥). | `couple_achievements`
- **Trivia de pareja**: Juego diario con una pregunta de opción múltiple; cada uno elige su respuesta (`answer`) y predice la de su pareja (`guess`). Un punto por predicción acertada = "quién conoce más a quién" (`TriviaStats.scoreFor`). Preguntas en `daily_questions` (con `options`), respuestas en `question_answers`. Entrada desde el botón Icons.school del Home. | `daily_questions`, `question_answers`
- **Memoria FURI**: Los matches del mazo dejan memoria: match más reciente ("FURI del mes"), primer FURI y conteo mensual. Lógica pura en `DeckMemory` sobre `deck_cards` (reusa `DeckCard.isMatch` + `updatedAt`). | `deck_cards`
- **Recompensa de pareja**: Deseo físico de la "cajita" con costo en puntos, marcable como cumplida. | `couple_rewards`
- **Punto de pareja**: Movimiento del libro mayor de puntos (deltas +/− por razón). Balance por usuario con `PointsStats` (lógica pura). | `couple_points`
- **Ubicación de pareja**: Última ubicación conocida de cada miembro (lat/lng). La distancia entre ambos se calcula con haversine (`distanceKm`, lógica pura). El botón DISTANCIA 🗺️ de Nosotros actualiza la propia (GPS con fallback manual) y muestra la distancia en tiempo real. | `couple_locations`
- **Modo de color**: Uno de 5 temas visuales (flower, green, dark, blue, heart).
- **Pantalla "loca"**: Pantalla estilo Nosotros cuya entrada es un mosaico de bloques-icono gigantes que ocupa todo el lienzo (sin texto a simple vista). Kit compartido `LocaScreen` (`LocaEntry` + paneles swink + swap) y mosaico determinístico `LocaArranger` (seed por pantalla = cada pantalla distribuye distinto). El contenido real (listas/cartas/detalles) se abre al tocar el icono.
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
| ChatTyping | Indicador "escribiendo..." del chat (1 fila por usuario: is_typing, updated_at); la pareja lo ve con realtime | `chat_typing` |
| Note | Nota de la sección "Notas" (antes pizarrón). Tiene `title`/`content`/`color`; se comparte con la pareja (sync Supabase offline-first con `cloudId` + dirty flag `synced` + realtime). Autor en `user_id` | SQLite `notes` + Supabase `notes` |
| BoardElement | Elemento del Pizarrón Infinito colaborativo (nota, checklist, dibujo). Coordenadas (x, y), dimensiones, autoría (Facu/Rocío), color brutalista y sync realtime + offline-first | SQLite `board_elements` + Supabase `board_elements` |
| DeviceToken | Token FCM | `device_tokens` |
| Schedule | Evento de calendario (único o recurrente vía `recurrence`: weekly, every:N, monthly, yearly); `cloudId` = id cloud (BIGSERIAL de Supabase) distinto del id local de SQLite; `user_id` en cloud = autor (colores F/R) | SQLite `schedules` + Supabase `schedules` |
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
| CoupleStreak/Racha de pareja | Cálculo derivado (sin tabla) de días en que ambos estuvieron activos, vía `CoupleStats.activeByDay`/`bothActiveDays` | Se deriva de `moods` + `workout_completions` |
| CoupleAchievement/Logro | Insignia de pareja desbloqueada al cumplir un hito; `achievement_code` UNIQUE | `couple_achievements` |
| MusicTrack | Canción de la biblioteca compartida descargada comprimida desde YouTube con streaming y cache local | SQLite `music_tracks` + Supabase `music_tracks` |
| MusicPlaylist | Playlist colaborativa con canciones ordenadas compartidas entre la pareja | SQLite `music_playlists` + Supabase `music_playlists` |
| MusicComment | Comentario o nota colaborativa en una canción compartida | SQLite `music_comments` + Supabase `music_comments` |
| DrawingProject | Proyecto de dibujo digital con capas, trazos vectoriales suaves, miniatura PNG y persistencia local | Almacenamiento local `furi_drawings/projects/` |
| ComicProject | Proyecto multipágina de cómic o manga con metadatos y lista de páginas | Almacenamiento local `furi_comics/projects/` |
| ComicPage | Página de cómic con viñetas, globos de diálogo y onomatopeyas | Incrustada en `ComicProject` |
| ComicPanel | Viñeta delimitada con dibujo a proporción real, escala y encuadre | Incrustada en `ComicPage` |
| ComicBubble | Globo de diálogo vectorial con 6 estilos (manga clásico, grito, pensamiento, narrador, susurro, chat FURI) y tipografías mangaka | Incrustada en `ComicPage` |
| ComicSticker | Onomatopeya / SFX con contorno, rotación y tipografía Bangers | Incrustada en `ComicPage` |

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
