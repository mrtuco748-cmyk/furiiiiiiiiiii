# Flujo de Trabajo de F.U.R.I

## Setup Inicial

```bash
# Clonar (cuando haya git)
git clone <repo-url>
cd furi_app

# Obtener dependencias
flutter pub get

# Configurar Supabase
# 1. Crear proyecto en supabase.com
# 2. Ejecutar supabase_schema.sql en SQL Editor
# 3. Copiar URL y anon key a lib/supabase_config.dart
# 4. Desplegar Edge Function: cd supabase/functions/send-push && supabase functions deploy send-push

# Configurar Firebase (para FCM)
# 1. Crear proyecto en console.firebase.google.com
# 2. Agregar apps Android/iOS
# 3. Descargar google-services.json y GoogleService-Info.plist
# 4. Ejecutar: flutterfire configure

# Configurar API key de Gemini
# 1. Obtener API key en aistudio.google.com
# 2. Colocar en lib/services/ai_config.dart

# Ejecutar
flutter run
```

## Pasos para Hacer un Cambio

### 1. Escribir test primero (TDD)
```dart
// test/providers/mi_provider_test.dart
void main() {
  test('descripción del comportamiento esperado', () {
    // arrange
    // act
    // assert
  });
}
```

### 2. Implementar
- Seguir convenciones del proyecto
- Respetar guía de estilo brutalista
- Manejar estados: loading, empty, error, data

### 3. Validar
```bash
flutter analyze
flutter test
```

### 4. Commit
```
feat: agregar funcionalidad X
fix: corregir bug en Y
refactor: simplificar Z
test: agregar tests para W
```

## Checklist de "Terminado"

- [ ] Pasa `flutter analyze` sin warnings
- [ ] Pasa `flutter test` (todos los tests verdes)
- [ ] Sigue la guía de estilo brutalista
- [ ] Maneja estados loading/empty/error/data
- [ ] Sin código muerto ni imports sin usar
- [ ] Sin valores hardcodeados (usar constantes)
- [ ] Sin secretos expuestos (API keys, tokens)
- [ ] Documentación actualizada (historial.md si aplica)

## Proceso de Deploy

### Build con script (recomendado - un solo comando)
```powershell
# Windows + APK en un solo comando
pwsh scripts/build-all.ps1

# Solo Windows
pwsh scripts/build-windows.ps1
# Output: build/windows/x64/runner/Release/furi_app.exe

# Solo APK
pwsh scripts/build-apk.ps1
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Los scripts verifican que Flutter este en PATH, que JAVA_HOME sea valido (APK) y reportan el tamaño del binario final. Los settings de Gradle (daemon off, heap 6G, compileSdk override) ya estan en `android/gradle.properties` y `android/build.gradle.kts` - no hay que pasar variables de entorno a mano.

### Firma de release (APK instalable en celulares)

Desde 2026-08-06 el APK release se firma con un **keystore propio** (`android/app/upload-keystore.jks`), no con la firma debug. Esto permite reinstalar sobre versiones anteriores sin conflicto de firma.

- Credenciales en `android/key.properties` (storePassword/keyPassword/keyAlias/storeFile) — **NO se commitea** (en `.gitignore`).
- Si borrás `key.properties` o el keystore, el release compila con firma vacía y Android no lo instala. Guardalos en lugar seguro.
- ⚠️ **IMPORTANTE**: nunca borres `android/app/upload-keystore.jks`. Si se pierde, no se puede actualizar la app sobre una instalación existente (habría que desinstalar y perder datos).

### Build manual (sin script)
```bash
flutter build windows --release
# Exe en build/windows/x64/runner/Release/

flutter build apk --release
# APK en build/app/outputs/flutter-apk/
```

### Supabase Edge Function
```bash
cd supabase
supabase functions deploy send-push
```

## Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| Chat no envía mensajes | Supabase caído o RLS bloqueando | Verificar conexión, RLS policies |
| Notificaciones push no llegan | Token FCM no registrado | Revisar `device_tokens` table |
| Error "getBoards() not found" | BoardProvider usa método que no existe | Eliminar BoardProvider o implementar método |
| Provider no encontrado | Provider no registrado en main.dart | Agregar a MultiProvider |
| Pantalla en blanco | Falta manejo de estados | Implementar loading/empty/error/data |
