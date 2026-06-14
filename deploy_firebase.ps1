<#
  KO'Z SHIFO — build the Flutter web client to talk to an EXTERNAL backend and
  deploy it to Firebase Hosting (free Spark plan, no Blaze needed).

  The Firebase frontend can't run the backend itself, so it calls a separate
  free backend (see render.yaml) by absolute URL, baked in at build time via
  --dart-define=API_BASE_URL. CORS on the backend already allows the Firebase
  origin.

  Usage (from the repo root):
    ./deploy_firebase.ps1 -ApiBase https://kozshifo-api.onrender.com

  Later, ON THE CLINIC'S OWN SERVER (which serves the UI + API together on one
  origin), you do NOT need this script or a define — just rebuild same-origin:
    flutter build web --release
  and serve build/web from the backend (run_lan.ps1 already does this).
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBase
)

$ErrorActionPreference = 'Stop'
$ApiBase = $ApiBase.TrimEnd('/')
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "[..] Сборка Flutter web (API_BASE_URL=$ApiBase)..." -ForegroundColor Cyan
flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=$ApiBase
if ($LASTEXITCODE -ne 0) { throw 'flutter build web завершился с ошибкой' }

Write-Host '[..] Деплой на Firebase Hosting (проект kozshifo-32e6f)...' -ForegroundColor Cyan
# Use the local firebase-tools if the global CLI is not on PATH.
$fb = (Get-Command firebase -ErrorAction SilentlyContinue)
if ($fb) {
    firebase deploy --only hosting
} else {
    Write-Host '    (firebase не в PATH — пробую через npx)' -ForegroundColor DarkGray
    npx --yes firebase-tools deploy --only hosting
}
if ($LASTEXITCODE -ne 0) { throw 'firebase deploy завершился с ошибкой' }

Write-Host ''
Write-Host '==================================================================' -ForegroundColor Green
Write-Host '  Готово. Откройте https://kozshifo-32e6f.web.app и войдите:'        -ForegroundColor Green
Write-Host '     director@kozshifo.uz  /  KozShifo!Test2026'
Write-Host '==================================================================' -ForegroundColor Green
