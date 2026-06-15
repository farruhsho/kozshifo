<#
  KO'Z SHIFO — поделиться приложением по ВРЕМЕННОЙ публичной HTTPS-ссылке (бесплатно).

  Поднимает «всё-в-одном» бэкенд (он же отдаёт Flutter-веб UI) на localhost:8000 и
  открывает его через бесплатный Cloudflare Quick Tunnel — БЕЗ аккаунта Cloudflare,
  БЕЗ карты, БЕЗ лимита по времени. Вы получаете публичный адрес вида
  https://что-то.trycloudflare.com, который отдаёт И UI, И API на одном origin,
  поэтому вход работает без единой правки кода.

  Используйте, чтобы дать тестировщикам доступ, пока не приедет ваш сервер.
  Держите это окно открытым: ссылка живёт только пока скрипт запущен и меняется
  при каждом перезапуске.

  Данные: dev-режим = SQLite-файл backend/kozshifo.db (хранится у вас на диске и
  переживает перезапуск). Демо-логин: director@kozshifo.uz / Director!2026

  ВНИМАНИЕ: ссылка публичная — у кого она есть, тот зайдёт. Не выкладывайте её в
  открытый доступ; это для теста с доверенными людьми.

  Запуск:  правый клик -> «Выполнить с помощью PowerShell»   (админ не нужен)
#>
param([int]$Port = 8000)

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'backend'
$python  = Join-Path $backend '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) { $python = 'python' }

# --- гарантируем cloudflared.exe (скачиваем один раз, если нет) ---
$cf = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
if (-not $cf) {
    $tools = Join-Path $root '.tools'
    $cf = Join-Path $tools 'cloudflared.exe'
    if (-not (Test-Path $cf)) {
        New-Item -ItemType Directory -Force -Path $tools | Out-Null
        Write-Host '[..] Скачиваю cloudflared (один раз, ~25 МБ)...' -ForegroundColor Cyan
        $url = 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe'
        Invoke-WebRequest -Uri $url -OutFile $cf
    }
}
Write-Host "[ok] cloudflared: $cf" -ForegroundColor Green

# --- стартуем бэкенд (UI + API на localhost:Port) ---
Write-Host '[..] Запускаю бэкенд KO''Z SHIFO...' -ForegroundColor Cyan
$uvic = Start-Process -FilePath $python `
    -ArgumentList @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', "$Port") `
    -WorkingDirectory $backend -PassThru -WindowStyle Minimized

try {
    # ждём, пока /health ответит
    $ok = $false
    for ($i = 0; $i -lt 40; $i++) {
        try {
            Invoke-WebRequest "http://127.0.0.1:$Port/health" -TimeoutSec 2 -UseBasicParsing | Out-Null
            $ok = $true; break
        } catch { Start-Sleep -Milliseconds 500 }
    }
    if (-not $ok) { throw "Бэкенд не поднялся на порту $Port" }
    Write-Host '[ok] Бэкенд запущен.' -ForegroundColor Green
    Write-Host ''
    Write-Host '==================================================================' -ForegroundColor Cyan
    Write-Host '  Открываю бесплатный публичный туннель. Ваша ссылка появится ниже'  -ForegroundColor Cyan
    Write-Host '  как  https://<что-то>.trycloudflare.com'                          -ForegroundColor Yellow
    Write-Host '  Откройте её в браузере и войдите:'                                 -ForegroundColor Cyan
    Write-Host '     director@kozshifo.uz  /  Director!2026'
    Write-Host '  Держите это окно открытым. Ctrl+C — остановить.'                   -ForegroundColor DarkGray
    Write-Host '==================================================================' -ForegroundColor Cyan
    Write-Host ''
    & $cf tunnel --url "http://127.0.0.1:$Port"
}
finally {
    if ($uvic -and -not $uvic.HasExited) {
        Write-Host ''
        Write-Host '[..] Останавливаю бэкенд...' -ForegroundColor DarkGray
        Stop-Process -Id $uvic.Id -Force -ErrorAction SilentlyContinue
    }
}
