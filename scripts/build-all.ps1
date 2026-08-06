# Compila Windows + APK de F.U.R.I en un solo comando
# Uso: pwsh scripts/build-all.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host '=== F.U.R.I - Build ALL (Windows + APK) ===' -ForegroundColor Cyan

$results = @{}

# Windows
Write-Host ''
Write-Host '[1/2] Windows...' -ForegroundColor Cyan
& "$here\build-windows.ps1"
$results['windows'] = $LASTEXITCODE

# APK
Write-Host ''
Write-Host '[2/2] APK...' -ForegroundColor Cyan
& "$here\build-apk.ps1"
$results['apk'] = $LASTEXITCODE

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