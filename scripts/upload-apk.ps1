# Sube los APKs split-per-abi a un release de GitHub
# Uso: pwsh scripts/upload-apk.ps1
# Requiere: gh CLI autenticado, APKs ya compilados con build-apk.ps1
[CmdletBinding()]
param(
  [string]$Tag,         # Ej: "v1.0.4". Si se omite, usa la version de pubspec.yaml
  [string]$Title,       # Titulo del release. Default: "FURI {tag}"
  [switch]$Draft        # Crear como draft (borrador)
)

$ErrorActionPreference = 'Stop'

# --- Detectar version desde pubspec.yaml ---
if (-not $Tag) {
  $pubspec = Get-Content 'pubspec.yaml' -Raw
  if ($pubspec -match 'version:\s+(\S+)') {
    $ver = $Matches[1] -replace '\+', '-'
    $Tag = "v$ver"
  } else {
    $Tag = "v1.0.0"
  }
}
if (-not $Title) { $Title = "FURI $Tag - APKs por arquitectura" }

Write-Host "=== F.U.R.I - Upload APKs a GitHub ===" -ForegroundColor Cyan
Write-Host "  Release: $Tag ($Title)" -ForegroundColor Cyan

# --- Verificar gh ---
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host 'ERROR: gh CLI no esta en PATH. Instalar desde https://cli.github.com/' -ForegroundColor Red
  exit 1
}

# --- Verificar APKs ---
$outputDir = 'build\app\outputs\flutter-apk'
$apks = Get-ChildItem "$outputDir\app-*-release.apk" -ErrorAction SilentlyContinue
if (-not $apks -or $apks.Count -eq 0) {
  Write-Host "ERROR: No se encontraron APKs en $outputDir. Ejecuta build-apk.ps1 primero." -ForegroundColor Red
  exit 1
}

Write-Host "`nAPKs a subir:" -ForegroundColor Cyan
foreach ($a in $apks) {
  $size = [math]::Round($a.Length / 1MB, 2)
  Write-Host "  $($a.Name)  ($size MB)" -ForegroundColor Green
}

# --- Crear release (si no existe) ---
Write-Host "`nCreando/verificando release $Tag..." -ForegroundColor Cyan
$releaseExists = gh release view $Tag --repo mrtuco748-cmyk/furiiiiiiiiiii 2>&1
if ($LASTEXITCODE -ne 0) {
  # Release no existe, crearlo
  $notes = @"
## APKs por arquitectura

Descarga el APK que coincida con tu celular:

| Arquitectura | Dispositivos | Archivo |
|---|---|---|
| **arm64-v8a** | La mayoria (64-bit moderno) | ``app-arm64-v8a-release.apk`` |
| **armeabi-v7a** | Celulares viejos (32-bit) | ``app-armeabi-v7a-release.apk`` |
| **x86_64** | Emuladores, tablets | ``app-x86_64-release.apk`` |

> Si no sabes cual descargar, prueba **arm64-v8a** (el mas comun).
"@
  $notesFile = Join-Path $env:TEMP "release-notes-$Tag.md"
  Set-Content -Path $notesFile -Value $notes -Encoding UTF8

  $createArgs = @('release', 'create', $Tag, '--repo', 'mrtuco748-cmyk/furiiiiiiiiiii', '--title', $Title, '--notes-file', $notesFile)
  if ($Draft) { $createArgs += '--draft' }
  # Agregar todos los APKs como assets
  foreach ($a in $apks) {
    $createArgs += $a.FullName
  }
  & gh @createArgs
  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: fallo al crear release." -ForegroundColor Red
    exit $LASTEXITCODE
  }
  Write-Host "Release $Tag creado con $($apks.Count) APKs." -ForegroundColor Green
} else {
  # Release existe, subir assets uno por uno
  Write-Host "Release $Tag ya existe. Subiendo APKs..." -ForegroundColor Yellow
  $anyFail = $false
  foreach ($a in $apks) {
    Write-Host "  Subiendo $($a.Name)..."
    gh release upload $Tag $a.FullName --repo mrtuco748-cmyk/furiiiiiiiiiii --clobber
    if ($LASTEXITCODE -ne 0) {
      Write-Host "  ERROR al subir $($a.Name)" -ForegroundColor Red
      $anyFail = $true
    } else {
      $size = [math]::Round($a.Length / 1MB, 2)
      Write-Host "  OK: $($a.Name) ($size MB)" -ForegroundColor Green
    }
  }
  if ($anyFail) {
    Write-Host 'ERROR: hubo fallos al subir los APKs al release.' -ForegroundColor Red
    exit 1
  }
}

# --- Verificar ---
Write-Host "`nVerificando assets del release..." -ForegroundColor Cyan
$assets = gh release view $Tag --repo mrtuco748-cmyk/furiiiiiiiiiii --json assets --jq '.assets[].name' 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Host 'ERROR: no se pudo verificar los assets del release.' -ForegroundColor Red
  exit 1
}
$assets | ForEach-Object { Write-Host "  $_" }

Write-Host "`nListo. Link de descarga:" -ForegroundColor Green
Write-Host "  https://github.com/mrtuco748-cmyk/furiiiiiiiiiii/releases/tag/$Tag" -ForegroundColor Cyan
