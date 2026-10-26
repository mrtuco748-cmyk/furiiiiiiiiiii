# F.U.R.I. v1.0.13 — Taller de Dibujo Digital Pro, Taller de Cómic & Manga con Guías Inteligentes y Estabilidad

### 🎨 Taller de Dibujo Digital Pro (Multicapa, Pinceles Profesionales y Trazo Predictivo)
- **Motor Multicapa Completo**:
  - Gestión de capas ilimitadas con soporte de opacidad independiente, visibilidad, bloqueo, reordenamiento y fusión hacia abajo.
  - Dock flotante de capas con miniaturas en tiempo real y botón de descarte directo.
- **Pinceles Profesionales con Físicas Realistas**:
  - **Lápiz de Grafito**: Sensibilidad a la presión y trazo de grafito texturizado.
  - **Birome Clásica**: Tinta fluida y respuesta rápida.
  - **Marcador / Plumón**: Multiplicación de pigmento orgánico en superposiciones.
  - **Resaltador / Marcatextos**: Tinta traslúcida y ancha.
  - **Pluma Caligráfica**: Variación dinámica de ancho según el ángulo y dirección del trazo.
  - **Tinta China**: Alta densidad de pigmento con bordes definidos estilo entintado manga.
  - **Aerógrafo**: Difuminado radial estocástico con partículas finas.
  - **Crayón**: Textura rugosa de cera sobre grano de papel.
  - **Acuarela**: Simulación de mezcla húmeda y transparencia translúcida.
  - **Dedo / Difuminador**: Difuminado direccional dinámico de trazos sobre el lienzo.
  - **Goma de Borrar Inteligente**: Borrado suave y por trazos con deselección automática.
- **Estabilización de Trazos y Trazo Predictivo**:
  - Suavizado adaptativo de trazos con corrección de temblor en tiempo real (evita líneas accidentadas).
  - Selector deslizante de Trazo Predictivo (niveles 1 a 10) con interpolación Hermite / lookahead predictivo para trazos de precisión extrema.
  - Círculo guía interactivo (cursor visual) en tiempo real con el radio exacto del grosor del pincel o goma seleccionada.
- **Herramientas de Selección y Relleno**:
  - Lazo libre con panel de acción flotante y guía para traslación.
  - Relleno de balde y degradados lineales/radiales.
  - Geometría precisa: Líneas, Rectángulos, Círculos y Polígonos.
  - Alternancia inteligente de herramientas (`toggleTool`): pulsar una herramienta auxiliar una segunda vez restaura el pincel previo configurado (`previousDrawingTool`).
- **Gestión de Proyectos & Miniaturas de Galería**:
  - Renombrado interactivo de proyectos (edición directa del título desde la barra superior).
  - Miniaturas de previsualización en galería generadas con fondo blanco nítido (eliminado el fondo negro por transparencia).
  - Historial multinivel completo de Deshacer y Rehacer.

---

### 📖 Taller de Cómic & Manga con Guías Magnéticas Inteligentes
- **Guías Magnéticas de Alineación en Tiempo Real (Estilo Canva / Figma)**:
  - **Centros de la Hoja**: Detección magnética de centros horizontal y vertical con líneas en cian eléctrico (`#00D4FF`), atracción suave (*soft snap*) y píldora flotante "Centro".
  - **Alineación entre Elementos**: Detección inteligente de bordes (izq, der, sup, inf) y centros respecto a otras viñetas y bocadillos en magenta neón (`#FF2A85`).
  - **Márgenes Perimetrales**: Atracción a los márgenes seguros de página en amarillo cálido (`#FFDE59`) con píldora "Margen".
- **Bocadillos de Diálogo Dinámicos e Interactivos**:
  - Tipologías completas: Diálogo redondeado, Grito/Explosión con puntas poligonales, Pensamiento con nubes y burbujas, Susurro con contorno punteado y Cuadro narrativo.
  - Manipulación gestual continua: soporte total para editar, rotar, escalar y mover bocadillos tras múltiples selecciones sucesivas.
  - Control de cola direccional en 360° con renderizado sin cortes a la izquierda, derecha, arriba o abajo.
- **Onomatopeyas y Stickers SFX**:
  - Efectos de sonido con tipografías de impacto, deformación, curvatura, rotación y borde brutalista.
- **Modo Lectura Cómic**:
  - Visor inmersivo de cómics y mangas con paginación fluida, zoom interactivo y resiliencia ante proyectos de una sola página.

---

### 🛠️ Resiliencia, Estabilidad y Modularización
- **Correcciones Críticas de Estabilidad**:
  - Resuelto crash fatal por aserción de Flutter `min < max` al abrir cómics de una sola página en el visor de lectura.
  - Agregadas salvaguardas `.clamp(min, max)` en todos los sliders de ajuste de viñetas, bocadillos, capas y pinceles.
  - Habilitado botón de descarte directo en la cabecera del dock de capas.
  - Vinculación de la tarjeta "Animación Flipbook" en Herramientas con diálogo explicativo brutalista y acceso rápido al Taller de Dibujo.
  - Prevención de eventos fantasma en botones de navegación inactivos mediante `onTap: null`.
- **Arquitectura y Calidad de Código**:
  - **100% de archivos en `lib/` bajo la regla de 300 líneas**: 0 archivos exceden las 300 líneas en todo el proyecto.
  - **Análisis estático (`flutter analyze lib test`)**: 0 errores, 0 advertencias.
  - **Suite completa de pruebas (`flutter test`)**: 475 tests pasando con 100% de éxito.

---

### Descargas disponibles:

#### 📱 Android (APKs por arquitectura)
| Arquitectura | Dispositivos | Archivo |
|---|---|---|
| **arm64-v8a** | La inmensa mayoría de celulares modernos (64-bit) | `app-arm64-v8a-release.apk` |
| **armeabi-v7a** | Celulares anteriores o económicos (32-bit) | `app-armeabi-v7a-release.apk` |
| **x86_64** | Emuladores y tablets x86 | `app-x86_64-release.apk` |

> 💡 **Recomendación**: Si no estás seguro de cuál descargar para tu celular, elige **`app-arm64-v8a-release.apk`**.

#### 💻 Windows (Desktop x64)
- **`furi-windows-x64-v1.0.13.zip`**: Versión portable para Windows. Descomprimir y ejecutar `furi_app.exe`.
