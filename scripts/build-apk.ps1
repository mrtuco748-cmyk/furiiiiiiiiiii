# Compila el APK release de F.U.R.I
# Uso: pwsh scripts/build-apk.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host '=== F.U.R.I - Build APK (release) ===' -ForegroundColor Cyan

# Verificar Flutter en PATH
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host 'ERROR: flutter no esta en PATH. Agrega D:\flutter\bin al PATH.' -ForegroundColor Red
  exit 1
}

# Verificar JAVA_HOME
if (-not $env:JAVA_HOME -or -not (Test-Path $env:JAVA_HOME)) {
  Write-Host 'ERROR: JAVA_HOME no definido o invalido. Debe apuntar a D:\jdk17\jdk17.' -ForegroundColor Red
  exit 1
}

# Ejecutar build (daemon=false viene en android/gradle.properties)
# --split-per-abi genera un APK por arquitectura (arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: build apk fallo (exit code $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}

$apks = Get-ChildItem 'build\app\outputs\flutter-apk\app-*-release.apk' -ErrorAction SilentlyContinue
if ($apks) {
  foreach ($a in $apks) {
    $size = [math]::Round($a.Length / 1MB, 2)
    Write-Host "OK: $($a.Name) ($size MB)" -ForegroundColor Green
  }
} else {
  Write-Host "WARN: no se encontraron APKs en build\app\outputs\flutter-apk" -ForegroundColor Yellow
}