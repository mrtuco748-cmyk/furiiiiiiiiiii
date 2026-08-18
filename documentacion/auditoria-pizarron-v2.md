# Auditoría del Pizarrón v2 — Reporte de Bugs

> Fecha: 2026-08-12
> Auditoría completa basada en `documentacion/prompt-debugging-pizarron-v2.md`
> Código auditado: `lib/providers/board_provider_v2.dart`, `lib/models/board_element_v2.dart`, `lib/models/board_element_data.dart`, `lib/screens/pizarra_v2/` (todos los archivos)

---

## Resumen Ejecutivo

Se auditaron **10 secciones** del checklist. Se encontraron **19 bugs**:
- **3 CRÍTICOS** (pérdida de datos)
- **6 ALTOS** (funcionalidad rota o race conditions)
- **6 MEDIOS** (UX o edge cases)
- **4 BAJOS** (mejoras menores)

---

## 🔴 BUG 1: Modificaciones offline de elementos existentes NO se sincronizan

**Criticidad**: 🔴 CRÍTICO

**Descripción**:
Si el usuario edita un elemento ya sincronizado mientras está offline, el cambio se guarda en SQLite pero NUNCA se sube a Supabase al volver online.

**Paso a reproducir**:
1. Crear una nota (se sincroniza, `synced=1`)
2. Perder conexión
3. Editar el título de la nota
4. Volver online
5. La pareja nunca ve el nuevo título

**Resultado esperado**: El cambio debería subirse al volver online.
**Resultado actual**: El cambio queda solo en local para siempre.

**Posible causa**:
`_pushUnsyncedToCloud()` solo sube filas con `synced = 0`:
```dart
final unsynced = await db.query('board_elements_v2', where: 'synced = 0');
```
Pero `update()` y `moveLocal()` guardan en SQLite sin cambiar el flag `synced`. El elemento ya tiene `synced=1` de su sincronización inicial, así que nunca entra en la query de unsynced. Además, el update cloud dentro del debounce Timer simplemente se ignora si `_isOnline` es false, y no se encola para después.

**Solución propuesta**:
En `update()` y `moveLocal()`, al guardar en SQLite, marcar `synced = 0` si el cloud update falla o si estamos offline:
```dart
// En _saveToLocal o después del catch del cloud update:
if (!_isOnline) {
  await db.update('board_elements_v2', {'synced': 0}, where: 'id = ?', whereArgs: [id]);
}
```
Y en el catch del debounce cloud update, también marcar `synced = 0`.

---

## 🔴 BUG 2: Reacciones simultáneas se pisan (race condition)

**Criticidad**: 🔴 CRÍTICO

**Descripción**:
Si Facu y Rocio reaccionan con el mismo emoji al mismo elemento casi al mismo tiempo, la reacción de uno pisa la del otro.

**Paso a reproducir**:
1. Facu reacciona 🥰 a la nota X
2. Rocio reacciona 🥰 a la nota X casi simultáneamente (antes de que llegue el realtime de Facu)
3. El `update()` de Rocio envía el data map completo con `{'🥰': ['rocio-id']}`
4. El de Facu envía `{'🥰': ['facu-id']}`
5. El último en llegar a Supabase pisa al anterior

**Resultado esperado**: `{'🥰': ['facu-id', 'rocio-id']}` (ambos)
**Resultado actual**: Solo uno aparece en la reacción.

**Posible causa**:
`withToggledReaction` lee el data map LOCAL, modifica las reacciones, y envía el map completo vía `update()`. No hay merge en el servidor. El campo `data` es JSONB y se envía entero, pisando cualquier cambio concurrente.

**Solución propuesta**:
Opción A (ideal): Usar una Supabase RPC que haga el merge atómico del JSONB:
```sql
CREATE FUNCTION toggle_reaction(el_id bigint, key text, user_id text)
RETURNS void AS $$
DECLARE current jsonb;
BEGIN
  SELECT data FROM board_elements_v2 WHERE id = el_id INTO current;
  -- merge atómico de la reacción
  ...
END;
$$ LANGUAGE plpgsql;
```

Opción B (pragmática): Al recibir un update por realtime, MERGEAR las reacciones del cloud con las locales en vez de reemplazar:
```dart
// En el callback de realtime, antes de asignar:
final localReactions = BoardSocialData.reactionsOf(_elements[idx].data);
final cloudReactions = BoardSocialData.reactionsOf(el.data);
// Merge: union de user_ids por key
final merged = {...cloudReactions};
for (final entry in localReactions.entries) {
  if (merged.containsKey(entry.key)) {
    for (final uid in entry.value) {
      if (!merged[entry.key]!.contains(uid)) {
        merged[entry.key]!.add(uid);
      }
    }
  } else {
    merged[entry.key] = entry.value;
  }
}
```

---

## 🔴 BUG 3: Borrado de elemento NO limpia conectores que lo referencian

**Criticidad**: 🔴 CRÍTICO

**Descripción**:
Al eliminar un elemento que tiene conectores apuntando a él, los conectores quedan huérfanos. Se vuelven invisibles (el painter returna early) pero siguen en la BD ocupando espacio.

**Paso a reproducir**:
1. Crear nota A y nota B
2. Crear conector A → B
3. Eliminar nota B
4. El conector queda en la BD pero no se renderiza

**Resultado esperado**: El conector se elimina en cascada.
**Resultado actual**: Conector huérfano invisible en la BD.

**Posible causa**:
`delete()` en el provider solo borra el elemento por ID. No busca ni elimina conectores cuyo `fromId` o `toId` apunten al elemento borrado.

**Solución propuesta**:
```dart
Future<void> delete(int id) async {
  // Limpiar conectores que referencian este elemento
  final connectors = _elements.where((e) =>
    e.type == BoardElementType.connector &&
    (ConnectorData.fromMap(e.data).fromId == id ||
     ConnectorData.fromMap(e.data).toId == id)
  ).toList();
  for (final c in connectors) {
    if (c.id != null) await _deleteConnector(c.id!);
  }
  // ... resto del delete
}
```

---

## 🟠 BUG 4: Drag del elemento puede jitter si los pan events son más rápidos que el rebuild

**Criticidad**: 🟠 ALTO

**Descripción**:
Durante el drag, `onPanUpdate` usa `el.x + d.delta.dx` donde `el` es el snapshot del build. Si múltiples pan events llegan antes del rebuild, todos usan la posición vieja y el elemento salta.

**Paso a reproducir**:
1. Arrastrar un elemento rápidamente (especialmente en devices de alta refresh rate)
2. El elemento puede jitter o saltar hacia atrás

**Resultado esperado**: El elemento sigue el dedo suavemente.
**Resultado actual**: Posible jitter en drags rápidos.

**Posible causa**:
```dart
onPanUpdate: (d) {
  pv.moveLocal(_liveElement(pv, el), el.x + d.delta.dx, el.y + d.delta.dy);
},
```
`el.x` es del build snapshot. `d.delta.dx` es el delta de ESTE frame. Si el rebuild no llegó entre frames, la posición se resetea al snapshot + delta actual.

**Solución propuesta**:
Usar la posición del elemento vivo en vez del snapshot:
```dart
onPanUpdate: (d) {
  final live = _liveElement(pv, el);
  pv.moveLocal(live, live.x + d.delta.dx, live.y + d.delta.dy);
},
```

---

## 🟠 BUG 5: `isLocked` se guarda pero nunca se valida

**Criticidad**: 🟠 ALTO

**Descripción**:
El modelo tiene `isLocked` y la BD lo persiste, pero ninguna operación de `update()`, `moveLocal()`, o `delete()` verifica este flag. Un elemento "bloqueado" se puede editar/mover/eliminar libremente.

**Resultado esperado**: Un elemento bloqueado no debería poder editarse.
**Resultado actual**: El lock no tiene efecto.

**Solución propuesta**:
En `update()` y `moveLocal()`, verificar si el elemento tiene `isLocked == true` y rechazar la edición:
```dart
if (_elements[idx].isLocked) return; // o mostrar mensaje
```

---

## 🟠 BUG 6: Reacción 6ta key se ignora sin feedback

**Criticidad**: 🟠 ALTO

**Descripción**:
Cuando se intenta agregar una 6ta reacción custom, `withToggledReaction` retorna el data sin cambios (`return data`), pero el sheet no muestra ningún mensaje. El usuario no entiende por qué su reacción no se agregó.

**Resultado esperado**: Mensaje "Máximo 5 reacciones por elemento".
**Resultado actual**: Silencioso. El usuario cree que la app se bugueó.

**Solución propuesta**:
Retornar un resultado que indique si se alcanzó el límite, y mostrar un SnackBar o feedback visual.

---

## 🟠 BUG 7: Comentario con reply huérfano (padre borrado) queda visible sin contexto

**Criticidad**: 🟠 ALTO

**Descripción**:
Si se borra un comentario que tiene respuestas, las respuestas quedan huérfanas pero visibles. Pierden el contexto "→ 'texto original'" porque `repliedTo` ya no existe.

**Resultado esperado**: Las respuestas se eliminan en cascada o se muestra "Comentario eliminado".
**Resultado actual**: La respuesta se ve sola sin saber a qué responde.

**Solución propuesta**:
Opción A: Cascade-delete respuestas al borrar un comentario padre.
Opción B: Reemplazar el texto del padre borrado con "(comentario eliminado)" en vez de quitarlo del array.

---

## 🟠 BUG 8: Búsqueda solo busca en el tablero actual, no en sub-tableros

**Criticidad**: 🟠 ALTO

**Descripción**:
`BoardSearchPanel` recibe `pv.elements` que está filtrado por `board_id`. Buscar desde el tablero raíz no encuentra elementos en sub-tableros.

**Solución propuesta**:
Exponer `pv.allElements` (sin filtro de board) a la búsqueda, o agregar un toggle "buscar en todos los tableros".

---

## 🟠 BUG 9: No hay retry/cola para cloud writes fallidos

**Criticidad**: 🟠 ALTO

**Descripción**:
`update()`, `add()`, `delete()`, `markAsSeen()`, `toggleArchive()` — todos tienen try/catch con `debugPrint` en el cloud write. Si falla, no hay retry. El cambio queda solo en local.

**Solución propuesta**:
Implementar una cola de sync. Cuando un cloud write falla, marcar el elemento como `synced = 0` y encaiolarlo. En `load()`, además de `_pushUnsyncedToCloud`, también pushear elementos modificados (no solo nuevos).

---

## 🟡 BUG 10: Sync cloud sobrescribe cambios locales con full-document replacement

**Criticidad**: 🟡 MEDIO

**Descripción**:
`_syncFromCloud` hace `if (cloudEl.updatedAt.isAfter(_elements[localIdx].updatedAt)) _elements[localIdx] = cloudEl`. Si el usuario movió un elemento offline y la pareja cambió el color con timestamp ligeramente posterior, el movimiento offline se pierde.

**Solución propuesta**:
Merge a nivel campo: si el cloud trae un `updatedAt` más nuevo, mezclar el x/y local con el color cloud. Esto requiere tracking de qué campos se modificaron (dirty fields).

---

## 🟡 BUG 11: No hay indicador de offline en modales/editores

**Criticidad**: 🟡 MEDIO

**Descripción**:
`NoteCardModal`, `BoardDrawingEditor`, `BoardAudioEditor`, `BoardVideoSearchDialog` — ninguno muestra si el dispositivo está offline. El usuario guarda y no sabe si el cambio llegará a la nube.

**Solución propuesta**:
Exponer `pv.isOnline` y mostrar un banner "Sin conexión - cambios se guardarán localmente" en los editores.

---

## 🟡 BUG 12: Comentarios no tienen límite de longitud

**Criticidad**: 🟡 MEDIO

**Descripción**:
El TextField de comentarios tiene `maxLines: null` sin `maxLength`. Un comentario de 10,000 caracteres se guarda entero en JSONB del `data` del elemento.

**Solución propuesta**:
Agregar `maxLength: 1000` al TextField de comentarios.

---

## 🟡 BUG 13: Tags no se sincronizan con cloud

**Criticidad**: 🟡 MEDIO

**Descripción**:
Los tags se guardan en `board_tags` en SQLite local. No se suben a Supabase. La pareja no ve los tags que el otro crea, y al reinstalar la app se pierden.

**Solución propuesta**:
Sincronizar `board_tags` con una tabla en Supabase, o guardar los tags en el campo `data` de cada elemento (que ya se sincroniza).

---

## 🟡 BUG 14: No hay virtualización del canvas (500+ elementos = lag)

**Criticidad**: 🟡 MEDIO

**Descripción**:
Todos los elementos se renderizan como `Positioned` widgets en el `Stack` dentro del `InteractiveViewer`. Con 500+ elementos, todos se construyen y layoutean, incluso los fuera de viewport.

**Solución propuesta**:
Culling: solo renderizar elementos dentro del `_visibleRect` (que ya se calcula). O usar un `ListView.builder` virtualizado para la lista de elementos.

---

## 🟡 BUG 15: Imágenes de nota NO se comprimen antes de guardar

**Criticidad**: 🟡 MEDIO

**Descripción**:
`_pickImage()` usa `ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200)` — esto limita el ancho a 1200px, pero el archivo se guarda con `xFile.path` (la ruta temporal del archivo original comprimido por image_picker). El FORMATO no se controla (puede ser PNG grande) ni hay límite de file size.

**Solución propuesta**:
Usar `flutter_image_compress` para reducir a JPG con calidad 85%, y validar que el archivo no exceda ~5MB. Guardar la imagen en un path persistente (no el temporal de image_picker).

---

## 🟢 BUG 16: Audio playback falla silenciosamente si el archivo no existe

**Criticidad**: 🟢 BAJO

**Descripción**:
`BoardAudioRenderer._togglePlay()` hace try/catch y debugPrint si falla. No hay feedback visual al usuario.

**Solución propuesta**:
Mostrar un icono de error en la card cuando el audio no se puede cargar.

---

## 🟢 BUG 17: RLS permite que cualquiera edite/borre cualquier elemento

**Criticidad**: 🟢 BAJO (la app es privada para 2 usuarios)

**Descripción**:
La migración `migration_board_v2.sql` tiene `FOR ALL USING (true)` — sin validar owner. Cualquiera con la anon key puede leer/escribir/borrar todo.

**Solución propuesta**:
Para una app de 2 usuarios, esto es aceptable. Si se abre a más usuarios, implementar RLS real con auth.

---

## 🟢 BUG 18: No hay validación de URL de video (cualquier URI válido pasa)

**Criticidad**: 🟢 BAJO

**Descripción**:
`_parseVideoUrl` acepta cualquier URI válido como "other". Un link a una página web normal se agrega como "video" sin thumbnail.

**Solución propuesta**:
Validar que la URL apunte a un video real, o al menos advertir al usuario si el provider es "other".

---

## 🟢 BUG 19: Editor de dibujo no persiste entre ediciones si el targetId cambia

**Criticidad**: 🟢 BAJO

**Descripción**:
`BoardDrawingEditor._findTarget()` tiene fallback al "último dibujo" si `_targetId` es null. Si hay múltiples dibujos y se abre el editor sin targetId, puede editar el dibujo incorrecto.

**Solución propuesta**:
Eliminar el fallback y siempre pasar el `targetId` correcto desde el canvas.

---

## Checklist Final

| Sección | Estado | Bugs encontrados |
|---------|--------|-----------------|
| A. Sincronización y Realtime | 🔴 Auditada | 3 (CRÍTICO, ALTO) |
| B. Estado Local vs Cloud | 🟠 Auditada | 2 (ALTO) |
| C. Reglas de Negocio | 🟡 Auditada | 3 (ALTO, MEDIO) |
| D. Permisos y Autoría | 🟢 Auditada | 2 (ALTO, BAJO) |
| E. Gestos e Interacción | 🟠 Auditada | 1 (ALTO) |
| F. Modales y Navegación | 🟡 Auditada | 1 (MEDIO) |
| G. Búsqueda y Filtros | 🟡 Auditada | 2 (ALTO, MEDIO) |
| H. Rendimiento | 🟡 Auditada | 2 (MEDIO) |
| I. Formato y Codificación | 🟢 Auditada | 1 (BAJO) |
| J. Errores y Recuperación | 🟡 Auditada | 1 (ALTO) |
| **Total** | | **19** |

---

## Prioridad de Fixes Recomendada

1. **BUG 1** (offline sync) — menos de 10 líneas de cambio, impacto masivo
2. **BUG 4** (drag jitter) — fix de 1 línea, mejora UX inmediatamente
3. **BUG 9** (no retry cloud) — base para que todos los demás sync bugs se resuelvan
4. **BUG 5** (isLocked) — fix de ~5 líneas en update/moveLocal/delete
5. **BUG 2** (reacciones race) — requiere merge en realtime callback
6. **BUG 3** (conectores huérfanos) — agregar cascade en delete
7. Resto en orden MEDIO/BAJO

---

*Auditoría completada sobre el código en `lib/screens/pizarra_v2/` y `lib/providers/board_provider_v2.dart` al 2026-08-12.*