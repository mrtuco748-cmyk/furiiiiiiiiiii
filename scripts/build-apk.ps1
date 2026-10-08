# Compila los APKs release de F.U.R.I por arquitectura
# Uso: pwsh scripts/build-apk.ps1
# Genera 3 APKs separados (~20 MB c/u) en vez de uno universal (72 MB)
# que WhatsApp/Drive corrompen al transferir.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host '=== F.U.R.I - Build APK (release, split-per-abi) ===' -ForegroundColor Cyan

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

# Limpiar APKs viejos del directorio de output
$outputDir = 'build\app\outputs\flutter-apk'
Get-ChildItem "$outputDir\app-*-release.apk" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem "$outputDir\app-release.apk" -ErrorAction SilentlyContinue | Remove-Item -Force

# Ejecutar build (daemon=false viene en android/gradle.properties)
# --split-per-abi genera un APK por arquitectura: ~20 MB c/u (vs 72 MB universal)
# Los APKs separados se transfieren bien por WhatsApp/Drive sin corromperse.
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: build apk fallo (exit code $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}

# Listar APKs generados
$apks = Get-ChildItem "$outputDir\app-*-release.apk" -ErrorAction SilentlyContinue
if ($apks) {
  $total = 0
  foreach ($a in $apks) {
    $size = [math]::Round($a.Length / 1MB, 2)
    $total += $a.Length
    Write-Host "  $($a.Name)  ($size MB)" -ForegroundColor Green
  }
  $totalMb = [math]::Round($total / 1MB, 2)
  Write-Host "Total: $($apks.Count) APKs, $totalMb MB" -ForegroundColor Cyan
} else {
  Write-Host "WARN: no se encontraron APKs en $outputDir" -ForegroundColor Yellow
  exit 1
}