# PLAN DE REDISEÑO F.U.R.I — v1.0

Basado en los mandamientos de `Reglas.txt` y `Secciones F.U.R.I..txt`

---

## 0. MANDAMIENTOS (vigilancia constante)

| # | Regla | Implicación |
|---|-------|-------------|
| 1 | Ninguna pantalla puede parecerse a otra | Cada sección: color único, layout único, formas únicas, animaciones únicas |
| 2 | No existe la cuadrícula perfecta | Collage intencional. Prohibido el mismo tamaño/separación |
| 3 | Todo es grande | **Cada sección tiene UN botón/elemento que ocupa ≥30% del ancho.** Jerarquía visual por tamaño |
| 4 | Los iconos son el lenguaje | **CERO texto en botones y labels de navegación. Solo iconos. El texto solo aparece en datos (fechas, montos, nombres).** |
| 5 | Cada sección es un mundo | Mini-app. Distribución, orientación, animaciones, **SONIDOS** distintos |
| — | Bordes negros gruesos, sombras fuertes, esquinas redondeadas | Consistente en todas las secciones |
| — | Tensión visual: **elementos tocándose**, rotados, aire variable | No alineación perfecta. **Cada screen tiene ≥1 par de elementos superpuestos o tangentes** |
| — | Animaciones instantáneas en cada interacción | Rebote, giro, vibración, expansión, inclinación, cambio de color. **Duración máxima: 200ms** |
| — | Sonidos por sección | **Cada sección con SONIDO DISTINTO** (click, pop, golpe, moneda, campana, etc.) |
| — | IA integrada (no chat) | **Nunca un chat. Solo banners/sugerencias contextuales** que aparecen cuando hay algo que decir |
| — | Preferir paneles/tarjetas/widgets flotantes sobre ventanas completas | **Toda acción que no requiera navegación profunda se hace in-place: bottom sheet, popup, panel flotante** |
| — | Estados visibles siempre | **Cada screen maneja: loading, empty, error, data. Nunca pantalla en blanco.** |

---

## 1. AUDITORÍA vs ESTADO ACTUAL

### 1.1 NOSOTROS — ❌ REQUIERE REDISEÑO COMPLETO

**Problemas identificados:**
- Los bloques están en grilla uniforme → viola Regla #2
- No hay un elemento verdaderamente grande que domine → viola Regla #3
- Mucho texto ("← NOSOTROS", labels) → viola Regla #4
- Faltan funciones del spec: línea del tiempo, lugares/mapa, recuerdos, wishlist, contador, IA
- Layout similar al home → viola Regla #5

**Qué conservar:** Lógica de cartas, mood, preguntas (pasar a sub-paneles)

### 1.2 CALENDARIO — ⚠️ REQUIERE REDISEÑO PARCIAL

**Problemas identificados:**
- Las pantallas son Scaffold/ListView/Form estándar → muy convencionales, viola Regla #1 y #5
- Faltan: vista semanal, disponibilidad compartida, sugerencias IA, alarmas/temporizadores
- Sincronización automática: al crear examen → aparece en Estudio; al crear pago → aparece en Finanzas (no implementado)
- Demasiado texto en labels y botones

**Qué conservar:** Lógica de eventos, providers, ScheduleForm (mejorar UI), TableCalendar

### 1.3 PANTALLAS QUE NO EXISTEN (CREAR DESDE CERO)

- **ESTUDIO** — Programación + Gastronomía + Funciones compartidas (Amarillo)
- **FINANZAS** — Ingresos, gastos, deudas, ahorros, gráficos (Verde)
- **GALERÍA** — Fotos, videos, álbumes, etiquetas IA (Rosa)
- **PIZARRA** — Lienzo infinito colaborativo (Verde Neón)
- **TAREAS** — Checklists, prioridades, compartidas (Naranja)
- **FAVORITOS** — Películas, series, libros, wishlist (Azul)

---

## 2. PLAN POR SECCIÓN

### 2.1 NOSOTROS — Coral/Rosa ❤️

**Filosofía visual:** Un tablero emocional. Como un álbum de recortes digital.

```
┌─────────────────────────────────────┐
│  [BOTÓN ATRÁS]        [💬] [🔔]   │  ← Barra superior mínima
├─────────────┬───────────────────────┤
│             │   CONTADOR            │  ← Número GIGANTE de días
│   ÁLBUM     │   "245 días"          │  + próxima fecha especial
│   EMOCIONAL │   🎂 en 12 días       │
│   (foto     │                       │
│   grande)   ├───────────────────────┤
│             │  📍 LUGARES           │  ← Mapa mini interactivo
│             │  Último: [foto]       │
├─────────────┴───────────────────────┤
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐ │
│  │❤️    │ │🎯    │ │⭐    │ │📝  │ │  ← Tarjetas inclinadas
│  │Cartas│ │Metas │ │Favs  │ │Notas│ │    de distintos tamaños
│  └──────┘ └──────┘ └──────┘ └────┘ │
├─────────────────────────────────────┤
│  📜 LÍNEA DEL TIEMPO               │  ← Timeline horizontal
│  ●──●──●──●──●──●──●──●──●        │
│  Primer msg   1er beso   Viaje     │
├─────────────────────────────────────┤
│  💡 IA: "Hace 3 meses visitaron..." │  ← Banner contextual
└─────────────────────────────────────┘
```

**Layout (W×H en fracciones de pantalla):**
- Álbum emocional: bloque enorme arriba a la izquierda (~40% ancho × 45% alto)
- Contador: bloque vertical a la derecha (~55% ancho × 25% alto)
- Lugares: bloque debajo del contador (~55% × 18% alto)
- Tarjetas: fila de 4 tarjetas de tamaños diferentes (una más grande)
- Timeline: horizontal, ocupa todo el ancho (10% alto)
- Banner IA: barra inferior contextual

**Elementos rotados:** Tarjetas de acceso rotadas -3°, +2°, -5°, +4°
**Animaciones:** Contador animado (rebote al cambiar, 150ms), timeline scroll con efecto parallax, fotos del álbum hacen scale-up al tap (200ms)
**Sonido:** Pop suave al abrir cartas · click metálico al cambiar contador · swoosh al scroll de timeline
**Estados:** Loading = skeletons de álbum y contador · Empty = "🌟 Todavía no hay recuerdos" con icono grande centrado · Error = banner "💔 No pudimos cargar" con reintentar
**Acciones in-place:** Cartas, metas, wishlist → bottom sheet. Lugares → panel flotante. Solo timeline → navegación completa

---

### 2.2 CALENDARIO — Celeste 🩵

**Filosofía visual:** Un planificador de pared. Agenda visual.

```
┌─────────────────────────────────────┐
│  [←]  MARZO 2026  [→]   [+][🔍]  │  ← Header robusto
├─────────────────────────────────────┤
│  📅 TABLECALENDAR (mensual)        │  ← Ocupa 40% altura
│  con dots de colores                │
├───────────┬─────────────────────────┤
│  VISTA    │ 📋 EVENTOS DEL DÍA     │  ← Lista vertical
│  SEMANAL  │ ┌──────────────────┐   │    con tarjetas
│  (mini    │ │ 🎓 Examen Mate   │   │    de distintos
│   strip)  │ │ 10:30 - 12:00    │   │    tamaños según
│           │ └──────────────────┘   │    importancia
│           │ ┌────────────────┐     │
│           │ │💼 Trabajo      │     │
│           │ └────────────────┘     │
├───────────┴─────────────────────────┤
│  🎯 HOY: 3 eventos • 📚 Examen en 2d│  ← IA banner
│  💡 IA: "Tienen espacio libre..."   │
└─────────────────────────────────────┘
```

**Layout:**
- TableCalendar: enorme (45% altura, ancho completo)
- Mini strip semanal a la izquierda (15% ancho, 40% altura)
- Eventos del día a la derecha, scroll vertical (85% ancho)
- IA/banner inferior (10% altura)

**Elementos rotados:** Strip semanal rotado -2°, algunos eventos inclinados +3°
**Animaciones:** Transición entre meses con slide horizontal (150ms), eventos aparecen con fade+scale (100ms), dots pulsan suavemente
**Sonido:** Tick de reloj al cambiar día · swoosh al cambiar mes · pop al crear evento
**Estados:** Loading = calendario esqueleto con dots grises · Empty = "🎉 Sin eventos" con celebración · Error = banner "📡 Sin conexión" con botón retry
**Acciones in-place:** Crear/editar evento → bottom sheet (no push). Tipos de evento → panel flotante lateral. Countdown → widget siempre visible flotando

**Iconos replace:** Eliminar texto "MARZO 2026" → solo icono 📅 + flechas. Eventos: 🎓, 💼, ✈️, 🏠, 🎂 (sin texto de categoría). Botón "+" es enorme (>40% ancho).
**Tensión visual:** El strip semanal se toca con el calendario mensual (tangentes). El countdown flota sobre la lista de eventos (superposición intencional).

**Mejoras sobre actual:**
- Agregar vista semanal (strip lateral que al tap cambia el mes)
- Botón de tipos de evento integrado visualmente (no en diálogo aparte)
- Calendario compartido: mostrar eventos de ambos con bordes de distinto color
- Countdown widget flotante con IA
- IA: sugerencias de espacios libres

---

### 2.3 ESTUDIO — Amarillo 💛

**Filosofía visual:** Un escritorio de estudio. Dos caras: Programación | Gastronomía.

```
┌─────────────────────────────────────┐
│  [←]      ESTUDIO       [👤]      │  ← Header
├─────────────────────────────────────┤
│  ┌──────────┐  ┌──────────────────┐ │
│  │  💻      │  │    POMODORO      │ │
│  │ PROG     │  │  25:00 ⏱️       │ │
│  │          │  │  ─────────────   │ │
│  │ ██████   │  │  Racha: 7 días 🔥│ │
│  │ 65% meta │  │  Hoy: 2h 15m    │ │
│  └──────────┘  └──────────────────┘ │
├─────────────────────────────────────┤
│  ┌──────┐┌──────┐┌──────┐┌──────┐ │
│  │📝    ││📚    ││🎯    ││📊    │ │  ← 4 cards tamaño
│  │Notas ││Flash  ││Retos ││Prog  │ │    variado, rotadas
│  └──────┘└──────┘└──────┘└──────┘ │
├─────────────────────────────────────┤
│  🍳 GASTRONOMÍA                     │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐      │  ← Sección separada
│  │📖  │ │🧮  │ │⏱️  │ │📝  │      │    visualmente
│  │Rec │ │Conv│ │Temp│ │Not │      │
│  └────┘ └────┘ └────┘ └────┘      │
├─────────────────────────────────────┤
│  💡 IA: "Llevas 3 días sin..."      │
└─────────────────────────────────────┘
```

**Dos sub-secciones:**
- **PROGRAMACIÓN:** Editor código, retos, notas técnicas, cheatsheets, snippets
- **GASTRONOMÍA:** Recetas, ingredientes, técnicas, temporizadores, conversor

**Elementos rotados:** Tarjetas de acceso rotadas -7°, +4°, -3°, +6°. Pomodoro inclinado -2°
**Animaciones:** Pomodoro con cuenta regresiva animada (escala digital), cambio de materia con slide vertical (150ms), racha con fire animation
**Sonido:** Tic-tac de reloj durante pomodoro · campana al terminar · click de teclado en programación · swoosh al cambiar materia
**Estados:** Loading = tiempo en blanco con círculo pulsante · Empty = "📚 Elegí una materia" con icono · Error = "⚠️ No se pudo cargar" con retry
**Acciones in-place:** Flashcards, notas → bottom sheet. Editor de código → panel expandible. Pomodoro siempre visible (widget flotante)
**Iconos replace:** "PROGRAMACIÓN" → 💻. "GASTRONOMÍA" → 🍳. "Notas" → 📝. "Flash" → 🃏. "Retos" → 🎯. "Prog" → 📊. "Rec" → 📖. "Conv" → 🧮. "Temp" → ⏱️. Racha → 🔥. Tiempo → ⏰. Usuario activo → 👤. **CERO texto decorativo.**
**Tensión visual:** Pomodoro flotante se superpone parcialmente con la tarjeta de PROGRAMACIÓN. Las cards de funciones compartidas se tocan entre sí formando un collage.

**Cada usuario tiene su propio espacio** (toggle 👤 cambia entre "Facu" y "Rocio")

**Layout único:** Split horizontal con programación arriba (55%), gastronomía abajo (35%), pomodoro flotante en esquina

---

### 2.4 FINANZAS — Verde 💚

**Filosofía visual:** Un libro de cuentas brutalista. Dashboard financiero.

```
┌─────────────────────────────────────┐
│  [←]  FINANZAS          [+]/[−]   │
├─────────────────────────────────────┤
│  ┌────────────────────────────────┐ │
│  │    $  formateado               │ │  ← Saldo GIGANTE
│  │    +$120,000     −$85,000      │ │
│  │    ━━━━━━━━━━━━━━━━━━━━━━━━   │ │
│  │    ████████████░░░  64%        │ │
│  └────────────────────────────────┘ │
├────────────────┬────────────────────┤
│  GASTOS       │  GRÁFICO           │
│  ┌──────────┐ │  ┌──────────────┐  │
│  │🍕 $45k   │ │  │   🥧        │  │
│  │🚗 $30k   │ │  │   donut     │  │
│  │🏠 $120k  │ │  │   chart     │  │
│  └──────────┘ │  └──────────────┘  │
├────────────────┴────────────────────┤
│  ┌──────┐┌──────┐┌──────┐┌──────┐ │
│  │💰    ││💳    ││🎯    ││📊    │ │  ← Metas, deudas,
│  │Ahorro││Deudas││Metas ││Hist  │ │    presupuestos, hist.
│  └──────┘└──────┘└──────┘└──────┘ │
│  💡 IA: "Este mes gastaron 20% más"│
└─────────────────────────────────────┘
```

**Elementos rotados:** Gráfico donut rotado +3°. Tarjetas de acceso rotadas -5°, +4°, -2°, +6°
**Animaciones:** Saldo animado con contador ascendente (200ms). Gráfico donut animado al cargar. Gastos aparecen con slide-up (100ms)
**Sonido:** Sonido de moneda al agregar gasto/ingreso · papel al tachar deuda · click metálico en saldo
**Estados:** Loading = saldo shimmer + donut skeleton · Empty = "💰 Empezá a registrar" con icono · Error = "📊 Sin datos" con retry
**Acciones in-place:** Agregar gasto/ingreso → bottom sheet con teclado numérico. Ver detalle → panel expandible. Metas → bottom sheet.
**Iconos replace:** Sueldo → 💼. Comida → 🍕. Transporte → 🚗. Casa → 🏠. Ahorro → 🏦. Deudas → 💳. Metas → 🎯. Historial → 📊. Suscripciones → 📺. **Números sí (son datos), labels no.**
**Tensión visual:** La lista de gastos se toca con el borde del gráfico. El botón "+" y "−" están superpuestos parcialmente sobre el saldo.

**Layout:**
- Saldo: bloque dominante arriba (25% altura) con números enormes (fuente peso 900)
- Gastos recientes: columna izquierda (40% ancho)
- Gráfico: columna derecha con donut/pastel (55% ancho)
- Tarjetas de acceso: fila inferior con metas, deudas, presupuestos
- IA: alerta financiera contextual

---

### 2.5 GALERÍA — Rosa 🩷

**Filosofía visual:** Un mosaico de Polaroids. Álbum vivo.

```
┌─────────────────────────────────────┐
│  [←]  GALERÍA            [🔍]     │
├─────────────────────────────────────┤
│  ┌────┬────┬────┬────┬────┬────┐   │
│  │📸  │📸  │📸  │📸  │📸  │📸  │   │  ← Grid de fotos
│  │    │    │    │    │    │    │   │    (Polaroid style)
│  ├────┼────┼────┼────┼────┼────┤   │    algunas rotadas
│  │📸  │📸  │📸  │📸  │📸  │📸  │   │
│  │    │    │    │    │    │    │   │
│  └────┴────┴────┴────┴────┴────┘   │
├─────────────────────────────────────┤
│  📂 ÁLBUMES                        │  ← Scroll horizontal
│  [Vacaciones] [Casa] [Comida] [+] │
├─────────────────────────────────────┤
│  💡 IA: "Álbum sugerido: Otoño 2025"│
└─────────────────────────────────────┘
```

**Elementos rotados:** Polaroids rotados aleatoriamente -8° a +8°. Una foto destacada cada fila es 2x más grande.
**Animaciones:** Fotos aparecen con scale-in (150ms) escalonado. Álbumes scroll horizontal con snap. Favorito con animación de estrella (100ms)
**Sonido:** Click de cámara al abrir · sonido de álbum al pasar página · pop al marcar favorito
**Estados:** Loading = grid de skeletons tipo Polaroid · Empty = "📸 Subí tu primera foto" con icono · Error = "🖼️ No pudimos cargar" con retry
**Acciones in-place:** Marcar favorito, agregar a álbum → popup inline. Vista ampliada → overlay (no push). Búsqueda → barra que se expande desde icono 🔍
**Iconos replace:** Favoritos → ⭐. Álbumes → 📂. Personas → 👥. Lugares → 📍. Búsqueda → 🔍. **CERO texto en botones. Solo números de fotos.**
**Tensión visual:** Polaroids se superponen ligeramente. Álbumes en scroll horizontal cortan el borde inferior del grid de fotos.

**Layout:**
- Grid mosaico de fotos con Polaroid style (borde blanco, sombra, rotación aleatoria)
- Álbumes en tira horizontal abajo
- AI tags y búsqueda por lenguaje natural
- Al tap una foto: vista ampliada con opciones (favorito, álbum, info)
- Algunas fotos más grandes que otras (romper grilla)

---

### 2.6 PIZARRA — Verde Neón 💚

**Filosofía visual:** Pizarra infinita. Caos creativo.

```
┌─────────────────────────────────────┐
│  [←]  PIZARRA         [+] [🔗]    │
├─────────────────────────────────────┤
│                                     │
│    ┌──────────┐                     │
│    │ Nota 📝   │    ┌──────────┐   │  ← Espacio infinito
│    │ "Comprar" │    │ Dibujo   │   │    con elementos
│    └──────────┘    │ 🎨       │   │    flotantes
│                     └──────────┘   │
│          ┌────────────────┐        │
│          │  Post-it 💡    │        │  ← Elementos
│          │  "Idea!"       │        │    conectados
│          └────────────────┘        │    con flechas
│         ╱                          │
│    ┌───╱────────────────────┐      │
│    │ 🖼️ Foto                │      │
│    └────────────────────────┘      │
│                                     │
├─────────────────────────────────────┤
│  💡 IA: "Resumir pizarra..."        │
└─────────────────────────────────────┘
```

**Elementos rotados:** El canvas mismo permite rotación libre. Post-its aparecen con rotación aleatoria ±15°.
**Animaciones:** Elementos aparecen con pop (100ms). Flechas se dibujan animadas. Zoom con inertia. Elementos tienen bounce al soltarlos.
**Sonido:** Marcador al dibujar · pop-up al crear nota · rasgado al eliminar post-it · click magnético al conectar flechas
**Estados:** Loading = canvas con grilla tenue · Empty = "✏️ Tocá + para empezar" con icono grande en centro · Error = "🎨 No se pudo guardar" con toast
**Acciones in-place:** TODAS in-place. Es un canvas. No hay navegación. Herramientas en barra flotante. Propiedades de elemento en panel contextual que aparece al tap.
**Iconos replace:** Nota → 📝. Dibujo → 🎨. Post-it → 💡. Foto → 🖼️. Flecha → ➡️. PDF → 📄. Zoom → 🔍➕/➖. Mover → ✋. Eliminar → 🗑️. **CERO texto en herramientas.**
**Tensión visual:** Elementos se superponen intencionalmente (caos controlado). La barra de herramientas flota sobre el canvas. Post-its de distintos tamaños se tocan.

**Layout:** Canvas interactivo con zoom. No hay layout fijo — el usuario lo crea.
- Barra de herramientas flotante (abajo o lateral): nota, dibujo, post-it, foto, flecha, PDF
- Elementos se pueden mover, rotar, redimensionar
- Conexiones con flechas entre elementos
- IA: botón "Resumir" que analiza todo y genera resumen

---

### 2.7 TAREAS — Naranja 🟧

**Filosofía visual:** Tablero Kanban brutalista.

```
┌─────────────────────────────────────┐
│  [←]  TAREAS            [+]       │
├──────────┬──────────┬───────────────┤
│  URGENTE │   HOY    │   SEMANA     │  ← 3 columnas
│  ┌────┐  │ ┌────┐  │ ┌────┐       │    como Kanban
│  │📋  │  │ │📋  │  │ │📋  │       │
│  │... │  │ │... │  │ │... │       │
│  └────┘  │ └────┘  │ └────┘       │
│  ┌────┐  │         │ ┌────┐       │
│  │📋  │  │         │ │📋  │       │
│  └────┘  │         │ └────┘       │
├──────────┴──────────┴───────────────┤
│  👤 Tuyas · Compartidas · Asignadas │  ← Filtros
│  💡 IA: "Tarea urgente olvidada..." │
└─────────────────────────────────────┘
```

**Elementos rotados:** Columna "Urgente" ligeramente rotada -1° (destaca). Tarjetas de tarea rotadas individualmente +2°, -3°, etc.
**Animaciones:** Tarea completada → check animado + fade-out (150ms, no desaparece, se tacha). Mover entre columnas → drag con feedback visual. Contador decrece con bounce (100ms)
**Sonido:** Check al completar · papel al mover tarea · alerta urgente (sonido más agudo) · click al cambiar filtro
**Estados:** Loading = 3 columnas skeleton · Empty = "🎉 Todo al día" (si 0 tareas) · Error = "📋 No se pudieron cargar" con retry
**Acciones in-place:** Crear tarea → bottom sheet. Editar → panel lateral que se desliza. Cambiar prioridad → drag entre columnas. Filtros → chips inline.
**Iconos replace:** "URGENTE" → 🔴 (color rojo + icono ⚠️). "HOY" → 🟠 (naranja + 📅). "SEMANA" → 🟡 (amarillo + 📆). Filtros: Tuyas → 👤, Compartidas → 👥, Asignadas → 📋. Prioridad → 🔥 urgente, ⭐ normal, 💤 baja. **CERO texto en columnas y filtros, solo color+icono.**
**Tensión visual:** Las columnas tienen distinto ancho (Urgente más angosta, Hoy más ancha). Tarjetas en columna "Hoy" se tocan entre sí. El contador de pendientes cuelga sobre el borde superior.

**Layout:**
- 3 columnas Kanban de distinto ancho: Urgente (20%) | Hoy (45%) | Semana (35%)
- Cada tarea: tarjeta con checkbox, prioridad (color+icono), tiempo estimado
- Arriba: contador de tareas pendientes como número gigante
- Filtros: 👤 / 👥 / 📋 (chips inline, solo iconos)
- IA: reorganiza prioridades automáticamente (banner 💡)

---

### 2.8 FAVORITOS — Azul 💙

**Filosofía visual:** Estantería de coleccionista.

```
┌─────────────────────────────────────┐
│  [←]  FAVORITOS         [🔍] [+]
├─────────────────────────────────────┤
│  🎬 PELÍCULAS                       │  ← Categoría con
│  ┌────┬────┬────┬────┬────┬────┐  │    estante horizontal
│  │🎥  │🎥  │🎥  │🎥  │🎥  │🎥  │  │
│  │Tit │Tit │Tit │Tit │Tit │Tit │  │
│  └────┴────┴────┴────┴────┴────┘  │
├─────────────────────────────────────┤
│  📚 SERIES                          │
│  ┌────┬────┬────┬────┬────┐       │
│  │📺  │📺  │📺  │📺  │📺  │       │
│  └────┴────┴────┴────┴────┘       │
├─────────────────────────────────────┤
│  🎮 JUEGOS  📖 LIBROS  🍽️ LUGARES  │  ← Tabs compactos
│  💡 IA: "A ella le gustó..."        │
└─────────────────────────────────────┘
```

**Elementos rotados:** Algunos items en los estantes rotados +2°, -4°, etc. (como discos en una estantería real). Wishlist con inclinación general -2°.
**Animaciones:** Scroll horizontal con snap por estante. Items aparecen con slide-up escalonado (100ms). Favorito late (heartbeat 200ms)
**Sonido:** Estante deslizándose · pop al agregar favorito · click metálico al tachar wishlist
**Estados:** Loading = estantes skeleton · Empty = "⭐ Empezá a guardar" con icono por categoría · Error = "📚 No se pudieron cargar" con retry
**Acciones in-place:** Agregar → bottom sheet con selector de categoría. Marcar favorito → heart animado inline. Wishlist → tachar con tap. Búsqueda → overlay desde icono 🔍.
**Iconos replace:** Películas → 🎬. Series → 📺. Anime → 🎌. Canciones → 🎵. Juegos → 🎮. Libros → 📖. Recetas → 🍳. Restaurantes → 🍽️. Lugares → 📍. Videos → 🎥. Canales → 📡. Wishlist → ⭐⭐⭐. **CERO texto en categorías, solo icono+color.**
**Tensión visual:** Los estantes tienen distinta longitud (no todos iguales). Items sobresalen del borde del estante. La wishlist flota sobre el borde inferior como sticky.

**Layout:**
- Estantes horizontales por categoría (scroll horizontal), cada uno de distinta longitud
- Cada ítem: tarjeta con icono grande + título ultra-corto (1-2 palabras)
- Wishlist: estante flotante sticky al final (⭐⭐⭐)
- Búsqueda y filtros por icono
- IA: banner 💡 "A ambos les gustó X"

---

## 3. CRUZANDO LOS MANDAMIENTOS (verificación)

| Pantalla | R1 (única) | R2 (no grilla) | R3 (grande) | R4 (iconos) | R5 (mini-app) |
|----------|-----------|---------------|-------------|-------------|---------------|
| Nosotros | ✅ Álbum recortes | ✅ Tarjetas rotadas tamaños mixtos | ✅ Contador gigante + álbum grande | ✅ Iconos emocionales | ✅ Tablero emocional |
| Calendario | ✅ Agenda visual | ✅ Strip + lista asimétrica | ✅ Calendario enorme | ✅ Dots de color | ✅ Planificador de pared |
| Estudio | ✅ Escritorio split | ✅ Pomodoro flotante + cards rotadas | ✅ Pomodoro grande | ✅ Iconos de materia | ✅ Escritorio personal |
| Finanzas | ✅ Dashboard financiero | ✅ Split asimétrico + gráfico | ✅ Saldo enorme | ✅ Flechas de ingreso/gasto | ✅ Libro de cuentas |
| Galería | ✅ Mosaico Polaroid | ✅ Rotación aleatoria + tamaños mixtos | ✅ Foto destacada grande | ✅ Miniaturas | ✅ Álbum vivo |
| Pizarra | ✅ Canvas infinito | ✅ Caos intencional | ✅ Elementos redimensionables | ✅ Iconos de herramientas | ✅ Pizarra física |
| Tareas | ✅ Kanban brutalista | ✅ 3 columnas de distinto ancho | ✅ Tarea urgente destacada | ✅ Iconos de prioridad | ✅ Tablero físico |
| Favoritos | ✅ Estantería | ✅ Estantes de distinta longitud | ✅ Items grandes | ✅ Covers/posters | ✅ Colección física |

---

## 4. SINCRONIZACIÓN ENTRE SECCIONES

Según `Secciones F.U.R.I..txt`:

| Acción | Origen | Aparece en | Estado |
|--------|--------|-----------|--------|
| Crear examen | Calendario | Estudio | ⏳ Pendiente |
| Crear pago | Calendario | Finanzas | ⏳ Pendiente |
| Foto subida | Galería | Nosotros | ⏳ Pendiente |
| Fecha especial | Nosotros | Calendario | ⏳ Pendiente |
| Deuda creada | Finanzas | Tareas | ⏳ Pendiente |

**Implementación:** Event bus o callbacks en los providers. Cuando se crea un recurso en una sección, se emite un evento que las otras secciones escuchan.

---

## 5. ARQUITECTURA TÉCNICA

### 5.1 Providers necesarios
```
providers/
├── schedule_provider.dart         ✓ (mejorar)
├── event_type_provider.dart       ✓
├── class_schedule_provider.dart   ✓
├── class_type_provider.dart       ✓
├── theme_provider.dart            ✓
├── study_provider.dart            ✗ CREAR
├── finance_provider.dart           ✗ CREAR
├── gallery_provider.dart           ✗ CREAR
├── board_provider.dart            ✓ (mejorar)
├── tasks_provider.dart             ✗ CREAR
├── favorites_provider.dart         ✗ CREAR
├── sync_provider.dart              ✗ CREAR (event bus)
```

### 5.2 Nuevas tablas Supabase necesarias
- `study_sessions` — tiempo estudiado, materia, tipo
- `study_notes` — apuntes con código/recetas
- `flashcards` — tarjetas de estudio
- `transactions` — ingresos/gastos
- `budgets` — presupuestos
- `debts` — deudas
- `savings_goals` — metas de ahorro
- `photos` — fotos con metadatos
- `albums` — álbumes
- `board_elements` — elementos de pizarra
- `tasks` — tareas
- `favorites` — favoritos por categoría
- `wishlist` — lista de deseos
- `places` — lugares guardados
- `memories` — recuerdos
- `timeline_events` — eventos de línea temporal

### 5.3 Navegación
El home debe conectar a cada sección. Cada sección es una pantalla independiente con:
- AppBar mínima o inexistente (solo botón atrás + acciones esenciales)
- Layout propio
- Sin NavigationBar ni BottomNav (cada sección es su propio mundo)

---

## 6. PRIORIDAD DE IMPLEMENTACIÓN

### Fase 1 — Fundación (hacer que todo compile y navegue)
1. Crear estructura de carpetas para nuevas secciones
2. Crear `sync_provider.dart` (event bus)
3. Crear screens placeholder para cada sección (que naveguen desde home)
4. Verificar que todo compila

### Fase 2 — Pantallas existentes (rediseñar)
5. Rediseñar **NOSOTROS** (layout collage, contador, timeline, lugares)
6. Rediseñar **CALENDARIO** (vista semanal, shared calendar, IA)

### Fase 3 — Pantallas nuevas (core)
7. Crear **TAREAS** (kanban, prioridades, compartidas)
8. Crear **ESTUDIO** (pomodoro, prog, gastro, flashcards)
9. Crear **FINANZAS** (dashboard, ingresos/gastos, gráficos)

### Fase 4 — Pantallas nuevas (media)
10. Crear **GALERÍA** (fotos, álbumes, IA tags)
11. Crear **FAVORITOS** (estanterías, wishlist)

### Fase 5 — Experiencia
12. Crear **PIZARRA** (canvas infinito, colaboración)
13. Integrar IA en todas las secciones
14. Sincronización automática entre secciones
15. Animaciones y sonidos por sección

---

## 7. VERIFICACIÓN CONTRA MANDAMIENTOS (re-lectura)

Al releer los TXT después del plan:

**Ajustes APLICADOS al plan:**
1. ✅ Cada sección tiene AL MENOS UN widget rotado/inclinado (detallado por sección)
2. ✅ Cada sección tiene elementos tangentes/superpuestos (tensión visual detallada)
3. ✅ Sonidos distintos por sección especificados (click, pop, moneda, campana, tic-tac, etc.)
4. ✅ IA solo como banner/sugerencia contextual, nunca chat
5. ✅ Prohibido texto decorativo — todo reemplazado por iconos en cada sección
6. ✅ Botón de acción principal enorme (≥30% ancho) en cada sección
7. ✅ Layouts únicos verificados — ningún layout se repite entre secciones

**Bug prevention system (aplicar en cada screen):**

**Estado TRIPLE obligatorio:**
```
┌─────────────────────┐
│ LOADING             │  ← Shimmer/skeleton con la forma de la pantalla
│ ┌──────────────────┐│      (no spinner genérico)
│ │ ████ ████ ████   ││
│ │ ████ ████ ████   ││
│ └──────────────────┘│
├─────────────────────┤
│ EMPTY               │  ← Icono grande + mensaje corto + CTA
│   📭                │      (nunca pantalla blanca)
│ "Sin eventos"       │
│   [+]                │
├─────────────────────┤
│ ERROR               │  ← Banner con icono + mensaje + botón retry
│ ⚠️ "No cargó" [↻]  │      (nunca pantalla rota/blanca)
└─────────────────────┘
```

**Validación obligatoria:**
- Todo formulario valida antes de enviar (campos requeridos, formatos)
- Feedback visual inmediato: border rojo + shake en campo inválido (150ms)
- Botón de submit deshabilitado mientras no sea válido (opacidad 50%)

**Optimistic UI obligatoria en:**
- Tachar tarea (check inmediato, rollback si error)
- Marcar favorito (corazón cambia al instante)
- Posts en pizarra (aparecen al instante)
- Likes/reacciones

**Sync entre secciones (anti-bug):**
- Usar `SyncProvider` como event bus
- Eventos asíncronos: emisor no espera respuesta
- Cola de eventos con reintento (3 intentos, backoff 1s/2s/4s)
- Timeout global de 10s en llamadas Supabase
- Si falla sync, se muestra toast silencioso y se reintenta en background

**Estructura de código (anti-bug):**
```dart
// Cada screen sigue este patrón:
class SeccionScreen extends StatefulWidget { ... }

class _SeccionScreenState extends State<SeccionScreen> {
  // 1. Estados
  bool _loading = true;
  String? _error;
  List<Data> _data = [];

  // 2. Init: cargar datos
  @override void initState() { ... _load(); }

  // 3. Load: try/catch con timeout
  Future<void> _load() async { ... }

  // 4. Build: switch loading/error/empty/data
  @override Widget build(BuildContext context) {
    if (_loading) return _skeleton();
    if (_error != null) return _errorView();
    if (_data.isEmpty) return _emptyView();
    return _content();
  }

  // 5. Cada vista visible
  Widget _skeleton() => ...;  // shimmer con forma de la pantalla
  Widget _errorView() => ...; // icono + mensaje + retry
  Widget _emptyView() => ...; // icono + mensaje + CTA
  Widget _content() => ...;   // la pantalla real
}
```

**Timeouts:**
- Toda llamada a Supabase: timeout 10s
- Toda animación: duración ≤200ms
- Toda operación sync: timeout 5s con retry 3 veces
- Toda respuesta IA: timeout 15s con loading skeleton

---

*Documento generado el 27/07/2026 — Próxima revisión al completar Fase 1*
