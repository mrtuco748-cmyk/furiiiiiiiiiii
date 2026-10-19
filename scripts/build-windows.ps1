# Compila el release de Windows de F.U.R.I
# Uso: pwsh scripts/build-windows.ps1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host '=== F.U.R.I - Build Windows (release) ===' -ForegroundColor Cyan

# Verificar Flutter en PATH
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  if (Test-Path "D:\flutter\bin") {
    $env:PATH = "D:\flutter\bin;$env:PATH"
  } else {
    Write-Host 'ERROR: flutter no esta en PATH. Agrega D:\flutter\bin al PATH.' -ForegroundColor Red
    exit 1
  }
}

# Detener furi_app si esta corriendo para evitar bloqueos de archivos DLL o .exe
$running = Get-Process -Name furi_app -ErrorAction SilentlyContinue
if ($running) {
  Write-Host 'Deteniendo instancia activa de furi_app para actualizar archivos...' -ForegroundColor Yellow
  Stop-Process -Name furi_app -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
}

# Inicializar MSVC si es necesario
if (-not (Get-Command cl -ErrorAction SilentlyContinue)) {
  $vcvars = "D:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
  if (Test-Path $vcvars) {
    Write-Host "Activando entorno MSVC desde $vcvars..." -ForegroundColor Cyan
    cmd /c "`"$vcvars`" amd64 && set" | ForEach-Object {
      if ($_ -match '^(.*?)=(.*)$') {
        Set-Item -Path "env:\$($matches[1])" -Value $matches[2]
      }
    }
  }
}

# Ejecutar build
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERROR: build windows fallo (exit code $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}

if (Test-Path "build\windows\x64\install") {
  Copy-Item -Path "build\windows\x64\install\*" -Destination "build\windows\x64\runner\Release" -Recurse -Force
}

$exe = 'build\windows\x64\runner\Release\furi_app.exe'
if (Test-Path $exe) {
  $size = [math]::Round((Get-Item $exe).Length / 1MB, 2)
  Write-Host "OK: $exe ($size MB)" -ForegroundColor Green
} else {
  Write-Host "WARN: no se encontro $exe" -ForegroundColor Yellow
}