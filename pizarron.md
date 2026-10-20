# Pizarrón Infinito — Documentación Completa

> Documentación de referencia del Pizarrón Infinito de F.U.R.I (`lib/screens/milanote/`).

---

## 1. Arquitectura del Lienzo Infinito y Carga en Chunks (2x Viewport)

- **Coordenadas Infinitas**: El lienzo no tiene muros ni límites finitos (`-∞` a `+∞`).
- **Carga en Chunks (2x Viewport)**:
  - En cada frame de cámara (`_cameraPan`, `_cameraScale`), `MilanoteScreen` calcula el rectángulo visible del mundo y lo expande al **doble (2x) de lo mostrado en pantalla** (`_computeActiveChunkWorldRect`).
  - `BoardDataProvider.getInteractiveElementsInChunk` y `getChalkStrokesInChunk` filtran en memoria solo los objetos e ilustraciones de tiza que intersectan el chunk activo.
- **Fondo Sólido Personalizable + Dibujo de Tiza en el Fondo (`BoardChalkBackgroundPainter`)**:
  - El color sólido del pizarrón es personalizable y se sincroniza en tiempo real (`type: 'board_config'`).
  - Los trazos de tiza (`type: 'chalk_stroke'`) se renderizan en la **capa de fondo del pizarrón** (debajo de todas las notas) con textura porosa y granulado determinístico de tiza, por lo que jamás bloquean ni bugean la navegación ni el arrastre de notas.

---

## 2. Interfaz Minimalista de Un Único Botón (100% Iconos, Cero Popups)

- Al entrar al pizarrón no hay barras superiores ni indicadores flotantes: **solo un botón `+` de color verde opaco vibrante (`#2EE50F`) abajo a la derecha**.
- Al tocar el botón `+` se despliegan 3 opciones representadas únicamente por iconos:
  1. **Nota** (`Icons.sticky_note_2_rounded`)
  2. **Lista de tareas** (`Icons.checklist_rounded`)
  3. **Tuerca / Ajustes** (`Icons.settings_rounded`) — despliega el selector de color sólido del fondo del pizarrón y las herramientas de dibujo con tiza en el fondo.

---

## 3. Interacción, Desambiguación Multitáctil y Edición en el Mismo Objeto

- **Mismo Objeto en Pizarrón y Edición (`PizarronNoteWidget`)**:
  - La tarjeta que se ve en el pizarrón y la que se edita son **exactamente el mismo widget**, sin diferencias visuales ni botones de ajuste internos dentro de la nota.
  - Al tocar una nota una sola vez, la cámara hace un **zoom suave hacia la nota** y abre la **barra lateral derecha de personalización (`PizarronSidebarOverlay`)**.
- **Fluidez 1:1 Independiente del Zoom**:
  - Al arrastrar una nota, el desplazamiento en el mundo se calcula dividiendo el delta de pantalla por `_cameraScale` en vivo, manteniendo velocidad 1:1 con el dedo tanto con zoom alejado como con zoom máximo.
- **Desambiguación Multitáctil**:
  - **1 dedo sobre el fondo vacío**: desplaza el pizarrón (o dibuja con tiza si el modo tiza está activo).
  - **1 dedo arrastrando una nota**: mueve únicamente esa nota.
  - **2 dedos sobre la misma nota**: agranda o achica la nota incrementalmente desde todos sus lados de forma simétrica.
  - **2 dedos en el pizarrón (incluso si un dedo toca una nota por accidente)**: cancela cualquier movimiento de la nota e interpreta el gesto como zoom/paneo del pizarrón.

---

## 4. Sistema de Personalización de Notas (`NoteStyleConfig`)

### Capa 1 — Fondo Base
- **Color sólido**: paleta de 20 colores curados (sin negro puro `#000000`).
- **Degradado de 3 partes**: selección independiente del color inicial, color del medio y color final, más dirección angular (`0°`, `45°`, `90°`, `135°`).
- **Foto de fondo**: imagen desde galería recortada a la forma de la nota con control de opacidad.
- **Brillo animado**: toggle opcional de destello diagonal animado sobre la tarjeta.

### Capa 2 — Patrones (con controles contextuales según el patrón)
- **Patrones disponibles**:
  - `chess` (Ajedrez): tamaño de bloque, color/degradado, opacidad (**sin espaciado ni relleno**, ya que los bloques van juntos).
  - `linesOblique`, `linesHorizontal`, `linesVertical` (Líneas): grosor, espaciado, color/degradado, opacidad (**sin relleno**).
  - `waves` (Ondas): grosor, espaciado, amplitud/escala, color/degradado, opacidad.
  - `circlesFilled` y `circlesEmpty` (Círculos rellenos y vacíos): tamaño, espaciado, toggle relleno/vacío, grosor (en vacíos), color/degradado, opacidad.
  - `dots` (Puntos), `grid` (Cuadrícula) y `emoji` (Emojis o texto corto repetido en patrón).

### Formas (11 Formas con Padding Inscrito y Esquina de Estiramiento Adaptativa)
- `square`, `rounded`, `note` (esquina doblada), `paper` (papel ondulado), `leaf` (hoja orgánica), `circle`, `diamond` (rombo), `hexagon`, `octagon`, `shield` (escudo), `tag` (etiqueta).
- **Encaje de contenido**: `NoteShapeUtils.getContentPadding` calcula el margen inscrito para que el texto y las imágenes se centren y ajusten dentro de rombos, círculos, octágonos, hojas, etc.
- **Esquina de redimensionado adaptativa**: `NoteShapeUtils.getResizeHandleCenter` ubica la zona de estiramiento inferior-derecha sobre el perímetro geométrico real de cada forma.

### Bordes (6 Tipos sobre el `Path` de la Forma)
- `none`, `solid`, `dotted` (punteado), `dashed` (rayas), `doubleLine` (doble línea), `wavy` (ondulado), con controles de grosor, espaciado y color.

### Tipografía, Formatos de Bloque e Imagen Integrada
- **22 Fuentes de Google Fonts**: `Plus Jakarta Sans`, `Space Mono`, `Syne`, `Pacifico`, `Caveat`, `Permanent Marker`, `Press Start 2P`, `Cinzel`, `Abril Fatface`, `Righteous`, `Orbitron`, `Monoton`, `Bungee`, `Creepster`, `Special Elite`, `Sacramento`, `Shadows Into Light`, `Bebas Neue`, `Lobster`, `UnifrakturMaguntia`, `VT323`, `Comfortaa`.
- **Estilos independientes por bloque**: Título y cada párrafo del cuerpo pueden tener su propia fuente, tamaño, color y formato decorativo:
  - `escuadra` (línea vertical derecha + línea horizontal inferior gruesa)
  - `escuadraLeft` (línea vertical izquierda + línea horizontal inferior)
  - `thickUnderline` (subrayado grueso)
  - `topBottomLines` (líneas superior e inferior)
  - `sunken` (bloque hundido con fondo oscuro y sombreado interno)
  - `quoteBar` (barra lateral)
  - `framed` (marco completo)
- **Imagen integrada en la nota (`InlineImagePosition`)**:
  - `aboveBody` (arriba del texto del cuerpo)
  - `middleBody` (en el medio del texto del cuerpo)
  - `belowBody` (abajo del texto del cuerpo)
  - `footer` (en el pie de página de la tarjeta)
