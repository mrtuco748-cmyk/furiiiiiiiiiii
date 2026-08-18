# Prompt de Debugging: Pizarrón v2 — Errores de Lógica y Funcionamiento
> Prompt especializado para auditar, debuggear y resolver errores críticos del Pizarrón.
> Usar esta plantilla cuando haya conflictos, bugs, o comportamiento inesperado.

---

## INSTRUCCIÓN PRINCIPAL

Eres un auditor de lógica de aplicación colaborativa en tiempo real. Tu tarea es:

1. **Identificar errores de lógica** en sincronización, persistencia y conflictos.
2. **Encontrar race conditions** (dos usuarios actuando simultáneamente).
3. **Validar reglas de negocio** (límites, permisos, restricciones).
4. **Verificar edge cases** que rompen la experiencia.
5. **Proponer fixes** con código o pseudocódigo.

---

## CHECKLIST DE AUDITORÍA

### A. SINCRONIZACIÓN Y REALTIME

#### ⚠️ Conflicto de edición simultánea
```
Escenario:
- Facu edita nota A (título "Plan viaje")
- Rocio edita nota A simultáneamente (mismo título)
- Ambos guardan en paralelo

Preguntas:
1. ¿Cuál cambio "gana"? (Last-write-wins es determinístico?)
2. ¿Hay timestamp de precisión suficiente (milisegundos)?
3. ¿Qué datos se envían a Supabase? (Delta o documento completo?)
4. ¿El cliente B recibe la versión perdida o solo la ganadora?
5. ¿Se notifica al usuario que su cambio fue descartado?

Tests a hacer:
- [ ] Abrir dos browsers con misma nota, editar título en paralelo, guardar
- [ ] Verificar que uno "gana" determinísticamente
- [ ] Verificar que ambos ven el mismo estado final
```

#### ⚠️ Reacciones simultáneas a la misma key
```
Escenario:
- Facu hace reacción 🥰 a nota X
- Rocio hace reacción 🥰 a nota X (misma key)
- El chip debe mostrar "🥰 2"

Preguntas:
1. ¿Se valida que sea máximo 1 reacción por usuario por key?
2. ¿Qué pasa si alguien intenta reaccionar 2 veces con 🥰?
   - ¿Lo reemplaza? ¿No hace nada? ¿Error?
3. ¿Si Facu quita su 🥰, se elimina el chip entero?
4. ¿Se sincroniza el count correctamente?

Tests a hacer:
- [ ] Facu reacciona 🥰, Rocio reacciona 🥰, ambos ven 2
- [ ] Facu reacciona otra vez 🥰, debe quitar su reacción (toggle)
- [ ] Rocio quita su reacción, chip desaparece (solo Facu quedó)
- [ ] Verificar que el chip muestra estado correcto a cada usuario
```

#### ⚠️ Comentario respondido mientras se borra el original
```
Escenario:
- Rocio comenta en nota X
- Facu responde el comentario de Rocio
- Rocio borra su comentario original
- Facu sigue viendo la respuesta...

Preguntas:
1. ¿La respuesta se queda huérfana o se elimina en cascada?
2. ¿Se guarda referencia al comment_id del original?
3. ¿Qué pasa si el original se borra antes de que se sincronice la respuesta?

Tests a hacer:
- [ ] Crear comentario, responder, eliminar original, verificar estado
- [ ] Simular offline, crear respuesta, luego borra original va online
```

#### ⚠️ Offline → Online desincronización
```
Escenario:
- Facu agrega nota A sin internet
- Rocio (online) agrega nota B
- Rocio mueve nota B a posición (100, 100)
- Facu vuelve a internet
- ¿Facu ve nota B? ¿En posición correcta?

Preguntas:
1. ¿El SQLite local tiene prioridad? ¿O Supabase?
2. ¿Hay merge inteligente o se sobrescribe todo?
3. ¿Los movimientos debounceados se pierden si se va offline?
4. ¿Hay cola de sync visible?

Tests a hacer:
- [ ] Modo offline, crear elemento, ir online, verificar que aparece
- [ ] Offline, mover elemento, online simultáneamente, verificar posición final
- [ ] Offline modificar mismo elemento que se editó online
```

#### ⚠️ Borrado de elemento con referencias activas
```
Escenario:
- Conector 1: nota A → nota B
- Conector 2: nota B → nota C
- Se elimina nota B
- ¿Qué pasa con los conectores?

Preguntas:
1. ¿Se borran en cascada o quedan conectores "rotos"?
2. ¿Se notifica al usuario que se borraron conectores?
3. ¿Hay validación al eliminar?

Tests a hacer:
- [ ] Crear conector A→B, eliminar B, verificar que conector también se eliminó
```

---

### B. ESTADO LOCAL VS CLOUD

#### ⚠️ Base de datos inconsistente
```
Preguntas:
1. ¿SQLite y Supabase pueden divergir?
2. ¿Hay timestamp de última sincronización?
3. ¿Si fallan ambas escrituras (local + cloud), qué pasa?
4. ¿Hay trigger en Supabase que regenere datos?

Tests a hacer:
- [ ] Simular fallo de SQLite.insert(), verificar rollback
- [ ] Simular fallo de Supabase.upsert(), verificar retry
- [ ] Verificar que queue de sync no pierde elementos
```

#### ⚠️ Image/Audio storage sin coincidencia
```
Escenario:
- Nota con imagen se guarda en Supabase Storage
- Path en JSONB apunta a URL correcta
- Se reinicia app, imagen no carga

Preguntas:
1. ¿Se valida que el archivo existe antes de mostrar imagen?
2. ¿Hay fallback o placeholder si falla la descarga?
3. ¿Cómo se manejan URLs expiradas (si Storage tiene CORS)?

Tests a hacer:
- [ ] Agregar imagen, eliminar manualmente de Storage, ver error
- [ ] Verificar que hay placeholder visual
```

---

### C. VALIDACIÓN DE REGLAS DE NEGOCIO

#### ⚠️ Límites de reacciones
```
Preguntas:
1. ¿Máximo 5 keys por elemento se valida en cliente o servidor?
2. ¿Si se intenta agregar 6ta reacción, qué pasa?
3. ¿Hay validación de 10 caracteres máximo en custom?
4. ¿Se permite emoji + emoji o solo uno?

Tests a hacer:
- [ ] Intentar agregar 6ta reacción custom, debe fallar o advertir
- [ ] Intentar crear reacción con 15 caracteres, debe truncar
```

#### ⚠️ Límites de comentarios
```
Preguntas:
1. ¿Hay nesting profundo de respuestas? ¿Limit?
2. ¿Se permite comentario vacío?
3. ¿Largo máximo de comentario?
4. ¿Puede haber 100+ comentarios? ¿Rendimiento?

Tests a hacer:
- [ ] Enviar comentario vacío, debe rechazarse
- [ ] Crear 50 comentarios, verificar velocidad de scroll
- [ ] Crear 10 niveles de respuestas anidadas
```

#### ⚠️ Validación de elemento
```
Preguntas:
1. ¿Nota puede quedar sin título?
2. ¿Nota puede quedar sin cuerpo?
3. ¿Video URL se valida format?
4. ¿Dibujo puede guardarse vacío?

Tests a hacer:
- [ ] Crear nota con solo espacios, debe rechazarse o trimear
- [ ] URL inválida en video, debe mostrar error
```

---

### D. PERMISOS Y AUTORÍA

#### ⚠️ Usuario incorrecto en elemento
```
Preguntas:
1. ¿El badge de autor se toma del session token?
2. ¿Se puede suplantar autor (enviar user_id falso)?
3. ¿Supabase RLS valida owner del comentario antes de borrar?

Tests a hacer:
- [ ] Intentar editar user_id en el client, verificar que Supabase lo rechaza
- [ ] Intentar borrar comentario de otro usuario, debe fallar
```

#### ⚠️ Quien puede editar qué
```
Preguntas:
1. ¿Ambos usuarios pueden editar TODO o hay restricciones?
2. ¿Un elemento "bloqueado" (marcado en docs) se puede editar?
3. ¿Hay propiedad "editado por" que track cambios?

Tests a hacer:
- [ ] Verificar que Rocio puede editar nota de Facu
- [ ] Marcar nota como bloqueada, intentar editar, debe rechazarse
```

---

### E. GESTOS Y INTERACCIÓN

#### ⚠️ Pan se activa durante drag
```
Escenario:
- Usuario arrastra elemento
- Canvas "pan" se activa accidentalmente
- Elemento y pantalla se mueven

Preguntas:
1. ¿Hay flag que desactiva pan durante drag?
2. ¿El gesto de 2 dedos (pan) se distingue bien del single-drag?

Tests a hacer:
- [ ] Arrastrar elemento lentamente, verificar que no pan
- [ ] Arrastrar elemento rápido con 1 dedo, verificar que no pan
```

#### ⚠️ Long-press en elemento movido
```
Escenario:
- Usuario mueve nota
- Mientras se mueve, long-press accidentalmente
- ¿Se abre sheet o continúa drag?

Preguntas:
1. ¿Long-press se ignora durante drag activo?
2. ¿Hay debounce en long-press?

Tests a hacer:
- [ ] Arrastrar elemento, durante arrastre hacer long-press, no debe abrir sheet
```

#### ⚠️ Zoom durante drag
```
Escenario:
- Usuario está arrastrando elemento
- Otro usuario en otra pantalla hace zoom
- ¿El elemento se mueve también?

Preguntas:
1. ¿El offset de drag es en coordenadas mundo o pantalla?
2. ¿Se recalcula correctamente si zoom cambia durante drag?

Tests a hacer:
- [ ] Zoom 50%, arrastrar elemento, verificar posición en mundo real
- [ ] Hacer zoom mientras otro arrastra, verificar que se ve correcto
```

---

### F. MODALIDADES Y NAVEGACIÓN

#### ⚠️ Modal abierto cuando se va offline
```
Escenario:
- Usuario abre modal de nota para editar
- Se va offline
- Usuario cambia titulo, guarda

Preguntas:
1. ¿El save se guardaría en SQLite?
2. ¿Hay indicador visual de offline en el modal?
3. ¿Se puede cerrar el modal sin guardar?

Tests a hacer:
- [ ] Abrir nota en modal, ir offline, editar, guardar, verificar en SQLite
```

#### ⚠️ Cambiar de tablero (sub-tablero) con modal abierto
```
Escenario:
- Elemento A en tablero 1 con modal abierto
- Rocio crea sub-tablero
- Facu navega al sub-tablero
- ¿El modal sigue abierto?

Preguntas:
1. ¿Qué elemento muestra el modal si cambió de tablero?
2. ¿Se cierra automáticamente?

Tests a hacer:
- [ ] Abrir modal, navegar a otro tablero, verificar que se cierra
```

---

### G. BÚSQUEDA Y FILTROS

#### ⚠️ Búsqueda en tablero anidado
```
Preguntas:
1. ¿Busca solo en tablero actual o en sub-tableros?
2. ¿Se puede filtrar por tablero?
3. ¿Si encuentra elemento en sub-tablero, navega automáticamente?

Tests a hacer:
- [ ] Crear elemento en sub-tablero, buscar desde tablero padre
```

#### ⚠️ Tags eliminado pero elementos aún etiquetados
```
Escenario:
- Tag "importante" existe
- 10 elementos tienen tag "importante"
- Se elimina tag "importante"
- ¿Qué pasa con los elementos?

Preguntas:
1. ¿Se guarda referencia por tag_id o por nombre?
2. ¿Si se borra tag_id, los elementos quedan sin tag o con "sin asignar"?

Tests a hacer:
- [ ] Crear tag, etiquetar elemento, eliminar tag, verificar elemento
```

---

### H. RENDIMIENTO Y ESCALABILIDAD

#### ⚠️ Canvas con 500+ elementos
```
Preguntas:
1. ¿Se virtualiza el rendering (solo renderizar visibles)?
2. ¿Qué FPS se obtiene con 500 elementos?
3. ¿Conectores se calculan en tiempo real o en RAF?

Tests a hacer:
- [ ] Crear 500 elementos, medir FPS
- [ ] Crear 100 conectores, medir lag
- [ ] Zoom out 5x con 500 elementos, verificar FPS
```

#### ⚠️ Imagen grande en nota
```
Preguntas:
1. ¿Se comprime a 1200px? ¿En qué formato?
2. ¿Hay limite de file size (ej. 10MB)?
3. ¿Se muestra placeholder mientras carga?

Tests a hacer:
- [ ] Agregar imagen 50MB, debe rechazarse o comprimir
- [ ] Agregar imagen 4000×3000px, debe redimensionarse
```

#### ⚠️ Audio largo (30+ minutos)
```
Preguntas:
1. ¿Se guarda en cloud o solo local?
2. ¿Se comprime? ¿A qué bitrate?
3. ¿Se cachea en local después de descargar?

Tests a hacer:
- [ ] Grabar audio 30 min, verificar tamaño de archivo
- [ ] Reproducir audio mientras se descarga otro, verificar no bloquea
```

---

### I. FORMATO Y CODODIFICACIÓN

#### ⚠️ Caracteres especiales en nota
```
Preguntas:
1. ¿Se guarda en UTF-8?
2. ¿Emojis se rompen? ¿Caracteres asiáticos?
3. ¿Newlines se preservan correctamente?

Tests a hacer:
- [ ] Escribir nota con emoji, 中文, árabe, verificar que se renderiza
- [ ] Copiar/pegar texto con newlines, verificar formato
```

#### ⚠️ Nombres de archivos en Storage
```
Preguntas:
1. ¿Se genera nombre único para imagen/audio?
2. ¿Hay colisiones de filename?
3. ¿Se permite caracteres especiales en filename?

Tests a hacer:
- [ ] Dos usuarios suben imagen con mismo nombre simultáneamente
- [ ] Verificar que ambas se guardan sin colisión
```

---

### J. ERRORES Y RECUPERACIÓN

#### ⚠️ Request fallida a Supabase
```
Preguntas:
1. ¿Se reintenta automáticamente?
2. ¿Hay exponential backoff?
3. ¿Se notifica al usuario?

Tests a hacer:
- [ ] Simular fallo de network, intentar crear elemento, verificar retry
- [ ] Verificar que UI indica "sincronizando..." o "error"
```

#### ⚠️ App se crashea con modal abierto
```
Preguntas:
1. ¿El estado modal se persiste?
2. ¿Al relanzar, se muestra modal nuevamente?

Tests a hacer:
- [ ] Abrir modal, force-close app, relanzar, verificar estado
```

---

## TEMPLATE DE REPORTE DE BUG

Si encuentras error, documentalo así:

```markdown
## 🐛 BUG: [Título corto]

**Descripción**:
[Qué pasa]

**Paso a reproducir**:
1. [Acción 1]
2. [Acción 2]
3. [Acción 3]

**Resultado esperado**:
[Qué debería pasar]

**Resultado actual**:
[Qué pasó en lugar]

**Criticidad**: 🔴 CRÍTICO / 🟠 ALTO / 🟡 MEDIO / 🟢 BAJO

**Datos relevantes**:
- User A: [Browser/Device/OS]
- User B: [Browser/Device/OS]
- Network: [Online/Offline]
- Timestamp: [UTC]

**Stack trace** (si aplica):
```
error: ...
```

**Posible causa**:
[Hipótesis]

**Solución propuesta**:
[Código o explicación]

**Tests después del fix**:
- [ ] Test 1
- [ ] Test 2
```

---

## PROTOCOLO DE TESTING MULTI-USER

Para validar bugs que involucran dos usuarios:

1. **Abre dos browsers** (Chrome + Firefox, o dos instancias de Chrome)
2. **Login en ambos** como Facu y Rocio (usar diferentes sesiones)
3. **Synchronize watches** (ambas pantallas a la vista)
4. **Ejecuta acciones en paralelo**:
   - A: Acción 1
   - B: Acción 2 (simultáneamente)
5. **Verifica estado final**:
   - ¿Ambos ven lo mismo?
   - ¿Hay inconsistencias?
6. **Revisa logs** en ambas consolas

---

## HERRAMIENTAS RECOMENDADAS

- **React DevTools** → Inspeccionar estado de componentes
- **Redux DevTools** → Ver actions y estado (si hay Redux)
- **Network Tab** → Inspeccionar requests a Supabase
- **Console** → Logs de sincronización
- **Storage** → Inspeccionar SQLite local
- **Supabase Studio** → Ver datos en tiempo real

---

## CHECKLIST FINAL ANTES DE RELEASE

- [ ] ✅ Sin race conditions detectadas
- [ ] ✅ Sync offline↔online validada con múltiples escenarios
- [ ] ✅ Conflictos de edición resueltos determinísticamente
- [ ] ✅ Reacciones y comentarios sincronizan correctamente
- [ ] ✅ Conectores se actualizan al mover elementos
- [ ] ✅ Búsqueda rápida en 500+ elementos
- [ ] ✅ Imágenes/audios comprimen y cargan
- [ ] ✅ Undo/redo disponible (o muy buena razón para no estar)
- [ ] ✅ Errores de network muestran indicadores claros
- [ ] ✅ Mobile y desktop ambos responsivos
- [ ] ✅ Performance acceptable a 100+ elementos

---

*Prompt creado para auditoría completa del Pizarrón v2. Actualizar conforme se descubran nuevos edge cases.*