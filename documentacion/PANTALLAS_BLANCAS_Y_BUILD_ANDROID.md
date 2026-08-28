# Pantallas blancas en Android (release) — diagnóstico, causa y fixes

> Fecha: 2026-08-28 · Áreas: Android (APK), render Flutter, fuentes
> Síntoma reportado: las pantallas de **Logros** y **Metas** (y otras basadas en mosaico "loca") se veían **en blanco** ("no se ve nada más") SOLO en el APK release. En Windows/PC andaban bien.

---

## 1. Qué significa realmente "en blanco" en release

En **debug**, una excepción de build muestra la pantalla roja de `ErrorWidget`. En **release** las excepciones NO muestran UI (y ni siquiera se imprimen por defecto). Hay dos escenarios de "pantalla en blanco" que NO son lo mismo:

| Tipo | Lo que ve el usuario | Causa típica |
|------|---------------------|--------------|
| **A. Subárbol no se dibuja** | Zona en blanco / vacía | Excepción de **build/layout** en el hijo (`ErrorWidget` solo pinta rojo si se dispara; una excepción de `paint()` de un `CustomPainter` se logea pero NO dibuja esa capa → queda el fondo). |
| **B. La ventana Android queda en blanco** | Toda la pantalla blanca del sistema | El motor **no presenta el frame** de esa pantalla. En Flutter 3.44 hay bugs conocidos de **Impeller** (backend de render de Android) que en ciertas GPUs/drivers dejan pantallas sin frame → se ve el **fondo de la ventana** (que en el tema default es **blanco**). |

El síntoma de "Logros/Metas en blanco" encaja con **B** (ventana blanca = falta de frame + fondo blanco) agravado/investigando A.

---

## 2. Causas raíz probables (y cómo evitarlas)

### 2.1 Flutter 3.44 + Impeller (Android) = pantallas sin frame 📌 (más probable)
- Impeller es el motor de render por defecto en Android desde Flutter 3.29. En **3.44** hay issues abiertos de engine que dejan pantallas en blanco o bloques corruptos en **GPUs/drivers específicos** (p. ej. `#190519`, `#189535` en flutter/flutter).
- **Cómo evitarlo**: desactivar Impeller y volver al backend **Skia** (opción 100% soportada como escape hatch):
  - Manifest (persistente): en `android/app/src/main/AndroidManifest.xml` dentro de `<application>`:
    ```xml
    <meta-data
      android:name="io.flutter.embedding.android.EnableImpeller"
      android:value="false" />
    ```
  - O por build: `flutter build apk --release --no-enable-impeller`
- **A futuro**: cuando se actualice Flutter a una versión con Impeller maduro, se puede re-activar y probar en ese mismo dispositivo. No reintroducir hasta validar en el celular real.

### 2.2 Fondo de ventana blanco detrás del UI 📌
- El tema `NormalTheme` de Android usaba `?android:colorBackground` (**blanco** en tema Light). Cuando una pantalla no presenta frame (por cualquier motivo), se ve **blanco**.
- **Fix aplicado**: `android/app/src/main/res/values/styles.xml` y `values-night/styles.xml` → `android:windowBackground = #0D0D0D` (fondo oscuro, consistente con la app). Así, aunque una pantalla no dibuje, se ve oscuro y no blanco.

### 2.3 GoogleFonts: fetch HTTP en runtime = fallo silencioso en release ⚠️
- `google_fonts` descarga las fuentes **por HTTP en runtime** y las cachea en el dispositivo. Si en Android la red no responde o falla durante el primer build de una pantalla, el estilo de texto puede no cargar / provocar un fallo que en release no se ve (issue conocido de "visual font swap" / fallo al cargar).
- **Cómo evitarlo (recomendado a futuro)**: **empaquetar las fuentes como assets** en `google_fonts/` y listarlas en `pubspec.yaml`. El paquete usa los archivos empaquetados ANTES que el HTTP → offline-first, sin fallos de red. Aplicar al menos a **Bangers** (usada en toda la app) y a las 12 fuentes del pizarrón.
- O desactivar el fetch runtime: `GoogleFonts.config.allowRuntimeFetching = false;` (exige tener las fuentes como assets).

### 2.4 Excepciones invisibles en release 🔍
- En release las excepciones que no pasan por `runZonedGuarded`/`FlutterError` son invisibles para el usuario Y los logs.
- **Recomendado a futuro**: conectar `FlutterError.onError` a un logger (o Crashlytics) y verificar release en un **dispositivo con `adb logcat`**, porque el mensaje del error real aparece en logcat aunque la UI esté en blanco. La app ya tiene `runZonedGuarded` que muestra pantalla roja, pero conviene loggear a un servicio.

### 2.5 Layout degenerado (dimensión 0 / NaN) 🟢 (ya mitigado)
- `LocaArranger.arrange` divide por ancho/alto; si una pantalla llega con alto 0 en la transición de ruta, generaba NaN → excepción de layout → en release queda en blanco.
- **Fix aplicado**: `loca_arranger.dart` retorna vacío si `width <= 0 || height <= 0 || cantidad < 1`.

### 2.6 Cache local fuera de try ⚠️ (ya mitigado)
- La lectura de `LocalCache` corría fuera del try en metas/retos/cartas; si `SharedPreferences` fallaba en Android, la pantalla reventaba.
- **Fix aplicado**: lectura de cache dentro de try/catch en `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart`.

---

## 3. Fixes ya aplicados (resumen)

| Cambio | Archivo |
|--------|---------|
| Desactivar Impeller (Skia) | `android/app/src/main/AndroidManifest.xml` |
| Fondo de ventana oscuro (`#0D0D0D`) | `android/app/src/main/res/values/styles.xml` y `values-night/styles.xml` |
| Arranger a prueba de dimensión 0 | `lib/widgets/loca_arranger.dart` |
| Cache local con try/catch | `metas_screen.dart`, `retos_screen.dart`, `letters_screen.dart` |

## 4. Pendiente / recomendado a futuro

- [ ] **Empaquetar fuentes como assets** (`google_fonts/`) — al menos Bangers — y desactivar/preservar el fetch a HTTP solo offline. Elimina la clase de fallos de fuentes en release.
- [ ] **Logging de release**: conectar `FlutterError.onError` a Crashlytics o a un logger y conservar `adb logcat` para diagnosticar.
- [ ] **Revalidar en el celular real** tras este APK: si Logros/Metas siguen blancas, capturar `adb logcat` en ese momento (el stack salta ahí aunque la UI esté en blanco).
- [ ] **Re-activar Impeller al actualizar Flutter** (cuando la versión madure) y validar en el mismo dispositivo; hasta entonces mantener Skia.

## 5. Cómo diagnosticar una pantalla blanca en Android (guía)
1. Celular conectado y autorizado: `adb devices` → debe decir `device` (no `offline`).
2. Instalar: `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
3. `adb logcat` y abrir la pantalla blanca; buscar `flutter`, `E/flutter`, `FATAL`, `Exception`.
4. Si hay excepción de build → aparece en logcat aun en release si se hookea `FlutterError.onError`.
5. Si NO hay excepción → es render (Impeller/no presentó frame): aplicar el fix de Impeller (ya hecho).

---

*Fuentes: docs.flutter.dev/perf/impeller, flutter/flutter issues (#190519, #189535), pub.dev/packages/google_fonts.*