# Compila Windows + APK de F.U.R.I en un solo comando
# Uso: pwsh scripts/build-all.ps1
# Uso: pwsh scripts/build-all.ps1 -Upload  (tambien sube a GitHub)
#
# Cada sub-build se ejecuta como subproceso (pwsh -File) para que su `exit N`
# se propague como $LASTEXITCODE sin terminar este script y el resumen se
# compute SIEMPRE al final. Si cualquiera falla, el script sale con exit 1.
[CmdletBinding()]
param(
  [switch]$Upload    # Subir APKs a GitHub despues de compilar
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host '=== F.U.R.I - Build ALL (Windows + APK) ===' -ForegroundColor Cyan

$results = @{}

# Windows
Write-Host ''
Write-Host '[1/2] Windows...' -ForegroundColor Cyan
& pwsh -NoProfile -File "$here\build-windows.ps1"
$results['windows'] = $LASTEXITCODE

# APK (split-per-abi: 3 APKs ~20 MB c/u)
Write-Host ''
Write-Host '[2/2] APK...' -ForegroundColor Cyan
& pwsh -NoProfile -File "$here\build-apk.ps1"
$results['apk'] = $LASTEXITCODE

# Upload (opcional)
if ($Upload -and $results['apk'] -eq 0) {
  Write-Host ''
  Write-Host '[3/3] Upload a GitHub...' -ForegroundColor Cyan
  & pwsh -NoProfile -File "$here\upload-apk.ps1"
  $results['upload'] = $LASTEXITCODE
}

# Resumen
Write-Host ''
Write-Host '=== Resumen ===' -ForegroundColor Cyan
$ok = $true
foreach ($k in $results.Keys) {
  $code = $results[$k]
  if ($code -eq 0) {
    Write-Host "  $k : OK" -ForegroundColor Green
  } else {
    Write-Host "  $k : FALLO (exit $code)" -ForegroundColor Red
    $ok = $false
  }
}

if ($ok) {
  Write-Host 'TODO OK' -ForegroundColor Green
  exit 0
} else {
  Write-Host 'HUBO FALLAS' -ForegroundColor Red
  exit 1
}
