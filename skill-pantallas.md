# Skill de Pantallas y Sincronización F.U.R.I

> **REGLA OBLIGATORIA**: Este archivo se lee ANTES de tocar cualquier pantalla.
> No es una guía de referencia opcional. Es obligatorio cumplirlo.
> Si hay conflicto con otro documento, este tiene prioridad sobre sync y estructura de pantallas.

---

## Reglas Generales de Sincronización

### 1. Todo en tiempo real
Todos los datos compartidos entre Facu y Rocio se sincronizan vía **Supabase Realtime**.
Cualquier cambio que haga uno, el otro lo ve **al instante** sin refrescar la pantalla.

| Mecanismo | Cuándo se usa |
|-----------|--------------|
| Supabase Realtime (RealtimeChannel) | Chat, pizarra, emociones, notas, retos, cartas, metas, preguntas, galería, finanzas, calendario, favoritos |
| SQLite local | Solo datos de configuración local (class_schedules del wizard) |
| SharedPreferences | Solo sesión de identidad (AppState) |

### 2. Notificaciones entre usuarios
- **NO hay banners in-app** cuando el otro hace algo nuevo
- **Solo el bot WhatsApp** notifica actividad cada 30 min
- La pantalla se actualiza en silencio vía Realtime

### 3. Colores por usuario
Facu y Rocio tienen **colores distintos en TODAS las pantallas** para identificar quién hizo qué.

| Usuario | Color | Uso |
|---------|-------|-----|
| Facu | Naranja `#FF6B00` | Burbujas, badges, indicadores de autoría |
| Rocio | Rosa `#FF1493` | Burbujas, badges, indicadores de autoría |

### 4. Estados de cada pantalla
Toda pantalla debe manejar 4 estados con detalle visual:

| Estado | Cuándo | Qué mostrar |
|--------|--------|-------------|
| **LOADING** | Cargando datos de Supabase/SQLite | Spinner o skeleton con color de sección |
| **EMPTY** | No hay datos para mostrar | Icono + texto "No hay X todavía" con botón de crear |
| **ERROR** | Falló la consulta a Supabase | Banner rojo con mensaje y botón reintentar |
| **DATA** | Datos cargados correctamente | Contenido normal de la pantalla |

### 5. Mapa de navegación

```
LoginScreen
  └── HomeScreen
       ├── ChatScreen (desde botón CHAT en Nosotros o Home)
       ├── NosotrosScreen (desde Home)
       │    ├── ChatScreen (botón CHAT)
       │    ├── RetosScreen (botón RETOS)
       │    ├── CartasScreen (botón CARTAS)
       │    ├── MoodScreen (botón EMOCIONES)
       │    ├── QuestionScreen (botón PREGUNTAS)
       │    ├── MetasScreen (botón METAS)
       │    └── MapaScreen (botón DISTANCIA)
       ├── PizarraScreen (desde Home)
       ├── GaleriaScreen (desde Home)
       ├── FinanzasScreen (desde Home)
       ├── CalendarHomeScreen (desde Home)
       │    ├── ScheduleFormScreen (crear/editar evento)
       │    └── ClassSetupWizard (primera vez)
       ├── NotasScreen (desde Home)
       ├── FavoritosScreen (desde Home)
       └── SettingsScreen (desde Home)
```

### 6. Todo es comentable (excepto chat)
Cada elemento de cada pantalla (excepto los mensajes del chat, que ya tienen reply)
debe tener una **sección de comentarios** donde la pareja puede comentar.

| Elemento | Comentarios |
|----------|------------|
| Mensajes del chat | ❌ Ya tienen reply/swipe |
| Retos | ✅ Long-press → comentarios |
| Cartas | ✅ Al abrir carta → comentarios |
| Emociones | ✅ Tap largo → comentarios |
| Preguntas | ✅ Al ver pregunta → comentarios |
| Metas | ✅ Tap largo → comentarios |
| Fotos de galería | ✅ Panel de detalle → comentarios |
| Transacciones | ✅ Tap largo → comentarios |
| Eventos del calendario | ✅ Tap evento → comentarios |
| Notas | ✅ Tap largo → comentarios |
| Favoritos | ✅ Tap largo → comentarios |
| Elementos de pizarra | ✅ Ya tienen comentarios con @ |

**Formato de comentarios:**
- Cada comentario muestra **badge de autor** con color del usuario (Facu = naranja, Rocio = rosa)
- Se pueden **responder comentarios** (hilo de respuestas)
- Se actualizan en **tiempo real** vía Realtime
- Cualquiera puede **comentar y responder**
- Solo el autor del comentario puede **borrarlo**

### 7. Todo es reaccionable (como WhatsApp)
Cada elemento de cada pantalla debe tener **reacciones por long-press**, mismo formato que el chat.

| Elemento | Reacciones |
|----------|-----------|
| Mensajes del chat | ✅ Ya implementado |
| Retos | ✅ Long-press → emojis |
| Cartas | ✅ Long-press → emojis |
| Emociones | ✅ Long-press → emojis |
| Preguntas | ✅ Long-press → emojis |
| Metas | ✅ Long-press → emojis |
| Fotos de galería | ✅ Ya implementado |
| Transacciones | ✅ Long-press → emojis |
| Eventos del calendario | ✅ Long-press → emojis |
| Notas | ✅ Long-press → emojis |
| Favoritos | ✅ Long-press → emojis |
| Elementos de pizarra | ✅ Long-press → emojis |

**Formato de reacciones:**
- **Long-press** (tap largo) → aparecen emojis: 🥰 😘 😍 :v xD :0
- **Custom**: se puede agregar emoji personalizado (max 5 keys)
- **1 reacción por usuario por key** (Facu y Rocio pueden reaccionar distinto al mismo elemento)
- Las reacciones se muestran **inline** debajo del elemento con badge de quién reaccionó
- Se actualizan en **tiempo real** vía Realtime

### 8. Todo es interactuable por el otro
Cada cosa que crea Facu, Rocio puede **interactuar** con ella (comentar, reaccionar, completar, responder).
Cada cosa que crea Rocio, Facu puede **interactuar** con ella.

**No existe nada "de solo lectura"** — todo elemento creado por un usuario es un punto de
entrada para que el otro usuario participe. La app es de pareja: la interacción es el objetivo.

| Acción | ¿Puede el otro? |
|--------|----------------|
| Comentar | ✅ Ambos |
| Reaccionar | ✅ Ambos |
| Completar (retos/metas) | ✅ Ambos |
| Responder (preguntas) | ✅ La pareja |
| Editar | Depende de la pantalla (ver fichas) |
| Borrar | Solo el creador (ver fichas) |

### 9. Patrón de Provider por pantalla
Cada pantalla con sync tiene su **Provider** que:
1. Carga datos iniciales (`load()`)
2. Se suscribe a Realtime (`startListening()`)
3. Expone métodos CRUD (`add()`, `update()`, `delete()`)
4. Maneja estados `_loading`, `_error`, `_data`
5. Expone métodos de comentarios (`loadComments()`, `addComment()`, `deleteComment()`)
6. Expone métodos de reacciones (`toggleReaction()`)

---

## Fichas por Pantalla

### Chat 💬

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `messages` |
| **Sync** | RealtimeChannel en `messages` |
| **Quién ve qué** | Ambos ven todos los mensajes |
| **Quién puede borrar** | Solo el emisor puede borrar sus mensajes |
| **Quién puede editar** | Solo el emisor (reply, reacciones) |
| **Colores** | Facu = naranja `#FF6B00`, Rocio = rosa `#FF1493` |
| **Media** | Upload a bucket `chat-media`, delete-on-download |
| **Reacciones** | Max 5 keys, 1 reacción por usuario por key |
| **Comentarios** | ❌ No aplica — ya tiene reply/swipe |
| **Ticks** | ✓ enviado, ✓✓ entregado, ✓✓ azul leído |

**Estados:**
- **LOADING**: Spinner centrado con borde naranja
- **EMPTY**: Icono 💬 + "No hay mensajes todavía. ¡Escribile a tu pareja!"
- **ERROR**: Banner rojo "No se pudo cargar el chat" + botón reintentar
- **DATA**: Lista de mensajes con burbujas por usuario

---

### Nosotros 🏠

| Aspecto | Detalle |
|---------|---------|
| **Tipo** | Pantalla hub (no tiene tabla propia) |
| **Sync** | Cada botón abre su pantalla con su propio Realtime |
| **Animaciones** | SWAP (retos 4s, cartas 2s), SWINK (emociones, preguntas) |
| **Colores** | Fondo `#0A0A0A`, botones con color de sección |

**Estados:**
- **LOADING**: Spinner centrado
- **EMPTY**: No aplica (siempre muestra los botones)
- **ERROR**: Banner rojo "No se pudo cargar" + botón reintentar
- **DATA**: Grid de botones con animaciones SWAP activas

---

### Pizarra 🎨

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `board_elements`, `boards` |
| **Sync** | RealtimeChannel en `board_elements` + `boards` |
| **Quién ve qué** | Ambos ven y editan el mismo lienzo |
| **Quién puede borrar** | Cualquiera puede borrar cualquier elemento |
| **Quién puede mover** | Cualquiera puede mover cualquier elemento |
| **Bucket** | `board-media` (imágenes subidas) |
| **Tableros** | Anidados (breadcrumb, crear sub-tablero) |
| **Comentarios** | Por elemento, con menciones @ |
| **Conectores** | Líneas/flechas entre elementos |

**Estados:**
- **LOADING**: Spinner centrado + grid de fondo visible
- **EMPTY**: Lienzo vacío con grid + botón "+" centrado
- **ERROR**: Banner rojo "No se pudo cargar la pizarra" + botón reintentar
- **DATA**: Lienzo con elementos renderizados

---

### Retos 🚩

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `challenges` |
| **Sync** | RealtimeChannel en `challenges` |
| **Quién ve qué** | Ambos ven todos los retos |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede completar** | Solo el creador del reto |
| **Quién puede borrar** | Solo el creador |
| **Visto** | Columna `seen_by` (JSONB array) |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Long-press → bottom sheet con comentarios + respuestas |

**Estados:**
- **LOADING**: Skeleton cards con borde verde `#39FF14`
- **EMPTY**: Icono 🚩 + "No hay retos. ¡Creá uno!"
- **ERROR**: Banner rojo "No se pudieron cargar los retos" + botón reintentar
- **DATA**: Lista de cards de retos con estado (pendiente/en progreso/completado)

---

### Cartas 💌

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `letters` |
| **Sync** | RealtimeChannel en `letters` |
| **Quién ve qué** | Cada uno ve las cartas que le enviaron + las propias |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede borrar** | Solo el autor |
| **Visto** | Columna `seen_by` (JSONB array) |
| **Apertura** | Fecha programada (puede ser futura) |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Al abrir carta → sección de comentarios |

**Estados:**
- **LOADING**: Skeleton cards con borde violeta `#9D00FF`
- **EMPTY**: Icono 💌 + "No hay cartas todavía. ¡Escribile una!"
- **ERROR**: Banner rojo "No se pudieron cargar las cartas" + botón reintentar
- **DATA**: Lista de cartas ordenadas por tiempo

---

### Emociones 😊

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `moods` |
| **Sync** | RealtimeChannel en `moods` |
| **Quién ve qué** | Ambos ven las emociones de ambos |
| **Quién puede crear** | Cualquiera (1 por día por usuario) |
| **Quién puede borrar** | Solo el autor |
| **Quién puede editar** | Solo el autor |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Tap largo → bottom sheet con comentarios |

**Estados:**
- **LOADING**: Spinner centrado con borde amarillo `#FFFF00`
- **EMPTY**: Icono 😊 + "¿Cómo te sentís hoy?"
- **ERROR**: Banner rojo "No se pudieron cargar las emociones" + botón reintentar
- **DATA**: Lista de emojis ordenados por hora

---

### Preguntas ❓

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `custom_questions` |
| **Sync** | RealtimeChannel en `custom_questions` |
| **Quién ve qué** | Ambos ven todas las preguntas y respuestas |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede responder** | Solo la pareja puede responder la pregunta del otro |
| **Quién puede borrar** | Solo el autor de la pregunta |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Al ver pregunta → sección de comentarios |

**Estados:**
- **LOADING**: Skeleton cards con borde cian `#00D4FF`
- **EMPTY**: Icono ❓ + "No hay preguntas. ¡Hacé una!"
- **ERROR**: Banner rojo "No se pudieron cargar las preguntas" + botón reintentar
- **DATA**: Lista de preguntas con respuestas

---

### Metas 🏅

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `goals` |
| **Sync** | RealtimeChannel en `goals` |
| **Quién ve qué** | Ambos ven todas las metas |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede completar** | Cualquiera puede marcar como completada |
| **Quién puede borrar** | Solo el creador |
| **Completado por** | Columna `completed_by` (user_id de quien la hizo) |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Tap largo → bottom sheet con comentarios |

**Estados:**
- **LOADING**: Skeleton cards con borde verde `#39FF14`
- **EMPTY**: Icono 🏅 + "No hay metas. ¡Creá una juntos!"
- **ERROR**: Banner rojo "No se pudieron cargar las metas" + botón reintentar
- **DATA**: Lista de metas con badge de quién la completó

---

### Galería 🖼️

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `gallery`, `gallery_comments` |
| **Sync** | RealtimeChannel en `gallery` + `gallery_comments` |
| **Quién ve qué** | Ambos ven todas las fotos |
| **Quién puede subir** | Cualquiera puede subir |
| **Quién puede borrar** | Solo el subidor |
| **Descripción** | Compartida (un solo texto por foto) |
| **Reacciones** | Mismo formato que chat (max 5 keys) |
| **Comentarios** | Cualquiera puede comentar y responder |

**Estados:**
- **LOADING**: Grid skeleton con borde fucsia `#FF00FF`
- **EMPTY**: Icono 🖼️ + "No hay fotos todavía. ¡Subí una!"
- **ERROR**: Banner rojo "No se pudo cargar la galería" + botón reintentar
- **DATA**: Grid de fotos con panel de detalle

---

### Finanzas 💰

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `transactions` |
| **Sync** | RealtimeChannel en `transactions` |
| **Quién ve qué** | Ambos ven todos los ingresos y gastos |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede borrar** | Solo el creador |
| **Quién puede editar** | Solo el creador |
| **Colores** | Ingreso = verde oscuro `#008844`, Gasto = rojo `#FF0000` |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Tap largo → bottom sheet con comentarios |

**Estados:**
- **LOADING**: Skeleton rows con borde verde `#00FF66`
- **EMPTY**: Icono 💰 + "No hay transacciones. ¡Registra un gasto o ingreso!"
- **ERROR**: Banner rojo "No se pudieron cargar las finanzas" + botón reintentar
- **DATA**: Lista de transacciones con totales

---

### Calendario 📅

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `schedules` (Supabase), `class_schedules` (SQLite + Supabase) |
| **Sync** | RealtimeChannel en `schedules` + `class_schedules` |
| **Quién ve qué** | Ambos ven todos los eventos y clases |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede borrar** | Solo el creador |
| **Clases** | Recurrentes por día de la semana, con `cloudId` |
| **Eventos** | Fecha fija (exámenes, fechas especiales) |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Tap evento → sección de comentarios |

**Estados:**
- **LOADING**: Skeleton del calendario con borde cian `#00D4FF`
- **EMPTY**: Calendario vacío con mensaje "No hay eventos"
- **ERROR**: Banner rojo "No se pudo cargar el calendario" + botón reintentar
- **DATA**: Calendario con eventos y clases renderizados

---

### Notas 📝

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `notes` |
| **Sync** | RealtimeChannel en `notes` |
| **Quién ve qué** | Ambos ven todas las notas |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede editar** | Cualquiera puede editar (colaborativo) |
| **Quién puede borrar** | Solo el creador |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Tap largo → bottom sheet con comentarios |

**Estados:**
- **LOADING**: Skeleton cards con borde amarillo `#FFFF00`
- **EMPTY**: Icono 📝 + "No hay notas. ¡Creá una!"
- **ERROR**: Banner rojo "No se pudieron cargar las notas" + botón reintentar
- **DATA**: Lista de notas ordenadas por tiempo

---

### Favoritos ⭐

| Aspecto | Detalle |
|---------|---------|
| **Tabla** | `favorites` |
| **Sync** | RealtimeChannel en `favorites` |
| **Quién ve qué** | Ambos ven los mismos favoritos |
| **Quién puede crear** | Cualquiera puede crear |
| **Quién puede borrar** | Solo el creador |
| **Rating** | Dual: `rating_facu` y `rating_rocio` independientes |
| **Crítica** | Texto compartido (`critica`), ambos pueden editar |
| **Categorías** | Wrap selector de categoría |
| **Reacciones** | ✅ Long-press → emojis (mismo formato chat) |
| **Comentarios** | ✅ Tap largo → bottom sheet con comentarios |

**Estados:**
- **LOADING**: Skeleton cards con borde violeta `#9D00FF`
- **EMPTY**: Icono ⭐ + "No hay favoritos todavía. ¡Guardá algo!"
- **ERROR**: Banner rojo "No se pudieron cargar los favoritos" + botón reintentar
- **DATA**: Grid de favoritos con rating dual y crítica

---

## Checklist de Implementación

Antes de mergear cualquier cambio en una pantalla, verificar:

- [ ] Lee este archivo ANTES de tocar la pantalla
- [ ] La pantalla maneja los 4 estados: LOADING, EMPTY, ERROR, DATA
- [ ] Usa colores de usuario correctos (Facu = naranja, Rocio = rosa)
- [ ] Se suscribe a Realtime si corresponde
- [ ] Respeta las reglas de permisos (quién puede editar/borrar)
- [ ] Cumple skill_visual.md (fondo=borde, sólido, redondo, sin negro puro)
- [ ] **Cada elemento tiene reacciones por long-press** (mismo formato chat: 🥰😘😍 :v xD :0, max 5 keys)
- [ ] **Cada elemento tiene comentarios** (bottom sheet con badge de autor, respuestas)
- [ ] **Cada elemento es interactuable por el otro usuario** (no hay nada de "solo lectura")
- [ ] Las reacciones y comentarios se actualizan en **tiempo real** vía Realtime
- [ ] No hay código muerto ni imports sin usar
- [ ] Pasa `flutter analyze` sin warnings
- [ ] Pasa `flutter test` (todos los tests verdes)

---

## Pantallas excluidas de este skill

Las siguientes pantallas NO están detalladas aquí porque son simples o de configuración:

- **LoginScreen**: Selector de identidad, sin sync
- **SettingsScreen**: Configuración local, sin sync entre usuarios
- **MapaScreen**: Ubicación en tiempo real (geolocation), sin tabla Supabase
- **NotificationsScreen**: Notificaciones in-app, sin sync compleja

## Especificación del Pizarrón (Rediseño Completo)

> **Versión pizarra**: 1.0
> **Creado**: 2026-08-07
> **Basado en**: 100 preguntas respondidas por el usuario

### Estilo Visual
- **Fondo lienzo**: Negro `#0A0A0A`
- **Grid**: Puntos grises
- **Color acento**: Azul para Facu, Morado para Rocio
- **Forma notas**: Bordes redondos
- **Tipografía**: Monospace
- **Herramientas**: Menú radial
- **Header**: Minimalista (solo nombre del tablero + search)
- **Animaciones**: Scale bounce al agregar elementos
- **Sombras**: Sin sombras
- **Colores notas**: Paleta custom con color picker completo
- **Borde selección**: Punteado animado
- **Badge autor**: Iniciales con color (F=azul, R=morado) en esquina
- **Loading**: Skeleton del lienzo
- **Errores**: Banner rojo
- **Zoom**: Pinch + slider para ajustar

### Tipos de Elementos
- **Nota de texto enriquecido**: Título + cuerpo, formato completo (B/I/U, tamaño variable, color texto, listas, alineación, links inline), auto-size, 15 fuentes predefinidas, color picker de fondo, emoji header, tags custom guardados, estado (borrador/en progreso/finalizado), prioridad (urgente/importante/normal), asignado a (Facu/Rocio con autoría preservada), colapsable (se guarda estado), bloqueable con doble tap, duplicable con long-press
- **Checklist**: Items con estados (pendiente/en progreso/hecho), reordenar con drag, asignar items a Facu/Rocio
- **Dibujo libre**: Canvas libre sobre el lienzo + como elemento movible, herramientas: pincel, borrador, diferentes pinceles, colores, capas
- **Dibujo en notas**: Mini canvas dentro de la nota, dibujo puede estar encima o dentro en lugar elegido, con herramientas de pincel/borrador/colores
- **Video embed**: Pegar URL de YouTube/TikTok + buscar videos desde la app
- **Audio/voz**: Grabar nota de voz + subir archivo de audio, con waveform visual
- **Conectores**: Rectas + curvas bezier + puntos de control editables + etiquetas de texto
- **Sub-tableros**: Tarjetas redondeadas que al tocarlas abren otro pizarrón

### Interacción
- **Panel de edición**: Bottom sheet básico + panel lateral para opciones avanzadas (al tocar elemento)
- **Mover**: Drag libre
- **Rotar**: Gesto de dos dedos
- **Zoom**: Pinch-to-zoom
- **Pan**: Un dedo (un dedo = seleccionar y mover)
- **Doble tap vacío**: Crear nota nueva
- **Snap**: Sin snap
- **Agrupar**: Drag sobre otro elemento
- **Selección múltiple**: Rectángulo en desktop, taps en móvil
- **Undo/Redo**: Ctrl+Z/Ctrl+Y + botón en mobile
- **Atajos desktop**: Undo/Redo, Duplicar/Borrar, Copiar/Pegar, Flechas para mover

### Reacciones y Comentarios
- **Reacciones**: Tap para seleccionar elemento → aparecen opciones en panel
- **Reacciones vis**: Inline debajo del elemento
- **Comentarios**: Panel lateral deslizable
- **Contenido comments**: Texto + emojis + menciones @ + imágenes + audio
- **Editar comments**: Siempre se pueden editar
- **Hilos**: Infinitos (responder a respuestas)

### Sync y Colaboración
- **Cursor otro**: No se ve
- **Edición simultánea**: Solo el creador puede bloquear
- **Historial**: Lista de actividad ("X movió nota Y", "Z agregó imagen")
- **Nuevo elemento**: Badge NUEVO hasta que lo veas
- **Notificaciones**: Bot WhatsApp + badge NUEVO
- **Offline**: Funciona local sin internet, siempre online si se puede
- **Límite**: Sin límite de elementos

### Organización
- **Búsqueda**: Preview + filtros (tipo, autor, fecha, tags)
- **Vistas**: Lienzo infinito + lista + timeline
- **Breadcrumb**: Solo nombre del tablero actual
- **Archivados**: Sección de archivados accesible
- **Exportar**: PNG + PDF
- **Compartir**: Solo Facu y Rocio
- **Separadores**: Manuales (no automáticos ni predefinidos)

### Calidad
- **Bugs**: Solo críticos
- **Testing**: Unitarios + integración
- **Código**: Desde cero en widgets
- **Compatibilidad**: Empezar de cero (no migrar elementos viejos)
- **Prioridad**: Por etapas
- **Etapa 1**: Sync + offline

### NO incluido
- Modo presentación
- Mini mapa
- Kanban con columnas

---

Si alguna de estas pantallas requiere sync o reglas complejas en el futuro, se agrega acá.

---

## Reglas de Trabajo con el Usuario

### Las preguntas SIEMPRE se hacen con opciones clickeables
Cuando necesites información del usuario sobre diseño, funcionalidad, estilo o cualquier
decisión, **NUNCA escribas las preguntas como texto plano**. Usá SIEMPRE la tool `question`
de opencode que permite responder con un click.

**Formato obligatorio:**
```
tool: question
  - header: título corto (max 30 chars)
  - options: lista de opciones con label (1-5 palabras) + description (explicación)
  - question: la pregunta completa
  - multiple: true si puede elegir más de una
```

**Ejemplo correcto:**
```
question("Estilo de fondo", ["Negro puro", "Gris oscuro", "Otro"], "¿Qué color de fondo querés?")
```

**Ejemplo INCORRECTO (NUNCA HACER):**
```
¿Qué color de fondo querés?
A) Negro
B) Gris
C) Otro
```

**Reglas:**
- Máximo 5 opciones por pregunta
- Si hay más opciones, dividir en varias preguntas
- La última opción puede ser "Otro (decime cuál)" para respuestas abiertas
- Si la pregunta permite múltiples respuestas, usar `multiple: true`
- Agrupar preguntas relacionadas en batches de 5-10 por mensaje

---

**Versión**: 9.0 (pizarrón v2 - 24 bugs críticos arreglados)
**Creado**: 2026-08-07
**Actualizado**: 2026-08-07
**Prioridad**: ALTA (regla obligatoria)
