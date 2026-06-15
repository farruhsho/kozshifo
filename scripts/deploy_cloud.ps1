# KO'Z SHIFO — деплой backend в облако (Cloud Run + Cloud SQL Postgres).
# ПРЕДУСЛОВИЕ: проект kozshifo-prod переведён на план Blaze (биллинг включён),
# gcloud установлен и авторизован (см. docs/FIREBASE.md).
# Запуск:  powershell -ExecutionPolicy Bypass -File scripts/deploy_cloud.ps1

$ErrorActionPreference = 'Stop'
$g = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
$PROJECT = 'kozshifo-prod'
$REGION  = 'europe-west1'   # должен совпадать с firebase.json rewrites!
$SQL_INSTANCE = 'kozshifo-db'
$SQL_CONN = "${PROJECT}:${REGION}:${SQL_INSTANCE}"

function New-Secret([int]$len = 48) {
    -join ((65..90) + (97..122) + (48..57) | Get-Random -Count $len | ForEach-Object { [char]$_ })
}

Write-Host '[1/6] Включаю API...'
& $g services enable run.googleapis.com cloudbuild.googleapis.com sqladmin.googleapis.com artifactregistry.googleapis.com --project $PROJECT

Write-Host '[2/6] Cloud SQL (Postgres 16, минимальный тариф)...'
$exists = & $g sql instances list --project $PROJECT --format="value(name)" 2>$null
if ($exists -notcontains $SQL_INSTANCE) {
    & $g sql instances create $SQL_INSTANCE --database-version=POSTGRES_16 `
        --tier=db-f1-micro --region=$REGION --project $PROJECT
}
$dbs = & $g sql databases list --instance=$SQL_INSTANCE --project $PROJECT --format="value(name)" 2>$null
if ($dbs -notcontains 'kozshifo') {
    & $g sql databases create kozshifo --instance=$SQL_INSTANCE --project $PROJECT
}

Write-Host '[3/6] Генерирую секреты (СОХРАНИ ИХ — печатаются один раз)...'
$DB_PW   = New-Secret 32
$SECRET  = New-Secret 48
$DIR_PW  = "Dir!$(New-Secret 12)"
& $g sql users create kozshifo --instance=$SQL_INSTANCE --password=$DB_PW --project $PROJECT 2>$null
if (-not $?) { & $g sql users set-password kozshifo --instance=$SQL_INSTANCE --password=$DB_PW --project $PROJECT }
Write-Host "  DB password:       $DB_PW"
Write-Host "  SECRET_KEY:        $SECRET"
Write-Host "  Director password: $DIR_PW   (логин director@kozshifo.uz)"

Write-Host '[4/6] Деплой backend в Cloud Run (Cloud Build соберёт Dockerfile удалённо)...'
# DATABASE_URL через unix-сокет Cloud SQL; --port 8000 = порт из Dockerfile.
$DB_URL = "postgresql+psycopg://kozshifo:${DB_PW}@/kozshifo?host=/cloudsql/${SQL_CONN}"
& $g run deploy kozshifo-api --source backend --region $REGION --project $PROJECT `
    --allow-unauthenticated --port 8000 --memory 512Mi `
    --add-cloudsql-instances $SQL_CONN `
    --set-env-vars "ENVIRONMENT=production,SECRET_KEY=$SECRET,SEED_DIRECTOR_PASSWORD=$DIR_PW,DATABASE_URL=$DB_URL,UPLOAD_DIR=/app/data/uploads,TZ=Asia/Tashkent"

Write-Host '[5/6] Hosting с реврайтами /api/** -> Cloud Run...'
Set-Location $PSScriptRoot\..
firebase deploy --only hosting --project $PROJECT

Write-Host '[6/6] Проверка...'
Start-Sleep -Seconds 5
Invoke-WebRequest -Uri 'https://kozshifo-prod.web.app/health' -UseBasicParsing | Select-Object -ExpandProperty Content
Write-Host 'Готово: https://kozshifo-prod.web.app'
Write-Host 'ВНИМАНИЕ: загруженные файлы (B-сканы) на Cloud Run эфемерны до переезда на свой сервер.'
