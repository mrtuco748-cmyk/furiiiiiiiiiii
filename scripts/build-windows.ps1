# Compila el release de Windows de F.U.R.I
# Uso: pwsh scripts/build-windows.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host '=== F.U.R.I - Build Windows (release) ===' -ForegroundColor Cyan

# Verificar Flutter en PATH
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host 'ERROR: flutter no esta en PATH. Agrega D:\flutter\bin al PATH.' -ForegroundColor Red
  exit 1
}

# Ejecutar build
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: build windows fallo (exit code $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}

$exe = 'build\windows\x64\runner\Release\furi_app.exe'
if (Test-Path $exe) {
  $size = [math]::Round((Get-Item $exe).Length / 1MB, 2)
  Write-Host "OK: $exe ($size MB)" -ForegroundColor Green
} else {
  Write-Host "WARN: no se encontro $exe" -ForegroundColor Yellow
}