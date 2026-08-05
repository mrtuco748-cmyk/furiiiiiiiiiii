# F.U.R.I. - Pantalla "Nosotros"

## Objetivo Principal
Desarrollar completamente la pantalla "Nosotros" de la app F.U.R.I., con todos los 7 botones interactivos, animaciones y funcionalidades de interacción entre pareja.

## Contexto de la App F.U.R.I.
- **Propósito**: App de pareja para organizar finanzas, tiempo, actividades, interacción y crear historia juntos
- **Usuarios**: Facu y Rocio (personalización por usuario)
- **Plataformas**: Android y PC

---

## Estructura de la Pantalla "Nosotros"

### Componentes Principales

#### 1. Barra Superior Decorativa
- **Elemento**: 3 iconos de corazones ❤️
- **Ubicación**: Arriba a la derecha
- **Función**: Decoración + Indicador de sección
- **Estilo**: Diferencia visual de pantalla principal

#### 2. Botón CHAT 💬
- **Ubicación**: Arriba a la derecha (justo debajo de barra de corazones)
- **Función**: Abre chat con la pareja
- **Funcionalidad**: 
  - Mensajes en tiempo real
  - Historial de conversaciones
  - Notificaciones de nuevos mensajes

#### 3. Botón RETOS 🚩
- **Ubicación**: A la izquierda del botón CHAT
- **Función**: Gestionar retos individuales y conjuntos
- **Funcionalidad**:
  - Ver retos propuestos para ti
  - Crear nuevos retos
  - Aprobar retos en conjunto (requiere ambas confirmaciones)
  - Marcar retos como completados
  - Ver historial de retos

**ANIMACIÓN SWAP RETOS**:
- Cada 4 segundos: Cambia de icono 🚩 a un reto aleatorio de tu lista
- El texto del reto debe caber en el botón
- Animación de entrada suave
- Después de 7 segundos: Vuelve al icono
- Se repite en bucle

#### 4. Botón CARTAS 💌
- **Ubicación**: Debajo de CHAT y RETOS (ancho completo)
- **Tamaño**: Ocupa todo el ancho, 1/4 de alto
- **Función**: Ver todas las cartas de ambos ordenadas por tiempo
- **Funcionalidad**:
  - Leer cartas propias y de la pareja
  - Ordenamiento por tiempo (no por usuario)
  - Escribir nueva carta
  - Archivar/eliminar cartas

**ANIMACIÓN SWAP CARTAS**:
- Cada 2 segundos al estar en pantalla: Muestra carta nueva de la pareja
- Si carta es muy larga: Texto sube línea por línea (efecto de lectura lenta)
- Cuando termina de mostrarse: Vuelve a icono y repite bucle
- Las letras deben verse grandes

#### 5. Botón EMOCIONES 😊
- **Ubicación**: Abajo izquierda (debajo de CARTAS)
- **Tamaño**: Cuadrado vertical, ocupa espacio hasta abajo
- **Función**: Registrar y ver emociones del día

**ANIMACIÓN SWINK**:
- Al presionar: Se agranda y flota (popup)
- Se ensancha hacia la derecha
- En el nuevo espacio: Opción para agregar emoción + Ver emociones de ambos

**FUNCIONALIDAD**:
- Agregar emoción con emoji
- Ver emociones de ambos ordenadas por hora (no por persona)
- Emociones se muestran como emojis
- Swap automático: Si pareja agregó emoción, muestra emoji en vez de icono

#### 6. Botón PREGUNTAS ❓
- **Ubicación**: Abajo derecha del botón EMOCIONES (hasta borde derecho)
- **Tamaño**: Ocupa desde lado EMOCIONES hasta borde pantalla
- **Función**: Hacer y responder preguntas de pareja

**INTERACCIÓN CON CLICK**:
- **1 click**: Muestra última pregunta que te hizo tu pareja (swap)
  - Si pregunta es larga: Texto aparece frase por frase de derecha a izquierda
  - Luego repite en bucle

- **2 clicks seguidos**: Swink hacia abajo
  - Muestra historial de TODAS las preguntas de ambos ordenadas por tiempo
  - Al tocar una pregunta: Muestra su respuesta
  - Opción para hacer nueva pregunta

**FUNCIONALIDAD**:
- Enviar preguntas a pareja
- Ver historial de preguntas
- Responder preguntas
- Ordenamiento por tiempo

#### 7. Botón METAS 🏅
- **Ubicación**: Abajo, a la derecha del EMOCIONES, debajo de PREGUNTAS
- **Tamaño**: Cuadrado pequeño
- **Función**: Establecer y marcar metas en conjunto

**FUNCIONALIDAD**:
- Crear nuevas metas
- Marcar metas como completadas
- Ver metas completadas de pareja
- Ver metas en progreso
- Historial de metas

#### 8. Botón DISTANCIA 🗺️
- **Ubicación**: Abajo a la derecha (última posición)
- **Tamaño**: Cuadrado pequeño
- **Función**: Mostrar distancia entre ambos en tiempo real

**FUNCIONALIDAD**:
- Obtener ubicación de ambos
- Calcular distancia
- Actualizar en tiempo real
- Mostrar en km o millas (según preferencia)

---

## Animaciones Especiales

### SWAP
- Cambio automático entre icono y contenido
- Duración definida (4 seg para retos, 2 seg para cartas)
- Animación suave de transición
- Se repite en bucle automático
- Se restablece al salir de la pantalla

### SWINK
- Agrande y flotación (popup)
- Expansión hacia un lado (derecha o abajo según botón)
- Apertura de espacio nuevo para contenido
- Animación fluida

### SCROLL TEXTO
- **Línea por línea (cartas)**: Texto sube lentamente
- **Frase por frase (preguntas)**: Texto entra de derecha a izquierda
- Velocidad: Legible pero interesante (~1-2 seg por línea/frase)

---

## Flujo de Datos

### Estado a Mantener
- `usuarioActual`: "facu" | "rocio"
- `retos`: Array de retos
- `cartas`: Array de cartas
- `emociones`: Array de emociones del día
- `preguntas`: Array de preguntas
- `metas`: Array de metas
- `ubicacion`: {lat, lng} de ambos

### Actualizaciones en Tiempo Real
- Nuevas cartas de pareja
- Nuevos retos propuestos
- Nuevas emociones registradas
- Nuevas preguntas
- Cambios de ubicación

### Persistencia
- Base de datos local (SQLite o similar)
- Sincronización en tiempo real (Firebase o similar)
- Historial completo guardado

---

## Checklist de Implementación

### Estructura Base
- [ ] Layout principal con los 8 botones correctamente posicionados
- [ ] Barra de corazones decorativa arriba
- [ ] Responsividad para Android y PC

### Botón CHAT
- [ ] Interfaz de chat
- [ ] Historial de mensajes
- [ ] Envío en tiempo real
- [ ] Notificaciones

### Botón RETOS
- [ ] Listar retos personales
- [ ] Crear nuevo reto
- [ ] Aprobar retos en conjunto
- [ ] Marcar como completado
- [ ] **SWAP animado** (4 seg → reto aleatorio → 7 seg → icono)

### Botón CARTAS
- [ ] Listar todas las cartas
- [ ] Crear nueva carta
- [ ] Ver cartas completas
- [ ] **SWAP animado** (2 seg, último de pareja)
- [ ] **Scroll texto** (línea por línea si es larga)

### Botón EMOCIONES
- [ ] **SWINK** (agrande + ensanche)
- [ ] Selector de emojis
- [ ] Listar emociones del día ordenadas por hora
- [ ] **SWAP automático** (mostrar emoji si pareja agregó)

### Botón PREGUNTAS
- [ ] 1 click → Swap pregunta última de pareja
- [ ] 2 clicks → Swink historial
- [ ] **Scroll horizontal** (frase por frase de der a izq)
- [ ] Responder preguntas
- [ ] Hacer nuevas preguntas

### Botón METAS
- [ ] Crear metas
- [ ] Marcar completadas
- [ ] Ver metas de pareja
- [ ] Historial

### Botón DISTANCIA
- [ ] Obtener ubicación
- [ ] Calcular distancia
- [ ] Mostrar en tiempo real
- [ ] Formato en km/millas

### Personalización por Usuario
- [ ] Colores diferentes para Facu y Rocio
- [ ] Iconografía diferente si corresponde
- [ ] Preferencias guardadas

### Transiciones y Animaciones
- [ ] SWAP suave y legible
- [ ] SWINK fluido
- [ ] Scroll texto a velocidad apropiada
- [ ] Transiciones entre pantallas

---

## Notas Técnicas

### Stack Sugerido
- **Frontend**: React Native (Android/iOS) + Electron/Qt (PC)
- **Backend**: Node.js + Express
- **Base de Datos**: Firebase Realtime DB o PostgreSQL
- **Ubicación**: Geolocation API

### Consideraciones de Diseño
- Los botones deben ser touchables incluso cuando no están en "swap"
- Las animaciones no deben afectar usabilidad
- Textos largos siempre visibles de alguna forma
- Responsividad prioritaria

### Seguridad
- Autenticación de pareja vinculada
- Privacidad de emociones/cartas/preguntas
- Encriptación de datos sensibles

---

## Ejemplo de Flujo de Usuario

1. Usuario abre app → Pantalla de Nosotros
2. Ve barra de corazones arriba
3. Botones en posición: Chat, Retos, Cartas, Emociones, Preguntas, Metas, Distancia
4. Retos hace SWAP automático cada 4-7 seg
5. Cartas hace SWAP automático cada 2 seg (última de pareja)
6. Emociones muestra emoji de pareja si existe
7. Preguntas muestra última pregunta en swap
8. Usuario puede interactuar con cualquier botón en cualquier momento

---

**Estado**: Listo para desarrollo
**Versión**: 1.0
**Prioridad**: Alta
**Complejidad**: Media-Alta
