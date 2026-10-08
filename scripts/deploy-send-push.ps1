# Deploy de la Edge Function send-push + secretos, via Management API.
# Sin CLI de supabase. Usa el PAT guardado en scripts/.env y el service
# account de Firebase en scripts/.env.firebase (ambos gitignoreados).
# Uso: pwsh scripts/deploy-send-push.ps1
[CmdletBinding()]
param(
  [string]$ProjectRef = 'nruyjpvoplkilcxqnees'
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Cargar PAT ────────────────────────────────────────────────
$PAT = $null
Get-Content "$here\.env" | ForEach-Object {
  if ($_ -match '^SUPABASE_ACCESS_TOKEN=(.+)$') { $PAT = $Matches[1].Trim() }
}
if (-not $PAT) {
  Write-Host 'ERROR: no hay SUPABASE_ACCESS_TOKEN en scripts/.env' -ForegroundColor Red
  exit 1
}
$headers = @{ Authorization = "Bearer $PAT" }

Write-Host "=== Deploy send-push (ref $ProjectRef) ===" -ForegroundColor Cyan

# ── 1) Setear FIREBASE_SERVICE_ACCOUNT ───────────────────────
if (Test-Path "$here\.env.firebase") {
  $saJson = (Get-Content "$here\.env.firebase" -Raw).Trim()
  $secretObj = @{ name = 'FIREBASE_SERVICE_ACCOUNT'; value = $saJson }
  $secretBody = ConvertTo-Json -InputObject @($secretObj) -Compress
  try {
    Invoke-RestMethod -Method Post `
      -Uri "https://api.supabase.com/v1/projects/$ProjectRef/secrets" `
      -Headers $headers -ContentType 'application/json' -Body $secretBody
    Write-Host '  FIREBASE_SERVICE_ACCOUNT seteado OK.' -ForegroundColor Green
  } catch {
    Write-Host "  ERROR seteando secreto: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response -and $_.ErrorDetails.Message) {
      Write-Host "  Detalle: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
  }
} else {
  Write-Host '  No se encontro scripts/.env.firebase, omitiendo secreto (solo deploy).' -ForegroundColor Yellow
}

# ── 2) Deploy de la funcion ──────────────────────────────────
$indexTs = Join-Path $here '..\supabase\functions\send-push\index.ts'
if (-not (Test-Path $indexTs)) { Write-Host "ERROR: no existe $indexTs" -ForegroundColor Red; exit 1 }
$file = [IO.File]::ReadAllText((Resolve-Path $indexTs))
$metadata = '{"name":"send-push","entrypoint_path":"index.ts","verify_jwt":false}'

$boundary = [Guid]::NewGuid().ToString()
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("--$boundary")
$lines.Add('Content-Disposition: form-data; name="metadata"')
$lines.Add('Content-Type: application/json'); $lines.Add('')
$lines.Add($metadata)
$lines.Add("--$boundary")
$lines.Add('Content-Disposition: form-data; name="file"; filename="index.ts"')
$lines.Add('Content-Type: application/typescript'); $lines.Add('')
$lines.Add($file)
$lines.Add("--$boundary--"); $lines.Add('')
$body = [string]::Join("`r`n", $lines)

try {
  $res = Invoke-RestMethod -Method Post `
    -Uri "https://api.supabase.com/v1/projects/$ProjectRef/functions/deploy?slug=send-push" `
    -Headers $headers -ContentType "multipart/form-data; boundary=$boundary" -Body $body
  Write-Host "  Deploy OK: slug=$($res.slug) status=$($res.status) version=$($res.version)" -ForegroundColor Green
} catch {
  Write-Host "  ERROR en deploy: $($_.Exception.Message)" -ForegroundColor Red
  if ($_.ErrorDetails.Message) { Write-Host "  Detalle: $($_.ErrorDetails.Message)" -ForegroundColor Red }
  exit 1
}
