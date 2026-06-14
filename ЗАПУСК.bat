@echo off
chcp 65001 >nul
title KO'Z SHIFO
rem ============================================================
rem  KO'Z SHIFO - one-click launcher.
rem  Starts the server (it serves BOTH the web app and the API on
rem  one address) and opens the app in the browser AUTOMATICALLY,
rem  but only AFTER the server is actually ready (polls /health),
rem  so there is no "connection error" from opening too early.
rem
rem  Login works ONLY at http://127.0.0.1:8000 (this file).
rem  Do NOT open kozshifo-32e6f.web.app - no server there yet (404).
rem  (ASCII-only on purpose: Cyrillic in a .bat breaks cmd parsing.)
rem ============================================================
cd /d "%~dp0backend"
echo.
echo   ============================================================
echo    KO'Z SHIFO zapuskaetsya...
echo    Brauzer otkroetsya SAM, kogda server budet gotov.
echo    (pervyy zapusk mozhet zanyat do minuty - podozhdi)
echo.
echo    Adres:  http://127.0.0.1:8000
echo    Vhod:   knopka "Superadmin"  (ili director@kozshifo.uz / Director!2026)
echo.
echo    Eto okno NE zakryvay. Ostanovit server - zakroy okno.
echo    NE otkryvay kozshifo-32e6f.web.app - tam servera net (404).
echo   ============================================================
echo.

rem Background opener: waits until the server answers, then opens the browser.
start "" powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 90;$i++){try{$null=Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:8000/health' -TimeoutSec 1; Start-Process 'http://127.0.0.1:8000'; break}catch{Start-Sleep -Seconds 1}}"

rem The server itself (keeps this window; logs are shown here).
".venv\Scripts\python.exe" -m uvicorn app.main:app --host 127.0.0.1 --port 8000

echo.
echo   Server ostanovlen. Eto okno mozhno zakryt.
pause
