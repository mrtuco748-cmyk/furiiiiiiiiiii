# Pizarrón — Documentación Completa

> Documentación de referencia del Pizarrón v2 de F.U.R.I. Describe cada elemento,
> opción y comportamiento con detalle: aspecto, funcionalidad y concepto.

---

## Resumen General

### Qué es F.U.R.I

F.U.R.I es una app de pareja privada, usada solo por **Facu y Rocio**. Tiene chat,
finanzas, calendario, galería, favoritos, retos, cartas, metas, emociones, preguntas
y el **Pizarrón**. Corre en **Android** (celulares) y **Windows** (PC desktop).
Backend: **Supabase** (PostgreSQL + Realtime + Storage) con cache local **SQLite**.

### Para qué es el Pizarrón

El Pizarrón es un **lienzo infinito colaborativo** (estilo Milanote) donde la pareja
organiza ideas, planes y contenido en forma visual: notas con estilo personalizado,
checklists, dibujos, videos, audios, conectores, tableros anidados y separadores.

**Concepto**: en vez de listas lineales, el pizarrón imita una pared real donde
ambos van clavando cosas. Es un espacio de creación conjunta en tiempo real: lo que
uno agrega, mueve, reacciona o comenta, el otro lo ve al instante en su dispositivo.

**Principios de diseño**:
- Todo es **interactuable por el otro** — no hay nada de solo lectura.
- Todo es **reaccionable** (long-press, emojis como el chat) y **comentable**.
- **Offline-first**: funciona sin internet; cuando hay conexión, sincroniza solo.
- **Estilo visual propio**: fondo sólido, borde del mismo color que el fondo,
  esquinas redondeadas, sin negro puro, sin sombras.

### Identidad visual por usuario

| Usuario | Color acento | Badge de autor |
|---------|-------------|----------------|
| Facu | Azul `#4FC3F7` | Inicial "F" en círculo azul |
| Rocio | Morado `#CE93D8` | Inicial "R" en círculo morado |

---

## El Lienzo (Canvas)

### Aspecto
- **Fondo**: gris oscuro `#0A0A0A` (no negro puro).
- **Grid**: puntos grises `#333333` de 1.5px cada 30px, infinito en las 4 direcciones.
- El mundo mide 10000×10000 unidades; el grid se pinta en espacio de pantalla y se
  transforma con la cámara, por lo que el pan/zoom es fluido sin límites visibles.

### Funcionalidad
- **Pan**: arrastrar con un dedo (o mouse) sobre el fondo vacío.
- **Zoom**: pinch-to-zoom o rueda del mouse. Rango **0.1x a 5x**.
- **Centrado inicial**: al entrar, la vista arranca centrada en el origen del mundo.
- **Estados**:
  - **LOADING**: spinner verde `#39FF14` centrado (mientras carga de SQLite/Supabase).
  - **EMPTY**: lienzo vacío con grid y el menú de herramientas.
  - **ERROR**: banner rojo `#FF5757` arriba con el mensaje "No se pudo cargar la
    pizarra" y botón de reintentar.
  - **DATA**: elementos renderizados con su estilo real.

---

## Elementos del Pizarrón

Hay **8 tipos de elemento**: Nota, Checklist, Dibujo, Video, Audio, Conector,
Sub-tablero y Separador. Todos se crean desde el **menú radial de herramientas**
(botón + abajo a la derecha) y **aparecen en el centro de la vista actual**.

### Gestos comunes a todos los elementos

| Gesto | Acción |
|-------|--------|
| **Tap** | Acción por tipo (abrir/editar/reproducir). Además marca el elemento como visto (quita badge NUEVO). |
| **Long-press** | Abre el sheet de opciones: reacciones, comentarios, duplicar, archivar, eliminar. |
| **Drag** | Mueve el elemento libremente (el pan del lienzo se desactiva durante el arrastre). |

### Badges sobre cada elemento

- **NUEVO** (verde `#39FF14`, arriba-izquierda): aparece en todo elemento recién
  creado y **desaparece cuando lo tocás** (marcado como visto, se sincroniza).
- **Autor** (arriba-derecha): círculo de 22px con la inicial del creador — **F**
  azul para Facu, **R** morado para Rocio.
- **Reacciones inline**: debajo del elemento se muestran chips con la reacción y
  la cantidad (ej. `🥰 2`).

---

## 1. Nota 📝

El elemento central del pizarrón. Es una tarjeta de texto con un sistema de estilo
completo.

### Concepto
Es el post-it llevado al extremo: cada nota puede tener forma, color, degradado,
patrón de fondo, fuente y borde propios. Sirve para ideas, recordatorios, apuntes,
citas, o contenido visual decorativo.

### Aspecto en el canvas
- Card de 180px de ancho con su **forma** real (clip), **degradado** y **borde**.
- Título en negrita (1 línea con ellipsis) + preview del cuerpo (máx 3 líneas).
- Texto claro u oscuro según la luminancia del fondo (contraste automático).

### Crear y editar
- **Tap en el + del menú → Nota** (o tap en una nota existente) abre el
  **modal de edición** centrado, con la card a la izquierda y la **toolbar
  vertical de 5 herramientas** a la derecha. La card se ve **en vivo** con cada
  cambio.

### El modal de nota — contenido
- **Título**: campo de texto (1 línea).
- **Cuerpo**: campo de texto multilinea expandible.
- **Imagen**: botón de galería (imagen redimensionada a 1200px). Al elegirla se
  abre un selector de **posición**: arriba del título, en el medio, o abajo del
  cuerpo. Se puede **quitar**. Se muestra como preview dentro de la nota.
- **Grabadora de audio**: botón de micrófono que graba voz dentro de la nota
  (contador de tiempo, confirmación con check verde, botón de borrar). El audio
  queda embebido en la nota.
- **Guardar**: botón check verde. **Cerrar**: X arriba a la derecha.

### Toolbar de la nota (5 botones)

#### a) Forma (cian `#00D4FF`)
6 formas con icono y selección resaltada:
**Rectángulo**, **Cuadrado**, **Círculo**, **Óvalo**, **Diamante**, **Hexágono**.

#### b) Color (naranja `#FF6B00`)
- **5 colores base**: Naranja `#FF6B00`, Fucsia `#FF00FF`, Cian `#00D4FF`,
  Verde `#39FF14`, Violeta `#9D00FF`.
- **Rueda de color completa**: barra de tono (hue) + cuadrado saturación/brillo
  con gestos de arrastre, preview con código hex en tiempo real.
- **Recientes**: los últimos 5 colores custom elegidos.
- Color default de nota nueva: violeta `#5C2D91`.

#### c) Fondo (violeta `#9D00FF`)
Sistema de fondo por 2 capas:

**Capa 1 — Degradado** (tipo de relleno):
- **Liso**: color plano.
- **Lineal**: gradiente de 3 colores (Inicio, Medio, Borde) diagonal.
- **Radial**: gradiente de 3 colores circular desde el centro.

**Capa 2 — Patrón** (toggle on/off):
- 12 patrones: **Puntos, Líneas H, Líneas V, Cuadrícula, Diagonales, Zigzag,
  Diamantes, Ondas, Círculos, Triángulos, Rayas, Panal**.
- **Patrón personalizado**: texto o emoji repetido por todo el fondo.
- Sliders de ajuste: **Grosor** (0.5–8), **Ángulo** (rotación del patrón),
  **Tamaño**, **Opacidad** (5%–100%), **Espaciado** (2–60), **Saturación**.

#### d) Fuente (fucsia `#FF00FF`)
- **12 Google Fonts**: Roboto, Open Sans, Lato, Montserrat, Oswald, Raleway,
  Poppins, Dancing Script, Pacifico, Permanent Marker, Caveat, Indie Flower.
- **Color del texto**: 5 base (blanco, gris claro, gris oscuro, naranja, cian)
  + rueda de color custom.
- **Tamaño**: slider 8–48px con botones +/−.

#### e) Borde (naranja `#FF6B00`)
- **Toggle on/off**.
- **6 tipos**: Sólido, Punteado (círculos), Dashed (segmentos), Doble (2 líneas),
  Ondulado (sinusoide), Relieve (doble stroke con transparencia).
- **Color**: 5 base + custom.
- **Grosor**: 1–10px. **Espaciado**: 1–20px (afecta punteado/dashed).

---

## 2. Checklist ✓

### Concepto
Lista de tareas compartida con asignación por persona y seguimiento de progreso.

### Aspecto
- Card violeta `#7B2D8E` con esquinas redondeadas (ancho 200–350px).
- Título arriba + items + botón "Agregar item" + barra de progreso con contador
  (ej. `2/5`).

### Funcionalidad
- Cada item tiene un **checkbox de 3 estados** que cicla con tap:
  pendiente (gris) → en progreso (dorado `#FFD700` con icono play) →
  hecho (verde con check, texto tachado).
- **Asignación**: círculo pequeño al lado de cada item que cicla con tap:
  F (azul) → R (morado) → sin asignar.
- **Editar texto**: tap en el texto abre un diálogo.
- **Agregar item** (botón +) y **borrar item** (X).
- Barra de progreso: gris → dorado → verde según avance.
- Todo se edita **inline en el canvas**; los cambios de la pareja llegan por
  realtime.

---

## 3. Dibujo ✎

### Concepto
Canvas de dibujo libre incrustado en el pizarrón, como elemento movible.

### Aspecto
- Card de 300×200px con fondo gris `#111111`, esquinas redondeadas.
- Los strokes se renderizan con su color y grosor reales.

### Funcionalidad (editor tipo bottom sheet que se abre al crearlo o al tocarlo)
- **5 herramientas**: Pincel (trazo libre suavizado con bezier), Borrador
  (trazo más grueso color fondo), Línea, Rectángulo, Círculo.
- **8 colores**: blanco, rojo, amarillo, verde, cian, rosa, violeta, naranja.
- **Grosor**: slider 1–10px.
- **Undo**: deshace el último stroke. **Clear**: borra todo.
- **Guardar**: check (persiste los strokes en el elemento).
- Tap en el dibujo del canvas reabre el editor con ese dibujo cargado.

---

## 4. Video ▶

### Concepto
Video embebido por URL (YouTube, TikTok u otro) que se abre en el navegador.

### Aspecto
- Card de 320×180px con **thumbnail** (YouTube usa `img.youtube.com/vi/{id}/hqdefault.jpg`),
  botón de play circular centrado y **título superpuesto** abajo.
- Sin thumbnail: placeholder con icono del proveedor y su nombre.

### Funcionalidad
- **Crear**: menú → Video abre un diálogo para **pegar la URL** (YouTube, TikTok
  o directa). El thumbnail de YouTube se genera automáticamente desde el ID.
- **Ver**: tap en el video lo abre en el **navegador externo** del dispositivo.

---

## 5. Audio 🎤

### Concepto
Nota de voz grabada dentro del pizarrón, con reproducción con waveform.

### Aspecto
- Card de 280×80px con botón play/pause cian `#4FC3F7` circular, **waveform de
  barras** (las reproducidas se pintan con más opacidad) y duración mm:ss.

### Funcionalidad
- **Crear**: menú → Audio abre el **grabador** (bottom sheet): botón mic/stop,
  contador de duración, waveform que crece en tiempo real.
- **Grabación**: AAC-LC 128kbps 44.1kHz, guardada en archivos de la app.
- **Reproducir**: tap en play/pause del elemento en el canvas.
- Tap en un audio existente reabre el grabador para regrabarlo.

---

## 6. Conector 🔗

### Concepto
Flecha visual que une dos elementos (relación, flujo, orden).

### Aspecto
- Curva **bezier** verde `#39FF14` de 3px entre los centros de dos elementos,
  con **punta de flecha** en el destino. Se actualiza sola al mover los elementos.
- No captura gestos: es puramente visual.

### Funcionalidad
- **Crear** (modo conector): menú → Conector entra en **modo selección** con un
  banner cian arriba que guía: "Tocá el elemento de ORIGEN" → "Tocá el elemento
  de DESTINO". Los elementos candidatos se resaltan con borde cian.
- Se puede cancelar con el botón del banner.

---

## 7. Sub-tablero 📁

### Concepto
Tarjeta que abre **otro pizarrón anidado** — pizarras dentro de pizarras, para
separar proyectos o temas.

### Aspecto
- Card de 160×100px azul oscuro `#2D3A5C` con icono de carpeta, chevron (>) y el
  nombre del tablero.

### Funcionalidad
- **Crear**: menú → Sub-tablero pide un **nombre** en un diálogo → crea el tablero
  en Supabase (tabla `boards`) y agrega la card al canvas actual.
- **Abrir**: tap en la card → el pizarrón cambia al tablero anidado. El **header
  muestra el nombre del tablero actual** (breadcrumb) y aparece el botón
  **"← Volver"** arriba a la izquierda para subir al tablero padre.
- Los tableros pueden anidarse en niveles arbitrarios.
- La vista se centra al cambiar de tablero.

---

## 8. Separador ➖

### Concepto
Línea manual para dividir visualmente zonas del pizarrón.

### Aspecto
- Línea violeta `#9D00FF` de 2px de grosor. Horizontal por defecto (300px de
  largo). Tap la convierte en vertical (y viceversa, intercambiando dimensiones).

### Funcionalidad
- **Crear**: menú → Separador (aparece en el centro de la vista).
- **Rotar**: tap en el separador alterna horizontal/vertical.
- Se mueve y elimina como cualquier elemento.

---

## Interacción Social (long-press en cualquier elemento)

### Sheet de opciones
Al hacer long-press se abre un bottom sheet con:

**1. Barra de reacciones**
- 6 emojis default: **🥰 😘 😍 :v xD :0** (mismo set del chat).
- Botón **+** para agregar un emoji o texto **custom** (máx 10 caracteres).
- **Reglas**: máximo **5 keys** de reacción por elemento; **1 reacción por
  usuario por key**; tocar un emoji propio lo quita; tocar otro emoji cambia tu
  reacción. Los chips muestran el emoji + cantidad y el propio se resalta cian.

**2. Acciones**
- **Comentarios** (con contador) → abre el sheet de comentarios.
- **Duplicar** → copia el elemento con offset +30px (id y timestamp nuevos,
  autoría del que duplica).
- **Archivar** → el elemento desaparece del canvas y pasa a la vista Archivados.
- **Eliminar** → diálogo de confirmación (rojo) → borra de local y cloud.

### Comentarios
- Sheet con la lista de comentarios: **badge de autor** (F azul / R morado),
  texto, **tiempo relativo** ("hace 2m"), botón **Responder** y **Borrar**
  (solo visible si el comentario es tuyo).
- **Respuestas**: los comentarios pueden responderse entre sí formando hilos;
  las respuestas se muestran indentadas con preview "→ 'texto original'".
- Input de texto abajo con botón enviar (se ajusta al teclado).
- Todo sincroniza en tiempo real.

---

## Organización del Pizarrón

### Header (arriba)
- **Nombre del tablero actual** (modo canvas) o nombre de la vista activa.
- **Cambio de vista**: tap en el nombre cicla **Canvas → Lista → Timeline →
  Archivados → Canvas**.
- **Indicador online**: puntito verde (conectado a Supabase) o rojo (offline).
- Botones: **Tags** (label), **Actividad** (history), **Búsqueda** (search).

### Vistas alternativas
- **Lista**: cards con icono por tipo, título, contenido (2 líneas), tags y badge
  de autor. Tap → navega al elemento en el canvas.
- **Timeline**: orden cronológico inverso, línea vertical con puntos coloreados
  por autor, tiempo relativo por elemento.
- **Archivados**: elementos archivados con botón **Restaurar** (vuelven al canvas).

### Búsqueda
- Busca por **título, contenido y tags** con resultados en vivo.
- Tap en un resultado **cambia al canvas y centra la vista sobre el elemento**.

### Actividad
- Panel con el historial: "Facu creó una nota", "Rocio eliminó un dibujo", etc.,
  con tiempo relativo (últimos 50 registros).

### Tags
- Gestor para crear **tags con color** (8 colores disponibles). Se guardan local
  y quedan disponibles para etiquetar elementos.

---

## Sincronización y Persistencia

### Offline-first
1. Todo cambio se guarda **inmediatamente en SQLite local** (funciona sin internet).
2. Si hay conexión, se sube a **Supabase** (`board_elements_v2` + `boards`).
3. El **Realtime** de Supabase trae los cambios de la pareja al instante.
4. Los movimientos se suben con **debounce de 300ms** para no saturar.

### Datos técnicos por elemento
Cada elemento guarda: tipo, título, contenido, posición x/y, tamaño, rotación,
color, color de texto, fuente y tamaño, alineación, negrita/cursiva/subrayado,
emoji header, tags, prioridad, asignado a, autor, estado, colapsado, bloqueado,
archivado, tablero (board_id), capa (z), data flexible (JSONB: forma, gradiente,
patrón, borde, imagen, audio, strokes, reacciones, comentarios, conexiones),
timestamps y badge NUEVO.

### Colores por usuario (autoría)
Facu = azul `#4FC3F7` · Rocio = morado `#CE93D8` — en badges de autor, timeline,
comentarios y asignaciones.

---

## Reglas de Estilo Visual (obligatorias)

- Fondo sólido, nunca transparente ni semitransparente.
- **Borde del mismo color que el fondo**, siempre.
- Esquinas **redondeadas** (6–20px según tamaño).
- **Prohibido el negro puro** `#000000` (fondo del lienzo: `#0A0A0A`).
- Sin sombras ni degradados suaves.
- Tipografía monoespaciada como base.

---

## Lo que el Pizarrón NO tiene (por decisión)

- Undo/Redo global (Ctrl+Z/Y)
- Atajos de teclado desktop
- Doble tap en espacio vacío para crear nota
- Exportar a PNG/PDF
- Modo presentación, minimapa, kanban

---
*Documento generado el 2026-08-12. Fuente: código `lib/screens/pizarra_v2/` y
`skill-pantallas.md`.*
