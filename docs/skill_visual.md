# Skill Visual - Guía de Estilo Oficial de F.U.R.I

Guía obligatoria y no-negociable para toda la interfaz visual de F.U.R.I.

---

## 🚨 MANDATO FUNDAMENTAL (REGLA DE ORO)

> ### REPETICIÓN 1: PRINCIPIO GENERAL
> **NO QUIERO BORDES EN NINGÚN LADO. CADA COSA DEBE TENER UN SOLO COLOR Y TONO. NADA DE RELLENOS Y BORDES DE DISTINTO COLOR. UN SOLO COLOR Y SIN BORDES: BLOQUES DE LITERALMENTE UN SOLO COLOR Y TONALIDAD CADA UNO, EXACTAMENTE COMO SE VE EN EL INICIO.**

> ### REPETICIÓN 2: EN BOTONES Y ACCIONES
> **NO QUIERO BORDES EN NINGÚN LADO. CADA BOTÓN DEBE TENER UN SOLO COLOR Y TONO. NADA DE RELLENOS Y BORDES DE DISTINTO COLOR EN UN MISMO BOTÓN. UN SOLO COLOR Y SIN BORDES: CADA BOTÓN ES UN BLOQUE DE UN SOLO COLOR SÓLIDO Y TONALIDAD ÚNICA, EXACTAMENTE COMO SE VE EN EL INICIO.**

> ### REPETICIÓN 3: EN CARDS, PANELES Y MODALES
> **NO QUIERO BORDES EN NINGÚN LADO. CADA CARD O PANEL DEBE TENER UN SOLO COLOR Y TONO. NADA DE RELLENOS Y BORDES DE DISTINTO COLOR. UN SOLO COLOR Y SIN BORDES: TARJETAS Y BLOQUES DE LITERALMENTE UN SOLO COLOR Y TONALIDAD CADA UNO, EXACTAMENTE COMO SE VE EN EL INICIO.**

> ### REPETICIÓN 4: RESUMEN NO NEGOCIABLE
> **NO QUIERO BORDES EN NINGÚN LADO. CADA ELEMENTO TIENE UN SOLO COLOR Y TONO. NADA DE RELLENOS Y BORDES DE DISTINTO COLOR. UN SOLO COLOR Y SIN BORDES: BLOQUES DE LITERALMENTE UN SOLO COLOR Y TONALIDAD CADA UNO, EXACTAMENTE COMO SE VE EN EL INICIO.**

---

## Reglas Técnicas de Implementación en Flutter

### 1. Cero Bordes en `BoxDecoration`
- **PROHIBIDO** usar `border: Border.all(...)` con colores que contrasten, creen contornos, filetes o tonalidades distintas.
- En `BoxDecoration`, **no definir propiedad `border`** (`border: null`).
- Cada elemento es un bloque sólido y plano de un único color y tono.

```dart
// ❌ INCORRECTO: botón con fondo gris y borde cian o blanco (tonalidades distintas)
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF1E293B),
    border: Border.all(color: const Color(0xFF00D4FF), width: 2), // ❌ PROHIBIDO
    borderRadius: BorderRadius.circular(10),
  ),
  child: ...,
)

// ❌ INCORRECTO: outline button con borde de color y fondo transparente/distinto
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.white), // ❌ PROHIBIDO
  ),
  ...
)

// ✅ CORRECTO: Bloque sólido de UN SOLO COLOR Y TONO, SIN BORDES
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF00D4FF), // ✅ Un solo color sólido
    // SIN BORDES
    borderRadius: BorderRadius.circular(12),
  ),
  child: ...,
)
```

### 2. Monocromía por Componente
- Cada botón, chip, badge o card tiene **una única tonalidad de fondo**.
- Nada de franjas, ni filetes perimetrales, ni bordes con luminosidad o saturación diferente al cuerpo del componente.
- El contenido interior (icono o texto) contrasta en blanco puro (`#FFFFFF`) o negro carbón (`#111111`) según el brillo del bloque.

### 3. Como se ve en el Inicio (`HomeScreen`)
- En el inicio, cada botón de la grilla es un bloque contundente de color puro:
  - Bloque Verde (`#39FF14`)
  - Bloque Amarillo (`#FFDE59`)
  - Bloque Violeta (`#7000FF`)
  - Bloque Rosa (`#FF1493`)
  - Bloque Cian (`#00F0FF`)
- Esquinas redondeadas (`BorderRadius.circular(10)` a `18`).
- Cero líneas perimetrales de otro color. Cero efectos de outline.

### 4. Prohibiciones Absolutas
- ❌ **Prohibido el fondo negro puro (`#000000`)**: usar gris oscuro profundo (`#121212`, `#141414`, `#1A1A1A`).
- ❌ **Prohibido fondos transparentes** en botones que intenten usar solo borde.
- ❌ **Prohibido degradados** (`LinearGradient`, `RadialGradient`).
- ❌ **Prohibido sombras difusas** (`blurRadius > 0`).

---

## Tabla Resumen de Estilos

| Componente | Fondo | Borde | Esquinas |
|---|---|---|---|
| **Botón de Acción** | Color sólido de acento (`#00D4FF`, `#39FF14`, etc.) | **NINGUNO** (`null`) | `BorderRadius.circular(10-12)` |
| **Botón Secundario** | Bloque gris neutro sólido (`#222222`, `#2A2A2A`) | **NINGUNO** (`null`) | `BorderRadius.circular(10-12)` |
| **Card / Item Lista** | Bloque oscuro uniforme (`#1A1A1A` o `#1E1E1E`) | **NINGUNO** (`null`) | `BorderRadius.circular(14-16)` |
| **Badge / Tag** | Bloque sólido con el color de estado | **NINGUNO** (`null`) | `BorderRadius.circular(6-8)` |
| **Input / TextField** | Fondo sólido gris oscuro (`#1E1E1E`) | **InputBorder.none** | `BorderRadius.circular(10-12)` |
| **Modal / BottomSheet**| Fondo sólido uniforme (`#141414` o `#1A1A1A`) | **NINGUNO** (`null`) | Top `Radius.circular(20)` |

---

## Checklist Obligatorio para Todo Cambio de UI

- [ ] ¿El elemento tiene CERO bordes visibles de otro color o tono?
- [ ] ¿El botón/card es de un solo color y tono en su totalidad?
- [ ] ¿Se eliminaron todos los `Border.all` contrastantes o innecesarios?
- [ ] ¿Luce como los bloques limpios del inicio (`HomeScreen`)?
