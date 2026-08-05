# Skill Visual - Guía de Estilo

Guía de referencia para la implementación visual de componentes en el proyecto F.U.R.I.

---

## Reglas Fundamentales

### 1. Fondo y Borde del Mismo Color

Todo elemento visual que tenga borde y fondo (bloques, botones, pop-ups, cards, inputs, etc.) debe cumplir:

- **Fondo sólido, nunca transparente.**
- **El color de fondo y el color de borde deben ser siempre idénticos.**
- **Prohibido usar colores diferentes entre borde y fondo.**
- **Prohibido usar fondo negro (`#000000`).**
- **Prohibido usar fondo transparente o semitransparente (`transparent`, `rgba` con alpha < 1).**

```css
/* CORRECTO */
.elemento {
  background-color: #2d2d2d;
  border: 2px solid #2d2d2d;
  border-radius: 12px;
}

/* INCORRECTO */
.elemento {
  background-color: transparent;            /* ❌ fondo transparente */
  background-color: #000000;                /* ❌ fondo negro */
  background-color: #1a1a1a;
  border: 2px solid #ff6600;               /* ❌ colores diferentes */
}
```

### 2. Bordes Redondos

Todo elemento con borde y fondo de color debe tener bordes redondos (`border-radius`).

- Usar valores consistentes según el tamaño del elemento.
- Elementos pequeños (botones, tags): `6px - 8px`
- Elementos medianos (cards, inputs, modales): `10px - 16px`
- Elementos grandes (pop-ups, paneles): `16px - 24px`

```css
/* EJEMPLOS */
.btn    { border-radius: 8px; }
.card   { border-radius: 12px; }
.popup  { border-radius: 20px; }
```

---

## Estilo General: Brutalista Modificado

El estilo base es **brutalista**, adaptado con las reglas anteriores:

| Característica | Brutalista tradicional | F.U.R.I |
|---|---|---|
| Bordes | Sin bordes o crudos | **Redondos** |
| Fondo/Borde | Contrastantes | **Mismo color** |
| Fondo | A menudo crudo/transparente | **Sólido, nunca transparente ni negro** |
| Tipografía | Monoespaciada, grande | Mantener |
| Layout | Crudo, asimétrico | Mantener |
| Sombras | Ninguna | Ninguna (brutalista puro) |
| Degradados | No usar | No usar |

### Principios brutalistas que se mantienen:
- Tipografía monoespaciada.
- Layouts crudos y asimétricos bienvenidos.
- Sin sombras (`box-shadow: none`).
- Sin degradados (`linear-gradient`, `radial-gradient`).
- Paleta de colores limitada y saturada.
- Sin adornos decorativos innecesarios.

---

## Checklist de Implementación

Antes de mergear cualquier componente visual, verificar:

- [ ] ¿Todos los fondos son sólidos? (no `transparent`, no `rgba` con alpha < 1)
- [ ] ¿El color de borde es idéntico al color de fondo?
- [ ] ¿Hay algún fondo `#000000`? Debe ser eliminado.
- [ ] ¿Todos los elementos con borde/fondo tienen `border-radius`?
- [ ] ¿Se mantiene el espíritu brutalista? (sin sombras, sin degradados, tipografía mono)
- [ ] ¿Los colores usados son consistentes con la paleta del proyecto?

---

## Paleta de Referencia

*(A definir según el diseño final del proyecto)*

```css
/* Ejemplo de paleta tentativa - ajustar según diseño */
:root {
  --color-bg-primary:    #1a1a2e;
  --color-bg-secondary:  #16213e;
  --color-bg-accent:     #0f3460;
  --color-text:          #e0e0e0;
  --color-highlight:     #e94560;
  --color-success:       #4ecca3;
}
```

---

## Ejemplos Visuales

### Botón
```css
.btn {
  background-color: var(--color-highlight);
  border: 2px solid var(--color-highlight);
  border-radius: 8px;
  color: var(--color-text);
  padding: 10px 24px;
  font-family: monospace;
  box-shadow: none;
}
```

### Card / Bloque
```css
.card {
  background-color: var(--color-bg-secondary);
  border: 2px solid var(--color-bg-secondary);
  border-radius: 12px;
  padding: 16px;
  font-family: monospace;
  box-shadow: none;
}
```

### Pop-up / Modal
```css
.popup {
  background-color: var(--color-bg-primary);
  border: 2px solid var(--color-bg-primary);
  border-radius: 20px;
  padding: 24px;
  font-family: monospace;
  box-shadow: none;
}
```

### Input
```css
.input {
  background-color: var(--color-bg-secondary);
  border: 2px solid var(--color-bg-secondary);
  border-radius: 8px;
  color: var(--color-text);
  padding: 8px 12px;
  font-family: monospace;
  box-shadow: none;
}
```

---

> **Regla de oro:** Si tiene borde y fondo, mismo color, sólido, redondo. Sin excepciones.
