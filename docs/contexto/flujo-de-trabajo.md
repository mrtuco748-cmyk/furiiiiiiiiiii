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

### Android
```bash
flutter build apk --release
# El APK está en build/app/outputs/flutter-apk/
```

### Windows
```bash
flutter build windows --release
# El ejecutable está en build/windows/x64/runner/Release/
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
